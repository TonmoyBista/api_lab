import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../../domain/models/api_request.dart';
import '../../domain/models/mcp_and_ai.dart';
import '../../domain/models/mock_rule.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/use_cases/generate_mock_response_use_case.dart';
import '../../domain/use_cases/replay_request_use_case.dart';

class McpServer {
  final ITrafficRepository _trafficRepository;
  final IMockRuleRepository _mockRuleRepository;
  final ReplayRequestUseCase _replayRequestUseCase;
  final GenerateMockResponseUseCase _generateMockUseCase;
  final ISettingsRepository _settingsRepository;

  HttpServer? _httpServer;
  bool _isRunning = false;
  final List<McpLogEntry> _logs = [];
  final StreamController<List<McpLogEntry>> _logsController = StreamController<List<McpLogEntry>>.broadcast();
  final List<HttpResponse> _sseClients = [];
  final Map<String, HttpResponse> _sseSessionClients = {};
  Timer? _keepAliveTimer;

  String _detectedLanIp = '127.0.0.1';

  McpServer({
    required this._trafficRepository,
    required this._mockRuleRepository,
    required this._replayRequestUseCase,
    required this._generateMockUseCase,
    required this._settingsRepository,
  });

  bool get isRunning => _isRunning;
  String get detectedLanIp => _detectedLanIp;
  List<McpLogEntry> get logs => List.unmodifiable(_logs);
  Stream<List<McpLogEntry>> get logsStream => _logsController.stream;
  int get activeClients => _sseClients.length;

  Future<void> _detectLanIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) {
            _detectedLanIp = addr.address;
            return;
          }
        }
      }
    } catch (_) {}
  }

  Future<bool> start() async {
    if (_isRunning) return true;

    final config = _settingsRepository.getMcpConfig();
    try {
      await _detectLanIp();
      final bindAddress = (config.host == '127.0.0.1' || config.host == '0.0.0.0')
          ? InternetAddress.anyIPv4
          : config.host;
      _httpServer = await HttpServer.bind(bindAddress, config.port, shared: true);
      _isRunning = true;
      _log('SYSTEM', 'MCP Server active on 0.0.0.0:${config.port} (Local: 127.0.0.1:${config.port}, LAN: $_detectedLanIp:${config.port})');

      _keepAliveTimer?.cancel();
      _keepAliveTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        for (final client in _sseClients) {
          try {
            client.write(': keepalive\n\n');
            client.flush();
          } catch (_) {}
        }
      });

      _httpServer!.listen(_handleHttpRequest);
      return true;
    } catch (e) {
      _log('SYSTEM', 'Failed to start MCP server: $e');
      _isRunning = false;
      return false;
    }
  }

  Future<void> stop() async {
    if (!_isRunning) return;
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    for (final client in _sseClients) {
      try {
        await client.close();
      } catch (_) {}
    }
    _sseClients.clear();
    _sseSessionClients.clear();
    await _httpServer?.close(force: true);
    _httpServer = null;
    _isRunning = false;
    _log('SYSTEM', 'MCP Server stopped.');
  }

  Future<void> _handleHttpRequest(HttpRequest request) async {
    // Add CORS headers for web/desktop agents
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, HEAD');
    request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type, Authorization, Accept, X-Requested-With, mcp-session-id, x-session-id');
    request.response.headers.add('Access-Control-Expose-Headers', '*');
    request.response.headers.add('Access-Control-Max-Age', '86400');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    final path = request.uri.path;

    // 1. JSON-RPC requests via POST (Streamable HTTP /mcp, /sse, /messages, /jsonrpc, or /)
    if (request.method == 'POST') {
      await _handleJsonRpcMessage(request);
      return;
    }

    // 2. SSE subscription stream via GET (/sse, /mcp, or text/event-stream)
    if (path == '/sse' || path == '/mcp' || (request.headers.value('accept')?.contains('text/event-stream') ?? false)) {
      await _handleSse(request);
      return;
    }

    // 3. Health check / info
    if (path == '/' || path == '/info') {
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({
        'name': 'ApiLab MCP Server',
        'version': '1.0.0',
        'status': 'online',
        'protocolVersion': '2024-11-05',
        'endpoints': {
          'mcp': '/mcp',
          'sse': '/sse',
          'messages': '/messages',
        },
        'tools': _getAvailableTools().map((t) => t.name).toList(),
      }));
      await request.response.close();
      return;
    }

    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
  }

  Future<void> _handleSse(HttpRequest request) async {
    request.response.bufferOutput = false;
    request.response.headers.set('Content-Type', 'text/event-stream; charset=utf-8');
    request.response.headers.set('Cache-Control', 'no-cache, no-transform');
    request.response.headers.set('Connection', 'keep-alive');
    request.response.headers.set('X-Accel-Buffering', 'no');

    const uuid = Uuid();
    final sessionId = uuid.v4();
    _sseClients.add(request.response);
    _sseSessionClients[sessionId] = request.response;
    _log('IN', 'New MCP Client connected (Session $sessionId)');

    // 1. Initial keep-alive comment
    request.response.write(': ready\n\n');
    // 2. Send endpoint event per MCP specification (full resolved URI)
    final endpointUri = request.requestedUri.resolve('/messages?sessionId=$sessionId');
    request.response.write('event: endpoint\ndata: $endpointUri\n\n');
    await request.response.flush();

    request.response.done.then((_) {
      _sseClients.remove(request.response);
      _sseSessionClients.remove(sessionId);
      _log('OUT', 'MCP Client disconnected (Session $sessionId)');
    });
  }

  Future<void> _handleJsonRpcMessage(HttpRequest request) async {
    String bodyStr = '';
    try {
      final bodyBytes = await request.fold<List<int>>([], (p, e) => p..addAll(e));
      bodyStr = utf8.decode(bodyBytes);
    } catch (_) {}

    if (bodyStr.trim().isEmpty) {
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
      return;
    }

    _log('IN', bodyStr);

    final sessionId = request.uri.queryParameters['sessionId'] ??
        request.headers.value('mcp-session-id') ??
        request.headers.value('x-session-id');
    final sseClient = (sessionId != null ? _sseSessionClients[sessionId] : null) ??
        (_sseClients.isNotEmpty ? _sseClients.last : null);

    const uuid = Uuid();
    final currentSessionId = sessionId ?? uuid.v4();
    request.response.headers.set('Mcp-Session-Id', currentSessionId);
    request.response.headers.set('mcp-session-id', currentSessionId);
    request.response.headers.set('Access-Control-Expose-Headers', 'Mcp-Session-Id, mcp-session-id, Content-Type');

    try {
      final decodedJson = jsonDecode(bodyStr);

      dynamic responseData;
      if (decodedJson is List) {
        final batchResults = <Map<String, dynamic>>[];
        for (final item in decodedJson) {
          if (item is Map && (!item.containsKey('id') || item['id'] == null)) {
            // Notification inside batch - no response per JSON-RPC 2.0
            await processMcpRequest(item);
          } else {
            batchResults.add(await processMcpRequest(item));
          }
        }
        if (batchResults.isEmpty) {
          // All items were notifications
          request.response.statusCode = HttpStatus.accepted;
          await request.response.close();
          return;
        }
        responseData = batchResults;
      } else if (decodedJson is Map && (!decodedJson.containsKey('id') || decodedJson['id'] == null)) {
        // Notification - execute side effects but return 202 Accepted with NO body per JSON-RPC 2.0 & Streamable HTTP
        await processMcpRequest(decodedJson);
        request.response.statusCode = HttpStatus.accepted;
        await request.response.close();
        return;
      } else {
        responseData = await processMcpRequest(decodedJson);
      }

      if (responseData == null) {
        request.response.statusCode = HttpStatus.noContent;
        await request.response.close();
        return;
      }

      final responseStr = jsonEncode(responseData);
      _log('OUT', responseStr);

      // Push to SSE client if connected
      if (sseClient != null) {
        try {
          sseClient.write('event: message\ndata: $responseStr\n\n');
          await sseClient.flush();
        } catch (_) {}
      }

      request.response.bufferOutput = false;
      request.response.statusCode = HttpStatus.ok;

      final acceptHeader = request.headers.value('accept') ?? '';
      if (acceptHeader.contains('text/event-stream') && !acceptHeader.contains('application/json')) {
        request.response.headers.set('Content-Type', 'text/event-stream; charset=utf-8');
        request.response.write('event: message\ndata: $responseStr\n\n');
      } else {
        request.response.headers.contentType = ContentType.json;
        request.response.write(responseStr);
      }
      await request.response.close();
    } catch (e) {
      final errorResponse = {
        'jsonrpc': '2.0',
        'error': {'code': -32603, 'message': 'Internal error: $e'},
        'id': null,
      };
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(errorResponse));
      await request.response.close();
    }
  }

  Future<Map<String, dynamic>> processMcpRequest(dynamic requestData) async {
    if (requestData is! Map) {
      return {
        'jsonrpc': '2.0',
        'error': {'code': -32600, 'message': 'Invalid Request'},
        'id': null,
      };
    }

    final id = requestData['id'];
    final method = requestData['method'] as String?;
    final params = (requestData['params'] as Map?) ?? {};

    // Standard JSON-RPC notification handling
    if (method == 'notifications/initialized' || method == 'notifications/cancelled') {
      return {'jsonrpc': '2.0', 'id': id, 'result': {}};
    }

    switch (method) {
      case 'initialize':
        return {
          'jsonrpc': '2.0',
          'id': id,
          'result': {
            'protocolVersion': '2024-11-05',
            'capabilities': {
              'tools': {'listChanged': true},
              'resources': {'subscribe': false, 'listChanged': true},
              'prompts': {'listChanged': true},
              'logging': {},
            },
            'serverInfo': {
              'name': 'ApiLab-MCP-Server',
              'version': '1.0.0',
            },
            'instructions': 'ApiLab MCP server provides tools to inspect intercepted HTTP traffic, manage mock projects, and create conditional mock rules for simulating API endpoints in mobile and web applications.',
          }
        };

      case 'resources/list':
        return {
          'jsonrpc': '2.0',
          'id': id,
          'result': {
            'resources': [
              {
                'uri': 'apilab://traffic',
                'name': 'Intercepted HTTP Traffic',
                'description': 'Real-time JSON of all captured requests, responses, headers, and payloads',
                'mimeType': 'application/json',
              },
              {
                'uri': 'apilab://projects',
                'name': 'ApiLab Mock Projects',
                'description': 'List of all active and empty mock projects',
                'mimeType': 'application/json',
              },
              {
                'uri': 'apilab://rules',
                'name': 'Configured Mock Rules',
                'description': 'Complete set of active/inactive mock API rules, condition trees, and responses',
                'mimeType': 'application/json',
              },
            ]
          }
        };

      case 'resources/templates/list':
        return {
          'jsonrpc': '2.0',
          'id': id,
          'result': {'resourceTemplates': []}
        };

      case 'resources/read':
        final uri = (params['uri'] as String?) ?? '';
        final contentStr = _readResourceContent(uri);
        return {
          'jsonrpc': '2.0',
          'id': id,
          'result': {
            'contents': [
              {
                'uri': uri,
                'mimeType': 'application/json',
                'text': contentStr,
              }
            ]
          }
        };

      case 'prompts/list':
        return {
          'jsonrpc': '2.0',
          'id': id,
          'result': {
            'prompts': [
              {
                'name': 'simulate_mock_scenario',
                'description': 'Simulate an application API scenario by creating mock rules from intercepted traffic or specifications.',
                'arguments': [
                  {
                    'name': 'scenario',
                    'description': 'The scenario to simulate (e.g. login with mr x and mock profile)',
                    'required': true,
                  }
                ],
              }
            ]
          }
        };

      case 'prompts/get':
        final scenarioArg = (params['arguments'] as Map?)?['scenario'] ?? 'general simulation';
        return {
          'jsonrpc': '2.0',
          'id': id,
          'result': {
            'description': 'Prompt for scenario: $scenarioArg',
            'messages': [
              {
                'role': 'user',
                'content': {
                  'type': 'text',
                  'text': 'Analyze the intercepted HTTP traffic in ApiLab and create a mock project and rule for scenario: "$scenarioArg". Match the necessary endpoint and return realistic mock response payload.',
                }
              }
            ]
          }
        };

      case 'tools/list':
        final tools = _getAvailableTools();
        return {
          'jsonrpc': '2.0',
          'id': id,
          'result': {
            'tools': tools.map((t) => t.toJson()).toList(),
          }
        };

      case 'tools/call':
        final toolName = params['name'] as String?;
        final arguments = (params['arguments'] as Map?) ?? {};
        try {
          final resultText = await _executeTool(toolName, arguments);
          return {
            'jsonrpc': '2.0',
            'id': id,
            'result': {
              'content': [
                {
                  'type': 'text',
                  'text': resultText,
                }
              ],
              'isError': false,
            }
          };
        } catch (e) {
          return {
            'jsonrpc': '2.0',
            'id': id,
            'result': {
              'content': [
                {
                  'type': 'text',
                  'text': 'Error executing tool $toolName: $e',
                }
              ],
              'isError': true,
            }
          };
        }

      case 'ping':
        return {'jsonrpc': '2.0', 'id': id, 'result': {}};

      case 'logging/setLevel':
        return {'jsonrpc': '2.0', 'id': id, 'result': {}};

      case 'completion/complete':
        return {
          'jsonrpc': '2.0',
          'id': id,
          'result': {
            'completion': {'values': [], 'total': 0, 'hasMore': false}
          }
        };

      default:
        return {
          'jsonrpc': '2.0',
          'id': id,
          'error': {'code': -32601, 'message': 'Method not found: $method'},
        };
    }
  }

  String _readResourceContent(String uri) {
    if (uri == 'apilab://traffic') {
      final traffic = _trafficRepository.currentTraffic.map((t) => t.toJson()).toList();
      return jsonEncode({'count': traffic.length, 'traffic': traffic});
    } else if (uri == 'apilab://projects') {
      final projects = _mockRuleRepository.currentProjects;
      final rules = _mockRuleRepository.currentRules;
      final projectList = projects.map((p) {
        final projectRules = rules.where((r) => r.projectName == p || r.projectId == p).toList();
        return {
          'name': p,
          'totalRules': projectRules.length,
          'enabledRules': projectRules.where((r) => r.isEnabled).length,
          'rules': projectRules.map((r) => {
            'id': r.id,
            'name': r.name,
            'matchMethod': r.matchMethod,
            'urlPattern': r.urlPattern,
            'isEnabled': r.isEnabled,
          }).toList(),
        };
      }).toList();
      return jsonEncode({'count': projectList.length, 'projects': projectList});
    } else if (uri == 'apilab://rules') {
      final rules = _mockRuleRepository.currentRules.map((r) => r.toJson()).toList();
      return jsonEncode({'count': rules.length, 'rules': rules});
    }
    return jsonEncode({'error': 'Unknown resource: $uri'});
  }

  List<McpToolDefinition> _getAvailableTools() {
    return [
      const McpToolDefinition(
        name: 'apilab_get_traffic',
        description: 'Fetch recently intercepted HTTP/HTTPS requests and responses in ApiLab with optional URL, method, status, or keyword filtering.',
        inputSchema: {
          'type': 'object',
          'properties': {
            'limit': {'type': 'integer', 'description': 'Max items to return (default: 50)'},
            'urlFilter': {'type': 'string', 'description': 'Optional substring to match against URL'},
            'methodFilter': {'type': 'string', 'description': 'Optional HTTP method filter (GET, POST, etc.)'},
            'statusFilter': {'type': 'string', 'description': 'Optional status filter: pending, intercepted, completed, failed, mocked'},
            'mockedOnly': {'type': 'boolean', 'description': 'Filter only mocked responses'},
            'searchQuery': {'type': 'string', 'description': 'Search across URL, request body, and response body'},
          },
        },
      ),
      const McpToolDefinition(
        name: 'apilab_get_traffic_detail',
        description: 'Get full details of a specific intercepted request by ID, including complete headers, query params, request body, and response body.',
        inputSchema: {
          'type': 'object',
          'required': ['id'],
          'properties': {
            'id': {'type': 'string', 'description': 'Traffic item ID'},
          },
        },
      ),
      const McpToolDefinition(
        name: 'apilab_clear_traffic',
        description: 'Clear all captured HTTP traffic history in ApiLab.',
        inputSchema: {'type': 'object', 'properties': {}},
      ),
      const McpToolDefinition(
        name: 'apilab_list_projects',
        description: 'List all mock projects and their rule statistics.',
        inputSchema: {'type': 'object', 'properties': {}},
      ),
      const McpToolDefinition(
        name: 'apilab_create_project',
        description: 'Create a new mock project in ApiLab to organize mock rules.',
        inputSchema: {
          'type': 'object',
          'required': ['projectName'],
          'properties': {
            'projectName': {'type': 'string', 'description': 'Name of the project to create'},
          },
        },
      ),
      const McpToolDefinition(
        name: 'apilab_list_rules',
        description: 'List all mock rules or filter by project, urlPattern, or method.',
        inputSchema: {
          'type': 'object',
          'properties': {
            'projectName': {'type': 'string', 'description': 'Optional project name filter'},
            'urlFilter': {'type': 'string', 'description': 'Optional URL pattern filter'},
            'methodFilter': {'type': 'string', 'description': 'Optional HTTP method filter'},
            'isEnabledOnly': {'type': 'boolean', 'description': 'Filter only enabled rules'},
          },
        },
      ),
      const McpToolDefinition(
        name: 'apilab_get_rule_detail',
        description: 'Get complete definition and conditions of a mock rule by ID.',
        inputSchema: {
          'type': 'object',
          'required': ['id'],
          'properties': {
            'id': {'type': 'string', 'description': 'Mock rule ID'},
          },
        },
      ),
      const McpToolDefinition(
        name: 'apilab_create_mock',
        description: 'Create and activate a new mock API rule with optional conditions (AND/OR logic, query/body/header matching, custom variables, and template response).',
        inputSchema: {
          'type': 'object',
          'required': ['name', 'urlPattern', 'responseBody'],
          'properties': {
            'name': {'type': 'string', 'description': 'Descriptive name for the mock rule (e.g. "Simulate Login Mr X")'},
            'projectName': {'type': 'string', 'description': 'Project name to assign rule to (defaults to "Default Project")'},
            'urlPattern': {'type': 'string', 'description': 'URL pattern e.g. "*/api/v1/user_profile_info*" or "/api/login"'},
            'matchMethod': {'type': 'string', 'description': 'HTTP method: GET, POST, PUT, DELETE, PATCH, or ALL (default: ALL)'},
            'isRegex': {'type': 'boolean', 'description': 'Whether urlPattern is a regular expression'},
            'conditionLogic': {'type': 'string', 'description': 'Logic between conditions: "AND" or "OR" (default: "AND")'},
            'conditions': {
              'type': 'array',
              'description': 'List of conditional rules',
              'items': {
                'type': 'object',
                'properties': {
                  'source': {'type': 'string', 'description': '"any", "query", "body", or "header"'},
                  'field': {'type': 'string', 'description': 'Field or parameter name (e.g. "isUserType", "userid", "Authorization")'},
                  'operator': {'type': 'string', 'description': '"=", "!=", "contains", ">", "<", ">=", "<=", "regex"'},
                  'value': {'type': 'string', 'description': 'Expected value'},
                },
              },
            },
            'matchQueryParams': {'type': 'object', 'description': 'Optional key-value query parameters to match'},
            'matchHeaders': {'type': 'object', 'description': 'Optional key-value headers to match'},
            'matchBody': {'type': 'string', 'description': 'Optional substring to match in request body'},
            'customVariables': {'type': 'object', 'description': 'Key-value map of custom variables available in responseBody via {{key}}'},
            'statusCode': {'type': 'integer', 'description': 'HTTP status code e.g. 200, 201, 400, 404, 500 (default: 200)'},
            'responseStatusReason': {'type': 'string', 'description': 'HTTP status reason phrase (default: "OK")'},
            'responseHeaders': {'type': 'object', 'description': 'Custom response headers key-value map'},
            'responseBody': {'type': 'string', 'description': 'Response payload JSON or text. Supports template variables like {{username}}, {{timestamp}}, {{query.param}}, etc.'},
            'delayMs': {'type': 'integer', 'description': 'Simulated response delay in milliseconds'},
            'description': {'type': 'string', 'description': 'Documentation or notes for this rule'},
            'isEnabled': {'type': 'boolean', 'description': 'Whether this rule is immediately active (default: true)'},
          },
        },
      ),
      const McpToolDefinition(
        name: 'apilab_update_mock',
        description: 'Update an existing mock rule by ID in ApiLab.',
        inputSchema: {
          'type': 'object',
          'required': ['id'],
          'properties': {
            'id': {'type': 'string', 'description': 'ID of the mock rule to update'},
            'name': {'type': 'string', 'description': 'Updated name'},
            'projectName': {'type': 'string', 'description': 'Updated project name'},
            'urlPattern': {'type': 'string', 'description': 'Updated URL pattern'},
            'matchMethod': {'type': 'string', 'description': 'Updated HTTP method'},
            'isRegex': {'type': 'boolean', 'description': 'Whether urlPattern is regex'},
            'conditionLogic': {'type': 'string', 'description': '"AND" or "OR"'},
            'conditions': {'type': 'array', 'description': 'Updated conditions list'},
            'customVariables': {'type': 'object', 'description': 'Updated custom variables'},
            'statusCode': {'type': 'integer', 'description': 'Updated status code'},
            'responseHeaders': {'type': 'object', 'description': 'Updated response headers'},
            'responseBody': {'type': 'string', 'description': 'Updated response payload'},
            'delayMs': {'type': 'integer', 'description': 'Updated delay in ms'},
            'description': {'type': 'string', 'description': 'Updated description'},
            'isEnabled': {'type': 'boolean', 'description': 'Enable or disable rule'},
          },
        },
      ),
      const McpToolDefinition(
        name: 'apilab_delete_mock',
        description: 'Delete a mock rule by ID from ApiLab.',
        inputSchema: {
          'type': 'object',
          'required': ['id'],
          'properties': {
            'id': {'type': 'string', 'description': 'Mock rule ID to delete'},
          },
        },
      ),
      const McpToolDefinition(
        name: 'apilab_toggle_mock',
        description: 'Enable or disable a mock rule by ID in ApiLab.',
        inputSchema: {
          'type': 'object',
          'required': ['id'],
          'properties': {
            'id': {'type': 'string', 'description': 'Mock rule ID'},
            'isEnabled': {'type': 'boolean', 'description': 'Target enabled state (optional, toggles if omitted)'},
          },
        },
      ),
      const McpToolDefinition(
        name: 'apilab_generate_fake_response',
        description: 'Generate realistic synthetic mock data using ApiLab AI generation engine based on an endpoint URL, status code, and description.',
        inputSchema: {
          'type': 'object',
          'required': ['endpointUrl', 'method'],
          'properties': {
            'endpointUrl': {'type': 'string', 'description': 'API endpoint URL'},
            'method': {'type': 'string', 'description': 'GET, POST, etc.'},
            'statusCode': {'type': 'integer', 'description': 'Desired status code (default 200)'},
            'description': {'type': 'string', 'description': 'Description of the data needs'},
          },
        },
      ),
      const McpToolDefinition(
        name: 'apilab_send_request',
        description: 'Send and test an HTTP request directly through ApiLab client and inspect its response, latency, and headers.',
        inputSchema: {
          'type': 'object',
          'required': ['url', 'method'],
          'properties': {
            'url': {'type': 'string', 'description': 'Target URL to call'},
            'method': {'type': 'string', 'description': 'GET, POST, PUT, DELETE, etc.'},
            'headers': {'type': 'object', 'description': 'Key-value map of HTTP headers'},
            'body': {'type': 'string', 'description': 'Request payload string'},
          },
        },
      ),
      const McpToolDefinition(
        name: 'apilab_list_mocks',
        description: 'List all currently defined mock rules and their active status.',
        inputSchema: {'type': 'object', 'properties': {}},
      ),
    ];
  }

  Future<String> _executeTool(String? name, Map arguments) async {
    const uuid = Uuid();

    switch (name) {
      case 'apilab_get_traffic':
        final limit = arguments['limit'] as int? ?? 50;
        final urlFilter = (arguments['urlFilter'] as String?)?.toLowerCase();
        final methodFilter = (arguments['methodFilter'] as String?)?.toUpperCase();
        final statusFilter = (arguments['statusFilter'] as String?)?.toLowerCase();
        final mockedOnly = arguments['mockedOnly'] as bool? ?? false;
        final searchQuery = (arguments['searchQuery'] as String?)?.toLowerCase();

        var items = _trafficRepository.currentTraffic;
        if (mockedOnly) {
          items = items.where((t) => t.isMocked).toList();
        }
        if (urlFilter != null && urlFilter.isNotEmpty) {
          items = items.where((t) => t.request.url.toLowerCase().contains(urlFilter)).toList();
        }
        if (methodFilter != null && methodFilter.isNotEmpty && methodFilter != 'ALL') {
          items = items.where((t) => t.request.method.toUpperCase() == methodFilter).toList();
        }
        if (statusFilter != null && statusFilter.isNotEmpty) {
          items = items.where((t) => t.status.name.toLowerCase() == statusFilter).toList();
        }
        if (searchQuery != null && searchQuery.isNotEmpty) {
          items = items.where((t) {
            final urlMatch = t.request.url.toLowerCase().contains(searchQuery);
            final reqBodyMatch = t.request.body.toLowerCase().contains(searchQuery);
            final resBodyMatch = (t.response?.body ?? '').toLowerCase().contains(searchQuery);
            return urlMatch || reqBodyMatch || resBodyMatch;
          }).toList();
        }
        items = items.take(limit).toList();

        final trafficList = items.map((t) => {
          'id': t.id,
          'method': t.request.method,
          'url': t.request.url,
          'path': t.request.path,
          'queryParams': t.request.resolvedQueryParams,
          'status': t.status.name,
          'isMocked': t.isMocked,
          'mockRuleId': t.mockRuleId,
          'statusCode': t.response?.statusCode,
          'durationMs': t.response?.durationMs,
          'timestamp': t.request.timestamp.toIso8601String(),
          'clientIp': t.request.clientIp,
          'requestBody': t.request.body,
          'responseBody': t.response?.body,
        }).toList();

        return jsonEncode({'count': trafficList.length, 'traffic': trafficList});

      case 'apilab_get_traffic_detail':
        final id = arguments['id']?.toString() ?? '';
        final item = _trafficRepository.getById(id);
        if (item == null) {
          return jsonEncode({'error': 'Traffic item with id $id not found'});
        }
        return jsonEncode({'traffic': item.toJson()});

      case 'apilab_clear_traffic':
        _trafficRepository.clearTraffic();
        return jsonEncode({'success': true, 'message': 'All intercepted traffic cleared'});

      case 'apilab_list_projects':
        final projects = _mockRuleRepository.currentProjects;
        final rules = _mockRuleRepository.currentRules;
        final projectList = projects.map((p) {
          final pRules = rules.where((r) => r.projectName == p || r.projectId == p).toList();
          return {
            'name': p,
            'totalRules': pRules.length,
            'enabledRules': pRules.where((r) => r.isEnabled).length,
            'rules': pRules.map((r) => {
              'id': r.id,
              'name': r.name,
              'matchMethod': r.matchMethod,
              'urlPattern': r.urlPattern,
              'isEnabled': r.isEnabled,
            }).toList(),
          };
        }).toList();
        return jsonEncode({'count': projectList.length, 'projects': projectList});

      case 'apilab_create_project':
        final projectName = (arguments['projectName'] ?? arguments['name'])?.toString().trim() ?? '';
        if (projectName.isEmpty) {
          return jsonEncode({'error': 'projectName is required'});
        }
        await _mockRuleRepository.createProject(projectName);
        return jsonEncode({
          'success': true,
          'projectName': projectName,
          'message': 'Project "$projectName" created successfully',
        });

      case 'apilab_list_rules':
      case 'apilab_list_mocks':
        final projectName = arguments['projectName']?.toString();
        final urlFilter = arguments['urlFilter']?.toString().toLowerCase();
        final methodFilter = arguments['methodFilter']?.toString().toUpperCase();
        final isEnabledOnly = arguments['isEnabledOnly'] as bool? ?? false;

        var rules = _mockRuleRepository.currentRules;
        if (projectName != null && projectName.isNotEmpty) {
          rules = rules.where((r) => r.projectName == projectName || r.projectId == projectName).toList();
        }
        if (urlFilter != null && urlFilter.isNotEmpty) {
          rules = rules.where((r) => r.urlPattern.toLowerCase().contains(urlFilter)).toList();
        }
        if (methodFilter != null && methodFilter.isNotEmpty && methodFilter != 'ALL') {
          rules = rules.where((r) => r.matchMethod.toUpperCase() == methodFilter || r.matchMethod == 'ALL').toList();
        }
        if (isEnabledOnly) {
          rules = rules.where((r) => r.isEnabled).toList();
        }
        return jsonEncode({'count': rules.length, 'rules': rules.map((r) => r.toJson()).toList()});

      case 'apilab_get_rule_detail':
        final id = arguments['id']?.toString() ?? '';
        final rule = _mockRuleRepository.currentRules.firstWhere(
          (r) => r.id == id,
          orElse: () => const MockRule(id: '', name: '', urlPattern: '', responseBody: ''),
        );
        if (rule.id.isEmpty) {
          return jsonEncode({'error': 'Mock rule with id $id not found'});
        }
        return jsonEncode({'rule': rule.toJson()});

      case 'apilab_create_mock':
        final id = arguments['id'] as String? ?? uuid.v4();
        final name = arguments['name'] as String? ?? 'Agent Created Mock';
        final projectName = arguments['projectName'] as String? ?? 'Default Project';
        final urlPattern = arguments['urlPattern'] as String? ?? '*';
        final matchMethod = (arguments['matchMethod'] as String? ?? 'ALL').toUpperCase();
        final isRegex = arguments['isRegex'] as bool? ?? false;
        final conditionLogic = (arguments['conditionLogic'] as String? ?? 'AND').toUpperCase();

        final rawConditions = (arguments['conditions'] as List?) ?? [];
        final conditions = rawConditions.map((c) {
          final cMap = Map<String, dynamic>.from(c as Map);
          return MockCondition(
            id: cMap['id'] as String? ?? uuid.v4(),
            source: _parseConditionSource(cMap['source']),
            field: cMap['field']?.toString() ?? '',
            operator: _parseConditionOperator(cMap['operator']),
            value: cMap['value']?.toString() ?? '',
            isEnabled: cMap['isEnabled'] as bool? ?? true,
          );
        }).toList();

        final matchQueryParams = Map<String, String>.from(arguments['matchQueryParams'] as Map? ?? {});
        final matchHeaders = Map<String, String>.from(arguments['matchHeaders'] as Map? ?? {});
        final matchBody = arguments['matchBody']?.toString() ?? '';
        final customVariables = Map<String, String>.from(arguments['customVariables'] as Map? ?? {});

        final statusCode = (arguments['statusCode'] ?? arguments['responseStatusCode']) as int? ?? 200;
        final statusReason = arguments['responseStatusReason'] as String? ?? 'OK';
        final responseHeaders = arguments['responseHeaders'] != null
            ? Map<String, String>.from(arguments['responseHeaders'] as Map)
            : <String, String>{
                'content-type': 'application/json; charset=utf-8',
                'x-mocked-by': 'ApiLab',
              };
        final responseBody = arguments['responseBody']?.toString() ?? '{}';
        final delayMs = (arguments['delayMs'] ?? arguments['responseDelayMs']) as int? ?? 0;
        final description = arguments['description'] as String? ?? 'Created automatically via MCP Agent';
        final isEnabled = arguments['isEnabled'] as bool? ?? true;

        final rule = MockRule(
          id: id,
          name: name,
          projectId: projectName,
          projectName: projectName,
          isEnabled: isEnabled,
          matchMethod: matchMethod,
          urlPattern: urlPattern,
          isRegex: isRegex,
          conditionLogic: conditionLogic,
          conditions: conditions,
          matchQueryParams: matchQueryParams,
          matchHeaders: matchHeaders,
          matchBody: matchBody,
          customVariables: customVariables,
          responseStatusCode: statusCode,
          responseStatusReason: statusReason,
          responseHeaders: responseHeaders,
          responseBody: responseBody,
          responseDelayMs: delayMs,
          description: description,
          isAiGenerated: true,
        );

        await _mockRuleRepository.addRule(rule);
        return jsonEncode({
          'success': true,
          'ruleId': rule.id,
          'name': rule.name,
          'projectName': rule.projectName,
          'urlPattern': rule.urlPattern,
          'message': 'Mock rule "${rule.name}" created and active for ${rule.urlPattern}',
        });

      case 'apilab_update_mock':
        final id = arguments['id']?.toString() ?? '';
        final existing = _mockRuleRepository.currentRules.firstWhere(
          (r) => r.id == id,
          orElse: () => const MockRule(id: '', name: '', urlPattern: '', responseBody: ''),
        );
        if (existing.id.isEmpty) {
          return jsonEncode({'error': 'Mock rule with id $id not found'});
        }

        List<MockCondition>? updatedConditions;
        if (arguments['conditions'] != null) {
          final rawConditions = arguments['conditions'] as List;
          updatedConditions = rawConditions.map((c) {
            final cMap = Map<String, dynamic>.from(c as Map);
            return MockCondition(
              id: cMap['id'] as String? ?? uuid.v4(),
              source: _parseConditionSource(cMap['source']),
              field: cMap['field']?.toString() ?? '',
              operator: _parseConditionOperator(cMap['operator']),
              value: cMap['value']?.toString() ?? '',
              isEnabled: cMap['isEnabled'] as bool? ?? true,
            );
          }).toList();
        }

        final updated = existing.copyWith(
          name: arguments['name'] as String?,
          projectName: arguments['projectName'] as String?,
          projectId: arguments['projectName'] as String?,
          urlPattern: arguments['urlPattern'] as String?,
          matchMethod: (arguments['matchMethod'] as String?)?.toUpperCase(),
          isRegex: arguments['isRegex'] as bool?,
          conditionLogic: (arguments['conditionLogic'] as String?)?.toUpperCase(),
          conditions: updatedConditions,
          customVariables: arguments['customVariables'] != null
              ? Map<String, String>.from(arguments['customVariables'] as Map)
              : null,
          responseStatusCode: (arguments['statusCode'] ?? arguments['responseStatusCode']) as int?,
          responseStatusReason: arguments['responseStatusReason'] as String?,
          responseHeaders: arguments['responseHeaders'] != null
              ? Map<String, String>.from(arguments['responseHeaders'] as Map)
              : null,
          responseBody: arguments['responseBody'] as String?,
          responseDelayMs: (arguments['delayMs'] ?? arguments['responseDelayMs']) as int?,
          description: arguments['description'] as String?,
          isEnabled: arguments['isEnabled'] as bool?,
        );

        await _mockRuleRepository.updateRule(updated);
        return jsonEncode({
          'success': true,
          'ruleId': updated.id,
          'message': 'Mock rule "${updated.name}" updated successfully',
        });

      case 'apilab_delete_mock':
        final id = arguments['id']?.toString() ?? '';
        await _mockRuleRepository.deleteRule(id);
        return jsonEncode({
          'success': true,
          'ruleId': id,
          'message': 'Mock rule $id deleted successfully',
        });

      case 'apilab_toggle_mock':
        final id = arguments['id']?.toString() ?? '';
        final rule = _mockRuleRepository.currentRules.firstWhere(
          (r) => r.id == id,
          orElse: () => const MockRule(id: '', name: '', urlPattern: '', responseBody: ''),
        );
        if (rule.id.isEmpty) {
          return jsonEncode({'error': 'Mock rule with id $id not found'});
        }
        final targetState = arguments['isEnabled'] as bool? ?? !rule.isEnabled;
        await _mockRuleRepository.toggleRule(id, targetState);
        return jsonEncode({
          'success': true,
          'ruleId': id,
          'isEnabled': targetState,
          'message': 'Mock rule "$id" ${targetState ? 'enabled' : 'disabled'}',
        });

      case 'apilab_generate_fake_response':
        final url = arguments['endpointUrl'] as String? ?? '';
        final method = arguments['method'] as String? ?? 'GET';
        final status = arguments['statusCode'] as int? ?? 200;
        final desc = arguments['description'] as String? ?? '';

        final generated = await _generateMockUseCase.generate(
          config: _settingsRepository.getAiConfig(),
          endpointUrl: url,
          method: method,
          statusCode: status,
          description: desc,
        );
        return generated;

      case 'apilab_send_request':
        final url = arguments['url'] as String? ?? '';
        final method = arguments['method'] as String? ?? 'GET';
        final rawHeaders = (arguments['headers'] as Map?) ?? {};
        final body = arguments['body'] as String? ?? '';

        final headersList = rawHeaders.entries
            .map((e) => KeyValuePair(key: e.key.toString(), value: e.value.toString()))
            .toList();

        final reqModel = ApiRequestModel(
          id: uuid.v4(),
          name: 'MCP Sent Request',
          method: method,
          url: url,
          headers: headersList,
          bodyType: body.isNotEmpty ? 'json' : 'none',
          bodyContent: body,
          updatedAt: DateTime.now(),
        );

        final res = await _replayRequestUseCase.execute(reqModel);
        return jsonEncode({
          'statusCode': res.statusCode,
          'statusReason': res.statusReason,
          'durationMs': res.durationMs,
          'headers': res.headers,
          'body': res.body,
        });

      default:
        throw Exception('Unknown tool: $name');
    }
  }

  static ConditionOperator _parseConditionOperator(dynamic op) {
    final s = op?.toString().toLowerCase().trim() ?? '';
    switch (s) {
      case '=':
      case '==':
      case 'equals':
        return ConditionOperator.equals;
      case '!=':
      case 'notequals':
      case 'not_equals':
        return ConditionOperator.notEquals;
      case 'contain':
      case 'contains':
        return ConditionOperator.contains;
      case '>':
      case 'greaterthan':
      case 'greater_than':
        return ConditionOperator.greaterThan;
      case '<':
      case 'lessthan':
      case 'less_than':
        return ConditionOperator.lessThan;
      case '>=':
      case 'greaterthanorequal':
      case 'greater_than_or_equal':
        return ConditionOperator.greaterThanOrEqual;
      case '<=':
      case 'lessthanorequal':
      case 'less_than_or_equal':
        return ConditionOperator.lessThanOrEqual;
      case 'regex':
        return ConditionOperator.regex;
      default:
        return ConditionOperator.equals;
    }
  }

  static ConditionSource _parseConditionSource(dynamic src) {
    final s = src?.toString().toLowerCase().trim() ?? '';
    switch (s) {
      case 'query':
      case 'param':
      case 'queryparam':
        return ConditionSource.query;
      case 'header':
      case 'headers':
        return ConditionSource.header;
      case 'body':
      case 'json':
        return ConditionSource.body;
      case 'any':
      default:
        return ConditionSource.any;
    }
  }

  void _log(String direction, String payload) {
    const uuid = Uuid();
    final entry = McpLogEntry(
      id: uuid.v4(),
      timestamp: DateTime.now(),
      direction: direction,
      method: direction == 'IN' ? 'REQUEST' : 'RESPONSE',
      payload: payload,
    );
    _logs.insert(0, entry);
    if (_logs.length > 200) {
      _logs.removeLast();
    }
    _logsController.add(List.unmodifiable(_logs));
  }

  void dispose() {
    stop();
    _logsController.close();
  }
}
