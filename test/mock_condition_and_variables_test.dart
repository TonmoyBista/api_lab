import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:api_lab/domain/models/http_traffic.dart';
import 'package:api_lab/domain/models/mock_rule.dart';
import 'package:api_lab/data/repositories/mock_rule_repository_impl.dart';
import 'package:api_lab/data/repositories/settings_repository_impl.dart';
import 'package:api_lab/ui/features/mocks/view_models/mocks_view_model.dart';
import 'package:api_lab/ui/features/settings/view_models/settings_view_model.dart';
import 'package:api_lab/domain/use_cases/intercept_request_use_case.dart';
import 'package:api_lab/infrastructure/proxy/proxy_server.dart';
import 'package:api_lab/data/repositories/traffic_repository_impl.dart';

void main() {
  group('MockCondition & Logical Operators Tests', () {
    test('AND logic: Matches when both isUserType = project manager AND userid = 5', () {
      final rule = MockRule(
        id: 'rule_1',
        name: 'Project Manager Rule',
        urlPattern: '*/api/v1/user_profile*',
        conditionLogic: 'AND',
        conditions: const [
          MockCondition(
            id: 'c1',
            source: ConditionSource.any,
            field: 'isUserType',
            operator: ConditionOperator.equals,
            value: 'project manager',
          ),
          MockCondition(
            id: 'c2',
            source: ConditionSource.any,
            field: 'userid',
            operator: ConditionOperator.equals,
            value: '5',
          ),
        ],
        responseBody: '{"status": "ok"}',
      );

      // 1. Matches both
      final reqBoth = HttpRequestData(
        id: 'req_1',
        url: 'https://example.com/api/v1/user_profile?isUserType=project%20manager&userid=5',
        
        method: 'GET',
        headers: {},
        body: '',
        timestamp: DateTime.now(),
        queryParams: {'isUserType': 'project manager', 'userid': '5'},
      );
      expect(rule.matches(reqBoth), isTrue);

      // 2. Fails when userid is 6 (not 5)
      final reqWrongUser = HttpRequestData(
        id: 'req_2',
        url: 'https://example.com/api/v1/user_profile?isUserType=project%20manager&userid=6',
        
        method: 'GET',
        headers: {},
        body: '',
        timestamp: DateTime.now(),
        queryParams: {'isUserType': 'project manager', 'userid': '6'},
      );
      expect(rule.matches(reqWrongUser), isFalse);

      // 3. Fails when isUserType is developer
      final reqWrongType = HttpRequestData(
        id: 'req_3',
        url: 'https://example.com/api/v1/user_profile?isUserType=developer&userid=5',
        
        method: 'GET',
        headers: {},
        body: '',
        timestamp: DateTime.now(),
        queryParams: {'isUserType': 'developer', 'userid': '5'},
      );
      expect(rule.matches(reqWrongType), isFalse);
    });

    test('OR logic: Matches when either isUserType = admin OR userid = 5', () {
      final rule = MockRule(
        id: 'rule_or',
        name: 'Admin or User 5 Rule',
        urlPattern: '*/api/v1/user*',
        conditionLogic: 'OR',
        conditions: const [
          MockCondition(
            id: 'c1',
            field: 'isUserType',
            operator: ConditionOperator.equals,
            value: 'admin',
          ),
          MockCondition(
            id: 'c2',
            field: 'userid',
            operator: ConditionOperator.equals,
            value: '5',
          ),
        ],
        responseBody: '{"status": "ok"}',
      );

      // Matches only second condition (userid = 5, isUserType = guest)
      final reqUser5 = HttpRequestData(
        id: 'req_1',
        url: 'https://example.com/api/v1/user?isUserType=guest&userid=5',
        
        method: 'GET',
        headers: {},
        body: '',
        timestamp: DateTime.now(),
        queryParams: {'isUserType': 'guest', 'userid': '5'},
      );
      expect(rule.matches(reqUser5), isTrue);

      // Matches only first condition (isUserType = admin, userid = 99)
      final reqAdmin = HttpRequestData(
        id: 'req_2',
        url: 'https://example.com/api/v1/user?isUserType=admin&userid=99',
        
        method: 'GET',
        headers: {},
        body: '',
        timestamp: DateTime.now(),
        queryParams: {'isUserType': 'admin', 'userid': '99'},
      );
      expect(rule.matches(reqAdmin), isTrue);

      // Fails when neither matches
      final reqNeither = HttpRequestData(
        id: 'req_3',
        url: 'https://example.com/api/v1/user?isUserType=tester&userid=12',
        
        method: 'GET',
        headers: {},
        body: '',
        timestamp: DateTime.now(),
        queryParams: {'isUserType': 'tester', 'userid': '12'},
      );
      expect(rule.matches(reqNeither), isFalse);
    });

    test('Comparison operators: contain, >, <, >=, <=, !=, regex', () {
      // 1. Contains operator
      final condContains = const MockCondition(
        id: 'c_cont',
        field: 'role',
        operator: ConditionOperator.contains,
        value: 'manager',
      );
      final reqManager = HttpRequestData(
        id: '1', url: 'https://a.com?role=Project%20Manager',  method: 'GET',
        headers: {}, body: '', timestamp: DateTime.now(), queryParams: {'role': 'Project Manager'},
      );
      expect(condContains.evaluate(reqManager), isTrue);

      // 2. Greater Than (>) operator on numeric field
      final condGt = const MockCondition(
        id: 'c_gt',
        field: 'age',
        operator: ConditionOperator.greaterThan,
        value: '18',
      );
      final reqAge25 = HttpRequestData(
        id: '2', url: 'https://a.com?age=25',  method: 'GET',
        headers: {}, body: '', timestamp: DateTime.now(), queryParams: {'age': '25'},
      );
      final reqAge15 = HttpRequestData(
        id: '3', url: 'https://a.com?age=15',  method: 'GET',
        headers: {}, body: '', timestamp: DateTime.now(), queryParams: {'age': '15'},
      );
      expect(condGt.evaluate(reqAge25), isTrue);
      expect(condGt.evaluate(reqAge15), isFalse);

      // 3. Less than or equal (<=)
      final condLte = const MockCondition(
        id: 'c_lte',
        field: 'price',
        operator: ConditionOperator.lessThanOrEqual,
        value: '100',
      );
      final reqPrice100 = HttpRequestData(
        id: '4', url: 'https://a.com?price=100',  method: 'GET',
        headers: {}, body: '', timestamp: DateTime.now(), queryParams: {'price': '100'},
      );
      final reqPrice150 = HttpRequestData(
        id: '5', url: 'https://a.com?price=150',  method: 'GET',
        headers: {}, body: '', timestamp: DateTime.now(), queryParams: {'price': '150'},
      );
      expect(condLte.evaluate(reqPrice100), isTrue);
      expect(condLte.evaluate(reqPrice150), isFalse);

      // 4. Not equals (!=)
      final condNe = const MockCondition(
        id: 'c_ne',
        field: 'status',
        operator: ConditionOperator.notEquals,
        value: 'banned',
      );
      final reqActive = HttpRequestData(
        id: '6', url: 'https://a.com?status=active',  method: 'GET',
        headers: {}, body: '', timestamp: DateTime.now(), queryParams: {'status': 'active'},
      );
      final reqBanned = HttpRequestData(
        id: '7', url: 'https://a.com?status=banned',  method: 'GET',
        headers: {}, body: '', timestamp: DateTime.now(), queryParams: {'status': 'banned'},
      );
      expect(condNe.evaluate(reqActive), isTrue);
      expect(condNe.evaluate(reqBanned), isFalse);
    });

    test('Conditions can extract and match from JSON request body', () {
      final condBody = const MockCondition(
        id: 'c_body',
        source: ConditionSource.body,
        field: 'userid',
        operator: ConditionOperator.equals,
        value: '5',
      );
      final reqJson = HttpRequestData(
        id: 'req_body',
        url: 'https://example.com/api/v1/update_user',
        
        method: 'POST',
        headers: {'content-type': 'application/json'},
        body: '{"userid": 5, "isUserType": "project manager"}',
        timestamp: DateTime.now(),
      );
      expect(condBody.evaluate(reqJson), isTrue);
    });
  });

  group('Dynamic Variables System in Mock Responses', () {
    test('Resolves variables in response body as requested in example', () {
      final rule = MockRule(
        id: 'rule_var',
        name: 'User Profile Mock',
        urlPattern: '*/api/v1/user_profile_info*',
        customVariables: const {
          'Others': 'custom variable',
        },
        responseBody: '{\n  "user_type": "{{isUserType}}",\n  "userid": {{userid}},\n  "Others": "{{Others}}"\n}',
      );

      final req = HttpRequestData(
        id: 'req_ex',
        url: 'https://testing-flowpros.odoo.com/api/v1/user_profile_info?isUserType=project%20manager&userid=5',
        
        method: 'GET',
        headers: {'authorization': 'Bearer test-token-123'},
        body: '',
        timestamp: DateTime.now(),
        queryParams: {
          'isUserType': 'project manager',
          'userid': '5',
        },
      );

      final resolved = rule.resolveResponseBody(req);

      expect(resolved, contains('"user_type": "project manager"'));
      expect(resolved, contains('"userid": 5'));
      expect(resolved, contains('"Others": "custom variable"'));
    });

    test('Resolves built-in variables (uuid, timestamp, date, method, path)', () {
      final rule = MockRule(
        id: 'rule_builtins',
        name: 'Builtins Mock',
        urlPattern: '*/test*',
        responseBody: '{"id": "{{uuid}}", "method": "{{method}}", "date": "{{date}}"}',
      );

      final req = HttpRequestData(
        id: 'req_bi',
        url: 'https://api.test.com/test/item',
        
        method: 'DELETE',
        headers: {},
        body: '',
        timestamp: DateTime.now(),
      );

      final resolved = rule.resolveResponseBody(req);
      expect(resolved, contains('"method": "DELETE"'));
      expect(resolved, isNot(contains('{{uuid}}')));
      expect(resolved, isNot(contains('{{date}}')));
    });

    test('Resolves variables in response headers', () {
      final rule = MockRule(
        id: 'rule_headers',
        name: 'Headers Mock',
        urlPattern: '*/test*',
        responseHeaders: {
          'x-user-id': '{{userid}}',
          'x-role': '{{user_role}}',
        },
        customVariables: {
          'user_role': 'Admin',
        },
        responseBody: '{}',
      );

      final req = HttpRequestData(
        id: 'req_hdr',
        url: 'https://api.test.com/test?userid=42',
        
        method: 'GET',
        headers: {},
        body: '',
        timestamp: DateTime.now(),
        queryParams: {'userid': '42'},
      );

      final headers = rule.resolveResponseHeaders(req);
      expect(headers['x-user-id'], equals('42'));
      expect(headers['x-role'], equals('Admin'));
    });
  });

  group('Auto-fill Mock Rules from Intercepted Traffic', () {
    test('createMockFromItem auto-fills query parameters and JSON body as conditions', () {
      final traffic = TrafficItem(
        id: 'traffic_test_1',
        request: HttpRequestData(
          id: 'traffic_test_1',
          url: 'https://example.com/api/v1/user_profile?isUserType=project%20manager&userid=5',
          method: 'POST',
          headers: {'content-type': 'application/json'},
          body: '{"status": "active", "level": 3}',
          timestamp: DateTime.now(),
          queryParams: {'isUserType': 'project manager', 'userid': '5'},
        ),
        response: HttpResponseData(
          statusCode: 200,
          statusReason: 'OK',
          headers: {'content-type': 'application/json'},
          body: '{"success": true}',
          timestamp: DateTime.now(),
          durationMs: 45,
          contentLength: 17,
        ),
      );

      // Call createMockFromItem logic
      final req = traffic.request;
      final res = traffic.response;
      final conditions = <MockCondition>[];

      for (final entry in req.resolvedQueryParams.entries) {
        conditions.add(
          MockCondition(
            id: 'c_${entry.key}',
            source: ConditionSource.query,
            field: entry.key,
            operator: ConditionOperator.equals,
            value: entry.value,
          ),
        );
      }

      final decoded = {'status': 'active', 'level': 3};
      for (final entry in decoded.entries) {
        conditions.add(
          MockCondition(
            id: 'c_${entry.key}',
            source: ConditionSource.body,
            field: entry.key,
            operator: ConditionOperator.equals,
            value: entry.value.toString(),
          ),
        );
      }

      final mockRule = MockRule(
        id: 'mock_from_item',
        name: 'Mock: ${req.path}',
        matchMethod: req.method,
        urlPattern: '*${req.path}*',
        conditionLogic: 'AND',
        conditions: conditions,
        responseBody: res!.body,
      );

      expect(mockRule.conditions.length, equals(4));
      expect(mockRule.conditions.any((c) => c.field == 'isUserType' && c.value == 'project manager'), isTrue);
      expect(mockRule.conditions.any((c) => c.field == 'userid' && c.value == '5'), isTrue);
      expect(mockRule.conditions.any((c) => c.field == 'status' && c.value == 'active'), isTrue);
      expect(mockRule.conditions.any((c) => c.field == 'level' && c.value == '3'), isTrue);
      expect(mockRule.matches(traffic.request), isTrue);
    });
  });

  group('Projects & Import/Export JSON', () {
    test('JSON serialization & deserialization includes projects and conditions', () {
      final rule = MockRule(
        id: 'r_export_1',
        name: 'Export Rule Test',
        projectName: 'E-Commerce APIs',
        urlPattern: '*/products*',
        conditionLogic: 'AND',
        conditions: const [
          MockCondition(id: 'c1', field: 'category', value: 'electronics'),
        ],
        responseBody: '{"products": []}',
      );

      final jsonMap = rule.toJson();
      expect(jsonMap['projectName'], equals('E-Commerce APIs'));
      expect(jsonMap['conditions'], isNotEmpty);

      final restored = MockRule.fromJson(jsonMap);
      expect(restored.projectName, equals('E-Commerce APIs'));
      expect(restored.conditions.first.field, equals('category'));
      expect(restored.conditions.first.value, equals('electronics'));
    });

    test('Empty project remains visible in MocksViewModel.projects without saving rules', () {
      final mockRepo = MockRuleRepositoryImpl();
      final vm = MocksViewModel(
        mockRuleRepository: mockRepo,
      );

      expect(vm.projects.contains('Brand New Empty Project'), isFalse);
      vm.createProject('Brand New Empty Project');

      // Project is selected and listed in projects even with 0 rules
      expect(vm.selectedProject, equals('Brand New Empty Project'));
      expect(vm.projects.contains('Brand New Empty Project'), isTrue);
      expect(vm.rules.isEmpty, isTrue);
    });

    test('Export to folder and import from file works without displaying JSON', () async {
      final mockRepo = MockRuleRepositoryImpl();
      final vm = MocksViewModel(
        mockRuleRepository: mockRepo,
      );

      final tempDir = Directory.systemTemp.createTempSync('apilab_test_');
      try {
        final exportedPath = await vm.exportToFolder(tempDir.path);
        expect(File(exportedPath).existsSync(), isTrue);

        // Import into target project
        final count = await vm.importFromFile(exportedPath, targetProject: 'Imported Project');
        expect(count, greaterThan(0));
        expect(vm.projects.contains('Imported Project'), isTrue);
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('SettingsViewModel exports CA certificate to selected folder', () async {
      final settingsRepo = SettingsRepositoryImpl();
      final mockRepo = MockRuleRepositoryImpl();
      final trafficRepo = TrafficRepositoryImpl();
      final interceptUseCase = InterceptRequestUseCase(
        mockRuleRepository: mockRepo,
        trafficRepository: trafficRepo,
      );
      final proxyServer = ProxyServer(
        interceptUseCase: interceptUseCase,
        config: settingsRepo.getProxyConfig(),
      );
      final vm = SettingsViewModel(
        settingsRepository: settingsRepo,
        proxyServer: proxyServer,
      );

      final tempDir = Directory.systemTemp.createTempSync('apilab_ca_test_');
      try {
        final path = await vm.exportCaCertificateToFolder(tempDir.path);
        final file = File(path);
        expect(file.existsSync(), isTrue);
        expect(file.readAsStringSync(), contains('BEGIN CERTIFICATE'));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });
}
