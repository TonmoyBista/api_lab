import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:api_lab/domain/models/api_request.dart';
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

  test('HttpResponseData and ApiResponseModel detect image responses by Content-Type and magic bytes', () {
    // 1x1 PNG magic bytes
    final pngBytes = Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    ]);

    final resByHeader = HttpResponseData(
      statusCode: 200,
      statusReason: 'OK',
      headers: const {'Content-Type': 'image/png'},
      body: '[Binary Image Data]',
      bodyBytes: pngBytes,
      timestamp: DateTime.now(),
      contentLength: pngBytes.length,
    );
    expect(resByHeader.isImage, isTrue);
    expect(resByHeader.imageBytes, equals(pngBytes));

    final apiResByMagic = ApiResponseModel(
      statusCode: 200,
      statusReason: 'OK',
      headers: const {'content-type': 'application/octet-stream'},
      body: '',
      bodyBytes: pngBytes,
      durationMs: 25,
      sizeBytes: pngBytes.length,
      timestamp: DateTime.now(),
    );
    expect(apiResByMagic.isImage, isTrue);
    expect(apiResByMagic.imageBytes, equals(pngBytes));
  });
}
