import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../domain/models/api_request.dart';
import '../../../../domain/models/http_traffic.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/desktop_split_pane.dart';
import '../../../core/widgets/method_badge.dart';
import '../../../core/widgets/connection_guide_dialog.dart';
import '../../../core/widgets/status_badge.dart';
import '../../mocks/view_models/mocks_view_model.dart';
import '../view_models/interceptor_view_model.dart';

class InterceptorView extends StatelessWidget {
  final VoidCallback onNavigateToMocks;
  final bool isSidebarVisible;
  final VoidCallback? onToggleSidebar;

  const InterceptorView({
    super.key,
    required this.onNavigateToMocks,
    this.isSidebarVisible = true,
    this.onToggleSidebar,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InterceptorViewModel>();

    return Scaffold(
      body: Column(
        children: [
          _buildToolbar(context, vm),
          const Divider(height: 1),
          Expanded(
            child: DesktopSplitPane(
              initialRatio: 0.38,
              firstChild: _buildTrafficList(context, vm),
              secondChild: _RequestEditorPane(
                onNavigateToMocks: onNavigateToMocks,
              ),
            ),
          ),
          _buildStatusBar(context, vm),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, InterceptorViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: AppColors.surface,
      child: Row(
        children: [
          // 1. Start / Stop Button (Button name: "Start" / "Stop")
          ElevatedButton.icon(
            onPressed: vm.toggleProxy,
            icon: Icon(
              vm.isProxyRunning ? Icons.stop_circle_outlined : Icons.play_arrow_rounded,
              size: 16,
              color: Colors.white,
            ),
            label: Text(
              vm.isProxyRunning ? 'Stop' : 'Start',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: vm.isProxyRunning ? AppColors.methodDelete : AppColors.methodGet,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(width: 12),

          // 2. Search Filter (Search Input + Method Filter + Status Filter)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Filter search text
                  SizedBox(
                    width: 200,
                    height: 36,
                    child: TextField(
                      onChanged: vm.setSearchQuery,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Filter requests...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.textSecondary),
                        suffixIcon: vm.searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 14),
                                onPressed: () => vm.setSearchQuery(''),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Method Filter Dropdown
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: vm.methodFilter,
                        dropdownColor: AppColors.surfaceLight,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMain),
                        items: ['ALL', 'GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS']
                            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) vm.setMethodFilter(val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Status Filter Dropdown
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: vm.statusFilter,
                        dropdownColor: AppColors.surfaceLight,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMain),
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('All Status')),
                          DropdownMenuItem(value: '2XX', child: Text('2xx Success')),
                          DropdownMenuItem(value: '4XX', child: Text('4xx Error')),
                          DropdownMenuItem(value: '5XX', child: Text('5xx Server')),
                          DropdownMenuItem(value: 'MOCKED', child: Text('⚡ Mocked Only')),
                        ],
                        onChanged: (val) {
                          if (val != null) vm.setStatusFilter(val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // 3. Delete Button (Clear Traffic)
          IconButton(
            tooltip: 'Clear Traffic List',
            icon: const Icon(Icons.delete_sweep_outlined, size: 20, color: AppColors.textSecondary),
            onPressed: vm.clearTraffic,
          ),
          const SizedBox(width: 10),

          // 4. At last: New Request Button
          ElevatedButton.icon(
            onPressed: vm.createNewRequest,
            icon: const Icon(Icons.add, size: 14),
            label: const Text('New Request', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrafficList(BuildContext context, InterceptorViewModel vm) {
    final items = vm.filteredTraffic;

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_tethering_outlined, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              const Text(
                'No requests captured yet',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              Text(
                'Configure your device/app proxy to ${vm.lanIp}:${vm.proxyPort}\nor desktop: 127.0.0.1:${vm.proxyPort}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () => _showConnectionGuideDialog(context, vm),
                icon: const Icon(Icons.devices, size: 16),
                label: const Text('Open Setup Guide'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: vm.createNewRequest,
                icon: const Icon(Icons.edit_note, size: 16),
                label: const Text('Or Test a Request Now'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = vm.selectedItem?.id == item.id;

        return InkWell(
          onTap: () => vm.selectItem(item),
          child: Container(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.14) : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                MethodBadge(method: item.request.method),
                const SizedBox(width: 8),
                StatusBadge(
                  statusCode: item.response?.statusCode,
                  statusReason: item.response?.statusReason,
                  isMocked: item.isMocked,
                  isPending: item.status == TrafficStatus.pending,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.request.pathWithQuery,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: AppColors.textMain,
                                fontFamily: 'monospace',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.request.resolvedQueryParams.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                '?${item.request.resolvedQueryParams.length}',
                                style: const TextStyle(fontSize: 9, color: AppColors.primaryHover, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.request.host.isNotEmpty ? item.request.host : item.request.url,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.response != null ? '${item.response!.durationMs} ms' : '--',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'monospace'),
                    ),
                    Text(
                      item.response != null ? '${(item.response!.contentLength / 1024).toStringAsFixed(1)} KB' : '--',
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                IconButton(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    item.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    size: 14,
                    color: item.isPinned ? AppColors.primary : AppColors.textMuted,
                  ),
                  onPressed: () => vm.togglePin(item.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBar(BuildContext context, InterceptorViewModel vm) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.surfaceLight,
      child: Row(
        children: [
          Icon(
            vm.isProxyRunning ? Icons.check_circle : Icons.circle_outlined,
            size: 12,
            color: vm.isProxyRunning ? AppColors.methodGet : Colors.grey,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              vm.isProxyRunning ? 'Proxy Server Active on Port ${vm.proxyPort}' : 'Proxy Inactive',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Showing ${vm.filteredTraffic.length} requests',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showConnectionGuideDialog(BuildContext context, InterceptorViewModel vm) {
    showConnectionGuideDialog(context, vm);
  }
}

/// Interactive Postman-style Request & Response Editor Pane directly in the Interceptor!
class _RequestEditorPane extends StatefulWidget {
  final VoidCallback onNavigateToMocks;

  const _RequestEditorPane({
    required this.onNavigateToMocks,
  });

  @override
  State<_RequestEditorPane> createState() => _RequestEditorPaneState();
}

class _RequestEditorPaneState extends State<_RequestEditorPane> {
  late TextEditingController _urlController;
  late TextEditingController _bodyController;
  String? _lastLoadedRequestId;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _bodyController = TextEditingController();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _syncControllers(ApiRequestModel? req) {
    if (req == null) return;
    if (_lastLoadedRequestId != req.id) {
      _lastLoadedRequestId = req.id;
      _urlController.text = req.url;
      _bodyController.text = req.bodyContent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InterceptorViewModel>();
    final req = vm.editableRequest;

    if (req == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.touch_app_outlined, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text(
              'Select an intercepted request on the left\nor start a new request to test and edit in-place',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: vm.createNewRequest,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Create New Request'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      );
    }

    _syncControllers(req);

    return Column(
      children: [
        // 1. Postman-style Request URL & Method Bar
        _buildRequestBar(context, vm, req),
        const Divider(height: 1),

        // 2. Request & Response Tabs
        _buildTabBar(context, vm),
        const Divider(height: 1),

        // 3. Tab Body
        Expanded(
          child: _buildTabContent(context, vm, req),
        ),
      ],
    );
  }

  Widget _buildRequestBar(BuildContext context, InterceptorViewModel vm, ApiRequestModel req) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Method Dropdown (Height: 40)
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                alignment: Alignment.center,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: req.method.toUpperCase(),
                    isDense: true,
                    dropdownColor: AppColors.surfaceLight,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMain),
                    items: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS']
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) vm.updateMethod(val);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // URL Input (Height: 40)
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _urlController,
                    onChanged: vm.updateUrl,
                    style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      hintText: 'https://api.example.com/endpoint',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Send / Replay Icon Button (Height: 40, Width: 40)
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: 'Send Request',
                  icon: vm.isTesting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                  onPressed: vm.isTesting ? null : vm.sendCurrentRequest,
                ),
              ),
              const SizedBox(width: 8),

              // cURL Icon Button (Height: 40, Width: 40)
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: 'Copy as cURL',
                  icon: const Icon(Icons.terminal_rounded, size: 18, color: AppColors.textMain),
                  onPressed: () {
                    final curl = vm.generateCurlFromEditable();
                    Clipboard.setData(ClipboardData(text: curl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('cURL command copied to clipboard!')),
                    );
                  },
                ),
              ),

              // Mock Icon Button (Height: 40, Width: 40)
              if (vm.selectedItem != null) ...[
                const SizedBox(width: 8),
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: AppColors.statusMock.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.statusMock.withValues(alpha: 0.4)),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: 'Create Mock Rule from this request',
                    icon: const Icon(Icons.auto_awesome, size: 18, color: AppColors.statusMock),
                    onPressed: () {
                      final mockRule = vm.createMockFromItem(vm.selectedItem!);
                      final mocksVm = context.read<MocksViewModel>();
                      mocksVm.createNewRule(template: mockRule);
                      widget.onNavigateToMocks();
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, InterceptorViewModel vm) {
    final active = vm.activeEditorTab;
    final req = vm.editableRequest!;
    final res = vm.testResponse;

    return Container(
      color: AppColors.surfaceLight,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTabButton(
              title: 'Params (${req.queryParams.length})',
              isSelected: active == 'params',
              onTap: () => vm.setActiveEditorTab('params'),
            ),
            _buildTabButton(
              title: 'Headers (${req.headers.length})',
              isSelected: active == 'headers',
              onTap: () => vm.setActiveEditorTab('headers'),
            ),
            _buildTabButton(
              title: 'Body (${req.bodyType.toUpperCase()})',
              isSelected: active == 'body',
              onTap: () => vm.setActiveEditorTab('body'),
            ),
            _buildTabButton(
              title: 'Auth (${req.authType.toUpperCase()})',
              isSelected: active == 'auth',
              onTap: () => vm.setActiveEditorTab('auth'),
            ),
            _buildTabButton(
              title: 'Overview',
              isSelected: active == 'overview',
              onTap: () => vm.setActiveEditorTab('overview'),
            ),
            const SizedBox(width: 16),
          // Response Tab Badge Indicator
          InkWell(
            onTap: () => vm.setActiveEditorTab('response'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: active == 'response' ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: active == 'response' ? Border.all(color: AppColors.primaryHover) : null,
              ),
              child: Row(
                children: [
                  const Icon(Icons.reply_all_rounded, size: 14, color: AppColors.primaryHover),
                  const SizedBox(width: 6),
                  const Text('Response', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                  if (res != null) ...[
                    const SizedBox(width: 6),
                    StatusBadge(statusCode: res.statusCode, statusReason: res.statusReason),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primaryHover : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.primaryHover : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, InterceptorViewModel vm, ApiRequestModel req) {
    switch (vm.activeEditorTab) {
      case 'params':
        return _buildParamsTab(vm, req);
      case 'headers':
        return _buildHeadersTab(vm, req);
      case 'body':
        return _buildBodyTab(vm, req);
      case 'auth':
        return _buildAuthTab(vm, req);
      case 'overview':
        return _buildOverviewTab(vm);
      case 'response':
      default:
        return _buildResponseTab(vm);
    }
  }

  Widget _buildParamsTab(InterceptorViewModel vm, ApiRequestModel req) {
    return KeyedSubtree(
      key: ValueKey('${req.id}_params_${req.queryParams.length}'),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Query Parameters',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: vm.addQueryParam,
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Add Parameter', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceLight,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (req.queryParams.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Text('No query parameters defined. Click "Add Parameter" to append query params.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ),
            )
          else
            ...req.queryParams.asMap().entries.map((entry) {
              final idx = entry.key;
              final param = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Checkbox(
                      value: param.isEnabled,
                      onChanged: (val) => vm.updateQueryParam(idx, param.key, param.value, val ?? true),
                    ),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        key: ValueKey('${req.id}_pk_${idx}_${param.key}'),
                        initialValue: param.key,
                        onChanged: (val) => vm.updateQueryParam(idx, val, param.value, param.isEnabled),
                        decoration: const InputDecoration(hintText: 'Key', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        key: ValueKey('${req.id}_pv_${idx}_${param.value}'),
                        initialValue: param.value,
                        onChanged: (val) => vm.updateQueryParam(idx, param.key, val, param.isEnabled),
                        decoration: const InputDecoration(hintText: 'Value', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                      onPressed: () => vm.removeQueryParam(idx),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildHeadersTab(InterceptorViewModel vm, ApiRequestModel req) {
    return KeyedSubtree(
      key: ValueKey('${req.id}_headers_${req.headers.length}'),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Request Headers',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: vm.addHeader,
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Add Header', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceLight,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (req.headers.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Text('No custom headers defined. Click "Add Header" above.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ),
            )
          else
            ...req.headers.asMap().entries.map((entry) {
              final idx = entry.key;
              final header = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Checkbox(
                      value: header.isEnabled,
                      onChanged: (val) => vm.updateHeader(idx, header.key, header.value, val ?? true),
                    ),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        key: ValueKey('${req.id}_hk_${idx}_${header.key}'),
                        initialValue: header.key,
                        onChanged: (val) => vm.updateHeader(idx, val, header.value, header.isEnabled),
                        decoration: const InputDecoration(hintText: 'Header Key', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        key: ValueKey('${req.id}_hv_${idx}_${header.value}'),
                        initialValue: header.value,
                        onChanged: (val) => vm.updateHeader(idx, header.key, val, header.isEnabled),
                        decoration: const InputDecoration(hintText: 'Header Value', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                      onPressed: () => vm.removeHeader(idx),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildBodyTab(InterceptorViewModel vm, ApiRequestModel req) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  const Text('Body Format: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Wrap(
                    spacing: 8,
                    children: ['none', 'json', 'form', 'text'].map((type) {
                      final isSelected = req.bodyType == type;
                      return ChoiceChip(
                        label: Text(type.toUpperCase(), style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppColors.textSecondary)),
                        selected: isSelected,
                        onSelected: (_) => vm.updateBodyType(type),
                        selectedColor: AppColors.primary,
                      );
                    }).toList(),
                  ),
                ],
              ),
              if (req.bodyType == 'json')
                OutlinedButton.icon(
                  onPressed: () {
                    vm.formatRequestBodyJson();
                    _bodyController.text = req.bodyContent;
                  },
                  icon: const Icon(Icons.format_align_left, size: 14),
                  label: const Text('Format JSON', style: TextStyle(fontSize: 11)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (req.bodyType == 'none')
            const Expanded(
              child: Center(
                child: Text('This request has no body payload.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ),
            )
          else
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _bodyController,
                  onChanged: vm.updateBodyContent,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.4),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                    hintText: 'Enter request body content (JSON, raw string, etc.)...',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAuthTab(InterceptorViewModel vm, ApiRequestModel req) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Authorization Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: ['none', 'bearer', 'basic'].map((type) {
            final isSelected = req.authType == type;
            return ChoiceChip(
              label: Text(type == 'none' ? 'No Auth' : type.toUpperCase(),
                  style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppColors.textSecondary)),
              selected: isSelected,
              onSelected: (_) => vm.updateAuthType(type),
              selectedColor: AppColors.primary,
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        if (req.authType == 'bearer') ...[
          const Text('Bearer Token', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: req.authBearerToken,
            onChanged: vm.updateBearerToken,
            decoration: const InputDecoration(hintText: 'Paste JWT / Bearer token here'),
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          ),
        ] else if (req.authType == 'basic') ...[
          const Text('Username', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: req.authUsername,
            onChanged: (u) => vm.updateBasicAuth(u, req.authPassword),
            decoration: const InputDecoration(hintText: 'Username'),
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          const Text('Password', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: req.authPassword,
            obscureText: true,
            onChanged: (p) => vm.updateBasicAuth(req.authUsername, p),
            decoration: const InputDecoration(hintText: 'Password'),
            style: const TextStyle(fontSize: 12),
          ),
        ] else ...[
          const Text('No authorization headers will be injected.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ],
    );
  }

  Widget _buildOverviewTab(InterceptorViewModel vm) {
    final item = vm.selectedItem;
    if (item == null) {
      return const Center(child: Text('Compose new request. No original intercepted traffic.', style: TextStyle(color: AppColors.textMuted)));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard('Original Intercepted Request Information', [
          _buildInfoRow('Full URL', item.request.url),
          _buildInfoRow('Method', item.request.method),
          _buildInfoRow('Path', item.request.path),
          _buildInfoRow('Host', item.request.host),
          _buildInfoRow('Client IP', item.request.clientIp),
          _buildInfoRow('Timestamp', item.request.timestamp.toLocal().toString()),
          _buildInfoRow('Traffic Status', item.status.name.toUpperCase()),
          _buildInfoRow('Is Mocked', item.isMocked ? 'YES (Mock Engine Intercepted)' : 'NO (Forwarded Upstream)'),
        ]),
        const SizedBox(height: 16),
        if (item.response != null)
          _buildInfoCard('Original Performance & Response', [
            _buildInfoRow('Status Code', '${item.response!.statusCode} ${item.response!.statusReason}'),
            _buildInfoRow('Roundtrip Latency', '${item.response!.durationMs} ms'),
            _buildInfoRow('Content Length', '${item.response!.contentLength} bytes'),
            _buildInfoRow('Response Type', item.response!.isJson ? 'application/json' : 'text/plain'),
          ]),
      ],
    );
  }

  Widget _buildResponseTab(InterceptorViewModel vm) {
    final res = vm.testResponse;

    if (vm.isTesting) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Sending request to ${vm.editableRequest?.url}...',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (res == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.send_rounded, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text(
              'No response yet.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Click the "Send Request" button above to test this endpoint and view live results.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: vm.sendCurrentRequest,
              icon: const Icon(Icons.play_arrow_rounded, size: 16),
              label: const Text('Send Request Now'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Response summary bar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                StatusBadge(statusCode: res.statusCode, statusReason: res.statusReason),
                const SizedBox(width: 14),
                const Icon(Icons.timer_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('${res.durationMs} ms', style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.textMain)),
                const SizedBox(width: 14),
                const Icon(Icons.data_usage_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('${(res.sizeBytes / 1024).toStringAsFixed(1)} KB', style: const TextStyle(fontSize: 12, color: AppColors.textMain)),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: res.body));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Response body copied to clipboard!')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 13),
                  label: const Text('Copy Body', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Response Body
        const Text('Response Body', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: SelectableText(
            _formatResponseBody(res.body),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.4, color: AppColors.textMain),
          ),
        ),
        const SizedBox(height: 20),

        // Response Headers
        Text('Response Headers (${res.headers.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: res.headers.entries.map((e) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SelectableText(
                        e.key,
                        style: const TextStyle(color: AppColors.primaryHover, fontSize: 12, fontFamily: 'monospace'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: SelectableText(
                        e.value,
                        style: const TextStyle(color: AppColors.textMain, fontSize: 12, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _formatResponseBody(String raw) {
    if (raw.trim().isEmpty) return '[Empty Response Body]';
    try {
      final decoded = jsonDecode(raw);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(decoded);
    } catch (_) {
      return raw;
    }
  }

  Widget _buildInfoCard(String title, List<Widget> rows) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textMain)),
            const SizedBox(height: 12),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(color: AppColors.textMain, fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
