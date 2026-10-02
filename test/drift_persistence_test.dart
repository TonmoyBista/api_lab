import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:api_lab/data/database/app_database.dart';
import 'package:api_lab/data/repositories/mock_rule_repository_impl.dart';
import 'package:api_lab/data/repositories/traffic_repository_impl.dart';
import 'package:api_lab/domain/models/mock_rule.dart';
import 'package:api_lab/domain/models/http_traffic.dart';
import 'package:api_lab/ui/core/widgets/status_badge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Drift Database & Persistence Tests', () {
    test('AppDatabase can save and retrieve mock projects', () async {
      final initialProjects = await db.getAllProjectNames();
      expect(initialProjects, contains('Default Project'));

      await db.insertProject('Auth Service', 'Authentication endpoints');
      await db.insertProject('Payments API', 'Payment gateway mocks');

      final updated = await db.getAllProjectNames();
      expect(updated, containsAll(['Auth Service', 'Payments API']));

      // Delete project
      await db.deleteProject('Auth Service');
      final afterDelete = await db.getAllProjectNames();
      expect(afterDelete.contains('Auth Service'), isFalse);
      expect(afterDelete.contains('Payments API'), isTrue);
    });

    test('AppDatabase can save, toggle, and delete mock rules', () async {
      const rule = MockRule(
        id: 'rule_drift_1',
        name: 'Custom Mock',
        matchMethod: 'GET',
        urlPattern: '*/v2/profile',
        responseStatusCode: 200,
        responseBody: '{"name": "Alice"}',
        projectName: 'User Module',
      );

      await db.upsertMockRule(rule);

      var allRules = await db.getAllMockRules();
      expect(allRules.length, equals(1));
      expect(allRules.first.id, equals('rule_drift_1'));
      expect(allRules.first.name, equals('Custom Mock'));
      expect(allRules.first.isEnabled, isTrue);

      // Toggle rule
      await db.toggleMockRule('rule_drift_1', false);
      allRules = await db.getAllMockRules();
      expect(allRules.first.isEnabled, isFalse);

      // Delete rule
      await db.deleteMockRule('rule_drift_1');
      allRules = await db.getAllMockRules();
      expect(allRules, isEmpty);
    });

    test('MockRuleRepositoryImpl persists rules and projects across instances (simulating app restart)', () async {
      // Instance 1: First app session
      final repo1 = MockRuleRepositoryImpl(database: db);
      await Future.delayed(const Duration(milliseconds: 100));

      await repo1.createProject('E-commerce');
      const customRule = MockRule(
        id: 'ecom_rule_1',
        name: 'Product Details Mock',
        matchMethod: 'GET',
        urlPattern: '*/products/*',
        responseStatusCode: 200,
        responseBody: '{"product": "shoes"}',
        projectName: 'E-commerce',
      );
      await repo1.addRule(customRule);

      expect(repo1.currentRules.any((r) => r.id == 'ecom_rule_1'), isTrue);
      expect(repo1.currentProjects, contains('E-commerce'));

      // Instance 2: Cold app restart with same persistent database
      final repo2 = MockRuleRepositoryImpl(database: db);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(repo2.currentRules.any((r) => r.id == 'ecom_rule_1'), isTrue);
      final restoredRule = repo2.currentRules.firstWhere((r) => r.id == 'ecom_rule_1');
      expect(restoredRule.name, equals('Product Details Mock'));
      expect(restoredRule.responseBody, equals('{"product": "shoes"}'));
      expect(repo2.currentProjects, contains('E-commerce'));
    });
  });

  group('Interceptor Item List & Delete Tests', () {
    test('TrafficRepositoryImpl individual delete item removes only target item', () {
      final repo = TrafficRepositoryImpl();

      final item1 = TrafficItem(
        id: 'item_1',
        request: HttpRequestData(id: 'req_1', method: 'GET', url: 'https://test.com/1', timestamp: DateTime.now()),
      );
      final item2 = TrafficItem(
        id: 'item_2',
        request: HttpRequestData(id: 'req_2', method: 'POST', url: 'https://test.com/2', timestamp: DateTime.now()),
      );

      repo.addTraffic(item1);
      repo.addTraffic(item2);
      expect(repo.currentTraffic.length, equals(2));

      repo.deleteTraffic('item_1');
      expect(repo.currentTraffic.length, equals(1));
      expect(repo.currentTraffic.first.id, equals('item_2'));
    });

    testWidgets('StatusBadge displays only status code by default on item list', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(statusCode: 200, statusReason: 'OK'),
          ),
        ),
      );

      expect(find.text('200'), findsOneWidget);
      expect(find.text('200 OK'), findsNothing);
    });

    testWidgets('StatusBadge displays status code and reason when showReason is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(statusCode: 404, statusReason: 'Not Found', showReason: true),
          ),
        ),
      );

      expect(find.text('404 Not Found'), findsOneWidget);
    });
  });
}
