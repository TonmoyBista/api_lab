import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/connection_guide_dialog.dart';
import '../interceptor/view_models/interceptor_view_model.dart';
import '../interceptor/views/interceptor_view.dart';
import '../mcp/view_models/mcp_hub_view_model.dart';
import '../mcp/views/mcp_hub_view.dart';
import '../mocks/view_models/mocks_view_model.dart';
import '../mocks/views/mocks_view.dart';
import '../settings/views/settings_view.dart';

class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  int _selectedNavIndex = 0;
  bool _isSidebarVisible = true;

  void _navigateTo(int index) {
    setState(() {
      _selectedNavIndex = index;
    });
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarVisible = !_isSidebarVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final interceptorVm = context.watch<InterceptorViewModel>();
    final mocksVm = context.watch<MocksViewModel>();
    final mcpVm = context.watch<McpHubViewModel>();

    return Scaffold(
      body: Row(
        children: [
          // Desktop Left Navigation Rail (Collapsible)
          if (_isSidebarVisible) ...[
            _buildSidebar(context, interceptorVm, mocksVm, mcpVm),
            const VerticalDivider(width: 1, color: AppColors.border),
          ] else ...[
            _buildCollapsedSidebar(context, interceptorVm, mocksVm, mcpVm),
            const VerticalDivider(width: 1, color: AppColors.border),
          ],
          // Main Workspace Area
          Expanded(
            child: IndexedStack(
              index: _selectedNavIndex,
              children: [
                InterceptorView(
                  onNavigateToMocks: () => _navigateTo(1),
                  isSidebarVisible: _isSidebarVisible,
                  onToggleSidebar: _toggleSidebar,
                ),
                const MocksView(),
                McpHubView(
                  onNavigateToMocks: () => _navigateTo(1),
                ),
                const SettingsView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    InterceptorViewModel interceptorVm,
    MocksViewModel mocksVm,
    McpHubViewModel mcpVm,
  ) {
    return Container(
      width: 220,
      color: AppColors.surface,
      child: Column(
        children: [
          // App Header with Hide/Collapse Sidebar button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.science_outlined, color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ApiLab',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: -0.5,
                          color: AppColors.textMain,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'DESKTOP SUITE',
                          style: TextStyle(fontSize: 8, color: AppColors.primaryHover, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.menu_open_rounded, size: 20, color: AppColors.textSecondary),
                  tooltip: 'Hide Sidebar',
                  onPressed: _toggleSidebar,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // IP & Connection Guide Card (Moved from Top Bar)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: interceptorVm.isProxyRunning ? AppColors.methodGet : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Proxy Network IP',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMain),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Localhost IP
                Row(
                  children: [
                    const Icon(Icons.computer, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '127.0.0.1:${interceptorVm.proxyPort}',
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.copy, size: 12, color: AppColors.textMuted),
                      tooltip: 'Copy Localhost Proxy Address',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: '127.0.0.1:${interceptorVm.proxyPort}'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Copied 127.0.0.1:${interceptorVm.proxyPort} to clipboard!')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Wi-Fi LAN IP
                Row(
                  children: [
                    const Icon(Icons.wifi, size: 12, color: AppColors.primaryHover),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${interceptorVm.lanIp}:${interceptorVm.proxyPort}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: AppColors.primaryHover,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.copy, size: 12, color: AppColors.primaryHover),
                      tooltip: 'Copy LAN Wi-Fi Proxy Address',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: '${interceptorVm.lanIp}:${interceptorVm.proxyPort}'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Copied ${interceptorVm.lanIp}:${interceptorVm.proxyPort} to clipboard!')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Device Setup Guide Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => showConnectionGuideDialog(context, interceptorVm),
                    icon: const Icon(Icons.devices, size: 13),
                    label: const Text('Device Setup Guide', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Navigation Links
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.wifi_tethering,
                  title: 'Interceptor & Tester',
                  badge: '${interceptorVm.filteredTraffic.length}',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.alt_route_rounded,
                  title: 'Mock Server',
                  badge: '${mocksVm.rules.length}',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.hub_outlined,
                  title: 'AI & MCP Hub',
                  badge: mcpVm.isServerRunning ? 'MCP' : null,
                  badgeColor: AppColors.secondary,
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.settings_outlined,
                  title: 'Settings & SSL',
                ),
              ],
            ),
          ),

          // Bottom System Status Panel
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
              color: AppColors.surfaceLight,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Proxy toggle status
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: interceptorVm.isProxyRunning ? AppColors.methodGet : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        interceptorVm.isProxyRunning
                            ? 'Proxy :${interceptorVm.proxyPort}'
                            : 'Proxy Off',
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        interceptorVm.isProxyRunning ? Icons.power_settings_new : Icons.play_arrow,
                        size: 16,
                        color: interceptorVm.isProxyRunning ? AppColors.methodGet : AppColors.textMuted,
                      ),
                      onPressed: interceptorVm.toggleProxy,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // MCP status
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: mcpVm.isServerRunning ? AppColors.secondary : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        mcpVm.isServerRunning ? 'MCP Server Active' : 'MCP Inactive',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String title,
    String? badge,
    Color badgeColor = AppColors.primary,
  }) {
    final isSelected = _selectedNavIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: () => _navigateTo(index),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: isSelected
                ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.primaryHover : AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.textMain : AppColors.textSecondary,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedSidebar(
    BuildContext context,
    InterceptorViewModel interceptorVm,
    MocksViewModel mocksVm,
    McpHubViewModel mcpVm,
  ) {
    return Container(
      width: 52,
      color: AppColors.surface,
      child: Column(
        children: [
          // Expand Sidebar Button (Always accessible)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: IconButton(
              icon: const Icon(Icons.menu_rounded, size: 22, color: AppColors.textMain),
              tooltip: 'Show Sidebar',
              onPressed: _toggleSidebar,
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Navigation Icons
          _buildCollapsedNavItem(
            index: 0,
            icon: Icons.wifi_tethering,
            tooltip: 'HTTP Traffic (${interceptorVm.filteredTraffic.length})',
            badgeCount: interceptorVm.filteredTraffic.length,
          ),
          _buildCollapsedNavItem(
            index: 1,
            icon: Icons.alt_route_rounded,
            tooltip: 'Mock Server (${mocksVm.rules.length})',
            badgeCount: mocksVm.rules.length,
          ),
          _buildCollapsedNavItem(
            index: 2,
            icon: Icons.hub_outlined,
            tooltip: 'AI & MCP Hub',
            badgeCount: mcpVm.isServerRunning ? 1 : 0,
          ),
          _buildCollapsedNavItem(
            index: 3,
            icon: Icons.settings_outlined,
            tooltip: 'Settings',
          ),

          const Spacer(),
          // Mini Proxy Status Dot
          Tooltip(
            message: interceptorVm.isProxyRunning
                ? 'Proxy Running on ${interceptorVm.lanIp}:${interceptorVm.proxyPort}'
                : 'Proxy Stopped',
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: interceptorVm.isProxyRunning ? AppColors.methodGet : Colors.grey,
                boxShadow: interceptorVm.isProxyRunning
                    ? [BoxShadow(color: AppColors.methodGet.withValues(alpha: 0.4), blurRadius: 6)]
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedNavItem({
    required int index,
    required IconData icon,
    required String tooltip,
    int? badgeCount,
  }) {
    final isSelected = _selectedNavIndex == index;
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _navigateTo(index),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.16) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected ? Border.all(color: AppColors.primary.withValues(alpha: 0.4)) : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? AppColors.primaryHover : AppColors.textSecondary,
                ),
                if (badgeCount != null && badgeCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
