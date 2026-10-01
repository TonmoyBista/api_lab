import 'dart:convert';
import 'dart:math';
import 'http_traffic.dart';

enum ConditionSource {
  any,
  query,
  body,
  header,
}

enum ConditionOperator {
  equals,              // =
  notEquals,           // !=
  contains,            // contain
  greaterThan,         // >
  lessThan,            // <
  greaterThanOrEqual,  // >=
  lessThanOrEqual,     // <=
  regex,               // regex
}

class MockCondition {
  final String id;
  final ConditionSource source;
  final String field; // e.g. 'isUserType', 'userid', 'Authorization'
  final ConditionOperator operator;
  final String value; // expected value
  final bool isEnabled;

  const MockCondition({
    required this.id,
    this.source = ConditionSource.any,
    required this.field,
    this.operator = ConditionOperator.equals,
    this.value = '',
    this.isEnabled = true,
  });

  bool evaluate(HttpRequestData request) {
    if (!isEnabled) return true;
    final actual = _extractActualValue(request);
    return _compare(actual, value, operator);
  }

  String? _extractActualValue(HttpRequestData request) {
    final targetField = field.trim();
    if (targetField.isEmpty) return null;

    switch (source) {
      case ConditionSource.query:
        return _lookupQueryParam(request, targetField);
      case ConditionSource.header:
        return _lookupHeader(request, targetField);
      case ConditionSource.body:
        return _lookupBody(request, targetField);
      case ConditionSource.any:
        // Try query params first
        final queryVal = _lookupQueryParam(request, targetField);
        if (queryVal != null) return queryVal;
        // Try json/body
        final bodyVal = _lookupBody(request, targetField);
        if (bodyVal != null) return bodyVal;
        // Try headers
        final headerVal = _lookupHeader(request, targetField);
        if (headerVal != null) return headerVal;
        // Try general properties
        if (targetField.toLowerCase() == 'url') return request.url;
        if (targetField.toLowerCase() == 'path') return request.path;
        if (targetField.toLowerCase() == 'method') return request.method;
        return null;
    }
  }

  static String? _lookupQueryParam(HttpRequestData request, String field) {
    final lowerField = field.toLowerCase();
    for (final entry in request.resolvedQueryParams.entries) {
      if (entry.key.toLowerCase() == lowerField) {
        return entry.value;
      }
    }
    return null;
  }

  static String? _lookupHeader(HttpRequestData request, String field) {
    final lowerField = field.toLowerCase();
    for (final entry in request.headers.entries) {
      if (entry.key.toLowerCase() == lowerField) {
        return entry.value;
      }
    }
    return null;
  }

  static String? _lookupBody(HttpRequestData request, String field) {
    if (request.body.isEmpty) return null;
    final lowerField = field.toLowerCase();
    try {
      final decoded = json.decode(request.body);
      final found = _searchJson(decoded, lowerField);
      if (found != null) return found.toString();
    } catch (_) {}
    if (lowerField == 'body' || lowerField == 'raw' || lowerField.isEmpty) {
      return request.body;
    }
    return null;
  }

  static dynamic _searchJson(dynamic data, String targetKey) {
    if (data is Map) {
      for (final entry in data.entries) {
        final keyStr = entry.key.toString();
        if (keyStr.toLowerCase() == targetKey) {
          return entry.value;
        }
        final nested = _searchJson(entry.value, targetKey);
        if (nested != null) return nested;
      }
    } else if (data is List) {
      for (final item in data) {
        final nested = _searchJson(item, targetKey);
        if (nested != null) return nested;
      }
    }
    return null;
  }

  static bool _compare(String? actual, String expected, ConditionOperator op) {
    if (actual == null) {
      return op == ConditionOperator.notEquals;
    }

    final actTrim = actual.trim();
    final expTrim = expected.trim();

    // Check numeric comparison capability
    final actNum = double.tryParse(actTrim);
    final expNum = double.tryParse(expTrim);
    final bothNumeric = actNum != null && expNum != null;

    switch (op) {
      case ConditionOperator.equals:
        if (bothNumeric) return actNum == expNum;
        return actTrim.toLowerCase() == expTrim.toLowerCase();
      case ConditionOperator.notEquals:
        if (bothNumeric) return actNum != expNum;
        return actTrim.toLowerCase() != expTrim.toLowerCase();
      case ConditionOperator.contains:
        return actTrim.toLowerCase().contains(expTrim.toLowerCase());
      case ConditionOperator.greaterThan:
        if (bothNumeric) return actNum > expNum;
        return actTrim.compareTo(expTrim) > 0;
      case ConditionOperator.lessThan:
        if (bothNumeric) return actNum < expNum;
        return actTrim.compareTo(expTrim) < 0;
      case ConditionOperator.greaterThanOrEqual:
        if (bothNumeric) return actNum >= expNum;
        return actTrim.compareTo(expTrim) >= 0;
      case ConditionOperator.lessThanOrEqual:
        if (bothNumeric) return actNum <= expNum;
        return actTrim.compareTo(expTrim) <= 0;
      case ConditionOperator.regex:
        try {
          return RegExp(expected, caseSensitive: false).hasMatch(actual);
        } catch (_) {
          return false;
        }
    }
  }

  MockCondition copyWith({
    String? id,
    ConditionSource? source,
    String? field,
    ConditionOperator? operator,
    String? value,
    bool? isEnabled,
  }) {
    return MockCondition(
      id: id ?? this.id,
      source: source ?? this.source,
      field: field ?? this.field,
      operator: operator ?? this.operator,
      value: value ?? this.value,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'source': source.name,
    'field': field,
    'operator': operator.name,
    'value': value,
    'isEnabled': isEnabled,
  };

  factory MockCondition.fromJson(Map<String, dynamic> json) => MockCondition(
    id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
    source: ConditionSource.values.firstWhere(
      (e) => e.name == json['source'],
      orElse: () => ConditionSource.any,
    ),
    field: json['field'] as String? ?? '',
    operator: ConditionOperator.values.firstWhere(
      (e) => e.name == json['operator'],
      orElse: () => ConditionOperator.equals,
    ),
    value: json['value'] as String? ?? '',
    isEnabled: json['isEnabled'] as bool? ?? true,
  );
}

class MockRule {
  final String id;
  final String name;
  final String projectId;
  final String projectName;
  final bool isEnabled;
  final String matchMethod; // 'ALL', 'GET', 'POST', 'PUT', 'DELETE', 'PATCH', etc.
  final String urlPattern; // e.g. '/api/users' or '*v1/products*'
  final bool isRegex;
  final String conditionLogic; // 'AND' or 'OR'
  final List<MockCondition> conditions;
  final Map<String, String> matchQueryParams;
  final Map<String, String> matchHeaders;
  final String matchBody;
  final Map<String, String> customVariables;
  final int responseStatusCode;
  final String responseStatusReason;
  final Map<String, String> responseHeaders;
  final String responseBody;
  final int responseDelayMs;
  final String description;
  final bool isAiGenerated;

  const MockRule({
    required this.id,
    required this.name,
    this.projectId = 'default',
    this.projectName = 'Default Project',
    this.isEnabled = true,
    this.matchMethod = 'ALL',
    required this.urlPattern,
    this.isRegex = false,
    this.conditionLogic = 'AND',
    this.conditions = const [],
    this.matchQueryParams = const {},
    this.matchHeaders = const {},
    this.matchBody = '',
    this.customVariables = const {},
    this.responseStatusCode = 200,
    this.responseStatusReason = 'OK',
    this.responseHeaders = const {
      'content-type': 'application/json; charset=utf-8',
      'x-mocked-by': 'ApiLab',
    },
    required this.responseBody,
    this.responseDelayMs = 0,
    this.description = '',
    this.isAiGenerated = false,
  });

  bool matches(HttpRequestData request) {
    if (!isEnabled) return false;

    // 1. Check method
    if (matchMethod.toUpperCase() != 'ALL' && 
        matchMethod.toUpperCase() != request.method.toUpperCase()) {
      return false;
    }

    // 2. Check URL / path pattern
    final fullUrl = request.url;
    final path = request.path;

    if (urlPattern.trim().isNotEmpty) {
      if (isRegex) {
        try {
          final regex = RegExp(urlPattern, caseSensitive: false);
          if (!regex.hasMatch(fullUrl) && !regex.hasMatch(path)) {
            return false;
          }
        } catch (_) {
          return false;
        }
      } else {
        final pattern = urlPattern.trim().toLowerCase();
        final urlLower = fullUrl.toLowerCase();
        final pathLower = path.toLowerCase();

        if (pattern.startsWith('*') && pattern.endsWith('*') && pattern.length > 2) {
          final sub = pattern.substring(1, pattern.length - 1);
          if (!urlLower.contains(sub) && !pathLower.contains(sub)) return false;
        } else if (pattern.startsWith('*') && pattern.length > 1) {
          final sub = pattern.substring(1);
          if (!urlLower.endsWith(sub) && !pathLower.endsWith(sub)) return false;
        } else if (pattern.endsWith('*') && pattern.length > 1) {
          final sub = pattern.substring(0, pattern.length - 1);
          if (!urlLower.startsWith(sub) && !pathLower.startsWith(sub)) return false;
        } else {
          if (!urlLower.contains(pattern) && !pathLower.contains(pattern)) return false;
        }
      }
    }

    // 3. Check advanced conditions (with AND / OR logic)
    final activeConditions = conditions.where((c) => c.isEnabled && c.field.trim().isNotEmpty).toList();
    if (activeConditions.isNotEmpty) {
      if (conditionLogic.toUpperCase() == 'OR') {
        final anyMatched = activeConditions.any((c) => c.evaluate(request));
        if (!anyMatched) return false;
      } else {
        // Default: 'AND' logic
        final allMatched = activeConditions.every((c) => c.evaluate(request));
        if (!allMatched) return false;
      }
    } else {
      // Fallback to legacy field filters if no advanced conditions configured
      if (matchQueryParams.isNotEmpty) {
        final reqQueryParams = request.resolvedQueryParams;
        for (final entry in matchQueryParams.entries) {
          final filterKey = entry.key.trim().toLowerCase();
          final filterVal = entry.value.trim().toLowerCase();
          if (filterKey.isEmpty) continue;

          final reqEntry = reqQueryParams.entries.firstWhere(
            (e) => e.key.trim().toLowerCase() == filterKey,
            orElse: () => const MapEntry('', ''),
          );
          if (reqEntry.key.isEmpty) return false;
          if (filterVal.isNotEmpty && !reqEntry.value.toLowerCase().contains(filterVal)) {
            return false;
          }
        }
      }

      if (matchHeaders.isNotEmpty) {
        for (final entry in matchHeaders.entries) {
          final filterKey = entry.key.trim().toLowerCase();
          final filterVal = entry.value.trim().toLowerCase();
          if (filterKey.isEmpty) continue;

          final reqVal = request.headers[filterKey];
          if (reqVal == null) return false;
          if (filterVal.isNotEmpty && !reqVal.toLowerCase().contains(filterVal)) {
            return false;
          }
        }
      }

      if (matchBody.trim().isNotEmpty) {
        final reqBody = request.body.toLowerCase();
        final filterBody = matchBody.trim().toLowerCase();
        if (!reqBody.contains(filterBody)) {
          return false;
        }
      }
    }

    return true;
  }

  /// Resolves the response body template using variables from custom variables and incoming request
  String resolveResponseBody(HttpRequestData request) {
    if (responseBody.isEmpty) return responseBody;
    final contextVars = extractContextVariables(request);
    return interpolateTemplate(responseBody, contextVars);
  }

  /// Resolves any variable expressions in response headers
  Map<String, String> resolveResponseHeaders(HttpRequestData request) {
    if (responseHeaders.isEmpty) return responseHeaders;
    final contextVars = extractContextVariables(request);
    final resolved = <String, String>{};
    responseHeaders.forEach((key, val) {
      resolved[key] = interpolateTemplate(val, contextVars);
    });
    return resolved;
  }

  Map<String, String> extractContextVariables(HttpRequestData request) {
    final vars = <String, String>{};

    // 1. Built-in variables
    final now = DateTime.now();
    final random = Random();
    vars['timestamp'] = now.millisecondsSinceEpoch.toString();
    vars['iso_date'] = now.toIso8601String();
    vars['date'] = now.toIso8601String().split('T').first;
    vars['uuid'] = _generateUuidV4(random);
    vars['random_int'] = (random.nextInt(90000) + 10000).toString();
    vars['method'] = request.method;
    vars['url'] = request.url;
    vars['path'] = request.path;

    // 2. Custom variables defined on this mock rule
    customVariables.forEach((k, v) {
      final key = k.trim();
      if (key.isNotEmpty) {
        vars[key] = v;
      }
    });

    // 3. Query params
    request.resolvedQueryParams.forEach((k, v) {
      vars[k] = v;
      vars['query.$k'] = v;
    });

    // 4. Headers
    request.headers.forEach((k, v) {
      vars['header.$k'] = v;
      vars.putIfAbsent(k, () => v);
    });

    // 5. Body parameters (JSON extraction)
    if (request.body.isNotEmpty) {
      try {
        final decoded = json.decode(request.body);
        _flattenJsonVariables(decoded, '', vars);
      } catch (_) {
        vars['raw_body'] = request.body;
      }
    }

    return vars;
  }

  static void _flattenJsonVariables(dynamic data, String prefix, Map<String, String> vars) {
    if (data is Map) {
      for (final entry in data.entries) {
        final k = entry.key.toString();
        final path = prefix.isEmpty ? k : '$prefix.$k';
        if (entry.value is Map || entry.value is List) {
          _flattenJsonVariables(entry.value, path, vars);
        } else {
          final valStr = entry.value?.toString() ?? '';
          vars[path] = valStr;
          vars['body.$path'] = valStr;
          if (prefix.isNotEmpty) {
            vars.putIfAbsent(k, () => valStr);
            vars.putIfAbsent('body.$k', () => valStr);
          }
        }
      }
    } else if (data is List) {
      for (var i = 0; i < data.length; i++) {
        final path = '$prefix[$i]';
        _flattenJsonVariables(data[i], path, vars);
      }
    }
  }

  static String _generateUuidV4(Random r) {
    String hex(int len) => List.generate(len, (_) => r.nextInt(16).toRadixString(16)).join();
    return '${hex(8)}-${hex(4)}-4${hex(3)}-a${hex(3)}-${hex(12)}';
  }

  static String interpolateTemplate(String template, Map<String, String> vars) {
    if (template.isEmpty || vars.isEmpty) return template;

    // Matches {{ variable_name }} or {{variable_name}} or ${variable_name}
    final regex = RegExp(r'\{\{\s*([a-zA-Z0-9_\-\.]+)\s*\}\}|\$\{([a-zA-Z0-9_\-\.]+)\}');
    return template.replaceAllMapped(regex, (match) {
      final key = match.group(1) ?? match.group(2) ?? '';
      if (vars.containsKey(key)) {
        return vars[key]!;
      }
      for (final entry in vars.entries) {
        if (entry.key.toLowerCase() == key.toLowerCase()) {
          return entry.value;
        }
      }
      return match.group(0)!;
    });
  }

  MockRule copyWith({
    String? id,
    String? name,
    String? projectId,
    String? projectName,
    bool? isEnabled,
    String? matchMethod,
    String? urlPattern,
    bool? isRegex,
    String? conditionLogic,
    List<MockCondition>? conditions,
    Map<String, String>? matchQueryParams,
    Map<String, String>? matchHeaders,
    String? matchBody,
    Map<String, String>? customVariables,
    int? responseStatusCode,
    String? responseStatusReason,
    Map<String, String>? responseHeaders,
    String? responseBody,
    int? responseDelayMs,
    String? description,
    bool? isAiGenerated,
  }) {
    return MockRule(
      id: id ?? this.id,
      name: name ?? this.name,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      isEnabled: isEnabled ?? this.isEnabled,
      matchMethod: matchMethod ?? this.matchMethod,
      urlPattern: urlPattern ?? this.urlPattern,
      isRegex: isRegex ?? this.isRegex,
      conditionLogic: conditionLogic ?? this.conditionLogic,
      conditions: conditions ?? this.conditions,
      matchQueryParams: matchQueryParams ?? this.matchQueryParams,
      matchHeaders: matchHeaders ?? this.matchHeaders,
      matchBody: matchBody ?? this.matchBody,
      customVariables: customVariables ?? this.customVariables,
      responseStatusCode: responseStatusCode ?? this.responseStatusCode,
      responseStatusReason: responseStatusReason ?? this.responseStatusReason,
      responseHeaders: responseHeaders ?? this.responseHeaders,
      responseBody: responseBody ?? this.responseBody,
      responseDelayMs: responseDelayMs ?? this.responseDelayMs,
      description: description ?? this.description,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'projectId': projectId,
    'projectName': projectName,
    'isEnabled': isEnabled,
    'matchMethod': matchMethod,
    'urlPattern': urlPattern,
    'isRegex': isRegex,
    'conditionLogic': conditionLogic,
    'conditions': conditions.map((c) => c.toJson()).toList(),
    'matchQueryParams': matchQueryParams,
    'matchHeaders': matchHeaders,
    'matchBody': matchBody,
    'customVariables': customVariables,
    'responseStatusCode': responseStatusCode,
    'responseStatusReason': responseStatusReason,
    'responseHeaders': responseHeaders,
    'responseBody': responseBody,
    'responseDelayMs': responseDelayMs,
    'description': description,
    'isAiGenerated': isAiGenerated,
  };

  factory MockRule.fromJson(Map<String, dynamic> json) => MockRule(
    id: json['id'] as String,
    name: json['name'] as String? ?? 'Untitled Rule',
    projectId: json['projectId'] as String? ?? 'default',
    projectName: json['projectName'] as String? ?? 'Default Project',
    isEnabled: json['isEnabled'] as bool? ?? true,
    matchMethod: json['matchMethod'] as String? ?? 'ALL',
    urlPattern: json['urlPattern'] as String? ?? '',
    isRegex: json['isRegex'] as bool? ?? false,
    conditionLogic: json['conditionLogic'] as String? ?? 'AND',
    conditions: (json['conditions'] as List? ?? [])
        .map((c) => MockCondition.fromJson(Map<String, dynamic>.from(c as Map)))
        .toList(),
    matchQueryParams: Map<String, String>.from(json['matchQueryParams'] as Map? ?? {}),
    matchHeaders: Map<String, String>.from(json['matchHeaders'] as Map? ?? {}),
    matchBody: json['matchBody'] as String? ?? '',
    customVariables: Map<String, String>.from(json['customVariables'] as Map? ?? {}),
    responseStatusCode: json['responseStatusCode'] as int? ?? 200,
    responseStatusReason: json['responseStatusReason'] as String? ?? 'OK',
    responseHeaders: Map<String, String>.from(json['responseHeaders'] as Map? ?? {
      'content-type': 'application/json; charset=utf-8',
    }),
    responseBody: json['responseBody'] as String? ?? '{}',
    responseDelayMs: json['responseDelayMs'] as int? ?? 0,
    description: json['description'] as String? ?? '',
    isAiGenerated: json['isAiGenerated'] as bool? ?? false,
  );
}
