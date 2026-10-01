import '../../domain/models/mcp_and_ai.dart';
import '../../domain/repositories/repositories.dart';

class SettingsRepositoryImpl implements ISettingsRepository {
  ProxyConfig _proxyConfig = const ProxyConfig(
    port: 8888,
    host: '127.0.0.1',
    enableSslMitm: true,
    isInterceptActive: true,
  );

  McpServerConfig _mcpConfig = const McpServerConfig(
    isEnabled: true,
    host: '127.0.0.1',
    port: 8765,
  );

  AiConfig _aiConfig = const AiConfig(
    providerType: AiProviderType.heuristic,
    baseUrl: 'http://localhost:11434/v1',
    apiKey: '',
    modelName: 'llama3',
  );

  @override
  ProxyConfig getProxyConfig() => _proxyConfig;

  @override
  Future<void> saveProxyConfig(ProxyConfig config) async {
    _proxyConfig = config;
  }

  @override
  McpServerConfig getMcpConfig() => _mcpConfig;

  @override
  Future<void> saveMcpConfig(McpServerConfig config) async {
    _mcpConfig = config;
  }

  @override
  AiConfig getAiConfig() => _aiConfig;

  @override
  Future<void> saveAiConfig(AiConfig config) async {
    _aiConfig = config;
  }
}
