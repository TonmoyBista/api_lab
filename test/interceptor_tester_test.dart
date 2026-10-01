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
    expect(vm.editableRequest!.url, equals('https://httpbin.org/post'));
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
}
