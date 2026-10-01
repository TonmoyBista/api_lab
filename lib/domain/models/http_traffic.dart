import 'dart:convert';

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
  final DateTime timestamp;
  final int durationMs;
  final int contentLength;

  const HttpResponseData({
    required this.statusCode,
    required this.statusReason,
    this.headers = const {},
    this.body = '',
    required this.timestamp,
    this.durationMs = 0,
    this.contentLength = 0,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
  bool get isRedirect => statusCode >= 300 && statusCode < 400;
  bool get isClientError => statusCode >= 400 && statusCode < 500;
  bool get isServerError => statusCode >= 500 && statusCode < 600;

  bool get isJson {
    final contentType = headers['content-type'] ?? headers['Content-Type'] ?? '';
    return contentType.toLowerCase().contains('application/json');
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
    DateTime? timestamp,
    int? durationMs,
    int? contentLength,
  }) {
    return HttpResponseData(
      statusCode: statusCode ?? this.statusCode,
      statusReason: statusReason ?? this.statusReason,
      headers: headers ?? this.headers,
      body: body ?? this.body,
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
