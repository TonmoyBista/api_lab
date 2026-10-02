import 'package:flutter_test/flutter_test.dart';
import 'package:api_lab/domain/models/http_traffic.dart';
import 'package:api_lab/domain/use_cases/replay_request_use_case.dart';
import 'package:api_lab/data/repositories/mock_rule_repository_impl.dart';
import 'package:api_lab/data/repositories/traffic_repository_impl.dart';
import 'package:api_lab/infrastructure/proxy/proxy_server.dart';
import 'package:api_lab/domain/use_cases/intercept_request_use_case.dart';
import 'package:api_lab/ui/features/interceptor/view_models/interceptor_view_model.dart';

void main() {
  test('InterceptorViewModel supports in-place request editing and replay without separate page', () async {
    final trafficRepo = TrafficRepositoryImpl();
    final mockRepo = MockRuleRepositoryImpl();
    final interceptUseCase = InterceptRequestUseCase(
      mockRuleRepository: mockRepo,
      trafficRepository: trafficRepo,
    );
    final proxyServer = ProxyServer(interceptUseCase: interceptUseCase);
    final replayUseCase = ReplayRequestUseCase();

    final vm = InterceptorViewModel(
      trafficRepository: trafficRepo,
      proxyServer: proxyServer,
      mockRuleRepository: mockRepo,
      replayRequestUseCase: replayUseCase,
    );

    // 1. Create a request in-place
    vm.createNewRequest();
    expect(vm.editableRequest, isNotNull);
    expect(vm.editableRequest!.method, equals('GET'));

    // 2. Edit method, URL, query parameters, headers in-place
    vm.updateMethod('POST');
    vm.updateUrl('https://httpbin.org/post');
    vm.addQueryParam();
    vm.updateQueryParam(0, 'test_param', '123', true);
    vm.addHeader();
    vm.updateHeader(0, 'X-Custom-Test', 'ApiLabValue', true);
    vm.updateBodyType('json');
    vm.updateBodyContent('{"user": "tonmoy", "action": "test"}');

    expect(vm.editableRequest!.method, equals('POST'));
    expect(vm.editableRequest!.url, equals('https://httpbin.org/post?test_param=123'));
    expect(vm.editableRequest!.queryParams.any((p) => p.key == 'test_param' && p.value == '123'), isTrue);
    expect(vm.editableRequest!.headers.any((h) => h.key == 'X-Custom-Test' && h.value == 'ApiLabValue'), isTrue);
    expect(vm.editableRequest!.bodyContent, contains('tonmoy'));

    // 3. Test loading from intercepted traffic into in-place editor
    final capturedItem = TrafficItem(
      id: 'traffic_123',
      request: HttpRequestData(
        id: 'traffic_123',
        method: 'GET',
        url: 'https://jsonplaceholder.typicode.com/todos/1',
        headers: {'Authorization': 'Bearer test_token'},
        queryParams: {'filter': 'active'},
        body: '',
        timestamp: DateTime.now(),
      ),
      response: HttpResponseData(
        statusCode: 200,
        statusReason: 'OK',
        headers: {'content-type': 'application/json'},
        body: '{"id": 1, "title": "Buy milk"}',
        timestamp: DateTime.now(),
        durationMs: 45,
        contentLength: 30,
      ),
    );

    vm.selectItem(capturedItem);
    expect(vm.editableRequest, isNotNull);
    expect(vm.editableRequest!.url, equals('https://jsonplaceholder.typicode.com/todos/1'));
    expect(vm.editableRequest!.headers.any((h) => h.key == 'Authorization'), isTrue);
    expect(vm.testResponse, isNotNull);
    expect(vm.testResponse!.statusCode, equals(200));

    // Can immediately edit the captured request in-place:
    vm.updateHeader(0, 'Authorization', 'Bearer new_token', true);
    expect(vm.editableRequest!.headers.first.value, equals('Bearer new_token'));
  });

  test('Editing request body with existing content-length strips stale header and prevents mismatch', () async {
    final replayUseCase = ReplayRequestUseCase();
    final itemWithContentLength = TrafficItem(
      id: 'traffic_login',
      request: HttpRequestData(
        id: 'traffic_login',
        method: 'POST',
        url: 'https://httpbin.org/post',
        headers: {
          'content-type': 'application/json',
          'content-length': '55', // Stale 55 bytes
          'host': 'httpbin.org',
        },
        body: '[{"license_key":"asdf","login":"asdf","password":"asdf"}]', // 55 bytes
        timestamp: DateTime.now(),
      ),
    );

    final trafficRepo = TrafficRepositoryImpl();
    final mockRepo = MockRuleRepositoryImpl();
    final interceptUseCase = InterceptRequestUseCase(mockRuleRepository: mockRepo, trafficRepository: trafficRepo);
    final proxyServer = ProxyServer(interceptUseCase: interceptUseCase);

    final vm = InterceptorViewModel(
      trafficRepository: trafficRepo,
      proxyServer: proxyServer,
      mockRuleRepository: mockRepo,
      replayRequestUseCase: replayUseCase,
    );

    vm.selectItem(itemWithContentLength);

    // Stale content-length and host must NOT be imported into headers
    expect(vm.editableRequest!.headers.any((h) => h.key.toLowerCase() == 'content-length'), isFalse);
    expect(vm.editableRequest!.headers.any((h) => h.key.toLowerCase() == 'host'), isFalse);

    // Modify request body from 55 bytes to 56 bytes
    vm.updateBodyContent('[{"license_key":"asdf","login":"asdf","password":"asdf6"}]'); // 56 bytes

    // resolvedHeaders must never expose stale content-length
    expect(vm.editableRequest!.resolvedHeaders.containsKey('content-length'), isFalse);
    expect(vm.editableRequest!.resolvedHeaders.containsKey('Content-Length'), isFalse);
  });

  test('Modifying URL query parameters synchronizes bidirectionally with queryParams list and fullUri', () {
    final trafficRepo = TrafficRepositoryImpl();
    final mockRepo = MockRuleRepositoryImpl();
    final interceptUseCase = InterceptRequestUseCase(mockRuleRepository: mockRepo, trafficRepository: trafficRepo);
    final proxyServer = ProxyServer(interceptUseCase: interceptUseCase);
    final replayUseCase = ReplayRequestUseCase();

    final vm = InterceptorViewModel(
      trafficRepository: trafficRepo,
      proxyServer: proxyServer,
      mockRuleRepository: mockRepo,
      replayRequestUseCase: replayUseCase,
    );

    // Initial request with task_details_list?limit=100&offset=0
    vm.createNewRequest();
    vm.updateUrl('https://api.example.com/task_details_list?limit=100&offset=0');

    // 1. Verify queryParams list was automatically parsed and populated
    expect(vm.editableRequest!.queryParams.length, equals(2));
    expect(vm.editableRequest!.queryParams[0].key, equals('limit'));
    expect(vm.editableRequest!.queryParams[0].value, equals('100'));
    expect(vm.editableRequest!.queryParams[1].key, equals('offset'));
    expect(vm.editableRequest!.queryParams[1].value, equals('0'));

    // 2. User modifies URL bar to change limit=10
    vm.updateUrl('https://api.example.com/task_details_list?limit=10&offset=0');
    expect(vm.editableRequest!.queryParams.length, equals(2));
    expect(vm.editableRequest!.queryParams[0].key, equals('limit'));
    expect(vm.editableRequest!.queryParams[0].value, equals('10'));
    expect(vm.editableRequest!.fullUri.queryParameters['limit'], equals('10'));
    expect(vm.editableRequest!.fullUri.queryParameters['offset'], equals('0'));

    // 3. User modifies query param from the params list (e.g. limit -> 25)
    vm.updateQueryParam(0, 'limit', '25', true);
    expect(vm.editableRequest!.url, equals('https://api.example.com/task_details_list?limit=25&offset=0'));
    expect(vm.editableRequest!.fullUri.queryParameters['limit'], equals('25'));

    // 4. User unchecks offset (disables param)
    vm.updateQueryParam(1, 'offset', '0', false);
    expect(vm.editableRequest!.url, equals('https://api.example.com/task_details_list?limit=25'));
    expect(vm.editableRequest!.fullUri.queryParameters.containsKey('offset'), isFalse);
    expect(vm.editableRequest!.fullUri.queryParameters['limit'], equals('25'));

    // 5. User works with relative URL without scheme (e.g. task_details_list?limit=10&offset=0)
    vm.updateUrl('task_details_list?limit=10&offset=0');
    expect(vm.editableRequest!.queryParams.length, equals(2));
    expect(vm.editableRequest!.queryParams[0].key, equals('limit'));
    expect(vm.editableRequest!.queryParams[0].value, equals('10'));
    expect(vm.editableRequest!.fullUri.queryParameters['limit'], equals('10'));
  });
}
