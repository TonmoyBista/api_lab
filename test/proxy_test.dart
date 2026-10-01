import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:api_lab/domain/models/mcp_and_ai.dart';
import 'package:api_lab/domain/models/mock_rule.dart';
import 'package:api_lab/domain/use_cases/intercept_request_use_case.dart';
import 'package:api_lab/data/repositories/mock_rule_repository_impl.dart';
import 'package:api_lab/data/repositories/traffic_repository_impl.dart';
import 'package:api_lab/infrastructure/proxy/proxy_server.dart';

void main() {
  test('ProxyServer intercepts and mocks HTTPS requests with HttpClient proxy', () async {
    final trafficRepo = TrafficRepositoryImpl();
    final mockRepo = MockRuleRepositoryImpl();
    final interceptUseCase = InterceptRequestUseCase(
      mockRuleRepository: mockRepo,
      trafficRepository: trafficRepo,
    );

    // Add a mock rule for https://api.flowpros.com/users
    await mockRepo.addRule(const MockRule(
      id: 'mock_users',
      name: 'Users Mock',
      matchMethod: 'GET',
      urlPattern: '*/users*',
      responseStatusCode: 200,
      responseBody: '{"users": [{"id": 1, "name": "Tonmoy"}]}',
      responseHeaders: {'content-type': 'application/json'},
    ));

    final proxy = ProxyServer(
      interceptUseCase: interceptUseCase,
      config: const ProxyConfig(port: 9880, enableSslMitm: true),
    );

    final started = await proxy.start();
    expect(started, isTrue);

    // Client simulating user's Flutter app code
    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) => true;
    client.findProxy = (uri) => 'PROXY 127.0.0.1:9880';

    try {
      final req = await client.getUrl(Uri.parse('https://api.flowpros.com/users'));
      final res = await req.close();
      expect(res.statusCode, equals(200));

      final body = await utf8.decodeStream(res);
      expect(body, contains('"Tonmoy"'));

      // Verify traffic was recorded in repository
      final traffic = trafficRepo.currentTraffic;
      expect(traffic, isNotEmpty);
      expect(traffic.first.isMocked, isTrue);
      expect(traffic.first.request.url, equals('https://api.flowpros.com/users'));
    } finally {
      client.close();
      await proxy.stop();
    }
  });

  test('ProxyServer forwards direct HTTP gateway requests', () async {
    final trafficRepo = TrafficRepositoryImpl();
    final mockRepo = MockRuleRepositoryImpl();
    final interceptUseCase = InterceptRequestUseCase(
      mockRuleRepository: mockRepo,
      trafficRepository: trafficRepo,
    );

    final proxy = ProxyServer(
      interceptUseCase: interceptUseCase,
      config: const ProxyConfig(port: 9881, enableSslMitm: true),
    );

    await proxy.start();

    final client = HttpClient();
    try {
      final req = await client.getUrl(Uri.parse('http://127.0.0.1:9881/'));
      final res = await req.close();
      expect(res.statusCode, equals(200));

      final body = await utf8.decodeStream(res);
      final json = jsonDecode(body);
      expect(json['status'], equals('ApiLab Proxy Active'));
      expect(json['localIp'], isNotNull);
    } finally {
      client.close();
      await proxy.stop();
    }
  });

  test('ProxyServer accepts connections via local LAN Wi-Fi IP', () async {
    final trafficRepo = TrafficRepositoryImpl();
    final mockRepo = MockRuleRepositoryImpl();
    final interceptUseCase = InterceptRequestUseCase(
      mockRuleRepository: mockRepo,
      trafficRepository: trafficRepo,
    );

    final proxy = ProxyServer(
      interceptUseCase: interceptUseCase,
      config: const ProxyConfig(port: 9882, enableSslMitm: true),
    );

    await proxy.start();
    final lanIp = proxy.detectedLanIp;

    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) => true;
    client.findProxy = (uri) => 'PROXY $lanIp:9882';

    try {
      final req = await client.getUrl(Uri.parse('https://example.com/test-lan'));
      final res = await req.close();
      expect(res.statusCode, isNotNull);
    } finally {
      client.close();
      await proxy.stop();
    }
  });
}
