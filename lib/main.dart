import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Domain
import 'domain/repositories/repositories.dart';
import 'domain/use_cases/generate_mock_response_use_case.dart';
import 'domain/use_cases/intercept_request_use_case.dart';
import 'domain/use_cases/replay_request_use_case.dart';

// Data
import 'data/repositories/collection_repository_impl.dart';
import 'data/repositories/mock_rule_repository_impl.dart';
import 'data/repositories/settings_repository_impl.dart';
import 'data/repositories/traffic_repository_impl.dart';

// Infrastructure
import 'infrastructure/mcp/mcp_server.dart';
import 'infrastructure/proxy/proxy_server.dart';

// Presentation
import 'ui/core/theme/app_theme.dart';
import 'ui/features/composer/view_models/composer_view_model.dart';
import 'ui/features/interceptor/view_models/interceptor_view_model.dart';
import 'ui/features/mcp/view_models/mcp_hub_view_model.dart';
import 'ui/features/mocks/view_models/mocks_view_model.dart';
import 'ui/features/settings/view_models/settings_view_model.dart';
import 'ui/features/shell/desktop_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isMacOS) {
    try {
      await FilePickerPlatform.instance.skipEntitlementsChecks();
    } catch (e) {
      debugPrint('FilePicker skipEntitlementsChecks note: $e');
    }
  }

  // 1. Initialize Repositories (Data Layer)
  final trafficRepository = TrafficRepositoryImpl();
  final mockRuleRepository = MockRuleRepositoryImpl();
  final collectionRepository = CollectionRepositoryImpl();
  final settingsRepository = SettingsRepositoryImpl();

  // 2. Initialize Use Cases (Domain Layer)
  final interceptUseCase = InterceptRequestUseCase(
    mockRuleRepository: mockRuleRepository,
    trafficRepository: trafficRepository,
  );
  final replayRequestUseCase = ReplayRequestUseCase();
  final generateMockUseCase = GenerateMockResponseUseCase();

  // 3. Initialize Infrastructure Services
  final proxyServer = ProxyServer(
    interceptUseCase: interceptUseCase,
    config: settingsRepository.getProxyConfig(),
  );

  final mcpServer = McpServer(
    trafficRepository: trafficRepository,
    mockRuleRepository: mockRuleRepository,
    replayRequestUseCase: replayRequestUseCase,
    generateMockUseCase: generateMockUseCase,
    settingsRepository: settingsRepository,
  );

  // Auto-start Proxy and MCP servers in background for desktop experience
  try {
    await proxyServer.start();
    await mcpServer.start();
  } catch (e) {
    debugPrint('Service startup note: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        // Repositories & Services injection
        Provider<ITrafficRepository>.value(value: trafficRepository),
        Provider<IMockRuleRepository>.value(value: mockRuleRepository),
        Provider<ICollectionRepository>.value(value: collectionRepository),
        Provider<ISettingsRepository>.value(value: settingsRepository),
        Provider<ProxyServer>.value(value: proxyServer),
        Provider<McpServer>.value(value: mcpServer),

        // ViewModels (Presentation Layer)
        ChangeNotifierProvider(
          create: (_) => InterceptorViewModel(
            trafficRepository: trafficRepository,
            proxyServer: proxyServer,
            mockRuleRepository: mockRuleRepository,
            replayRequestUseCase: replayRequestUseCase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ComposerViewModel(
            replayRequestUseCase: replayRequestUseCase,
            collectionRepository: collectionRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => MocksViewModel(
            mockRuleRepository: mockRuleRepository,
            generateMockUseCase: generateMockUseCase,
            settingsRepository: settingsRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => McpHubViewModel(
            mcpServer: mcpServer,
            settingsRepository: settingsRepository,
            generateMockUseCase: generateMockUseCase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsViewModel(
            settingsRepository: settingsRepository,
            proxyServer: proxyServer,
          ),
        ),
      ],
      child: const ApiLabApp(),
    ),
  );
}

class ApiLabApp extends StatelessWidget {
  const ApiLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ApiLab - Desktop API Testing, Mocking & MCP Suite',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const DesktopShell(),
    );
  }
}
