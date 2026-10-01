import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../models/api_request.dart';

class ReplayRequestUseCase {
  Future<ApiResponseModel> execute(ApiRequestModel request) async {
    final uri = request.fullUri;
    final headers = request.resolvedHeaders;
    final stopwatch = Stopwatch()..start();

    try {
      final ioClient = HttpClient()..badCertificateCallback = (cert, host, port) => true;
      final client = IOClient(ioClient);
      http.Response response;

      switch (request.method.toUpperCase()) {
        case 'GET':
          response = await client.get(uri, headers: headers);
          break;
        case 'POST':
          response = await client.post(
            uri,
            headers: headers,
            body: request.bodyType == 'none' ? null : request.bodyContent,
          );
          break;
        case 'PUT':
          response = await client.put(
            uri,
            headers: headers,
            body: request.bodyType == 'none' ? null : request.bodyContent,
          );
          break;
        case 'PATCH':
          response = await client.patch(
            uri,
            headers: headers,
            body: request.bodyType == 'none' ? null : request.bodyContent,
          );
          break;
        case 'DELETE':
          response = await client.delete(
            uri,
            headers: headers,
            body: request.bodyType == 'none' ? null : request.bodyContent,
          );
          break;
        case 'HEAD':
          response = await client.head(uri, headers: headers);
          break;
        default:
          final req = http.Request(request.method, uri);
          req.headers.addAll(headers);
          if (request.bodyType != 'none' && request.bodyContent.isNotEmpty) {
            req.body = request.bodyContent;
          }
          final streamed = await client.send(req);
          response = await http.Response.fromStream(streamed);
      }

      stopwatch.stop();

      return ApiResponseModel(
        statusCode: response.statusCode,
        statusReason: response.reasonPhrase ?? 'OK',
        headers: response.headers,
        body: response.body,
        durationMs: stopwatch.elapsedMilliseconds,
        sizeBytes: response.bodyBytes.length,
        timestamp: DateTime.now(),
      );
    } on SocketException catch (e) {
      stopwatch.stop();
      return ApiResponseModel(
        statusCode: 0,
        statusReason: 'Network Error: ${e.message}',
        headers: {},
        body: jsonEncode({'error': 'Connection failed', 'details': e.message, 'address': e.address?.host}),
        durationMs: stopwatch.elapsedMilliseconds,
        sizeBytes: 0,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      stopwatch.stop();
      return ApiResponseModel(
        statusCode: 0,
        statusReason: 'Execution Error: $e',
        headers: {},
        body: jsonEncode({'error': e.toString()}),
        durationMs: stopwatch.elapsedMilliseconds,
        sizeBytes: 0,
        timestamp: DateTime.now(),
      );
    }
  }
}
