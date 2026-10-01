import 'dart:convert';

class KeyValuePair {
  final String key;
  final String value;
  final bool isEnabled;

  const KeyValuePair({
    required this.key,
    required this.value,
    this.isEnabled = true,
  });

  KeyValuePair copyWith({
    String? key,
    String? value,
    bool? isEnabled,
  }) {
    return KeyValuePair(
      key: key ?? this.key,
      value: value ?? this.value,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'value': value,
    'isEnabled': isEnabled,
  };

  factory KeyValuePair.fromJson(Map<String, dynamic> json) => KeyValuePair(
    key: json['key'] as String? ?? '',
    value: json['value'] as String? ?? '',
    isEnabled: json['isEnabled'] as bool? ?? true,
  );
}

class ApiRequestModel {
  final String id;
  final String name;
  final String method;
  final String url;
  final List<KeyValuePair> headers;
  final List<KeyValuePair> queryParams;
  final String bodyType; // 'none', 'json', 'form', 'text'
  final String bodyContent;
  final String authType; // 'none', 'bearer', 'basic'
  final String authBearerToken;
  final String authUsername;
  final String authPassword;
  final DateTime updatedAt;

  const ApiRequestModel({
    required this.id,
    this.name = 'New Request',
    this.method = 'GET',
    this.url = 'https://jsonplaceholder.typicode.com/todos/1',
    this.headers = const [
      KeyValuePair(key: 'Accept', value: 'application/json'),
    ],
    this.queryParams = const [],
    this.bodyType = 'none',
    this.bodyContent = '{\n  "title": "Test Item",\n  "completed": false\n}',
    this.authType = 'none',
    this.authBearerToken = '',
    this.authUsername = '',
    this.authPassword = '',
    required this.updatedAt,
  });

  Uri get fullUri {
    try {
      final base = Uri.parse(url);
      final activeParams = <String, String>{};
      for (final p in queryParams) {
        if (p.isEnabled && p.key.trim().isNotEmpty) {
          activeParams[p.key.trim()] = p.value;
        }
      }
      final mergedParams = Map<String, String>.from(base.queryParameters)..addAll(activeParams);
      return base.replace(queryParameters: mergedParams.isEmpty ? null : mergedParams);
    } catch (_) {
      return Uri();
    }
  }

  Map<String, String> get resolvedHeaders {
    final map = <String, String>{};
    for (final h in headers) {
      if (h.isEnabled && h.key.trim().isNotEmpty) {
        map[h.key.trim()] = h.value;
      }
    }
    if (authType == 'bearer' && authBearerToken.trim().isNotEmpty) {
      map['Authorization'] = 'Bearer ${authBearerToken.trim()}';
    } else if (authType == 'basic') {
      final credentials = base64Encode(utf8.encode('$authUsername:$authPassword'));
      map['Authorization'] = 'Basic $credentials';
    }
    if (bodyType == 'json' && !map.containsKey('Content-Type') && !map.containsKey('content-type')) {
      map['Content-Type'] = 'application/json';
    }
    return map;
  }

  ApiRequestModel copyWith({
    String? id,
    String? name,
    String? method,
    String? url,
    List<KeyValuePair>? headers,
    List<KeyValuePair>? queryParams,
    String? bodyType,
    String? bodyContent,
    String? authType,
    String? authBearerToken,
    String? authUsername,
    String? authPassword,
    DateTime? updatedAt,
  }) {
    return ApiRequestModel(
      id: id ?? this.id,
      name: name ?? this.name,
      method: method ?? this.method,
      url: url ?? this.url,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      bodyType: bodyType ?? this.bodyType,
      bodyContent: bodyContent ?? this.bodyContent,
      authType: authType ?? this.authType,
      authBearerToken: authBearerToken ?? this.authBearerToken,
      authUsername: authUsername ?? this.authUsername,
      authPassword: authPassword ?? this.authPassword,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'method': method,
    'url': url,
    'headers': headers.map((e) => e.toJson()).toList(),
    'queryParams': queryParams.map((e) => e.toJson()).toList(),
    'bodyType': bodyType,
    'bodyContent': bodyContent,
    'authType': authType,
    'authBearerToken': authBearerToken,
    'authUsername': authUsername,
    'authPassword': authPassword,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ApiRequestModel.fromJson(Map<String, dynamic> json) => ApiRequestModel(
    id: json['id'] as String,
    name: json['name'] as String? ?? 'Untitled',
    method: json['method'] as String? ?? 'GET',
    url: json['url'] as String? ?? '',
    headers: (json['headers'] as List? ?? [])
        .map((e) => KeyValuePair.fromJson(e as Map<String, dynamic>))
        .toList(),
    queryParams: (json['queryParams'] as List? ?? [])
        .map((e) => KeyValuePair.fromJson(e as Map<String, dynamic>))
        .toList(),
    bodyType: json['bodyType'] as String? ?? 'none',
    bodyContent: json['bodyContent'] as String? ?? '',
    authType: json['authType'] as String? ?? 'none',
    authBearerToken: json['authBearerToken'] as String? ?? '',
    authUsername: json['authUsername'] as String? ?? '',
    authPassword: json['authPassword'] as String? ?? '',
    updatedAt: json['updatedAt'] != null 
        ? DateTime.parse(json['updatedAt'] as String) 
        : DateTime.now(),
  );
}

class ApiResponseModel {
  final int statusCode;
  final String statusReason;
  final Map<String, String> headers;
  final String body;
  final int durationMs;
  final int sizeBytes;
  final DateTime timestamp;

  const ApiResponseModel({
    required this.statusCode,
    required this.statusReason,
    this.headers = const {},
    this.body = '',
    required this.durationMs,
    required this.sizeBytes,
    required this.timestamp,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
  bool get isRedirect => statusCode >= 300 && statusCode < 400;
  bool get isError => statusCode >= 400;

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

  Map<String, dynamic> toJson() => {
    'statusCode': statusCode,
    'statusReason': statusReason,
    'headers': headers,
    'body': body,
    'durationMs': durationMs,
    'sizeBytes': sizeBytes,
    'timestamp': timestamp.toIso8601String(),
  };
}

class ApiCollection {
  final String id;
  final String name;
  final String description;
  final List<ApiRequestModel> requests;

  const ApiCollection({
    required this.id,
    required this.name,
    this.description = '',
    this.requests = const [],
  });

  ApiCollection copyWith({
    String? id,
    String? name,
    String? description,
    List<ApiRequestModel>? requests,
  }) {
    return ApiCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      requests: requests ?? this.requests,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'requests': requests.map((r) => r.toJson()).toList(),
  };

  factory ApiCollection.fromJson(Map<String, dynamic> json) => ApiCollection(
    id: json['id'] as String,
    name: json['name'] as String? ?? 'Untitled Collection',
    description: json['description'] as String? ?? '',
    requests: (json['requests'] as List? ?? [])
        .map((r) => ApiRequestModel.fromJson(r as Map<String, dynamic>))
        .toList(),
  );
}
