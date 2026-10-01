import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../domain/models/mcp_and_ai.dart';
import '../../../../domain/repositories/repositories.dart';
import '../../../../domain/use_cases/generate_mock_response_use_case.dart';
import '../../../../infrastructure/mcp/mcp_server.dart';

class McpHubViewModel extends ChangeNotifier {
  final McpServer _mcpServer;
  final ISettingsRepository _settingsRepository;
  final GenerateMockResponseUseCase _generateMockUseCase;

  StreamSubscription<List<McpLogEntry>>? _logsSubscription;
  List<McpLogEntry> _logs = [];
  late AiConfig _aiConfig;
  late McpServerConfig _mcpConfig;

  String _testPrompt = 'Generate 3 ecommerce products with title, price, discount, and ratings';
  String _testEndpoint = '/api/v1/products';
  String _testMethod = 'GET';
  int _testStatusCode = 200;
  String _testOutput = '';
  bool _isTestingPrompt = false;

  McpHubViewModel({
    required this._mcpServer,
    required this._settingsRepository,
    required this._generateMockUseCase,
  }) {
    _init();
  }

  void _init() {
    _aiConfig = _settingsRepository.getAiConfig();
    _mcpConfig = _settingsRepository.getMcpConfig();
    _logs = _mcpServer.logs;

    _logsSubscription = _mcpServer.logsStream.listen((logs) {
      _logs = logs;
      notifyListeners();
    });
  }

  bool get isServerRunning => _mcpServer.isRunning;
  int get activeClients => _mcpServer.activeClients;
  List<McpLogEntry> get logs => _logs;
  AiConfig get aiConfig => _aiConfig;
  McpServerConfig get mcpConfig => _mcpConfig;

  String get testPrompt => _testPrompt;
  String get testEndpoint => _testEndpoint;
  String get testMethod => _testMethod;
  int get testStatusCode => _testStatusCode;
  String get testOutput => _testOutput;
  bool get isTestingPrompt => _isTestingPrompt;

  void updateTestPrompt(String val) {
    _testPrompt = val;
    notifyListeners();
  }

  void updateTestEndpoint(String val) {
    _testEndpoint = val;
    notifyListeners();
  }

  void updateTestMethod(String val) {
    _testMethod = val;
    notifyListeners();
  }

  void updateTestStatusCode(int val) {
    _testStatusCode = val;
    notifyListeners();
  }

  Future<void> toggleMcpServer() async {
    if (_mcpServer.isRunning) {
      await _mcpServer.stop();
    } else {
      await _mcpServer.start();
    }
    notifyListeners();
  }

  Future<void> updateAiConfig({
    AiProviderType? providerType,
    String? baseUrl,
    String? apiKey,
    String? modelName,
  }) async {
    _aiConfig = _aiConfig.copyWith(
      providerType: providerType,
      baseUrl: baseUrl,
      apiKey: apiKey,
      modelName: modelName,
    );
    await _settingsRepository.saveAiConfig(_aiConfig);
    notifyListeners();
  }

  Future<void> runTestGeneration() async {
    _isTestingPrompt = true;
    _testOutput = 'Generating mock payload with ${_aiConfig.providerType.name}...';
    notifyListeners();

    try {
      final res = await _generateMockUseCase.generate(
        config: _aiConfig,
        endpointUrl: _testEndpoint,
        method: _testMethod,
        statusCode: _testStatusCode,
        description: _testPrompt,
      );

      try {
        final decoded = jsonDecode(res);
        const encoder = JsonEncoder.withIndent('  ');
        _testOutput = encoder.convert(decoded);
      } catch (_) {
        _testOutput = res;
      }
    } catch (e) {
      _testOutput = 'Error during generation: $e';
    } finally {
      _isTestingPrompt = false;
      notifyListeners();
    }
  }

  String get lanIp => _mcpServer.detectedLanIp;
  String get lanSseUrl => 'http://$lanIp:${_mcpConfig.port}/sse';
  String get localSseUrl => 'http://127.0.0.1:${_mcpConfig.port}/sse';

  String getCodexCliCommand({bool useLan = false}) {
    final url = useLan ? lanSseUrl : localSseUrl;
    return 'codex mcp add apilab --url $url';
  }

  String getClaudeDesktopConfigSnippet({bool useLan = false}) {
    final url = useLan ? lanSseUrl : localSseUrl;
    return '''{
  "mcpServers": {
    "apilab": {
      "url": "$url"
    }
  }
}''';
  }

  @override
  void dispose() {
    _logsSubscription?.cancel();
    super.dispose();
  }
}
