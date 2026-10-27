import 'dart:convert';
import 'dart:typed_data';

enum TrafficStatus {
  pending,
  intercepted,
  completed,
  failed,
  mocked,
}

class HttpRequestData {
  final String id;
  final String method;
  final String url;
  final Map<String, String> headers;
  final Map<String, String> queryParams;
  final String body;
  final DateTime timestamp;
  final String clientIp;

  const HttpRequestData({
    required this.id,
    required this.method,
    required this.url,
    this.headers = const {},
    this.queryParams = const {},
    this.body = '',
    required this.timestamp,
    this.clientIp = '127.0.0.1',
  });

  Uri get uri => Uri.tryParse(url) ?? Uri();

  String get path => uri.path.isEmpty ? '/' : uri.path;

  String get pathWithQuery {
    final q = uri.query;
    return q.isNotEmpty ? '$path?$q' : (path.isEmpty ? '/' : path);
  }

  Map<String, String> get resolvedQueryParams {
    if (queryParams.isNotEmpty) return queryParams;
    return uri.queryParameters;
  }

  String get host => uri.host;

  int get port => uri.port;

  HttpRequestData copyWith({
    String? id,
    String? method,
    String? url,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    String? body,
    DateTime? timestamp,
    String? clientIp,
  }) {
    return HttpRequestData(
      id: id ?? this.id,
      method: method ?? this.method,
      url: url ?? this.url,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      clientIp: clientIp ?? this.clientIp,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'method': method,
    'url': url,
    'headers': headers,
    'queryParams': queryParams,
    'body': body,
    'timestamp': timestamp.toIso8601String(),
    'clientIp': clientIp,
  };

  factory HttpRequestData.fromJson(Map<String, dynamic> json) => HttpRequestData(
    id: json['id'] as String,
    method: json['method'] as String? ?? 'GET',
    url: json['url'] as String? ?? '',
    headers: Map<String, String>.from(json['headers'] as Map? ?? {}),
    queryParams: Map<String, String>.from(json['queryParams'] as Map? ?? {}),
    body: json['body'] as String? ?? '',
    timestamp: json['timestamp'] != null 
        ? DateTime.parse(json['timestamp'] as String) 
        : DateTime.now(),
    clientIp: json['clientIp'] as String? ?? '127.0.0.1',
  );
}

class HttpResponseData {
  final int statusCode;
  final String statusReason;
  final Map<String, String> headers;
  final String body;
  final Uint8List? bodyBytes;
  final DateTime timestamp;
  final int durationMs;
  final int contentLength;

  const HttpResponseData({
    required this.statusCode,
    required this.statusReason,
    this.headers = const {},
    this.body = '',
    this.bodyBytes,
    required this.timestamp,
    this.durationMs = 0,
    this.contentLength = 0,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
  bool get isRedirect => statusCode >= 300 && statusCode < 400;
  bool get isClientError => statusCode >= 400 && statusCode < 500;
  bool get isServerError => statusCode >= 500 && statusCode < 600;

  String get contentType {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase().trim() == 'content-type') {
        return entry.value.toLowerCase().trim();
      }
    }
    return '';
  }

  bool get isJson {
    return contentType.contains('application/json');
  }

  bool get isImage {
    return isImageResponse(headers, bodyBytes, body: body);
  }

  Uint8List? get imageBytes {
    if (bodyBytes != null && bodyBytes!.isNotEmpty) {
      return bodyBytes;
    }
    return tryDecodeImageBytesFromString(body);
  }

  static bool isSvgContentType(Map<String, String> headers) {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase().trim() == 'content-type') {
        return entry.value.toLowerCase().contains('image/svg');
      }
    }
    return false;
  }

  static bool isImageResponse(
    Map<String, String> headers,
    Uint8List? bytes, {
    String body = '',
  }) {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase().trim() == 'content-type') {
        final ct = entry.value.toLowerCase().trim();
        if (ct.startsWith('image/')) {
          return true;
        }
      }
    }
    if (hasImageMagicBytes(bytes)) {
      return true;
    }
    if (body.isNotEmpty) {
      final head = body.length > 64 ? body.substring(0, 64).trimLeft() : body.trimLeft();
      if (head.startsWith('data:image/') && head.contains(';base64,')) {
        return true;
      }
    }
    return false;
  }

  static bool hasImageMagicBytes(Uint8List? bytes) {
    if (bytes == null || bytes.length < 4) return false;
    // PNG: 89 50 4E 47 0D 0A 1A 0A
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }
    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return true;
    }
    // GIF: 47 49 46 38 ("GIF8")
    if (bytes.length >= 6 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return true;
    }
    // WebP: "RIFF" .... "WEBP"
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return true;
    }
    // BMP: "BM" (42 4D)
    if (bytes[0] == 0x42 && bytes[1] == 0x4D) {
      return true;
    }
    // ICO / CUR: 00 00 01 00 or 00 00 02 00
    if (bytes[0] == 0x00 &&
        bytes[1] == 0x00 &&
        (bytes[2] == 0x01 || bytes[2] == 0x02) &&
        bytes[3] == 0x00) {
      return true;
    }
    return false;
  }

  static Uint8List? tryDecodeImageBytesFromString(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('data:image/') && trimmed.contains(';base64,')) {
      final idx = trimmed.indexOf(';base64,');
      final b64 = trimmed.substring(idx + 8).trim();
      try {
        return base64Decode(b64);
      } catch (_) {}
    }
    try {
      final decoded = base64Decode(trimmed);
      if (hasImageMagicBytes(decoded)) {
        return decoded;
      }
    } catch (_) {}
    return null;
  }

  String get formattedBody {
    if (body.isEmpty) return '';
    try {
      final decoded = jsonDecode(body);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(decoded);
    } catch (_) {
      return body;
    }
  }

  HttpResponseData copyWith({
    int? statusCode,
    String? statusReason,
    Map<String, String>? headers,
    String? body,
    Uint8List? bodyBytes,
    DateTime? timestamp,
    int? durationMs,
    int? contentLength,
  }) {
    return HttpResponseData(
      statusCode: statusCode ?? this.statusCode,
      statusReason: statusReason ?? this.statusReason,
      headers: headers ?? this.headers,
      body: body ?? this.body,
      bodyBytes: bodyBytes ?? this.bodyBytes,
      timestamp: timestamp ?? this.timestamp,
      durationMs: durationMs ?? this.durationMs,
      contentLength: contentLength ?? this.contentLength,
    );
  }

  Map<String, dynamic> toJson() => {
    'statusCode': statusCode,
    'statusReason': statusReason,
    'headers': headers,
    'body': body,
    'timestamp': timestamp.toIso8601String(),
    'durationMs': durationMs,
    'contentLength': contentLength,
  };

  factory HttpResponseData.fromJson(Map<String, dynamic> json) => HttpResponseData(
    statusCode: json['statusCode'] as int? ?? 200,
    statusReason: json['statusReason'] as String? ?? 'OK',
    headers: Map<String, String>.from(json['headers'] as Map? ?? {}),
    body: json['body'] as String? ?? '',
    timestamp: json['timestamp'] != null 
        ? DateTime.parse(json['timestamp'] as String) 
        : DateTime.now(),
    durationMs: json['durationMs'] as int? ?? 0,
    contentLength: json['contentLength'] as int? ?? 0,
  );
}

class TrafficItem {
  final String id;
  final HttpRequestData request;
  final HttpResponseData? response;
  final TrafficStatus status;
  final bool isMocked;
  final String? mockRuleId;
  final String? error;
  final bool isPinned;

  const TrafficItem({
    required this.id,
    required this.request,
    this.response,
    this.status = TrafficStatus.pending,
    this.isMocked = false,
    this.mockRuleId,
    this.error,
    this.isPinned = false,
  });

  TrafficItem copyWith({
    String? id,
    HttpRequestData? request,
    HttpResponseData? response,
    TrafficStatus? status,
    bool? isMocked,
    String? mockRuleId,
    String? error,
    bool? isPinned,
  }) {
    return TrafficItem(
      id: id ?? this.id,
      request: request ?? this.request,
      response: response ?? this.response,
      status: status ?? this.status,
      isMocked: isMocked ?? this.isMocked,
      mockRuleId: mockRuleId ?? this.mockRuleId,
      error: error ?? this.error,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'request': request.toJson(),
    'response': response?.toJson(),
    'status': status.name,
    'isMocked': isMocked,
    'mockRuleId': mockRuleId,
    'error': error,
    'isPinned': isPinned,
  };
}
