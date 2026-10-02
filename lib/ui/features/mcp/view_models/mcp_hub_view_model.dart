import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../domain/models/mcp_and_ai.dart';
import '../../../../domain/repositories/repositories.dart';
import '../../../../infrastructure/mcp/mcp_server.dart';

class McpHubViewModel extends ChangeNotifier {
  final McpServer _mcpServer;
  final ISettingsRepository _settingsRepository;

  StreamSubscription<List<McpLogEntry>>? _logsSubscription;
  List<McpLogEntry> _logs = [];
  late McpServerConfig _mcpConfig;

  McpHubViewModel({
    required this._mcpServer,
    required this._settingsRepository,
  }) {
    _init();
  }

  void _init() {
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
  McpServerConfig get mcpConfig => _mcpConfig;
  List<McpToolDefinition> get availableTools => _mcpServer.availableTools;

  Future<void> toggleMcpServer() async {
    if (_mcpServer.isRunning) {
      await _mcpServer.stop();
    } else {
      await _mcpServer.start();
    }
    notifyListeners();
  }

  void clearLogs() {
    _mcpServer.clearLogs();
    notifyListeners();
  }

  int get boundPort => _mcpServer.boundPort;
  String get lanIp => _mcpServer.detectedLanIp;
  String get lanSseUrl => 'http://$lanIp:$boundPort/sse';
  String get localSseUrl => 'http://127.0.0.1:$boundPort/sse';

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

  String getClaudeDesktopWindowsSnippet({bool useLan = false}) {
    final url = useLan ? lanSseUrl : localSseUrl;
    return '''{
  "mcpServers": {
    "apilab": {
      "command": "cmd.exe",
      "args": ["/c", "npx", "-y", "mcp-remote", "$url"]
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
