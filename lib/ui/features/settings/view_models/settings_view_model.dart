import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../domain/models/mcp_and_ai.dart';
import '../../../../domain/repositories/repositories.dart';
import '../../../../infrastructure/proxy/proxy_server.dart';
import '../../../../infrastructure/proxy/ssl_certificate_manager.dart';

class SettingsViewModel extends ChangeNotifier {
  final ISettingsRepository settingsRepository;
  final ProxyServer proxyServer;

  late ProxyConfig _proxyConfig;
  late McpServerConfig _mcpConfig;
  String? _exportedCertPath;
  String _statusMessage = '';

  SettingsViewModel({
    required this.settingsRepository,
    required this.proxyServer,
  }) {
    _proxyConfig = settingsRepository.getProxyConfig();
    _mcpConfig = settingsRepository.getMcpConfig();
  }

  ProxyConfig get proxyConfig => _proxyConfig;
  McpServerConfig get mcpConfig => _mcpConfig;
  String get lanIp => proxyServer.detectedLanIp;
  String? get exportedCertPath => _exportedCertPath;
  String get statusMessage => _statusMessage;

  Future<void> updateProxyPort(int port) async {
    _proxyConfig = _proxyConfig.copyWith(port: port);
    await settingsRepository.saveProxyConfig(_proxyConfig);
    proxyServer.updateConfig(_proxyConfig);
    notifyListeners();
  }

  Future<void> updateProxyHost(String host) async {
    _proxyConfig = _proxyConfig.copyWith(host: host);
    await settingsRepository.saveProxyConfig(_proxyConfig);
    proxyServer.updateConfig(_proxyConfig);
    notifyListeners();
  }

  Future<void> toggleSslMitm(bool enabled) async {
    _proxyConfig = _proxyConfig.copyWith(enableSslMitm: enabled);
    await settingsRepository.saveProxyConfig(_proxyConfig);
    proxyServer.updateConfig(_proxyConfig);
    notifyListeners();
  }

  Future<void> updateMcpPort(int port) async {
    _mcpConfig = _mcpConfig.copyWith(port: port);
    await settingsRepository.saveMcpConfig(_mcpConfig);
    notifyListeners();
  }

  Future<String> exportCaCertificateToFolder(String folderPath) async {
    try {
      final file = File('$folderPath/apilab_ca.crt');
      await file.writeAsString(SslCertificateManager.caCertificatePem);
      _exportedCertPath = file.path;
      _statusMessage = 'CA Certificate exported successfully to ${file.path}';
      notifyListeners();
      return file.path;
    } catch (e) {
      _statusMessage = 'Export failed: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> exportCaCertificate() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      await exportCaCertificateToFolder(dir.path);
    } catch (e) {
      _statusMessage = 'Export failed: $e';
      notifyListeners();
    }
  }
}
