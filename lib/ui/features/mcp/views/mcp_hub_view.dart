import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/desktop_split_pane.dart';
import '../view_models/mcp_hub_view_model.dart';

class McpHubView extends StatelessWidget {
  final VoidCallback onNavigateToMocks;

  const McpHubView({super.key, required this.onNavigateToMocks});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<McpHubViewModel>();

    return Scaffold(
      body: DesktopSplitPane(
        initialRatio: 0.42,
        minFirstRatio: 0.32,
        maxFirstRatio: 0.55,
        firstChild: _buildLeftControlPanel(context, vm),
        secondChild: _buildRightToolsAndLogs(context, vm),
      ),
    );
  }

  Widget _buildLeftControlPanel(BuildContext context, McpHubViewModel vm) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // MCP Server Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.hub_outlined, color: AppColors.primaryHover, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Model Context Protocol (MCP) Server',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (vm.isServerRunning ? AppColors.methodGet : Colors.grey).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: (vm.isServerRunning ? AppColors.methodGet : Colors.grey).withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        vm.isServerRunning ? 'ACTIVE' : 'STOPPED',
                        style: TextStyle(
                          color: vm.isServerRunning ? AppColors.methodGet : Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'ApiLab exposes standard MCP tools so AI agents (Claude Desktop, Cursor, Antigravity, custom agents) can inspect traffic, replay calls, create mocks, and manage rules directly.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 12),
                _buildInfoBadge('Local Endpoint', vm.localSseUrl),
                if (vm.lanIp != '127.0.0.1' && vm.lanIp.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildInfoBadge('LAN Wi-Fi Endpoint', vm.lanSseUrl),
                ],
                const SizedBox(height: 6),
                _buildInfoBadge('Active Clients', '${vm.activeClients} Connected'),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: vm.toggleMcpServer,
                      icon: Icon(vm.isServerRunning ? Icons.stop : Icons.play_arrow, size: 16),
                      label: Text(vm.isServerRunning ? 'Stop Server' : 'Start Server'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: vm.isServerRunning ? AppColors.methodDelete : AppColors.methodGet,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: vm.getClaudeDesktopConfigSnippet(useLan: false)));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Claude Desktop SSE config (127.0.0.1) copied!')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 14),
                      label: const Text('Copy SSE Config'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: vm.getClaudeDesktopWindowsSnippet(useLan: false)));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Windows Claude Desktop (stdio/npx) config copied!')),
                        );
                      },
                      icon: const Icon(Icons.window, size: 14),
                      label: const Text('Copy Windows Config'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: vm.getCodexCliCommand(useLan: false)));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Codex CLI command copied to clipboard!')),
                        );
                      },
                      icon: const Icon(Icons.terminal, size: 14),
                      label: const Text('Copy Codex Command'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Setup Guide Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.integration_instructions_outlined, color: AppColors.primaryHover, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'AI Client Integration Guide',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  '1. Claude Desktop (Windows):\n'
                  '   Add snippet to %APPDATA%\\Claude\\claude_desktop_config.json.\n'
                  '   Use "Copy Windows Config" for standard stdio or "Copy SSE Config" for direct SSE.\n'
                  '2. Claude Desktop (macOS):\n'
                  '   Add snippet to ~/Library/Application Support/Claude/claude_desktop_config.json.\n'
                  '3. Cursor / VS Code / Antigravity:\n'
                  '   Configure SSE MCP connection to 127.0.0.1 or LAN Wi-Fi URL.\n'
                  '4. Windows Firewall & Loopback:\n'
                  '   Connecting via 127.0.0.1 never requires Windows firewall approval.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onNavigateToMocks,
                  icon: const Icon(Icons.rule_folder_outlined, size: 14),
                  label: const Text('Go to Mock Rules'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRightToolsAndLogs(BuildContext context, McpHubViewModel vm) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: AppColors.surface,
            child: Row(
              children: [
                const Expanded(
                  child: TabBar(
                    labelColor: AppColors.primaryHover,
                    indicatorColor: AppColors.primary,
                    tabs: [
                      Tab(icon: Icon(Icons.construction_outlined, size: 16), text: 'Available MCP Tools'),
                      Tab(icon: Icon(Icons.terminal, size: 16), text: 'Live MCP Agent Logs'),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined, size: 18, color: AppColors.textSecondary),
                  tooltip: 'Clear Logs',
                  onPressed: vm.clearLogs,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              children: [
                _buildToolsTab(context, vm),
                _buildMcpLogsTab(context, vm),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsTab(BuildContext context, McpHubViewModel vm) {
    final tools = vm.availableTools;
    if (tools.isEmpty) {
      return const Center(
        child: Text('No MCP tools registered.', style: TextStyle(color: AppColors.textMuted)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tools.length,
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final tool = tools[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'TOOL',
                        style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SelectableText(
                      tool.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace', color: AppColors.primaryHover),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  tool.description,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                ),
                if (tool.inputSchema.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: SelectableText(
                      const JsonEncoder.withIndent('  ').convert(tool.inputSchema),
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textMuted),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMcpLogsTab(BuildContext context, McpHubViewModel vm) {
    if (vm.logs.isEmpty) {
      return const Center(
        child: Text('No MCP requests recorded yet. Connect an AI agent via SSE.', style: TextStyle(color: AppColors.textMuted)),
      );
    }
    return ListView.builder(
      itemCount: vm.logs.length,
      itemBuilder: (context, index) {
        final log = vm.logs[index];
        final isIn = log.direction == 'IN';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isIn ? AppColors.primary : AppColors.secondary).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      log.direction,
                      style: TextStyle(
                        color: isIn ? AppColors.primary : AppColors.secondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    log.timestamp.toLocal().toString().substring(11, 19),
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'monospace'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SelectableText(
                log.payload,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textMain),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoBadge(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.primaryHover),
          ),
        ),
      ],
    );
  }
}
