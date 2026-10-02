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
      var raw = url.trim();
      if (!raw.startsWith('http://') && !raw.startsWith('https://') && raw.isNotEmpty) {
        raw = 'https://$raw';
      }
      final parsed = Uri.parse(raw);
      if (queryParams.isEmpty) {
        return parsed;
      }
      final activeParams = <String, String>{};
      for (final p in queryParams) {
        if (p.isEnabled && p.key.trim().isNotEmpty) {
          activeParams[p.key.trim()] = p.value;
        }
      }
      return parsed.replace(
        queryParameters: activeParams.isEmpty
            ? (queryParams.any((p) => p.key.trim().isNotEmpty) ? {} : (parsed.queryParameters.isEmpty ? null : parsed.queryParameters))
            : activeParams,
      );
    } catch (_) {
      return Uri();
    }
  }

  static List<KeyValuePair> syncQueryParamsFromUrl(String url, List<KeyValuePair> currentParams) {
    final hashIdx = url.indexOf('#');
    final cleanUrl = hashIdx != -1 ? url.substring(0, hashIdx) : url;
    final queryIdx = cleanUrl.indexOf('?');

    final disabledParams = currentParams.where((p) => !p.isEnabled && p.key.trim().isNotEmpty).toList();

    if (queryIdx == -1 || queryIdx >= cleanUrl.length - 1) {
      return disabledParams;
    }

    final queryString = cleanUrl.substring(queryIdx + 1);
    final pairs = queryString.split('&');
    final result = <KeyValuePair>[];

    for (final pair in pairs) {
      if (pair.isEmpty) continue;
      final eqIdx = pair.indexOf('=');
      final String k;
      final String v;
      if (eqIdx == -1) {
        k = Uri.decodeQueryComponent(pair);
        v = '';
      } else {
        k = Uri.decodeQueryComponent(pair.substring(0, eqIdx));
        v = Uri.decodeQueryComponent(pair.substring(eqIdx + 1));
      }
      result.add(KeyValuePair(key: k, value: v, isEnabled: true));
    }

    // Preserve disabled params that were previously present (if key is not active in new URL)
    for (final dp in disabledParams) {
      if (!result.any((r) => r.key.trim().toLowerCase() == dp.key.trim().toLowerCase())) {
        result.add(dp);
      }
    }

    return result;
  }

  static String buildUrlWithParams(String currentUrl, List<KeyValuePair> params) {
    final hashIdx = currentUrl.indexOf('#');
    final fragment = hashIdx != -1 ? currentUrl.substring(hashIdx) : '';
    final urlWithoutFragment = hashIdx != -1 ? currentUrl.substring(0, hashIdx) : currentUrl;

    final queryIdx = urlWithoutFragment.indexOf('?');
    final baseUrl = queryIdx != -1 ? urlWithoutFragment.substring(0, queryIdx) : urlWithoutFragment;

    final activeParams = params.where((p) => p.isEnabled && p.key.trim().isNotEmpty).toList();
    if (activeParams.isEmpty) {
      return '$baseUrl$fragment';
    }

    final queryString = activeParams.map((p) {
      final k = Uri.encodeQueryComponent(p.key.trim());
      final v = Uri.encodeQueryComponent(p.value);
      return '$k=$v';
    }).join('&');

    return '$baseUrl?$queryString$fragment';
  }

  Map<String, String> get resolvedHeaders {
    final map = <String, String>{};
    for (final h in headers) {
      if (h.isEnabled && h.key.trim().isNotEmpty) {
        final lk = h.key.trim().toLowerCase();
        if (lk == 'content-length' ||
            lk == 'host' ||
            lk == 'connection' ||
            lk == 'transfer-encoding') {
          continue;
        }
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
