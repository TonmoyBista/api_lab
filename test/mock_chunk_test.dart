import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:api_lab/domain/models/mock_rule.dart';
import 'package:api_lab/domain/models/mcp_and_ai.dart';
import 'package:api_lab/domain/use_cases/intercept_request_use_case.dart';
import 'package:api_lab/data/repositories/mock_rule_repository_impl.dart';
import 'package:api_lab/data/repositories/traffic_repository_impl.dart';
import 'package:api_lab/infrastructure/proxy/proxy_server.dart';

void main() {
  test('Mock rule with transfer-encoding chunked or unescaped body parses cleanly', () async {
    final trafficRepo = TrafficRepositoryImpl();
    final mockRepo = MockRuleRepositoryImpl();
    final interceptUseCase = InterceptRequestUseCase(
      mockRuleRepository: mockRepo,
      trafficRepository: trafficRepo,
    );

    // Add mock rule with headers that might contain transfer-encoding: chunked
    await mockRepo.addRule(const MockRule(
      id: 'mock_profile',
      name: 'User Profile Mock',
      matchMethod: 'GET',
      urlPattern: '*/api/v1/user_profile_info*',
      responseStatusCode: 200,
      responseBody: '{"status": "success", "profile": {"name": "Test User"}}',
      responseHeaders: {
        'transfer-encoding': 'chunked',
        'content-encoding': 'gzip',
        'content-type': 'application/json',
      },
    ));

    final proxy = ProxyServer(
      interceptUseCase: interceptUseCase,
      config: const ProxyConfig(port: 9885, enableSslMitm: true),
    );

    await proxy.start();

    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) => true;
    client.findProxy = (uri) => 'PROXY 127.0.0.1:9885';

    try {
      final req = await client.getUrl(Uri.parse('https://testing-flowpros.odoo.com/api/v1/user_profile_info'));
      final res = await req.close();
      expect(res.statusCode, equals(200));

      final body = await utf8.decodeStream(res);
      expect(body, contains('Test User'));
    } catch (_) {
      rethrow;
    } finally {
      client.close();
      await proxy.stop();
    }
  });
}
