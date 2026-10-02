import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/mock_rule.dart';

part 'app_database.g.dart';

class MockProjectsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class MockRulesTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get projectId => text().withDefault(const Constant('default'))();
  TextColumn get projectName => text().withDefault(const Constant('Default Project'))();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  TextColumn get matchMethod => text().withDefault(const Constant('ALL'))();
  TextColumn get urlPattern => text()();
  BoolColumn get isRegex => boolean().withDefault(const Constant(false))();
  TextColumn get conditionLogic => text().withDefault(const Constant('AND'))();
  TextColumn get conditionsJson => text().withDefault(const Constant('[]'))();
  TextColumn get matchQueryParamsJson => text().withDefault(const Constant('{}'))();
  TextColumn get matchHeadersJson => text().withDefault(const Constant('{}'))();
  TextColumn get matchBody => text().withDefault(const Constant(''))();
  TextColumn get customVariablesJson => text().withDefault(const Constant('{}'))();
  IntColumn get responseStatusCode => integer().withDefault(const Constant(200))();
  TextColumn get responseStatusReason => text().withDefault(const Constant('OK'))();
  TextColumn get responseHeadersJson => text().withDefault(const Constant('{}'))();
  TextColumn get responseBody => text()();
  IntColumn get responseDelayMs => integer().withDefault(const Constant(0))();
  TextColumn get description => text().withDefault(const Constant(''))();
  BoolColumn get isAiGenerated => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [MockProjectsTable, MockRulesTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'apilab_database');
  }

  Future<List<MockRule>> getAllMockRules() async {
    final query = select(mockRulesTable)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    final rows = await query.get();
    return rows.map(_rowToMockRule).toList();
  }

  Future<void> upsertMockRule(MockRule rule) async {
    await into(mockRulesTable).insertOnConflictUpdate(
      MockRulesTableCompanion.insert(
        id: rule.id,
        name: rule.name,
        projectId: Value(rule.projectId),
        projectName: Value(rule.projectName),
        isEnabled: Value(rule.isEnabled),
        matchMethod: Value(rule.matchMethod),
        urlPattern: rule.urlPattern,
        isRegex: Value(rule.isRegex),
        conditionLogic: Value(rule.conditionLogic),
        conditionsJson: Value(jsonEncode(rule.conditions.map((c) => c.toJson()).toList())),
        matchQueryParamsJson: Value(jsonEncode(rule.matchQueryParams)),
        matchHeadersJson: Value(jsonEncode(rule.matchHeaders)),
        matchBody: Value(rule.matchBody),
        customVariablesJson: Value(jsonEncode(rule.customVariables)),
        responseStatusCode: Value(rule.responseStatusCode),
        responseStatusReason: Value(rule.responseStatusReason),
        responseHeadersJson: Value(jsonEncode(rule.responseHeaders)),
        responseBody: rule.responseBody,
        responseDelayMs: Value(rule.responseDelayMs),
        description: Value(rule.description),
        isAiGenerated: Value(rule.isAiGenerated),
      ),
    );
  }

  Future<void> deleteMockRule(String id) async {
    await (delete(mockRulesTable)..where((t) => t.id.equals(id))).go();
  }

  Future<void> toggleMockRule(String id, bool isEnabled) async {
    await (update(mockRulesTable)..where((t) => t.id.equals(id)))
        .write(MockRulesTableCompanion(isEnabled: Value(isEnabled)));
  }

  Future<List<String>> getAllProjectNames() async {
    final projectRows = await select(mockProjectsTable).get();
    final ruleRows = await select(mockRulesTable).get();
    final names = <String>{'Default Project'};
    for (final p in projectRows) {
      if (p.name.trim().isNotEmpty) names.add(p.name.trim());
    }
    for (final r in ruleRows) {
      if (r.projectName.trim().isNotEmpty) names.add(r.projectName.trim());
    }
    return names.toList();
  }

  Future<void> insertProject(String name, [String description = '']) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await into(mockProjectsTable).insertOnConflictUpdate(
      MockProjectsTableCompanion.insert(
        id: const Uuid().v4(),
        name: trimmed,
        description: Value(description),
      ),
    );
  }

  Future<void> deleteProject(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'default project') return;
    await (delete(mockProjectsTable)..where((t) => t.name.equals(trimmed))).go();
    await (delete(mockRulesTable)..where((t) => t.projectName.equals(trimmed))).go();
  }

  Future<void> seedDefaultRulesIfEmpty() async {
    final count = await (select(mockRulesTable)..limit(1)).get();
    if (count.isNotEmpty) return;

    await insertProject('Default Project', 'Default workspace mock project');
    const uuid = Uuid();
    final defaults = [
      MockRule(
        id: uuid.v4(),
        name: 'Mock Users API',
        isEnabled: true,
        matchMethod: 'GET',
        urlPattern: '*/api/v1/users*',
        responseStatusCode: 200,
        responseHeaders: {'content-type': 'application/json'},
        responseBody: '''{
  "status": "success",
  "total": 2,
  "data": [
    {
      "id": "usr_101",
      "name": "Jane Cooper",
      "email": "jane.cooper@example.com",
      "role": "Lead Architect",
      "active": true
    },
    {
      "id": "usr_102",
      "name": "Cody Fisher",
      "email": "cody.fisher@example.com",
      "role": "Security Engineer",
      "active": true
    }
  ]
}''',
        responseDelayMs: 150,
        description: 'Simulates user directory list endpoint',
      ),
      MockRule(
        id: uuid.v4(),
        name: 'Simulated 500 Server Error',
        isEnabled: false,
        matchMethod: 'POST',
        urlPattern: '*/checkout/pay*',
        responseStatusCode: 500,
        responseHeaders: {'content-type': 'application/json'},
        responseBody: '''{
  "error": "PAYMENT_GATEWAY_TIMEOUT",
  "message": "The upstream banking processor timed out.",
  "retryable": true
}''',
        responseDelayMs: 400,
        description: 'Simulates payment processor failure for resilience testing',
      ),
      MockRule(
        id: uuid.v4(),
        name: 'Mock AI Agent Telemetry',
        isEnabled: true,
        matchMethod: 'GET',
        urlPattern: '*/agent/status*',
        responseStatusCode: 200,
        responseHeaders: {'content-type': 'application/json'},
        responseBody: '''{
  "agent_id": "apilab_agent_01",
  "status": "operational",
  "protocol": "MCP/1.0",
  "active_sessions": 3,
  "capabilities": ["mock_generator", "traffic_inspector"]
}''',
        responseDelayMs: 50,
        description: 'Mock response for AI agent telemetry',
        isAiGenerated: true,
      ),
    ];

    for (final r in defaults) {
      await upsertMockRule(r);
    }
  }

  MockRule _rowToMockRule(MockRulesTableData row) {
    List<MockCondition> conditions = [];
    try {
      final decoded = jsonDecode(row.conditionsJson);
      if (decoded is List) {
        conditions = decoded
            .map((c) => MockCondition.fromJson(Map<String, dynamic>.from(c as Map)))
            .toList();
      }
    } catch (_) {}

    Map<String, String> queryParams = {};
    try {
      final decoded = jsonDecode(row.matchQueryParamsJson);
      if (decoded is Map) {
        queryParams = decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    } catch (_) {}

    Map<String, String> headers = {};
    try {
      final decoded = jsonDecode(row.matchHeadersJson);
      if (decoded is Map) {
        headers = decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    } catch (_) {}

    Map<String, String> customVars = {};
    try {
      final decoded = jsonDecode(row.customVariablesJson);
      if (decoded is Map) {
        customVars = decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    } catch (_) {}

    Map<String, String> resHeaders = {};
    try {
      final decoded = jsonDecode(row.responseHeadersJson);
      if (decoded is Map) {
        resHeaders = decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    } catch (_) {}

    return MockRule(
      id: row.id,
      name: row.name,
      projectId: row.projectId,
      projectName: row.projectName,
      isEnabled: row.isEnabled,
      matchMethod: row.matchMethod,
      urlPattern: row.urlPattern,
      isRegex: row.isRegex,
      conditionLogic: row.conditionLogic,
      conditions: conditions,
      matchQueryParams: queryParams,
      matchHeaders: headers,
      matchBody: row.matchBody,
      customVariables: customVars,
      responseStatusCode: row.responseStatusCode,
      responseStatusReason: row.responseStatusReason,
      responseHeaders: resHeaders.isNotEmpty
          ? resHeaders
          : const {'content-type': 'application/json; charset=utf-8'},
      responseBody: row.responseBody,
      responseDelayMs: row.responseDelayMs,
      description: row.description,
      isAiGenerated: row.isAiGenerated,
    );
  }
}
