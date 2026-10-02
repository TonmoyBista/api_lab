import 'package:flutter_test/flutter_test.dart';
import 'package:api_lab/domain/models/http_traffic.dart';
import 'package:api_lab/domain/models/mock_rule.dart';
import 'package:api_lab/domain/use_cases/intercept_request_use_case.dart';
import 'package:api_lab/domain/models/api_request.dart';
import 'package:api_lab/data/repositories/mock_rule_repository_impl.dart';
import 'package:api_lab/data/repositories/traffic_repository_impl.dart';
import 'package:api_lab/data/repositories/settings_repository_impl.dart';
import 'package:api_lab/infrastructure/mcp/mcp_server.dart';
import 'package:api_lab/domain/use_cases/replay_request_use_case.dart';

void main() {
  group('MockRule Pattern Matching Tests', () {
    test('Matches wildcard URL correctly', () {
      const rule = MockRule(
        id: 'rule_1',
        name: 'Users API Mock',
        matchMethod: 'GET',
        urlPattern: '*/api/v1/users*',
        responseBody: '{"users": []}',
      );

      final matchingReq = HttpRequestData(
        id: 'req_1',
        method: 'GET',
        url: 'https://example.com/api/v1/users?page=1',
        timestamp: DateTime.now(),
      );

      final nonMatchingReq = HttpRequestData(
        id: 'req_2',
        method: 'POST',
        url: 'https://example.com/api/v1/users',
        timestamp: DateTime.now(),
      );

      final otherPathReq = HttpRequestData(
        id: 'req_3',
        method: 'GET',
        url: 'https://example.com/api/v1/orders',
        timestamp: DateTime.now(),
      );

      expect(rule.matches(matchingReq), isTrue);
      expect(rule.matches(nonMatchingReq), isFalse); // method mismatch
      expect(rule.matches(otherPathReq), isFalse); // path mismatch
    });

    test('Matches method ALL correctly', () {
      const rule = MockRule(
        id: 'rule_2',
        name: 'Telemetry Mock',
        matchMethod: 'ALL',
        urlPattern: '*telemetry*',
        responseBody: '{"ok": true}',
      );

      expect(rule.matches(HttpRequestData(
        id: '1', method: 'GET', url: 'http://app.io/telemetry', timestamp: DateTime.now(),
      )), isTrue);

      expect(rule.matches(HttpRequestData(
        id: '2', method: 'POST', url: 'http://app.io/telemetry', timestamp: DateTime.now(),
      )), isTrue);
    });
  });

  group('InterceptRequestUseCase Tests', () {
    test('Intercepts and returns mock response when rule matches', () async {
      final trafficRepo = TrafficRepositoryImpl();
      final mockRepo = MockRuleRepositoryImpl();
      final useCase = InterceptRequestUseCase(
        mockRuleRepository: mockRepo,
        trafficRepository: trafficRepo,
      );

      const rule = MockRule(
        id: 'test_rule',
        name: 'Mock Test',
        matchMethod: 'GET',
        urlPattern: '*/mocked-endpoint*',
        responseStatusCode: 201,
        responseBody: '{"created": true}',
      );
      await mockRepo.addRule(rule);

      final req = HttpRequestData(
        id: 'test_req',
        method: 'GET',
        url: 'https://api.test.com/mocked-endpoint',
        timestamp: DateTime.now(),
      );

      final result = await useCase.evaluateRequest(req);

      expect(result.isMocked, isTrue);
      expect(result.mockResponse, isNotNull);
      expect(result.mockResponse!.statusCode, equals(201));
      expect(result.mockResponse!.body, equals('{"created": true}'));

      final logged = trafficRepo.getById('test_req');
      expect(logged, isNotNull);
      expect(logged!.isMocked, isTrue);
      expect(logged.status, equals(TrafficStatus.mocked));
    });
  });

  group('Project Deletion & Replay Request Tests', () {
    test('MockRuleRepository deletes project and its associated mock rules', () async {
      final repo = MockRuleRepositoryImpl();
      await repo.createProject('Temp Project');
      expect(repo.currentProjects, contains('Temp Project'));

      await repo.addRule(const MockRule(
        id: 'temp_rule_1',
        name: 'Temp Mock',
        urlPattern: '*/temp*',
        responseBody: '{"ok": true}',
        projectName: 'Temp Project',
      ));
      expect(repo.currentRules.any((r) => r.id == 'temp_rule_1'), isTrue);

      await repo.deleteProject('Temp Project');
      expect(repo.currentProjects.contains('Temp Project'), isFalse);
      expect(repo.currentRules.any((r) => r.id == 'temp_rule_1'), isFalse);
    });

    test('ApiRequestModel resolvedHeaders strips content-length and transport headers', () {
      final req = ApiRequestModel(
        id: 'req_mod_1',
        url: 'https://example.com/api/login',
        method: 'POST',
        headers: const [
          KeyValuePair(key: 'Content-Length', value: '55'),
          KeyValuePair(key: 'Host', value: 'example.com'),
          KeyValuePair(key: 'Content-Type', value: 'application/json'),
        ],
        bodyType: 'json',
        bodyContent: '[{"license_key":"asdf","login":"asdf","password":"asdf6"}]', // 56 bytes
        updatedAt: DateTime.now(),
      );

      final headers = req.resolvedHeaders;
      // Stale Content-Length of 55 must NOT be present, preventing contentLength mismatch
      expect(headers.containsKey('Content-Length'), isFalse);
      expect(headers.containsKey('content-length'), isFalse);
      expect(headers.containsKey('Host'), isFalse);
      expect(headers['Content-Type'], equals('application/json'));
    });
  });

  group('MCP Server Protocol Tests', () {
    test('Initializes with standard MCP capabilities', () async {
      final trafficRepo = TrafficRepositoryImpl();
      final mockRepo = MockRuleRepositoryImpl();
      final settingsRepo = SettingsRepositoryImpl();
      final replayUseCase = ReplayRequestUseCase();

      final mcpServer = McpServer(
        trafficRepository: trafficRepo,
        mockRuleRepository: mockRepo,
        replayRequestUseCase: replayUseCase,
        settingsRepository: settingsRepo,
      );

      final initResponse = await mcpServer.processMcpRequest({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'initialize',
        'params': {},
      });

      expect(initResponse['jsonrpc'], equals('2.0'));
      expect(initResponse['result']['serverInfo']['name'], equals('ApiLab-MCP-Server'));

      final toolsResponse = await mcpServer.processMcpRequest({
        'jsonrpc': '2.0',
        'id': 2,
        'method': 'tools/list',
        'params': {},
      });

      final tools = toolsResponse['result']['tools'] as List;
      expect(tools.any((t) => t['name'] == 'apilab_create_mock'), isTrue);
      expect(tools.any((t) => t['name'] == 'apilab_get_traffic'), isTrue);
      expect(tools.any((t) => t['name'] == 'apilab_delete_project'), isTrue);
    });
  });
}
