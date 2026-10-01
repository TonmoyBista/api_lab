import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/mcp_and_ai.dart';

class GenerateMockResponseUseCase {
  Future<String> generate({
    required AiConfig config,
    required String endpointUrl,
    required String method,
    required int statusCode,
    String description = '',
    String customSchema = '',
  }) async {
    if (config.providerType != AiProviderType.heuristic && config.baseUrl.isNotEmpty) {
      try {
        final aiResult = await _generateWithAi(
          config: config,
          endpointUrl: endpointUrl,
          method: method,
          statusCode: statusCode,
          description: description,
          customSchema: customSchema,
        );
        if (aiResult != null && aiResult.trim().isNotEmpty) {
          return aiResult;
        }
      } catch (e) {
        // Fall back to heuristic if AI request fails
      }
    }

    return _generateHeuristic(
      endpointUrl: endpointUrl,
      method: method,
      statusCode: statusCode,
      description: description,
    );
  }

  Future<String?> _generateWithAi({
    required AiConfig config,
    required String endpointUrl,
    required String method,
    required int statusCode,
    required String description,
    required String customSchema,
  }) async {
    final prompt = '''
You are an expert backend API simulation engine. 
Generate a realistic, production-ready JSON mock response for the following API request:
- HTTP Method: $method
- Endpoint URL: $endpointUrl
- Target Status Code: $statusCode
- Description/Requirements: $description
${customSchema.isNotEmpty ? '- Provided JSON/Schema Hints:\n$customSchema' : ''}

Output ONLY valid JSON. Do not include markdown code block formatting (like ```json), no conversational filler, and no comments.
''';

    final uri = Uri.parse('${config.baseUrl.replaceAll(RegExp(r'/+$'), '')}/chat/completions');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (config.apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${config.apiKey}';
    }

    final payload = {
      'model': config.modelName.isEmpty ? 'default' : config.modelName,
      'messages': [
        {
          'role': 'system',
          'content': 'You are a mock API data generator. You output ONLY raw valid JSON without markdown fences.'
        },
        {'role': 'user', 'content': prompt}
      ],
      'temperature': 0.7,
    };

    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      final rawContent = data['choices']?[0]?['message']?['content'] as String?;
      if (rawContent != null) {
        var clean = rawContent.trim();
        if (clean.startsWith('```json')) {
          clean = clean.substring(7);
        } else if (clean.startsWith('```')) {
          clean = clean.substring(3);
        }
        if (clean.endsWith('```')) {
          clean = clean.substring(0, clean.length - 3);
        }
        clean = clean.trim();
        // Verify valid JSON
        jsonDecode(clean);
        return clean;
      }
    }
    return null;
  }

  String _generateHeuristic({
    required String endpointUrl,
    required String method,
    required int statusCode,
    required String description,
  }) {
    final lowerUrl = endpointUrl.toLowerCase();
    final lowerDesc = description.toLowerCase();
    final rnd = Random();

    if (statusCode >= 400) {
      return jsonEncode({
        'error': {
          'code': statusCode,
          'message': _getErrorMessage(statusCode, lowerUrl),
          'timestamp': DateTime.now().toIso8601String(),
          'requestId': 'req_${rnd.nextInt(900000) + 100000}',
        }
      });
    }

    if (lowerUrl.contains('auth') || lowerUrl.contains('login') || lowerDesc.contains('auth')) {
      return jsonEncode({
        'token_type': 'Bearer',
        'access_token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c3JfMTIzNDUiLCJuYW1lIjoiQWxleCBKb2huc29uIiwicm9sZSI6ImFkbWluIn0.c2FtcGxlX3NpZ25hdHVyZQ',
        'refresh_token': 'rt_9938210948120398',
        'expires_in': 3600,
        'user': {
          'id': 'usr_98124',
          'email': 'alex.johnson@example.com',
          'name': 'Alex Johnson',
          'role': 'developer',
          'is_active': true,
        }
      });
    }

    if (lowerUrl.contains('product') || lowerDesc.contains('product')) {
      return jsonEncode({
        'data': List.generate(4, (i) => {
          'id': 'prod_${i + 101}',
          'name': ['Quantum Pro Wireless Headset', 'ErgoMech Mechanical Keyboard', 'UltraVision 4K OLED Monitor', 'Titanium USB-C Dock'][i % 4],
          'price': [149.99, 129.50, 499.00, 89.95][i % 4],
          'currency': 'USD',
          'category': 'Electronics',
          'stock': rnd.nextInt(50) + 5,
          'rating': (3.5 + rnd.nextDouble() * 1.5).toStringAsFixed(1),
          'tags': ['wireless', 'premium', 'tech'],
          'in_stock': true,
        }),
        'meta': {
          'total': 28,
          'page': 1,
          'per_page': 4,
          'has_more': true,
        }
      });
    }

    if (lowerUrl.contains('user') || lowerUrl.contains('profile') || lowerDesc.contains('user')) {
      return jsonEncode({
        'users': List.generate(3, (i) => {
          'id': 'usr_${1001 + i}',
          'name': ['Sarah Connor', 'Marcus Vance', 'Elena Rostova'][i % 3],
          'email': ['sarah.c@cyber.org', 'marcus.v@studio.io', 'elena.r@fintech.dev'][i % 3],
          'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
          'status': 'active',
          'department': ['Engineering', 'Design', 'Product Management'][i % 3],
          'created_at': DateTime.now().subtract(Duration(days: (i + 1) * 30)).toIso8601String(),
        }),
        'count': 3,
        'status': 'success',
      });
    }

    if (lowerUrl.contains('order') || lowerUrl.contains('checkout') || lowerDesc.contains('order')) {
      return jsonEncode({
        'order_id': 'ord_${rnd.nextInt(89999) + 10000}',
        'status': 'confirmed',
        'total_amount': 279.49,
        'currency': 'USD',
        'items_count': 2,
        'customer': {
          'name': 'David Miller',
          'email': 'david.miller@example.com',
        },
        'shipping_address': {
          'street': '742 Evergreen Terrace',
          'city': 'Springfield',
          'postal_code': '97477',
          'country': 'USA',
        },
        'estimated_delivery': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
      });
    }

    // Default generic payload
    return jsonEncode({
      'success': true,
      'code': statusCode,
      'endpoint': endpointUrl,
      'method': method,
      'data': {
        'id': 'item_${rnd.nextInt(9000) + 1000}',
        'title': 'Simulated Resource from ApiLab',
        'description': description.isNotEmpty ? description : 'Auto-generated mock response payload',
        'isMocked': true,
        'generatedAt': DateTime.now().toIso8601String(),
        'attributes': {
          'version': '1.0.0',
          'latency_simulated': 'realtime',
        }
      }
    });
  }

  String _getErrorMessage(int statusCode, String url) {
    switch (statusCode) {
      case 400: return 'Invalid request payload or malformed query parameters.';
      case 401: return 'Authentication required. Missing or expired token.';
      case 403: return 'Access forbidden. Insufficient permissions for resource.';
      case 404: return 'The requested resource at $url was not found.';
      case 422: return 'Validation failed for field "email". Expected format user@domain.com.';
      case 429: return 'Rate limit exceeded. Try again in 60 seconds.';
      case 500: return 'Internal server error occurred while processing transaction.';
      case 502: return 'Bad Gateway: Upstream dependency failed to respond.';
      case 503: return 'Service temporarily unavailable due to maintenance.';
      default: return 'Request failed with status $statusCode.';
    }
  }
}
