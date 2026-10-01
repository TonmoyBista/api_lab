import 'dart:async';
import 'dart:convert';
import '../models/http_traffic.dart';
import '../models/mock_rule.dart';
import '../repositories/repositories.dart';

class InterceptResult {
  final bool isMocked;
  final HttpResponseData? mockResponse;
  final MockRule? matchedRule;

  const InterceptResult({
    required this.isMocked,
    this.mockResponse,
    this.matchedRule,
  });
}

class InterceptRequestUseCase {
  final IMockRuleRepository _mockRuleRepository;
  final ITrafficRepository _trafficRepository;

  InterceptRequestUseCase({
    required this._mockRuleRepository,
    required this._trafficRepository,
  });

  Future<InterceptResult> evaluateRequest(HttpRequestData request) async {
    final matchedRule = _mockRuleRepository.findMatchingRule(request);

    if (matchedRule != null) {
      if (matchedRule.responseDelayMs > 0) {
        await Future.delayed(Duration(milliseconds: matchedRule.responseDelayMs));
      }

      final resolvedBody = matchedRule.resolveResponseBody(request);
      final resolvedHeaders = matchedRule.resolveResponseHeaders(request);
      final bodyBytes = utf8.encode(resolvedBody);

      final mockResponse = HttpResponseData(
        statusCode: matchedRule.responseStatusCode,
        statusReason: matchedRule.responseStatusReason.isNotEmpty 
            ? matchedRule.responseStatusReason 
            : _getStatusReason(matchedRule.responseStatusCode),
        headers: resolvedHeaders,
        body: resolvedBody,
        timestamp: DateTime.now(),
        durationMs: matchedRule.responseDelayMs,
        contentLength: bodyBytes.length,
      );

      final trafficItem = TrafficItem(
        id: request.id,
        request: request,
        response: mockResponse,
        status: TrafficStatus.mocked,
        isMocked: true,
        mockRuleId: matchedRule.id,
      );

      _trafficRepository.addTraffic(trafficItem);

      return InterceptResult(
        isMocked: true,
        mockResponse: mockResponse,
        matchedRule: matchedRule,
      );
    }

    // Not mocked: register as pending traffic
    final pendingTraffic = TrafficItem(
      id: request.id,
      request: request,
      status: TrafficStatus.pending,
      isMocked: false,
    );
    _trafficRepository.addTraffic(pendingTraffic);

    return const InterceptResult(isMocked: false);
  }

  void completeTraffic(String requestId, HttpResponseData response) {
    final existing = _trafficRepository.getById(requestId);
    if (existing != null) {
      _trafficRepository.updateTraffic(existing.copyWith(
        response: response,
        status: response.isServerError 
            ? TrafficStatus.failed 
            : TrafficStatus.completed,
      ));
    }
  }

  void failTraffic(String requestId, String error) {
    final existing = _trafficRepository.getById(requestId);
    if (existing != null) {
      _trafficRepository.updateTraffic(existing.copyWith(
        status: TrafficStatus.failed,
        error: error,
      ));
    }
  }

  String _getStatusReason(int statusCode) {
    switch (statusCode) {
      case 200: return 'OK';
      case 201: return 'Created';
      case 202: return 'Accepted';
      case 204: return 'No Content';
      case 301: return 'Moved Permanently';
      case 302: return 'Found';
      case 304: return 'Not Modified';
      case 400: return 'Bad Request';
      case 401: return 'Unauthorized';
      case 403: return 'Forbidden';
      case 404: return 'Not Found';
      case 405: return 'Method Not Allowed';
      case 409: return 'Conflict';
      case 422: return 'Unprocessable Entity';
      case 429: return 'Too Many Requests';
      case 500: return 'Internal Server Error';
      case 502: return 'Bad Gateway';
      case 503: return 'Service Unavailable';
      case 504: return 'Gateway Timeout';
      default: return 'Custom Status';
    }
  }
}
