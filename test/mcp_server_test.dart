import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:api_lab/domain/models/http_traffic.dart';
import 'package:api_lab/domain/use_cases/generate_mock_response_use_case.dart';
import 'package:api_lab/domain/use_cases/replay_request_use_case.dart';
import 'package:api_lab/data/repositories/traffic_repository_impl.dart';
import 'package:api_lab/data/repositories/mock_rule_repository_impl.dart';
import 'package:api_lab/data/repositories/settings_repository_impl.dart';
import 'package:api_lab/infrastructure/mcp/mcp_server.dart';

void main() {
  group('McpServer AI Agent Workflow Tests', () {
    late TrafficRepositoryImpl trafficRepo;
    late MockRuleRepositoryImpl mockRepo;
    late SettingsRepositoryImpl settingsRepo;
    late McpServer mcpServer;

    setUp(() {
      trafficRepo = TrafficRepositoryImpl();
      mockRepo = MockRuleRepositoryImpl();
      settingsRepo = SettingsRepositoryImpl();
      mcpServer = McpServer(
        trafficRepository: trafficRepo,
        mockRuleRepository: mockRepo,
        replayRequestUseCase: ReplayRequestUseCase(),
        generateMockUseCase: GenerateMockResponseUseCase(),
        settingsRepository: settingsRepo,
      );
    });

    tearDown(() {
      mcpServer.dispose();
    });

    test('AI Agent can inspect available tools and initialize MCP connection', () async {
      final initRes = await mcpServer.processMcpRequest({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'initialize',
      });
      expect(initRes['result']['serverInfo']['name'], 'ApiLab-MCP-Server');
      expect(initRes['result']['protocolVersion'], '2024-11-05');

      final toolsRes = await mcpServer.processMcpRequest({
        'jsonrpc': '2.0',
        'id': 2,
        'method': 'tools/list',
      });
      final tools = toolsRes['result']['tools'] as List;
      final toolNames = tools.map((t) => t['name'] as String).toList();
      expect(toolNames, contains('apilab_get_traffic'));
      expect(toolNames, contains('apilab_get_traffic_detail'));
      expect(toolNames, contains('apilab_create_project'));
      expect(toolNames, contains('apilab_list_projects'));
      expect(toolNames, contains('apilab_create_mock'));
      expect(toolNames, contains('apilab_list_rules'));
      expect(toolNames, contains('apilab_update_mock'));
      expect(toolNames, contains('apilab_delete_mock'));
      expect(toolNames, contains('apilab_toggle_mock'));
    });

    test('AI Agent can read resources: traffic, projects, and rules', () async {
      // 1. Add some initial traffic
      final req = HttpRequestData(
        id: 'req-1',
        method: 'POST',
        url: 'https://example.com/api/v1/auth/login',
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'username': 'mr_x', 'password': 'secretPassword123'}),
        timestamp: DateTime.now(),
      );
      final res = HttpResponseData(
        statusCode: 200,
        statusReason: 'OK',
        body: jsonEncode({'status': 'ok'}),
        timestamp: DateTime.now(),
      );
      trafficRepo.addTraffic(TrafficItem(id: 'traffic-1', request: req, response: res));

      // 2. Read resources via MCP
      final listRes = await mcpServer.processMcpRequest({
        'jsonrpc': '2.0',
        'id': 10,
        'method': 'resources/list',
      });
      final resources = listRes['result']['resources'] as List;
      expect(resources.any((r) => r['uri'] == 'apilab://traffic'), isTrue);
      expect(resources.any((r) => r['uri'] == 'apilab://projects'), isTrue);
      expect(resources.any((r) => r['uri'] == 'apilab://rules'), isTrue);

      // Read traffic resource
      final readTrafficRes = await mcpServer.processMcpRequest({
        'jsonrpc': '2.0',
        'id': 11,
        'method': 'resources/read',
        'params': {'uri': 'apilab://traffic'},
      });
      final trafficContent = jsonDecode(readTrafficRes['result']['contents'][0]['text']);
      expect(trafficContent['count'], 1);
      expect(trafficContent['traffic'][0]['request']['url'], contains('/auth/login'));
      expect(trafficContent['traffic'][0]['request']['body'], contains('mr_x'));
    });

    test('Full Workflow: AI analyzes login request, creates project and mock for Mr X, and tests rule matching', () async {
      // Step 1: Simulated app sends login request
      final loginReq = HttpRequestData(
        id: 'req-login-001',
        method: 'POST',
        url: 'https://app.company.com/api/v1/auth/login',
        headers: {'content-type': 'application/json'},
        queryParams: {'version': '2.0'},
        body: jsonEncode({'username': 'mr_x', 'client': 'mobile_app'}),
        timestamp: DateTime.now(),
      );
      trafficRepo.addTraffic(TrafficItem(id: 'item-001', request: loginReq));

      // Step 2: AI reads intercepted traffic to analyze endpoint and payload
      final trafficCall = await mcpServer.processMcpRequest({
        'jsonrpc': '2.0',
        'id': 20,
        'method': 'tools/call',
        'params': {
          'name': 'apilab_get_traffic',
          'arguments': {'urlFilter': 'auth/login'},
        },
      });
      final trafficData = jsonDecode(trafficCall['result']['content'][0]['text']);
      expect(trafficData['count'], 1);
      expect(trafficData['traffic'][0]['method'], 'POST');
      expect(trafficData['traffic'][0]['requestBody'], contains('mr_x'));

      // Step 3: AI creates a dedicated project "User Simulation"
      final createProjCall = await mcpServer.processMcpRequest({
        'jsonrpc': '2.0',
        'id': 21,
        'method': 'tools/call',
        'params': {
          'name': 'apilab_create_project',
          'arguments': {'projectName': 'User Simulation'},
        },
      });
      final projResult = jsonDecode(createProjCall['result']['content'][0]['text']);
      expect(projResult['success'], isTrue);
      expect(projResult['projectName'], 'User Simulation');
      expect(mockRepo.currentProjects, contains('User Simulation'));

      // Step 4: AI creates conditional Mock Rule for Mr X
      final createMockCall = await mcpServer.processMcpRequest({
        'jsonrpc': '2.0',
        'id': 22,
        'method': 'tools/call',
        'params': {
          'name': 'apilab_create_mock',
          'arguments': {
            'name': 'Simulate Login Mr X',
            'projectName': 'User Simulation',
            'urlPattern': '*/api/v1/auth/login*',
            'matchMethod': 'POST',
            'conditionLogic': 'AND',
            'conditions': [
              {
                'source': 'body',
                'field': 'username',
                'operator': '=',
                'value': 'mr_x',
              }
            ],
            'customVariables': {
              'role': 'Enterprise Administrator',
              'token': 'jwt-mrx-auth-token-xyz',
            },
            'statusCode': 200,
            'responseHeaders': {
              'content-type': 'application/json',
              'x-agent-simulated': 'true',
            },
            'responseBody': jsonEncode({
              'user_id': 1001,
              'username': '{{username}}',
              'role': '{{role}}',
              'auth_token': '{{token}}',
              'timestamp': '{{timestamp}}',
              'status': 'SUCCESS'
            }),
            'description': 'Simulates successful authentication for user mr_x',
          },
        },
      });
      final mockResult = jsonDecode(createMockCall['result']['content'][0]['text']);
      expect(mockResult['success'], isTrue);
      final ruleId = mockResult['ruleId'] as String;

      // Step 5: Verify Mock Rule matches the request and interpolates variables correctly
      final matchingRule = mockRepo.findMatchingRule(loginReq);
      expect(matchingRule, isNotNull);
      expect(matchingRule!.name, 'Simulate Login Mr X');
      expect(matchingRule.projectName, 'User Simulation');

      final resolvedBody = matchingRule.resolveResponseBody(loginReq);
      final bodyJson = jsonDecode(resolvedBody);
      expect(bodyJson['username'], 'mr_x');
      expect(bodyJson['role'], 'Enterprise Administrator');
      expect(bodyJson['auth_token'], 'jwt-mrx-auth-token-xyz');
      expect(bodyJson['status'], 'SUCCESS');

      // Check request with different user "mr_y" -> should NOT match
      final wrongReq = HttpRequestData(
        id: 'req-login-002',
        method: 'POST',
        url: 'https://app.company.com/api/v1/auth/login',
        body: jsonEncode({'username': 'mr_y'}),
        timestamp: DateTime.now(),
      );
      final noMatch = mockRepo.findMatchingRule(wrongReq);
      expect(noMatch, isNull);

      // Step 6: AI can toggle rule state and update rule
      final toggleCall = await mcpServer.processMcpRequest({
        'jsonrpc': '2.0',
        'id': 23,
        'method': 'tools/call',
        'params': {
          'name': 'apilab_toggle_mock',
          'arguments': {'id': ruleId, 'isEnabled': false},
        },
      });
      final toggleResult = jsonDecode(toggleCall['result']['content'][0]['text']);
      expect(toggleResult['isEnabled'], isFalse);

      final noMatchDisabled = mockRepo.findMatchingRule(loginReq);
      expect(noMatchDisabled, isNull);

      // Step 7: AI deletes rule
      final deleteCall = await mcpServer.processMcpRequest({
        'jsonrpc': '2.0',
        'id': 24,
        'method': 'tools/call',
        'params': {
          'name': 'apilab_delete_mock',
          'arguments': {'id': ruleId},
        },
      });
      final deleteResult = jsonDecode(deleteCall['result']['content'][0]['text']);
      expect(deleteResult['success'], isTrue);
      expect(mockRepo.currentRules.any((r) => r.id == ruleId), isFalse);
    });
  });
}
