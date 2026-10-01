class McpServerConfig {
  final bool isEnabled;
  final String host;
  final int port;

  const McpServerConfig({
    this.isEnabled = true,
    this.host = '127.0.0.1',
    this.port = 8765,
  });

  String get sseUrl => 'http://$host:$port/sse';
  String get messagesUrl => 'http://$host:$port/messages';

  McpServerConfig copyWith({
    bool? isEnabled,
    String? host,
    int? port,
  }) {
    return McpServerConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      host: host ?? this.host,
      port: port ?? this.port,
    );
  }

  Map<String, dynamic> toJson() => {
    'isEnabled': isEnabled,
    'host': host,
    'port': port,
  };

  factory McpServerConfig.fromJson(Map<String, dynamic> json) => McpServerConfig(
    isEnabled: json['isEnabled'] as bool? ?? true,
    host: json['host'] as String? ?? '127.0.0.1',
    port: json['port'] as int? ?? 8765,
  );
}

class McpToolDefinition {
  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;

  const McpToolDefinition({
    required this.name,
    required this.description,
    required this.inputSchema,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'inputSchema': inputSchema,
  };
}

class McpLogEntry {
  final String id;
  final DateTime timestamp;
  final String direction; // 'IN' or 'OUT'
  final String method;
  final String payload;

  const McpLogEntry({
    required this.id,
    required this.timestamp,
    required this.direction,
    required this.method,
    required this.payload,
  });
}

enum AiProviderType {
  heuristic,
  openAiCompatible,
  ollama,
  lmStudio,
  gemini,
}

class AiConfig {
  final AiProviderType providerType;
  final String baseUrl;
  final String apiKey;
  final String modelName;
  final String customPrompt;

  const AiConfig({
    this.providerType = AiProviderType.heuristic,
    this.baseUrl = 'http://localhost:11434/v1',
    this.apiKey = '',
    this.modelName = 'llama3',
    this.customPrompt = '',
  });

  AiConfig copyWith({
    AiProviderType? providerType,
    String? baseUrl,
    String? apiKey,
    String? modelName,
    String? customPrompt,
  }) {
    return AiConfig(
      providerType: providerType ?? this.providerType,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      modelName: modelName ?? this.modelName,
      customPrompt: customPrompt ?? this.customPrompt,
    );
  }

  Map<String, dynamic> toJson() => {
    'providerType': providerType.name,
    'baseUrl': baseUrl,
    'apiKey': apiKey,
    'modelName': modelName,
    'customPrompt': customPrompt,
  };

  factory AiConfig.fromJson(Map<String, dynamic> json) => AiConfig(
    providerType: AiProviderType.values.firstWhere(
      (e) => e.name == json['providerType'],
      orElse: () => AiProviderType.heuristic,
    ),
    baseUrl: json['baseUrl'] as String? ?? 'http://localhost:11434/v1',
    apiKey: json['apiKey'] as String? ?? '',
    modelName: json['modelName'] as String? ?? 'llama3',
    customPrompt: json['customPrompt'] as String? ?? '',
  );
}

class ProxyConfig {
  final int port;
  final String host;
  final bool enableSslMitm;
  final bool isInterceptActive;

  const ProxyConfig({
    this.port = 8888,
    this.host = '127.0.0.1',
    this.enableSslMitm = true,
    this.isInterceptActive = true,
  });

  ProxyConfig copyWith({
    int? port,
    String? host,
    bool? enableSslMitm,
    bool? isInterceptActive,
  }) {
    return ProxyConfig(
      port: port ?? this.port,
      host: host ?? this.host,
      enableSslMitm: enableSslMitm ?? this.enableSslMitm,
      isInterceptActive: isInterceptActive ?? this.isInterceptActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'port': port,
    'host': host,
    'enableSslMitm': enableSslMitm,
    'isInterceptActive': isInterceptActive,
  };

  factory ProxyConfig.fromJson(Map<String, dynamic> json) => ProxyConfig(
    port: json['port'] as int? ?? 8888,
    host: json['host'] as String? ?? '127.0.0.1',
    enableSslMitm: json['enableSslMitm'] as bool? ?? true,
    isInterceptActive: json['isInterceptActive'] as bool? ?? true,
  );
}
