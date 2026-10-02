import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../infrastructure/proxy/ssl_certificate_manager.dart';
import '../../../core/theme/app_theme.dart';
import '../view_models/settings_view_model.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late TextEditingController _proxyPortController;
  late TextEditingController _mcpPortController;

  @override
  void initState() {
    super.initState();
    final vm = context.read<SettingsViewModel>();
    _proxyPortController = TextEditingController(text: vm.proxyConfig.port.toString());
    _mcpPortController = TextEditingController(text: vm.mcpConfig.port.toString());
  }

  @override
  void dispose() {
    _proxyPortController.dispose();
    _mcpPortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Settings & Configuration', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Configure ApiLab network proxy, MCP integration, and SSL/TLS certificates', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),

          // Proxy Server Configuration Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.router_outlined, color: AppColors.primaryHover, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'HTTP / HTTPS Proxy Server',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      SizedBox(
                        width: 180,
                        child: TextField(
                          controller: _proxyPortController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Proxy Port', hintText: '8888'),
                          onSubmitted: (v) {
                            final port = int.tryParse(v);
                            if (port != null) vm.updateProxyPort(port);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          final port = int.tryParse(_proxyPortController.text);
                          if (port != null) {
                            vm.updateProxyPort(port);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Proxy port updated to $port')),
                            );
                          }
                        },
                        child: const Text('Update Port'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable SSL MITM Interception & Decryption'),
                    subtitle: const Text('Allows inspecting and modifying HTTPS encrypted traffic. Requires installing ApiLab CA certificate or badCertificateCallback in Flutter.'),
                    value: vm.proxyConfig.enableSslMitm,
                    onChanged: vm.toggleSslMitm,
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Mobile Device & Local Wi-Fi Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.wifi, color: AppColors.primaryHover, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Mobile Devices & Local Wi-Fi (LAN) Setup',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'ApiLab is bound to 0.0.0.0 and accepts connections from your phone, tablet, and emulators on the same Wi-Fi network.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lan_outlined, size: 18, color: AppColors.primaryHover),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Local Wi-Fi Proxy Endpoint:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                SelectableText(
                                  '${vm.lanIp}:${vm.proxyConfig.port}',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: AppColors.textMain),
                                ),
                              ],
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: '${vm.lanIp}:${vm.proxyConfig.port}'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Copied ${vm.lanIp}:${vm.proxyConfig.port} to clipboard!')),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 14),
                          label: const Text('Copy Wi-Fi Address'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Universal Client & Device Proxy Configuration:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  _buildCodeBox('''# 1. cURL / Terminal (macOS, Linux, Windows):
export HTTP_PROXY="http://${vm.lanIp}:${vm.proxyConfig.port}"
export HTTPS_PROXY="http://${vm.lanIp}:${vm.proxyConfig.port}"
curl -k -x http://${vm.lanIp}:${vm.proxyConfig.port} https://api.example.com/data

# 2. Mobile Phones & Tablets (iOS & Android):
Go to Wi-Fi Settings -> Tap current Wi-Fi -> Configure Proxy -> Manual
Server: ${vm.lanIp}
Port:   ${vm.proxyConfig.port}

# 3. Direct Gateway Mode (No proxy setting needed):
Send HTTP request to http://${vm.lanIp}:${vm.proxyConfig.port}/path
with header: "X-ApiLab-Target: https://real-api.com/path"'''),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      final code = '''export HTTP_PROXY="http://${vm.lanIp}:${vm.proxyConfig.port}"
export HTTPS_PROXY="http://${vm.lanIp}:${vm.proxyConfig.port}"
curl -k -x http://${vm.lanIp}:${vm.proxyConfig.port} https://api.example.com''';
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Proxy commands copied to clipboard!')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 14),
                    label: const Text('Copy Proxy Configuration'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // SSL Certificate Authority Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.security_outlined, color: AppColors.methodGet, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'HTTPS Certificate Authority (CA)',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'To decrypt and mock HTTPS traffic from apps and browsers, trust ApiLab Root CA certificate on your system.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (Platform.isMacOS) {
                            await FilePickerPlatform.instance.skipEntitlementsChecks();
                          }
                          final selectedDirectory = await FilePicker.getDirectoryPath(
                            dialogTitle: 'Select Folder to Export CA Certificate',
                          );
                          if (selectedDirectory != null) {
                            final path = await vm.exportCaCertificateToFolder(selectedDirectory);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('CA Certificate exported to: $path')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.folder_open_rounded, size: 16),
                        label: const Text('Export CA Certificate (Select Folder)'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      ),
                    ],
                  ),
                  if (vm.exportedCertPath != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.methodGet.withValues(alpha: 0.3)),
                      ),
                      child: SelectableText(
                        'Saved: ${vm.exportedCertPath}',
                        style: const TextStyle(color: AppColors.methodGet, fontSize: 12, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text('OS Trust Installation Commands:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  DefaultTabController(
                    length: 3,
                    child: Column(
                      children: [
                        const TabBar(
                          isScrollable: true,
                          labelColor: AppColors.primaryHover,
                          tabs: [
                            Tab(text: 'macOS'),
                            Tab(text: 'Windows'),
                            Tab(text: 'Linux'),
                          ],
                        ),
                        SizedBox(
                          height: 120,
                          child: TabBarView(
                            children: [
                              _buildCodeBox(SslCertificateManager.getMacInstructions(vm.exportedCertPath ?? '~/Documents/apilab_ca.crt')),
                              _buildCodeBox(SslCertificateManager.getWindowsInstructions(vm.exportedCertPath ?? 'C:\\Users\\...\\apilab_ca.crt')),
                              _buildCodeBox(SslCertificateManager.getLinuxInstructions(vm.exportedCertPath ?? '/path/to/apilab_ca.crt')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // About Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('About API Lab', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 8),
                  const Text('API Lab v1.0.1 • Desktop HTTP/HTTPS Interceptor, Mock Engine & MCP AI Agent Hub', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  const Text('Architecture: MVVM + Domain-Driven Design (DDD) + Clean Code', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  const SizedBox(height: 6),
                  const Text('Cross-Platform: macOS (Intel & ARM64), Windows (x64 & ARM64), Linux (x64 & ARM64)', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeBox(String code) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: SelectableText(
        code.trim(),
        style: const TextStyle(fontFamily: 'monospace', fontSize: 11, height: 1.4, color: AppColors.textMain),
      ),
    );
  }
}
