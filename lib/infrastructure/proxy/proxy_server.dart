import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../../domain/models/http_traffic.dart';
import '../../domain/models/mcp_and_ai.dart';
import '../../domain/use_cases/intercept_request_use_case.dart';
import 'ssl_certificate_manager.dart';

class ProxyServer {
  final InterceptRequestUseCase _interceptUseCase;
  ServerSocket? _serverSocket;
  HttpServer? _internalHttpServer;
  bool _isRunning = false;
  ProxyConfig _config;
  String _detectedLanIp = '127.0.0.1';

  final StreamController<String> _logController = StreamController<String>.broadcast();
  Stream<String> get logStream => _logController.stream;

  ProxyServer({
    required this._interceptUseCase,
    this._config = const ProxyConfig(),
  });

  bool get isRunning => _isRunning;
  ProxyConfig get config => _config;
  String get detectedLanIp => _detectedLanIp;

  void updateConfig(ProxyConfig newConfig) {
    _config = newConfig;
  }

  Future<void> _detectLanIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) {
            _detectedLanIp = addr.address;
            return;
          }
        }
      }
    } catch (_) {}
  }

  Future<bool> start() async {
    if (_isRunning) return true;

    try {
      await _detectLanIp();

      // 1. Start internal loopback HTTP server to handle plain HTTP and Gateway proxy requests
      _internalHttpServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _internalHttpServer!.listen(
        _handleHttpOrGateway,
        onError: (e) => _log('Internal HTTP server error: $e'),
      );

      // 2. Start public ServerSocket bound to 0.0.0.0 (anyIPv4) so 127.0.0.1 and Wi-Fi LAN IP (e.g. 192.168.0.101) both work
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, _config.port, shared: true);
      _isRunning = true;
      _log('ApiLab Proxy Server active on 0.0.0.0:${_config.port} (Local Wi-Fi: $_detectedLanIp:${_config.port})');

      _serverSocket!.listen(
        _handleClientSocket,
        onError: (e) {
          _log('Server socket error: $e');
        },
        onDone: () {
          _isRunning = false;
        },
      );
      return true;
    } catch (e) {
      _log('Failed to start proxy server: $e');
      _isRunning = false;
      return false;
    }
  }

  Future<void> stop() async {
    if (!_isRunning) return;
    await _serverSocket?.close();
    await _internalHttpServer?.close(force: true);
    _serverSocket = null;
    _internalHttpServer = null;
    _isRunning = false;
    _log('Proxy server stopped.');
  }

  void _handleClientSocket(Socket clientSocket) {
    final buffer = <int>[];
    StreamSubscription<List<int>>? sub;

    sub = clientSocket.listen(
      (data) async {
        buffer.addAll(data);
        final str = utf8.decode(buffer, allowMalformed: true);

        // Wait until at least the first HTTP header line is received
        if (str.contains('\r\n')) {
          sub?.pause();

          final firstLine = str.split('\r\n').first.trim();
          final tokens = firstLine.split(' ');
          final method = tokens.isNotEmpty ? tokens[0].toUpperCase() : '';

          if (method == 'CONNECT') {
            await _handleHttpsConnect(clientSocket, sub, tokens);
          } else {
            await _forwardToInternalHttp(clientSocket, sub, buffer);
          }
        }
      },
      onError: (e) {
        _log('Client socket connection error: $e');
        clientSocket.destroy();
      },
      onDone: () {
        clientSocket.destroy();
      },
    );
  }

  Future<void> _handleHttpsConnect(
    Socket clientSocket,
    StreamSubscription<List<int>>? sub,
    List<String> tokens,
  ) async {
    final target = tokens.length > 1 ? tokens[1] : '';
    final cleanTarget = target.replaceAll('/', '').trim();
    final parts = cleanTarget.split(':');
    final targetHost = parts[0];
    final targetPort = parts.length > 1 ? int.tryParse(parts[1]) ?? 443 : 443;

    try {
      clientSocket.write('HTTP/1.1 200 Connection Established\r\n\r\n');
      await clientSocket.flush();
    } catch (e) {
      _log('Error sending 200 Connection Established: $e');
      clientSocket.destroy();
      return;
    }

    if (_config.enableSslMitm) {
      try {
        final secureContext = await SslCertificateManager.getSecurityContextForHost(targetHost);
        final secureClient = await SecureSocket.secureServer(
          clientSocket,
          secureContext,
        );
        _handleDecryptedHttpsConnection(secureClient, targetHost, targetPort);
      } catch (e) {
        _log('TLS Handshake with client failed for $targetHost ($e). Closing socket.');
        clientSocket.destroy();
      }
    } else {
      // Pass-through tunnel if MITM is disabled
      _handleRawTunnel(clientSocket, sub, targetHost, targetPort);
    }
  }

  Future<void> _forwardToInternalHttp(
    Socket clientSocket,
    StreamSubscription<List<int>>? sub,
    List<int> initialBytes,
  ) async {
    if (_internalHttpServer == null) {
      clientSocket.destroy();
      return;
    }

    try {
      final loopbackSocket = await Socket.connect(
        InternetAddress.loopbackIPv4,
        _internalHttpServer!.port,
      );

      // Send the bytes already received
      loopbackSocket.add(initialBytes);

      // Forward subsequent client data to internal HTTP server
      sub?.onData(loopbackSocket.add);
      sub?.onError((_) => loopbackSocket.destroy());
      sub?.onDone(() => loopbackSocket.destroy());
      sub?.resume();

      // Forward internal HTTP responses back to client
      loopbackSocket.listen(
        clientSocket.add,
        onError: (_) => clientSocket.destroy(),
        onDone: () => clientSocket.destroy(),
      );
    } catch (e) {
      _log('Failed forwarding to internal HTTP server: $e');
      clientSocket.destroy();
    }
  }

  void _handleDecryptedHttpsConnection(
    SecureSocket secureClient,
    String targetHost,
    int targetPort,
  ) {
    final buffer = <int>[];
    StreamSubscription? sub;

    sub = secureClient.listen(
      (data) async {
        buffer.addAll(data);

        final headerEndIndex = _findHeaderEnd(buffer);
        if (headerEndIndex == -1) return;

        sub?.pause();

        final headerBytes = buffer.sublist(0, headerEndIndex);
        final headerStr = utf8.decode(headerBytes, allowMalformed: true);
        final lines = headerStr.split('\r\n');
        if (lines.isEmpty) {
          secureClient.destroy();
          return;
        }

        final requestLine = lines[0].split(' ');
        final method = requestLine.isNotEmpty ? requestLine[0] : 'GET';
        final rawPath = requestLine.length > 1 ? requestLine[1] : '/';

        final headers = <String, String>{};
        for (var i = 1; i < lines.length; i++) {
          final line = lines[i];
          final colon = line.indexOf(':');
          if (colon != -1) {
            headers[line.substring(0, colon).trim().toLowerCase()] =
                line.substring(colon + 1).trim();
          }
        }

        final contentLength = int.tryParse(headers['content-length'] ?? '0') ?? 0;
        final totalNeeded = headerEndIndex + 4 + contentLength;

        if (buffer.length < totalNeeded) {
          sub?.resume();
          return;
        }

        final bodyBytes = buffer.sublist(headerEndIndex + 4, totalNeeded);
        final bodyStr = utf8.decode(bodyBytes, allowMalformed: true);

        final fullUrl = 'https://$targetHost$rawPath';
        final parsedUri = Uri.tryParse(fullUrl);
        final queryParams = parsedUri?.queryParameters ?? {};
        const uuid = Uuid();
        final reqId = uuid.v4();

        final reqData = HttpRequestData(
          id: reqId,
          method: method,
          url: fullUrl,
          headers: headers,
          queryParams: queryParams,
          body: bodyStr,
          timestamp: DateTime.now(),
          clientIp: secureClient.remoteAddress.address,
        );

        final evalResult = await _interceptUseCase.evaluateRequest(reqData);

        if (evalResult.isMocked && evalResult.mockResponse != null) {
          final mock = evalResult.mockResponse!;

          final mockBytes = utf8.encode(mock.body);
          final resHeaderBuffer = StringBuffer();
          resHeaderBuffer.write('HTTP/1.1 ${mock.statusCode} ${mock.statusReason}\r\n');

          final sanitizedHeaders = <String, String>{};
          mock.headers.forEach((k, v) {
            final lk = k.toLowerCase().trim();
            // NEVER pass chunked transfer or gzip encoding on mock responses!
            if (lk != 'transfer-encoding' &&
                lk != 'content-encoding' &&
                lk != 'content-length' &&
                lk != 'connection' &&
                lk != 'server' &&
                lk != 'date') {
              sanitizedHeaders[k] = v;
              resHeaderBuffer.write('$k: $v\r\n');
            }
          });

          // Ensure proper content-type is sent
          if (!sanitizedHeaders.keys.any((k) => k.toLowerCase() == 'content-type')) {
            resHeaderBuffer.write('Content-Type: application/json; charset=utf-8\r\n');
            sanitizedHeaders['content-type'] = 'application/json; charset=utf-8';
          }

          resHeaderBuffer.write('Content-Length: ${mockBytes.length}\r\n');
          resHeaderBuffer.write('X-Mocked-By: ApiLab\r\n');
          resHeaderBuffer.write('Connection: close\r\n\r\n');

          secureClient.add(utf8.encode(resHeaderBuffer.toString()));
          secureClient.add(mockBytes);
          await secureClient.flush();
          await secureClient.close();

          _interceptUseCase.completeTraffic(
            reqId,
            HttpResponseData(
              statusCode: mock.statusCode,
              statusReason: mock.statusReason,
              headers: sanitizedHeaders,
              body: mock.body,
              timestamp: DateTime.now(),
              durationMs: mock.durationMs,
              contentLength: mockBytes.length,
            ),
          );
          return;
        }

        // Forward to upstream
        try {
          final stopwatch = Stopwatch()..start();
          final client = HttpClient();
          client.badCertificateCallback = (cert, host, port) => true;

          final uri = Uri.parse(fullUrl);
          final upstreamReq = await client.openUrl(method, uri);

          headers.forEach((k, v) {
            final lk = k.toLowerCase();
            if (lk != 'host' && lk != 'content-length' && lk != 'accept-encoding') {
              upstreamReq.headers.set(k, v);
            }
          });

          if (bodyBytes.isNotEmpty) {
            upstreamReq.add(bodyBytes);
          }

          final upstreamRes = await upstreamReq.close();
          stopwatch.stop();

          final resBodyBytes = await upstreamRes.fold<List<int>>([], (p, e) => p..addAll(e));
          final resBodyStr = utf8.decode(resBodyBytes, allowMalformed: true);

          final resHeadersMap = <String, String>{};
          upstreamRes.headers.forEach((name, values) {
            resHeadersMap[name] = values.join('; ');
          });

          final resHeaderBuffer = StringBuffer();
          resHeaderBuffer.write('HTTP/1.1 ${upstreamRes.statusCode} ${upstreamRes.reasonPhrase}\r\n');
          resHeadersMap.forEach((k, v) {
            final lk = k.toLowerCase();
            if (lk != 'transfer-encoding' && lk != 'content-length' && lk != 'content-encoding') {
              resHeaderBuffer.write('$k: $v\r\n');
            }
          });
          resHeaderBuffer.write('Content-Length: ${resBodyBytes.length}\r\n');
          resHeaderBuffer.write('Connection: close\r\n\r\n');

          secureClient.add(utf8.encode(resHeaderBuffer.toString()));
          secureClient.add(resBodyBytes);
          await secureClient.flush();
          await secureClient.close();

          _interceptUseCase.completeTraffic(
            reqId,
            HttpResponseData(
              statusCode: upstreamRes.statusCode,
              statusReason: upstreamRes.reasonPhrase,
              headers: resHeadersMap,
              body: resBodyStr,
              timestamp: DateTime.now(),
              durationMs: stopwatch.elapsedMilliseconds,
              contentLength: resBodyBytes.length,
            ),
          );
        } catch (e) {
          _interceptUseCase.failTraffic(reqId, 'HTTPS forward error: $e');
          try {
            secureClient.write('HTTP/1.1 502 Bad Gateway\r\nConnection: close\r\n\r\n');
            await secureClient.flush();
            await secureClient.close();
          } catch (_) {}
        }
      },
      onError: (e) {
        secureClient.destroy();
      },
      onDone: () {
        secureClient.destroy();
      },
    );
  }

  int _findHeaderEnd(List<int> bytes) {
    for (var i = 0; i < bytes.length - 3; i++) {
      if (bytes[i] == 13 && bytes[i + 1] == 10 && bytes[i + 2] == 13 && bytes[i + 3] == 10) {
        return i;
      }
    }
    return -1;
  }

  Future<void> _handleRawTunnel(
    Socket clientSocket,
    StreamSubscription<List<int>>? sub,
    String targetHost,
    int targetPort,
  ) async {
    const uuid = Uuid();
    final reqId = uuid.v4();
    final reqData = HttpRequestData(
      id: reqId,
      method: 'CONNECT',
      url: 'https://$targetHost:$targetPort',
      timestamp: DateTime.now(),
      clientIp: clientSocket.remoteAddress.address,
    );

    await _interceptUseCase.evaluateRequest(reqData);

    try {
      final targetSocket = await Socket.connect(targetHost, targetPort, timeout: const Duration(seconds: 10));
      final stopwatch = Stopwatch()..start();
      var bytesTransferred = 0;

      sub?.onData((data) {
        bytesTransferred += data.length;
        targetSocket.add(data);
      });
      sub?.onError((_) {
        clientSocket.destroy();
        targetSocket.destroy();
      });
      sub?.onDone(() => targetSocket.destroy());
      sub?.resume();

      targetSocket.listen(
        (data) {
          bytesTransferred += data.length;
          clientSocket.add(data);
        },
        onError: (_) {
          clientSocket.destroy();
          targetSocket.destroy();
        },
        onDone: () {
          stopwatch.stop();
          clientSocket.destroy();
          _interceptUseCase.completeTraffic(
            reqId,
            HttpResponseData(
              statusCode: 200,
              statusReason: 'Tunnel Closed',
              headers: {'Content-Type': 'application/octet-stream'},
              body: '[HTTPS Tunnel - $bytesTransferred bytes transferred]',
              timestamp: DateTime.now(),
              durationMs: stopwatch.elapsedMilliseconds,
              contentLength: bytesTransferred,
            ),
          );
        },
      );
    } catch (e) {
      _interceptUseCase.failTraffic(reqId, 'Tunnel connection failed: $e');
      clientSocket.destroy();
    }
  }

  Future<void> _handleHttpOrGateway(HttpRequest clientRequest) async {
    const uuid = Uuid();
    final reqId = uuid.v4();
    final stopwatch = Stopwatch()..start();

    // Check if target is forwarded or direct
    var targetUrlStr = clientRequest.uri.toString();
    final overrideHeader = clientRequest.headers.value('x-apilab-target');
    if (overrideHeader != null && overrideHeader.isNotEmpty) {
      targetUrlStr = overrideHeader;
    } else if (clientRequest.uri.queryParameters.containsKey('apilab_target')) {
      targetUrlStr = clientRequest.uri.queryParameters['apilab_target']!;
    }

    final headersMap = _extractHeaders(clientRequest.headers);
    String bodyStr = '';
    try {
      final bodyBytes = await clientRequest.fold<List<int>>([], (prev, element) => prev..addAll(element));
      if (bodyBytes.isNotEmpty) {
        bodyStr = utf8.decode(bodyBytes, allowMalformed: true);
      }
    } catch (_) {}

    final reqData = HttpRequestData(
      id: reqId,
      method: clientRequest.method,
      url: targetUrlStr,
      headers: headersMap,
      queryParams: clientRequest.uri.queryParameters,
      body: bodyStr,
      timestamp: DateTime.now(),
      clientIp: clientRequest.connectionInfo?.remoteAddress.address ?? '127.0.0.1',
    );

    final evalResult = await _interceptUseCase.evaluateRequest(reqData);

    if (evalResult.isMocked && evalResult.mockResponse != null) {
      final mock = evalResult.mockResponse!;
      final mockBytes = utf8.encode(mock.body);
      clientRequest.response.statusCode = mock.statusCode;

      final sanitizedHeaders = <String, String>{};
      mock.headers.forEach((k, v) {
        final lk = k.toLowerCase().trim();
        if (lk != 'transfer-encoding' &&
            lk != 'content-encoding' &&
            lk != 'content-length' &&
            lk != 'connection' &&
            lk != 'server' &&
            lk != 'date') {
          clientRequest.response.headers.set(k, v);
          sanitizedHeaders[k] = v;
        }
      });

      if (!sanitizedHeaders.keys.any((k) => k.toLowerCase() == 'content-type')) {
        clientRequest.response.headers.set('content-type', 'application/json; charset=utf-8');
        sanitizedHeaders['content-type'] = 'application/json; charset=utf-8';
      }

      clientRequest.response.headers.set('content-length', mockBytes.length.toString());
      clientRequest.response.headers.set('x-apilab-mocked', 'true');
      clientRequest.response.headers.set('connection', 'close');
      clientRequest.response.add(mockBytes);
      await clientRequest.response.close();

      _interceptUseCase.completeTraffic(
        reqId,
        HttpResponseData(
          statusCode: mock.statusCode,
          statusReason: mock.statusReason,
          headers: sanitizedHeaders,
          body: mock.body,
          timestamp: DateTime.now(),
          durationMs: stopwatch.elapsedMilliseconds,
          contentLength: mockBytes.length,
        ),
      );
      return;
    }

    // Forward to upstream
    try {
      final uri = Uri.parse(targetUrlStr);
      if (!uri.hasScheme) {
        clientRequest.response.statusCode = HttpStatus.ok;
        clientRequest.response.headers.contentType = ContentType.json;
        clientRequest.response.write(jsonEncode({
          'status': 'ApiLab Proxy Active',
          'port': _config.port,
          'localIp': _detectedLanIp,
          'message': 'Send HTTP/HTTPS requests configured with this proxy (e.g. $_detectedLanIp:${_config.port}) or use X-ApiLab-Target header.',
        }));
        await clientRequest.response.close();
        return;
      }

      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;

      final upstreamReq = await client.openUrl(clientRequest.method, uri);
      headersMap.forEach((k, v) {
        final lk = k.toLowerCase();
        if (lk != 'host' && lk != 'content-length') {
          upstreamReq.headers.set(k, v);
        }
      });

      if (bodyStr.isNotEmpty) {
        upstreamReq.write(bodyStr);
      }

      final upstreamRes = await upstreamReq.close();
      stopwatch.stop();

      final resBodyBytes = await upstreamRes.fold<List<int>>([], (prev, element) => prev..addAll(element));
      final resBodyStr = utf8.decode(resBodyBytes, allowMalformed: true);

      final resHeadersMap = <String, String>{};
      upstreamRes.headers.forEach((name, values) {
        resHeadersMap[name] = values.join(', ');
      });

      clientRequest.response.statusCode = upstreamRes.statusCode;
      resHeadersMap.forEach((k, v) {
        final lk = k.toLowerCase();
        if (lk != 'content-length' && lk != 'transfer-encoding' && lk != 'content-encoding') {
          clientRequest.response.headers.set(k, v);
        }
      });
      clientRequest.response.add(resBodyBytes);
      await clientRequest.response.close();

      _interceptUseCase.completeTraffic(
        reqId,
        HttpResponseData(
          statusCode: upstreamRes.statusCode,
          statusReason: upstreamRes.reasonPhrase,
          headers: resHeadersMap,
          body: resBodyStr,
          timestamp: DateTime.now(),
          durationMs: stopwatch.elapsedMilliseconds,
          contentLength: resBodyBytes.length,
        ),
      );
    } catch (e) {
      stopwatch.stop();
      _interceptUseCase.failTraffic(reqId, 'Forwarding error: $e');
      clientRequest.response.statusCode = HttpStatus.badGateway;
      clientRequest.response.write('ApiLab Proxy Gateway Error: $e');
      await clientRequest.response.close();
    }
  }

  Map<String, String> _extractHeaders(HttpHeaders headers) {
    final map = <String, String>{};
    headers.forEach((name, values) {
      map[name] = values.join('; ');
    });
    return map;
  }

  void _log(String message) {
    _logController.add('[${DateTime.now().toIso8601String().substring(11, 19)}] $message');
  }

  void dispose() {
    stop();
    _logController.close();
  }
}
