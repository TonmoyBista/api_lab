import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
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
                        prefixIcon: Icon(Icons.search, size: 16, color: AppColors.textSecondary),
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
                        style: TextStyle(fontSize: 12, color: AppColors.textMain),
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
                        style: TextStyle(fontSize: 12, color: AppColors.textMain),
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
            icon: Icon(Icons.delete_sweep_outlined, size: 20, color: AppColors.textSecondary),
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
              Text(
                'No requests captured yet',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              Text(
                'Configure your device/app proxy to ${vm.lanIp}:${vm.proxyPort}\nor desktop: 127.0.0.1:${vm.proxyPort}',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 260;
                return Row(
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
                              if (!isCompact && item.request.resolvedQueryParams.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    '?${item.request.resolvedQueryParams.length}',
                                    style: TextStyle(fontSize: 9, color: AppColors.primaryHover, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.request.host.isNotEmpty ? item.request.host : item.request.url,
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isCompact) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                item.response != null ? '${item.response!.durationMs} ms' : '--',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'monospace'),
                              ),
                              Text(
                                item.response != null ? '${(item.response!.contentLength / 1024).toStringAsFixed(1)} KB' : '--',
                                style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: item.isPinned ? 'Unpin item' : 'Pin item',
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              item.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                              size: 14,
                              color: item.isPinned ? AppColors.primary : AppColors.textMuted,
                            ),
                            onPressed: () => vm.togglePin(item.id),
                          ),
                          const SizedBox(width: 2),
                        ],
                        IconButton(
                          tooltip: 'Delete item',
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.close,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          hoverColor: Colors.red.withValues(alpha: 0.15),
                          onPressed: () => vm.deleteItem(item.id),
                        ),
                      ],
                    ),
                  ],
                );
              },
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
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Showing ${vm.filteredTraffic.length} requests',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
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
  bool _autoOpenFindOnResponse = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _bodyController = TextEditingController();
    HardwareKeyboard.instance.addHandler(_handleGlobalKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKey);
    _urlController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  bool _handleGlobalKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isMetaOrCtrl =
          HardwareKeyboard.instance.isMetaPressed || HardwareKeyboard.instance.isControlPressed;
      if (isMetaOrCtrl && event.logicalKey == LogicalKeyboardKey.keyF) {
        final vm = context.read<InterceptorViewModel>();
        if (vm.testResponse != null && vm.activeEditorTab != 'response') {
          setState(() {
            _autoOpenFindOnResponse = true;
          });
          vm.setActiveEditorTab('response');
          return true;
        }
      }
    }
    return false;
  }

  void _syncControllers(ApiRequestModel? req) {
    if (req == null) return;
    if (_lastLoadedRequestId != req.id) {
      _lastLoadedRequestId = req.id;
      _urlController.text = req.url;
      _bodyController.text = req.bodyContent;
    } else {
      if (_urlController.text != req.url) {
        final selection = _urlController.selection;
        _urlController.text = req.url;
        if (selection.start <= req.url.length && selection.end <= req.url.length) {
          _urlController.selection = selection;
        }
      }
      if (_bodyController.text != req.bodyContent) {
        final selection = _bodyController.selection;
        _bodyController.text = req.bodyContent;
        if (selection.start <= req.bodyContent.length && selection.end <= req.bodyContent.length) {
          _bodyController.selection = selection;
        }
      }
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
            Icon(Icons.touch_app_outlined, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
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

  Color _getMethodColor(String m) {
    switch (m.toUpperCase()) {
      case 'GET': return AppColors.methodGet;
      case 'POST': return AppColors.methodPost;
      case 'PUT': return AppColors.methodPut;
      case 'DELETE': return AppColors.methodDelete;
      case 'PATCH': return AppColors.methodPatch;
      case 'HEAD': return AppColors.methodHead;
      case 'OPTIONS': return AppColors.methodOptions;
      default: return AppColors.primary;
    }
  }

  Widget _buildRequestBar(BuildContext context, InterceptorViewModel vm, ApiRequestModel req) {
    final methodColor = _getMethodColor(req.method);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 640;
          final isVeryNarrow = constraints.maxWidth < 480;

          return Row(
            children: [
              // Unified Address Bar (Method Badge + Vertical Divider + URL Input + Clear Button)
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      // HTTP Method dropdown badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: methodColor.withValues(alpha: 0.12),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(7),
                            bottomLeft: Radius.circular(7),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: req.method.toUpperCase(),
                            isDense: true,
                            dropdownColor: AppColors.surface,
                            icon: Icon(Icons.arrow_drop_down, size: 16, color: methodColor),
                            selectedItemBuilder: (context) {
                              return ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS'].map((m) {
                                return Center(
                                  child: Text(
                                    m,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: _getMethodColor(m),
                                    ),
                                  ),
                                );
                              }).toList();
                            },
                            items: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS'].map((m) {
                              return DropdownMenuItem(
                                value: m,
                                child: Text(
                                  m,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: _getMethodColor(m),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) vm.updateMethod(val);
                            },
                          ),
                        ),
                      ),
                      // Divider
                      Container(
                        width: 1,
                        height: 24,
                        color: AppColors.border,
                      ),
                      // Monospace URL TextField
                      Expanded(
                        child: TextField(
                          controller: _urlController,
                          onChanged: vm.updateUrl,
                          onSubmitted: (_) {
                            if (!vm.isTesting) vm.sendCurrentRequest();
                          },
                          style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                          decoration: InputDecoration(
                            hintText: 'https://api.example.com/endpoint',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              fontFamily: 'monospace',
                              color: AppColors.textMuted,
                            ),
                            filled: false,
                            fillColor: Colors.transparent,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            isDense: true,
                          ),
                        ),
                      ),
                      // Clear URL Icon
                      if (_urlController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 14),
                          tooltip: 'Clear URL',
                          color: AppColors.textMuted,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            _urlController.clear();
                            vm.updateUrl('');
                          },
                        ),
                      const SizedBox(width: 6),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Send / Replay Button
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: vm.isTesting ? null : vm.sendCurrentRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                    disabledForegroundColor: Colors.white70,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: isVeryNarrow ? 12 : 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (vm.isTesting)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      else
                        const Icon(Icons.send_rounded, size: 15),
                      if (!isVeryNarrow) ...[
                        const SizedBox(width: 6),
                        const Text(
                          'Send',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.3),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // cURL Tool Button
              Tooltip(
                message: 'Copy as cURL command',
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        final curl = vm.generateCurlFromEditable();
                        Clipboard.setData(ClipboardData(text: curl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                                SizedBox(width: 8),
                                Text('cURL command copied to clipboard!'),
                              ],
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: isNarrow ? 10 : 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.terminal_rounded, size: 16, color: AppColors.textMain),
                            if (!isNarrow) ...[
                              const SizedBox(width: 6),
                              Text(
                                'cURL',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMain,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Mock Tool Button
              if (vm.selectedItem != null) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Create Mock Rule from this request',
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.statusMock.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.statusMock.withValues(alpha: 0.35)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          final mockRule = vm.createMockFromItem(vm.selectedItem!);
                          final mocksVm = context.read<MocksViewModel>();
                          mocksVm.createNewRule(template: mockRule);
                          widget.onNavigateToMocks();
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: isNarrow ? 10 : 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome_rounded, size: 15, color: AppColors.statusMock),
                              if (!isNarrow) ...[
                                const SizedBox(width: 6),
                                const Text(
                                  'Mock',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.statusMock,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
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
              title: 'Params',
              badge: req.queryParams.isNotEmpty ? '${req.queryParams.length}' : null,
              isSelected: active == 'params',
              onTap: () => vm.setActiveEditorTab('params'),
            ),
            _buildTabButton(
              title: 'Headers',
              badge: req.headers.isNotEmpty ? '${req.headers.length}' : null,
              isSelected: active == 'headers',
              onTap: () => vm.setActiveEditorTab('headers'),
            ),
            _buildTabButton(
              title: 'Body',
              badge: req.bodyType != 'none' ? req.bodyType.toUpperCase() : null,
              isSelected: active == 'body',
              onTap: () => vm.setActiveEditorTab('body'),
            ),
            _buildTabButton(
              title: 'Auth',
              badge: req.authType != 'none' ? req.authType.toUpperCase() : null,
              isSelected: active == 'auth',
              onTap: () => vm.setActiveEditorTab('auth'),
            ),
            _buildTabButton(
              title: 'Overview',
              isSelected: active == 'overview',
              onTap: () => vm.setActiveEditorTab('overview'),
            ),
            const SizedBox(width: 8),
            Container(height: 18, width: 1, color: AppColors.border),
            const SizedBox(width: 8),
            _buildTabButton(
              title: 'Response',
              isSelected: active == 'response',
              badgeWidget: res != null ? StatusBadge(statusCode: res.statusCode, statusReason: res.statusReason) : null,
              onTap: () => vm.setActiveEditorTab('response'),
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
    String? badge,
    Widget? badgeWidget,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primaryHover : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primaryHover : AppColors.textSecondary,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.primaryHover : AppColors.textMuted,
                  ),
                ),
              ),
            ],
            if (badgeWidget != null) ...[
              const SizedBox(width: 6),
              badgeWidget,
            ],
          ],
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
              child: Center(
                child: Text('No query parameters defined. Click "Add Parameter" to append query params.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ),
            )
          else
            ...req.queryParams.asMap().entries.map((entry) {
              final idx = entry.key;
              final param = entry.value;
              return _QueryParamEditorRow(
                key: ValueKey('${req.id}_param_$idx'),
                param: param,
                onChanged: (updated) => vm.updateQueryParam(idx, updated.key, updated.value, updated.isEnabled),
                onRemove: () => vm.removeQueryParam(idx),
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
              child: Center(
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
                      icon: Icon(Icons.close, size: 16, color: AppColors.textMuted),
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
            Expanded(
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
          Text('Bearer Token', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: req.authBearerToken,
            onChanged: vm.updateBearerToken,
            decoration: const InputDecoration(hintText: 'Paste JWT / Bearer token here'),
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          ),
        ] else if (req.authType == 'basic') ...[
          Text('Username', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: req.authUsername,
            onChanged: (u) => vm.updateBasicAuth(u, req.authPassword),
            decoration: const InputDecoration(hintText: 'Username'),
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          Text('Password', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: req.authPassword,
            obscureText: true,
            onChanged: (p) => vm.updateBasicAuth(req.authUsername, p),
            decoration: const InputDecoration(hintText: 'Password'),
            style: const TextStyle(fontSize: 12),
          ),
        ] else ...[
          Text('No authorization headers will be injected.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ],
    );
  }

  Widget _buildOverviewTab(InterceptorViewModel vm) {
    final item = vm.selectedItem;
    if (item == null) {
      return Center(child: Text('Compose new request. No original intercepted traffic.', style: TextStyle(color: AppColors.textMuted)));
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
            _buildInfoRow(
              'Response Type',
              item.response!.contentType.isNotEmpty
                  ? item.response!.contentType
                  : (item.response!.isJson ? 'application/json' : (item.response!.isImage ? 'image/*' : 'text/plain')),
            ),
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
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
            Icon(Icons.send_rounded, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'No response yet.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
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

    final autoOpen = _autoOpenFindOnResponse;
    if (_autoOpenFindOnResponse) {
      _autoOpenFindOnResponse = false;
    }
    return _ResponseBodyPanel(response: res, autoOpenFind: autoOpen);
  }


  Widget _buildInfoCard(String title, List<Widget> rows) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textMain)),
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
            child: Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(color: AppColors.textMain, fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Background Isolate Parser & Flattener for Large JSON / Text Responses
// =============================================================================
class _ParsedResponsePayload {
  final dynamic parsedJson;
  final String formattedText;
  final List<String> rawLines;
  final int totalJsonNodes;
  final Set<String> initialCollapsedPaths;

  const _ParsedResponsePayload({
    required this.parsedJson,
    required this.formattedText,
    required this.rawLines,
    required this.totalJsonNodes,
    required this.initialCollapsedPaths,
  });
}

_ParsedResponsePayload _parseAndFormatResponseIsolate(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return const _ParsedResponsePayload(
      parsedJson: null,
      formattedText: '[Empty Response Body]',
      rawLines: ['[Empty Response Body]'],
      totalJsonNodes: 0,
      initialCollapsedPaths: {},
    );
  }

  try {
    final decoded = jsonDecode(raw);
    const encoder = JsonEncoder.withIndent('  ');
    final formatted = encoder.convert(decoded);
    final rawLines = formatted.split('\n');

    int nodeCount = 0;
    final collapsed = <String>{};

    void analyzeTree(dynamic node, String path, int depth) {
      nodeCount++;
      if (node is Map) {
        if (depth >= 1 && (nodeCount > 250 || node.length > 50)) {
          collapsed.add(path);
        }
        for (final entry in node.entries) {
          final childVal = entry.value;
          if (childVal is Map || childVal is List) {
            analyzeTree(childVal, '$path.${entry.key}', depth + 1);
          } else {
            nodeCount++;
          }
        }
      } else if (node is List) {
        if (depth >= 1 && (nodeCount > 250 || node.length > 50)) {
          collapsed.add(path);
        }
        for (int i = 0; i < node.length; i++) {
          final childVal = node[i];
          if (childVal is Map || childVal is List) {
            analyzeTree(childVal, '$path[$i]', depth + 1);
          } else {
            nodeCount++;
          }
        }
      }
    }

    analyzeTree(decoded, r'$', 0);

    return _ParsedResponsePayload(
      parsedJson: decoded,
      formattedText: formatted,
      rawLines: rawLines,
      totalJsonNodes: nodeCount,
      initialCollapsedPaths: collapsed,
    );
  } catch (_) {
    final lines = raw.split('\n');
    return _ParsedResponsePayload(
      parsedJson: null,
      formattedText: raw,
      rawLines: lines,
      totalJsonNodes: 0,
      initialCollapsedPaths: const {},
    );
  }
}

enum _FlatJsonRowKind {
  expandableHeader,
  closingBracket,
  leaf,
}

class _FlatJsonRow {
  final String path;
  final int depth;
  final String? keyLabel;
  final _FlatJsonRowKind kind;
  final dynamic value;
  final bool isExpanded;
  final bool isMap;
  final int childCount;
  final String searchText;

  const _FlatJsonRow({
    required this.path,
    required this.depth,
    this.keyLabel,
    required this.kind,
    this.value,
    this.isExpanded = false,
    this.isMap = false,
    this.childCount = 0,
    required this.searchText,
  });
}

// =============================================================================
// _ResponseBodyPanel – houses summary bar, find bar, image preview / JSON tree / raw text
// =============================================================================
class _ResponseBodyPanel extends StatefulWidget {
  final ApiResponseModel response;
  final bool autoOpenFind;

  const _ResponseBodyPanel({
    required this.response,
    this.autoOpenFind = false,
  });

  @override
  State<_ResponseBodyPanel> createState() => _ResponseBodyPanelState();
}

class _ResponseBodyPanelState extends State<_ResponseBodyPanel> {
  // Find-bar state
  bool _findBarVisible = false;
  final TextEditingController _findController = TextEditingController();
  String _findQuery = '';
  int _currentMatchIndex = 0;
  final ScrollController _bodyScrollController = ScrollController();

  // JSON / Image / Virtualized view state
  bool _isJsonMode = false;
  bool _isImageMode = false;
  bool _isParsing = false;
  int _parseGeneration = 0;

  dynamic _parsedJson;
  String _formattedText = '';
  List<String> _rawLines = const [];
  String? _cachedRawImageDataText;

  final Set<String> _collapsedPaths = {};
  List<_FlatJsonRow> _flatJsonRows = const [];

  // Cached search state (indices into either _flatJsonRows or _rawLines)
  List<int> _matchedRowIndices = const [];

  // Focus
  final FocusNode _findFocusNode = FocusNode();

  String get _rawImageDataText {
    if (_cachedRawImageDataText != null) return _cachedRawImageDataText!;
    final res = widget.response;
    if (res.imageBytes != null && res.imageBytes!.isNotEmpty) {
      _cachedRawImageDataText = utf8.decode(res.imageBytes!, allowMalformed: true);
    } else {
      _cachedRawImageDataText = res.body;
    }
    return _cachedRawImageDataText!;
  }

  List<String> get _activeRawLines {
    final res = widget.response;
    if (res.isImage && res.imageBytes != null) {
      return _rawImageDataText.split('\n');
    }
    return _rawLines;
  }

  int get _totalMatches => _matchedRowIndices.length;

  void _recomputeSearchMatches({bool autoExpandJsonMatches = false}) {
    final q = _findQuery.trim().toLowerCase();
    if (q.isEmpty) {
      _matchedRowIndices = const [];
      _currentMatchIndex = 0;
      return;
    }

    if (_isJsonMode && _parsedJson != null) {
      if (autoExpandJsonMatches && _collapsedPaths.isNotEmpty) {
        bool expandedAny = false;
        void expandMatchingBranches(dynamic node, String path, List<String> ancestors) {
          if (node is Map) {
            for (final entry in node.entries) {
              final kStr = '${entry.key}';
              final childPath = '$path.$kStr';
              final val = entry.value;
              if (kStr.toLowerCase().contains(q)) {
                for (final a in ancestors) {
                  if (_collapsedPaths.remove(a)) expandedAny = true;
                }
                if (_collapsedPaths.remove(path)) expandedAny = true;
              }
              if (val is Map || val is List) {
                expandMatchingBranches(val, childPath, [...ancestors, path]);
              } else {
                final vStr = val == null ? 'null' : (val is String ? '"$val"' : val.toString());
                if (vStr.toLowerCase().contains(q)) {
                  for (final a in ancestors) {
                    if (_collapsedPaths.remove(a)) expandedAny = true;
                  }
                  if (_collapsedPaths.remove(path)) expandedAny = true;
                }
              }
            }
          } else if (node is List) {
            for (int i = 0; i < node.length; i++) {
              final childPath = '$path[$i]';
              final val = node[i];
              if (val is Map || val is List) {
                expandMatchingBranches(val, childPath, [...ancestors, path]);
              } else {
                final vStr = val == null ? 'null' : (val is String ? '"$val"' : val.toString());
                if (vStr.toLowerCase().contains(q)) {
                  for (final a in ancestors) {
                    if (_collapsedPaths.remove(a)) expandedAny = true;
                  }
                  if (_collapsedPaths.remove(path)) expandedAny = true;
                }
              }
            }
          }
        }

        expandMatchingBranches(_parsedJson, r'$', []);
        if (expandedAny) {
          _rebuildFlatJsonRows();
        }
      }

      final matches = <int>[];
      for (int i = 0; i < _flatJsonRows.length; i++) {
        if (_flatJsonRows[i].searchText.toLowerCase().contains(q)) {
          matches.add(i);
        }
      }
      _matchedRowIndices = matches;
    } else {
      final lines = _activeRawLines;
      final matches = <int>[];
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].toLowerCase().contains(q)) {
          matches.add(i);
        }
      }
      _matchedRowIndices = matches;
    }

    if (_currentMatchIndex >= _matchedRowIndices.length) {
      _currentMatchIndex = 0;
    }
  }

  void _rebuildFlatJsonRows() {
    if (_parsedJson == null) {
      _flatJsonRows = const [];
      return;
    }
    final rows = <_FlatJsonRow>[];

    void visit(dynamic node, String path, int depth, String? keyLabel) {
      if (node is Map) {
        final isExpanded = !_collapsedPaths.contains(path);
        final preview = node.isEmpty
            ? '{}'
            : '{…} (${node.length} key${node.length == 1 ? '' : 's'})';
        final headerSearch = keyLabel != null
            ? '"$keyLabel": ${isExpanded ? '{' : preview}'
            : (isExpanded ? '{' : preview);
        rows.add(_FlatJsonRow(
          path: path,
          depth: depth,
          keyLabel: keyLabel,
          kind: _FlatJsonRowKind.expandableHeader,
          value: node,
          isExpanded: isExpanded,
          isMap: true,
          childCount: node.length,
          searchText: headerSearch,
        ));
        if (isExpanded) {
          for (final entry in node.entries) {
            final k = '${entry.key}';
            visit(entry.value, '$path.$k', depth + 1, k);
          }
          rows.add(_FlatJsonRow(
            path: '$path#close',
            depth: depth,
            kind: _FlatJsonRowKind.closingBracket,
            isMap: true,
            searchText: '}',
          ));
        }
      } else if (node is List) {
        final isExpanded = !_collapsedPaths.contains(path);
        final preview = node.isEmpty
            ? '[]'
            : '[…] (${node.length} item${node.length == 1 ? '' : 's'})';
        final headerSearch = keyLabel != null
            ? '$keyLabel: ${isExpanded ? '[' : preview}'
            : (isExpanded ? '[' : preview);
        rows.add(_FlatJsonRow(
          path: path,
          depth: depth,
          keyLabel: keyLabel,
          kind: _FlatJsonRowKind.expandableHeader,
          value: node,
          isExpanded: isExpanded,
          isMap: false,
          childCount: node.length,
          searchText: headerSearch,
        ));
        if (isExpanded) {
          for (int i = 0; i < node.length; i++) {
            visit(node[i], '$path[$i]', depth + 1, '[$i]');
          }
          rows.add(_FlatJsonRow(
            path: '$path#close',
            depth: depth,
            kind: _FlatJsonRowKind.closingBracket,
            isMap: false,
            searchText: ']',
          ));
        }
      } else {
        final valStr = node == null ? 'null' : (node is String ? '"$node"' : node.toString());
        final searchStr = keyLabel != null ? '"$keyLabel": $valStr' : valStr;
        rows.add(_FlatJsonRow(
          path: path,
          depth: depth,
          keyLabel: keyLabel,
          kind: _FlatJsonRowKind.leaf,
          value: node,
          searchText: searchStr,
        ));
      }
    }

    visit(_parsedJson, r'$', 0, null);
    _flatJsonRows = rows;
  }

  void _toggleNodeExpansion(String path) {
    setState(() {
      if (_collapsedPaths.contains(path)) {
        _collapsedPaths.remove(path);
      } else {
        _collapsedPaths.add(path);
      }
      _rebuildFlatJsonRows();
      _recomputeSearchMatches(autoExpandJsonMatches: false);
    });
  }

  void _expandAllNodes() {
    setState(() {
      _collapsedPaths.clear();
      _rebuildFlatJsonRows();
      _recomputeSearchMatches(autoExpandJsonMatches: false);
    });
  }

  void _collapseAllNodes() {
    if (_parsedJson == null) return;
    setState(() {
      _collapsedPaths.clear();
      void collectAll(dynamic node, String path, int depth) {
        if (node is Map) {
          if (depth >= 1) _collapsedPaths.add(path);
          for (final entry in node.entries) {
            if (entry.value is Map || entry.value is List) {
              collectAll(entry.value, '$path.${entry.key}', depth + 1);
            }
          }
        } else if (node is List) {
          if (depth >= 1) _collapsedPaths.add(path);
          for (int i = 0; i < node.length; i++) {
            if (node[i] is Map || node[i] is List) {
              collectAll(node[i], '$path[$i]', depth + 1);
            }
          }
        }
      }
      collectAll(_parsedJson, r'$', 0);
      _rebuildFlatJsonRows();
      _recomputeSearchMatches(autoExpandJsonMatches: false);
    });
  }

  void _nextMatch() {
    final total = _totalMatches;
    if (total == 0) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % total;
    });
    _scrollToCurrentMatch();
  }

  void _previousMatch() {
    final total = _totalMatches;
    if (total == 0) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex - 1 + total) % total;
    });
    _scrollToCurrentMatch();
  }

  void _scrollToCurrentMatch() {
    if (!_bodyScrollController.hasClients) return;
    if (_matchedRowIndices.isEmpty || _currentMatchIndex >= _matchedRowIndices.length) return;

    final rowIndex = _matchedRowIndices[_currentMatchIndex];
    const estimatedRowHeight = 22.0;
    final maxScroll = _bodyScrollController.position.maxScrollExtent;
    final targetOffset = ((rowIndex * estimatedRowHeight) - 80.0).clamp(0.0, maxScroll);

    _bodyScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void initState() {
    super.initState();
    _prepareResponseData();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    if (widget.autoOpenFind) {
      _findBarVisible = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _findFocusNode.requestFocus();
          _findController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _findController.text.length,
          );
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant _ResponseBodyPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.response != widget.response) {
      _prepareResponseData();
    }
    if (widget.autoOpenFind && !_findBarVisible) {
      setState(() {
        _findBarVisible = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _findFocusNode.requestFocus();
          _findController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _findController.text.length,
          );
        }
      });
    }
  }

  Future<void> _prepareResponseData() async {
    final gen = ++_parseGeneration;
    _cachedRawImageDataText = null;

    if (widget.response.isImage && widget.response.imageBytes != null) {
      setState(() {
        _isImageMode = true;
        _isJsonMode = false;
        _isParsing = false;
        _parsedJson = null;
        _formattedText = '';
        _rawLines = const [];
        _flatJsonRows = const [];
        _collapsedPaths.clear();
        _recomputeSearchMatches();
      });
      return;
    }

    _isImageMode = false;
    final rawBody = widget.response.body;

    // For small payloads (< 25 KB), parse synchronously so there is zero frame delay.
    // For larger payloads, offload JSON decoding, formatting, and node counting to a background Isolate.
    if (rawBody.length <= 25000) {
      final payload = _parseAndFormatResponseIsolate(rawBody);
      _applyParsedPayload(payload);
    } else {
      setState(() {
        _isParsing = true;
      });
      final payload = await compute(_parseAndFormatResponseIsolate, rawBody);
      if (!mounted || gen != _parseGeneration) return;
      setState(() {
        _applyParsedPayload(payload);
      });
    }
  }

  void _applyParsedPayload(_ParsedResponsePayload payload) {
    _isParsing = false;
    _parsedJson = payload.parsedJson;
    _formattedText = payload.formattedText;
    _rawLines = payload.rawLines;
    _isJsonMode = payload.parsedJson != null;
    _collapsedPaths
      ..clear()
      ..addAll(payload.initialCollapsedPaths);
    _rebuildFlatJsonRows();
    _recomputeSearchMatches(autoExpandJsonMatches: _findQuery.isNotEmpty);
  }

  void _toggleFindBar() {
    setState(() {
      _findBarVisible = !_findBarVisible;
      if (_findBarVisible) {
        _currentMatchIndex = 0;
        _recomputeSearchMatches(autoExpandJsonMatches: true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _findFocusNode.requestFocus();
            _findController.selection = TextSelection(
              baseOffset: 0,
              extentOffset: _findController.text.length,
            );
          }
        });
      } else {
        _findQuery = '';
        _findController.clear();
        _currentMatchIndex = 0;
        _matchedRowIndices = const [];
      }
    });
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isMetaOrCtrl =
          HardwareKeyboard.instance.isMetaPressed || HardwareKeyboard.instance.isControlPressed;
      final isShift = HardwareKeyboard.instance.isShiftPressed;

      if (isMetaOrCtrl && event.logicalKey == LogicalKeyboardKey.keyF) {
        if (!_findBarVisible) {
          _toggleFindBar();
        } else {
          _findFocusNode.requestFocus();
          _findController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _findController.text.length,
          );
        }
        return true;
      }

      if (_findBarVisible) {
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          _toggleFindBar();
          return true;
        }

        if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter) {
          if (isShift) {
            _previousMatch();
          } else {
            _nextMatch();
          }
          return true;
        }

        if ((isMetaOrCtrl && event.logicalKey == LogicalKeyboardKey.keyG) || event.logicalKey == LogicalKeyboardKey.f3) {
          if (isShift) {
            _previousMatch();
          } else {
            _nextMatch();
          }
          return true;
        }

        if (_findFocusNode.hasFocus) {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _nextMatch();
            return true;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _previousMatch();
            return true;
          }
        }
      }
    }
    return false;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _findController.dispose();
    _findFocusNode.dispose();
    _bodyScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final res = widget.response;
    final body = res.body;
    final headers = res.headers;
    final hasImage = res.isImage && res.imageBytes != null;
    final activeMatchedRow = (_matchedRowIndices.isNotEmpty && _currentMatchIndex < _matchedRowIndices.length)
        ? _matchedRowIndices[_currentMatchIndex]
        : -1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Summary bar ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                StatusBadge(statusCode: res.statusCode, statusReason: res.statusReason),
                const SizedBox(width: 14),
                Icon(Icons.timer_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('${res.durationMs} ms',
                    style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.textMain)),
                const SizedBox(width: 14),
                Icon(Icons.data_usage_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('${(res.sizeBytes / 1024).toStringAsFixed(1)} KB',
                    style: TextStyle(fontSize: 12, color: AppColors.textMain)),
                const SizedBox(width: 16),
                if (hasImage) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isImageMode = !_isImageMode;
                        _recomputeSearchMatches();
                      });
                    },
                    icon: Icon(
                      _isImageMode ? Icons.data_object : Icons.image_outlined,
                      size: 13,
                    ),
                    label: Text(_isImageMode ? 'Raw Data' : 'Image Preview', style: const TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _downloadImage(context, res.imageBytes!, res.contentType),
                    icon: const Icon(Icons.download_rounded, size: 13),
                    label: const Text('Download Image', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else if (_parsedJson != null) ...[
                  // Toggle JSON / Raw
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isJsonMode = !_isJsonMode;
                        _recomputeSearchMatches(autoExpandJsonMatches: _isJsonMode);
                      });
                    },
                    icon: Icon(
                      _isJsonMode ? Icons.code : Icons.account_tree_outlined,
                      size: 13,
                    ),
                    label: Text(_isJsonMode ? 'Raw Text' : 'JSON Tree', style: const TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                  ),
                  const SizedBox(width: 8),
                  if (_isJsonMode) ...[
                    OutlinedButton.icon(
                      onPressed: _expandAllNodes,
                      icon: const Icon(Icons.unfold_more_rounded, size: 13),
                      label: const Text('Expand All', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton.icon(
                      onPressed: _collapseAllNodes,
                      icon: const Icon(Icons.unfold_less_rounded, size: 13),
                      label: const Text('Collapse All', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
                // Find button (when not in image preview mode)
                if (!_isImageMode) ...[
                  OutlinedButton.icon(
                    onPressed: _toggleFindBar,
                    icon: const Icon(Icons.search, size: 13),
                    label: const Text('Find  ⌘F', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                  ),
                  const SizedBox(width: 8),
                ],
                // Copy body / Copy Raw Data
                OutlinedButton.icon(
                  onPressed: () {
                    if (hasImage && res.imageBytes != null) {
                      final textToCopy = _isImageMode
                          ? 'data:${res.contentType.isNotEmpty ? res.contentType.split(';').first.trim() : 'image/png'};base64,${base64Encode(res.imageBytes!)}'
                          : _rawImageDataText;
                      Clipboard.setData(ClipboardData(text: textToCopy));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _isImageMode
                                ? 'Image Base64 Data URI copied to clipboard!'
                                : 'Raw image data copied to clipboard!',
                          ),
                        ),
                      );
                    } else {
                      Clipboard.setData(ClipboardData(text: _formattedText.isNotEmpty ? _formattedText : body));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Response body copied to clipboard!')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy, size: 13),
                  label: Text(
                    hasImage ? (_isImageMode ? 'Copy Base64' : 'Copy Raw Data') : 'Copy Body',
                    style: const TextStyle(fontSize: 11),
                  ),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                ),
              ],
            ),
          ),
        ),

        // ── Find bar ─────────────────────────────────────────────────────
        if (_findBarVisible)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _findController,
                    focusNode: _findFocusNode,
                    onChanged: (v) {
                      setState(() {
                        _findQuery = v;
                        _currentMatchIndex = 0;
                        _recomputeSearchMatches(autoExpandJsonMatches: true);
                      });
                      if (v.isNotEmpty) {
                        _scrollToCurrentMatch();
                      }
                    },
                    onSubmitted: (_) => _nextMatch(),
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Find in response...',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_findQuery.isNotEmpty) ...[
                  Text(
                    _totalMatches > 0
                        ? '${_currentMatchIndex + 1} of $_totalMatches'
                        : 'No matches',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _totalMatches > 0
                          ? AppColors.textSecondary
                          : AppColors.methodDelete,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Move Up (Previous match)
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_up, size: 18),
                    tooltip: 'Previous match (Shift+Enter or ↑)',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    onPressed: _totalMatches > 0 ? _previousMatch : null,
                  ),
                  const SizedBox(width: 2),
                  // Move Down (Next match)
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                    tooltip: 'Next match (Enter or ↓)',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    onPressed: _totalMatches > 0 ? _nextMatch : null,
                  ),
                  const SizedBox(width: 6),
                ],
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  tooltip: 'Close (Esc)',
                  onPressed: _toggleFindBar,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),

        // ── Body label ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              const Text('Response Body', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              if (hasImage) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    res.contentType.isNotEmpty ? res.contentType.split(';').first.toUpperCase() : 'IMAGE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryHover,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const Spacer(),
                ChoiceChip(
                  label: const Text('Image Preview', style: TextStyle(fontSize: 11)),
                  selected: _isImageMode,
                  onSelected: (_) => setState(() => _isImageMode = true),
                  selectedColor: AppColors.primary.withValues(alpha: 0.25),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('Raw Data', style: TextStyle(fontSize: 11)),
                  selected: !_isImageMode,
                  onSelected: (_) {
                    setState(() {
                      _isImageMode = false;
                      _recomputeSearchMatches();
                    });
                  },
                  selectedColor: AppColors.primary.withValues(alpha: 0.25),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
        ),

        // ── Virtualized Body & Headers Content ───────────────────────────
        Expanded(
          child: _isParsing
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Formatting large response (${(res.sizeBytes / 1024).toStringAsFixed(1)} KB)...',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  controller: _bodyScrollController,
                  slivers: [
                    if (hasImage && _isImageMode)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverToBoxAdapter(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: _ImageResponsePreview(
                              bytes: res.imageBytes!,
                              contentType: res.contentType,
                              rawBody: body,
                              onDownload: () => _downloadImage(context, res.imageBytes!, res.contentType),
                            ),
                          ),
                        ),
                      )
                    else if (_isJsonMode && _parsedJson != null)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: DecoratedSliver(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          sliver: SliverPadding(
                            padding: const EdgeInsets.all(12),
                            sliver: SliverList.builder(
                              itemCount: _flatJsonRows.length,
                              itemBuilder: (context, index) {
                                final row = _flatJsonRows[index];
                                return _VirtualJsonRowWidget(
                                  row: row,
                                  highlight: _findQuery,
                                  isActiveMatch: index == activeMatchedRow,
                                  onToggleExpand: () => _toggleNodeExpansion(row.path),
                                );
                              },
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: DecoratedSliver(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          sliver: SliverPadding(
                            padding: const EdgeInsets.all(12),
                            sliver: SliverList.builder(
                              itemCount: _activeRawLines.length,
                              itemBuilder: (context, index) {
                                final line = _activeRawLines[index];
                                return _VirtualRawLineWidget(
                                  line: line,
                                  highlight: _findQuery,
                                  isActiveMatch: index == activeMatchedRow,
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                    // ── Response Headers Section ─────────────────────────
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Response Headers (${headers.length})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                children: headers.entries.map((e) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: SelectableText(
                                            e.key,
                                            style: TextStyle(
                                                color: AppColors.primaryHover, fontSize: 12, fontFamily: 'monospace'),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          flex: 3,
                                          child: SelectableText(
                                            e.value,
                                            style: TextStyle(
                                                color: AppColors.textMain, fontSize: 12, fontFamily: 'monospace'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  static String _detectImageExtension(Uint8List bytes, String contentType) {
    final ct = contentType.toLowerCase();
    if (ct.contains('png')) return 'png';
    if (ct.contains('jpeg') || ct.contains('jpg')) return 'jpg';
    if (ct.contains('gif')) return 'gif';
    if (ct.contains('webp')) return 'webp';
    if (ct.contains('bmp')) return 'bmp';
    if (ct.contains('svg')) return 'svg';
    if (ct.contains('icon') || ct.contains('ico')) return 'ico';

    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'png';
    }
    if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'jpg';
    }
    if (bytes.length >= 6 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return 'gif';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'webp';
    }
    if (bytes.length >= 2 && bytes[0] == 0x42 && bytes[1] == 0x4D) {
      return 'bmp';
    }
    return 'png';
  }

  Future<void> _downloadImage(BuildContext context, Uint8List bytes, String contentType) async {
    try {
      if (Platform.isMacOS) {
        await FilePickerPlatform.instance.skipEntitlementsChecks();
      }
      final selectedDirectory = await FilePicker.getDirectoryPath(
        dialogTitle: 'Select Folder to Download Image',
      );
      if (selectedDirectory == null) return;

      final ext = _detectImageExtension(bytes, contentType);
      final fileName = 'apilab_image_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final filePath = '$selectedDirectory${Platform.pathSeparator}$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image saved to: $filePath')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save image: $e')),
        );
      }
    }
  }
}

// =============================================================================
// _ImageResponsePreview – displays the image response and download button
// =============================================================================
class _ImageResponsePreview extends StatelessWidget {
  final Uint8List bytes;
  final String contentType;
  final String rawBody;
  final VoidCallback onDownload;

  const _ImageResponsePreview({
    required this.bytes,
    required this.contentType,
    required this.rawBody,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final isSvg = contentType.toLowerCase().contains('svg');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: onDownload,
            icon: const Icon(Icons.download_rounded, size: 14),
            label: const Text('Download Image', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image_outlined, size: 36, color: AppColors.textMuted),
                      const SizedBox(height: 8),
                      Text(
                        isSvg
                            ? 'SVG vector image received (${bytes.length} bytes)'
                            : 'Unable to decode image preview (${bytes.length} bytes)',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      if (isSvg && rawBody.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          rawBody,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: AppColors.textMain,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Virtualized Raw Line & JSON Row Widgets (O(1) visible viewport rendering)
// =============================================================================
TextSpan _buildHighlightedSpan({
  required String text,
  required TextStyle baseStyle,
  required String highlight,
  required bool isActiveRow,
}) {
  if (highlight.isEmpty || !text.toLowerCase().contains(highlight.toLowerCase())) {
    return TextSpan(text: text, style: baseStyle);
  }

  final spans = <TextSpan>[];
  final regex = RegExp(RegExp.escape(highlight), caseSensitive: false);
  int last = 0;
  for (final m in regex.allMatches(text)) {
    if (m.start > last) {
      spans.add(TextSpan(text: text.substring(last, m.start), style: baseStyle));
    }
    spans.add(TextSpan(
      text: text.substring(m.start, m.end),
      style: baseStyle.copyWith(
        color: Colors.black,
        backgroundColor: isActiveRow ? const Color(0xFFFF9800) : const Color(0xFFFFD700),
        fontWeight: isActiveRow ? FontWeight.w900 : FontWeight.bold,
      ),
    ));
    last = m.end;
  }
  if (last < text.length) {
    spans.add(TextSpan(text: text.substring(last), style: baseStyle));
  }
  return TextSpan(children: spans);
}

class _VirtualRawLineWidget extends StatelessWidget {
  final String line;
  final String highlight;
  final bool isActiveMatch;

  const _VirtualRawLineWidget({
    required this.line,
    required this.highlight,
    required this.isActiveMatch,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 12,
      height: 1.4,
      color: AppColors.textMain,
    );

    if (highlight.isEmpty) {
      return SelectableText(line.isEmpty ? ' ' : line, style: baseStyle);
    }

    return SelectableText.rich(
      _buildHighlightedSpan(
        text: line.isEmpty ? ' ' : line,
        baseStyle: baseStyle,
        highlight: highlight,
        isActiveRow: isActiveMatch,
      ),
    );
  }
}

class _VirtualJsonRowWidget extends StatelessWidget {
  final _FlatJsonRow row;
  final String highlight;
  final bool isActiveMatch;
  final VoidCallback onToggleExpand;

  const _VirtualJsonRowWidget({
    required this.row,
    required this.highlight,
    required this.isActiveMatch,
    required this.onToggleExpand,
  });

  Color _valueColor(dynamic v) {
    if (v == null) return AppColors.jsonNull;
    if (v is bool) return AppColors.jsonBool;
    if (v is num) return AppColors.jsonNumber;
    if (v is String) return AppColors.jsonString;
    return AppColors.textMain;
  }

  String _stringify(dynamic v) {
    if (v == null) return 'null';
    if (v is String) return '"$v"';
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final indent = row.depth * 16.0;
    final keyStyle = TextStyle(fontSize: 12, color: AppColors.primaryHover, fontFamily: 'monospace');
    final punctStyle = TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'monospace');

    switch (row.kind) {
      case _FlatJsonRowKind.expandableHeader:
        final openBracket = row.isMap ? '{' : '[';
        final closeBracket = row.isMap ? '}' : ']';
        final preview = row.isMap
            ? (row.childCount == 0 ? '{}' : '{…} (${row.childCount} key${row.childCount == 1 ? '' : 's'})')
            : (row.childCount == 0 ? '[]' : '[…] (${row.childCount} item${row.childCount == 1 ? '' : 's'})');

        return Padding(
          padding: EdgeInsets.only(left: indent, top: 1, bottom: 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InkWell(
                onTap: onToggleExpand,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  child: Icon(
                    row.isExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              if (row.keyLabel != null) ...[
                SelectableText.rich(
                  _buildHighlightedSpan(
                    text: row.keyLabel!.startsWith('[') ? row.keyLabel! : '"${row.keyLabel!}"',
                    baseStyle: keyStyle,
                    highlight: highlight,
                    isActiveRow: isActiveMatch,
                  ),
                ),
                Text(': ', style: punctStyle),
              ],
              InkWell(
                onTap: onToggleExpand,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  child: Text(
                    row.isExpanded ? openBracket : '$preview $closeBracket',
                    style: punctStyle,
                  ),
                ),
              ),
            ],
          ),
        );

      case _FlatJsonRowKind.closingBracket:
        return Padding(
          padding: EdgeInsets.only(left: indent + 16.0, top: 1, bottom: 1),
          child: Text(
            row.isMap ? '}' : ']',
            style: punctStyle,
          ),
        );

      case _FlatJsonRowKind.leaf:
        final valText = _stringify(row.value);
        final valStyle = TextStyle(fontSize: 12, color: _valueColor(row.value), fontFamily: 'monospace');

        return Padding(
          padding: EdgeInsets.only(left: indent + 16.0, top: 1, bottom: 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SelectableText.rich(
                  TextSpan(
                    children: [
                      if (row.keyLabel != null) ...[
                        _buildHighlightedSpan(
                          text: row.keyLabel!.startsWith('[') ? row.keyLabel! : '"${row.keyLabel!}"',
                          baseStyle: keyStyle,
                          highlight: highlight,
                          isActiveRow: isActiveMatch,
                        ),
                        TextSpan(text: ': ', style: punctStyle),
                      ],
                      _buildHighlightedSpan(
                        text: valText,
                        baseStyle: valStyle,
                        highlight: highlight,
                        isActiveRow: isActiveMatch,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}



class _QueryParamEditorRow extends StatefulWidget {
  final KeyValuePair param;
  final ValueChanged<KeyValuePair> onChanged;
  final VoidCallback onRemove;

  const _QueryParamEditorRow({
    super.key,
    required this.param,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<_QueryParamEditorRow> createState() => _QueryParamEditorRowState();
}

class _QueryParamEditorRowState extends State<_QueryParamEditorRow> {
  late TextEditingController _keyController;
  late TextEditingController _valController;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.param.key);
    _valController = TextEditingController(text: widget.param.value);
  }

  @override
  void didUpdateWidget(covariant _QueryParamEditorRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_keyController.text != widget.param.key) {
      final sel = _keyController.selection;
      _keyController.text = widget.param.key;
      if (sel.start <= widget.param.key.length && sel.end <= widget.param.key.length) {
        _keyController.selection = sel;
      }
    }
    if (_valController.text != widget.param.value) {
      final sel = _valController.selection;
      _valController.text = widget.param.value;
      if (sel.start <= widget.param.value.length && sel.end <= widget.param.value.length) {
        _valController.selection = sel;
      }
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Checkbox(
            value: widget.param.isEnabled,
            onChanged: (val) => widget.onChanged(
              KeyValuePair(key: widget.param.key, value: widget.param.value, isEnabled: val ?? true),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _keyController,
              onChanged: (val) => widget.onChanged(
                KeyValuePair(key: val, value: widget.param.value, isEnabled: widget.param.isEnabled),
              ),
              decoration: const InputDecoration(
                hintText: 'Key',
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _valController,
              onChanged: (val) => widget.onChanged(
                KeyValuePair(key: widget.param.key, value: val, isEnabled: widget.param.isEnabled),
              ),
              decoration: const InputDecoration(
                hintText: 'Value',
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: AppColors.textMuted),
            onPressed: widget.onRemove,
          ),
        ],
      ),
    );
  }
}
