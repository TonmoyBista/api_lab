import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../domain/models/http_traffic.dart';
import '../../domain/models/mock_rule.dart';
import '../../domain/repositories/repositories.dart';
import '../database/app_database.dart';

class MockRuleRepositoryImpl implements IMockRuleRepository {
  final AppDatabase? database;
  final List<MockRule> _rules = [];
  final Set<String> _explicitProjects = {'Default Project'};
  final StreamController<List<MockRule>> _controller = StreamController<List<MockRule>>.broadcast();

  MockRuleRepositoryImpl({this.database}) {
    _init();
  }

  Future<void> _init() async {
    final db = database;
    if (db != null) {
      try {
        await db.seedDefaultRulesIfEmpty();
        final loadedRules = await db.getAllMockRules();
        final loadedProjects = await db.getAllProjectNames();
        _rules.clear();
        _rules.addAll(loadedRules);
        _explicitProjects.addAll(loadedProjects);
        _emit();
        return;
      } catch (_) {}
    }

    _seedDefaultRules();
  }

  void _seedDefaultRules() {
    const uuid = Uuid();
    _rules.addAll([
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
    ]);
    _emit();
  }

  @override
  Stream<List<MockRule>> get rulesStream => _controller.stream;

  @override
  List<MockRule> get currentRules => List.unmodifiable(_rules);

  @override
  List<String> get currentProjects {
    final set = <String>{..._explicitProjects};
    for (final r in _rules) {
      if (r.projectName.trim().isNotEmpty) {
        set.add(r.projectName.trim());
      }
    }
    return set.toList();
  }

  @override
  Future<void> createProject(String projectName) async {
    final trimmed = projectName.trim();
    if (trimmed.isNotEmpty) {
      _explicitProjects.add(trimmed);
      final db = database;
      if (db != null) {
        try {
          await db.insertProject(trimmed);
        } catch (_) {}
      }
      _emit();
    }
  }

  @override
  Future<void> deleteProject(String projectName) async {
    final trimmed = projectName.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'default project') return;
    _explicitProjects.removeWhere((p) => p.trim().toLowerCase() == trimmed.toLowerCase());
    _rules.removeWhere((r) => r.projectName.trim().toLowerCase() == trimmed.toLowerCase());
    final db = database;
    if (db != null) {
      try {
        await db.deleteProject(trimmed);
      } catch (_) {}
    }
    _emit();
  }

  @override
  Future<void> addRule(MockRule rule) async {
    if (rule.projectName.trim().isNotEmpty) {
      _explicitProjects.add(rule.projectName.trim());
    }
    _rules.insert(0, rule);
    final db = database;
    if (db != null) {
      try {
        await db.upsertMockRule(rule);
      } catch (_) {}
    }
    _emit();
  }

  @override
  Future<void> updateRule(MockRule rule) async {
    final index = _rules.indexWhere((r) => r.id == rule.id);
    if (index != -1) {
      _rules[index] = rule;
      final db = database;
      if (db != null) {
        try {
          await db.upsertMockRule(rule);
        } catch (_) {}
      }
      _emit();
    }
  }

  @override
  Future<void> deleteRule(String id) async {
    _rules.removeWhere((r) => r.id == id);
    final db = database;
    if (db != null) {
      try {
        await db.deleteMockRule(id);
      } catch (_) {}
    }
    _emit();
  }

  @override
  Future<void> toggleRule(String id, bool isEnabled) async {
    final index = _rules.indexWhere((r) => r.id == id);
    if (index != -1) {
      _rules[index] = _rules[index].copyWith(isEnabled: isEnabled);
      final db = database;
      if (db != null) {
        try {
          await db.toggleMockRule(id, isEnabled);
        } catch (_) {}
      }
      _emit();
    }
  }

  @override
  MockRule? findMatchingRule(HttpRequestData request) {
    for (final rule in _rules) {
      if (rule.matches(request)) {
        return rule;
      }
    }
    return null;
  }

  void _emit() {
    _controller.add(List.unmodifiable(_rules));
  }

  void dispose() {
    _controller.close();
  }
}
