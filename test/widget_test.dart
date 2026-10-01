import 'package:flutter_test/flutter_test.dart';
import 'package:api_lab/domain/models/http_traffic.dart';
import 'package:api_lab/domain/models/mock_rule.dart';

void main() {
  testWidgets('ApiLab Domain Models instantiation smoke test', (WidgetTester tester) async {
    const rule = MockRule(
      id: '1',
      name: 'Sample Rule',
      urlPattern: '*/test*',
      responseBody: '{}',
    );

    final req = HttpRequestData(
      id: 'req_1',
      method: 'GET',
      url: 'https://example.com/test',
      timestamp: DateTime.now(),
    );

    expect(rule.matches(req), isTrue);
  });
}
