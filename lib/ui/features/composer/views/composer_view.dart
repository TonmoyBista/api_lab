import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/desktop_split_pane.dart';
import '../../../core/widgets/method_badge.dart';
import '../../../core/widgets/status_badge.dart';
import '../view_models/composer_view_model.dart';

class ComposerView extends StatefulWidget {
  const ComposerView({super.key});

  @override
  State<ComposerView> createState() => _ComposerViewState();
}

class _ComposerViewState extends State<ComposerView> {
  late TextEditingController _urlController;
  late TextEditingController _bodyController;
  late TextEditingController _bearerController;
  late TextEditingController _userController;
  late TextEditingController _passController;

  @override
  void initState() {
    super.initState();
    final vm = context.read<ComposerViewModel>();
    _urlController = TextEditingController(text: vm.currentRequest.url);
    _bodyController = TextEditingController(text: vm.currentRequest.bodyContent);
    _bearerController = TextEditingController(text: vm.currentRequest.authBearerToken);
    _userController = TextEditingController(text: vm.currentRequest.authUsername);
    _passController = TextEditingController(text: vm.currentRequest.authPassword);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _bodyController.dispose();
    _bearerController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _syncControllers(ComposerViewModel vm) {
    if (_urlController.text != vm.currentRequest.url) {
      final selection = _urlController.selection;
      _urlController.text = vm.currentRequest.url;
      if (selection.start <= vm.currentRequest.url.length && selection.end <= vm.currentRequest.url.length) {
        _urlController.selection = selection;
      }
    }
    if (_bodyController.text != vm.currentRequest.bodyContent) {
      final selection = _bodyController.selection;
      _bodyController.text = vm.currentRequest.bodyContent;
      if (selection.start <= vm.currentRequest.bodyContent.length && selection.end <= vm.currentRequest.bodyContent.length) {
        _bodyController.selection = selection;
      }
    }
    if (_bearerController.text != vm.currentRequest.authBearerToken) {
      _bearerController.text = vm.currentRequest.authBearerToken;
    }
    if (_userController.text != vm.currentRequest.authUsername) {
      _userController.text = vm.currentRequest.authUsername;
    }
    if (_passController.text != vm.currentRequest.authPassword) {
      _passController.text = vm.currentRequest.authPassword;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ComposerViewModel>();
    _syncControllers(vm);

    return Scaffold(
      body: DesktopSplitPane(
        initialRatio: 0.22,
        minFirstRatio: 0.16,
        maxFirstRatio: 0.35,
        firstChild: _buildCollectionsSidebar(context, vm),
        secondChild: _buildMainRequestArea(context, vm),
      ),
    );
  }

  Widget _buildCollectionsSidebar(BuildContext context, ComposerViewModel vm) {
    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            color: AppColors.surfaceLight,
            child: Row(
              children: [
                const Icon(Icons.folder_special_outlined, size: 16, color: AppColors.primaryHover),
                const SizedBox(width: 8),
                const Text(
                  'Collections',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textMain),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  tooltip: 'New Collection',
                  onPressed: () => _showCreateCollectionDialog(context, vm),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: vm.collections.length,
              itemBuilder: (context, colIdx) {
                final col = vm.collections[colIdx];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.folder_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              col.name,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMain),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.borderSubtle,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${col.requests.length}',
                              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...col.requests.map((req) {
                      final isCurrent = vm.currentRequest.id == req.id;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        child: InkWell(
                          onTap: () => vm.loadSavedRequest(req),
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: isCurrent ? AppColors.primary.withValues(alpha: 0.14) : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: isCurrent ? Border.all(color: AppColors.primary.withValues(alpha: 0.3)) : null,
                            ),
                            child: Row(
                              children: [
                                MethodBadge(method: req.method, fontSize: 8),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    req.name,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isCurrent ? AppColors.textMain : AppColors.textSecondary,
                                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 6),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainRequestArea(BuildContext context, ComposerViewModel vm) {
    return Column(
      children: [
        // Request bar
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.surface,
          child: Row(
            children: [
              // Method dropdown
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: vm.currentRequest.method,
                    dropdownColor: AppColors.surfaceLight,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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
              // URL input
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _urlController,
                    onChanged: vm.updateUrl,
                    style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                    decoration: const InputDecoration(
                      hintText: 'Enter request URL (e.g. https://api.example.com/data)',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Send button
              ElevatedButton.icon(
                onPressed: vm.isLoading ? null : vm.sendRequest,
                icon: vm.isLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 15),
                label: const Text('Send'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                ),
              ),
              const SizedBox(width: 8),
              // Save button
              OutlinedButton.icon(
                onPressed: () => _showSaveRequestDialog(context, vm),
                icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                label: const Text('Save'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Tabs & Content
        Expanded(
          child: DesktopSplitPane(
            initialRatio: 0.50,
            firstChild: _buildRequestEditorTabs(context, vm),
            secondChild: _buildResponseArea(context, vm),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestEditorTabs(BuildContext context, ComposerViewModel vm) {
    return Column(
      children: [
        Container(
          color: AppColors.surfaceLight,
          width: double.infinity,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTabButton(context, vm, 'params', 'Params (${vm.currentRequest.queryParams.length})'),
                _buildTabButton(context, vm, 'headers', 'Headers (${vm.currentRequest.headers.length})'),
                _buildTabButton(context, vm, 'body', 'Body (${vm.currentRequest.bodyType})'),
                _buildTabButton(context, vm, 'auth', 'Auth (${vm.currentRequest.authType})'),
              ],
            ),
          ),
        ),
        Expanded(
          child: _buildActiveTabContent(context, vm),
        ),
      ],
    );
  }

  Widget _buildTabButton(BuildContext context, ComposerViewModel vm, String tabKey, String label) {
    final isActive = vm.activeTab == tabKey;
    return InkWell(
      onTap: () => vm.setActiveTab(tabKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? AppColors.primaryHover : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(BuildContext context, ComposerViewModel vm) {
    switch (vm.activeTab) {
      case 'params':
        return _buildParamsTab(context, vm);
      case 'headers':
        return _buildHeadersTab(context, vm);
      case 'body':
        return _buildBodyTab(context, vm);
      case 'auth':
        return _buildAuthTab(context, vm);
      default:
        return const SizedBox();
    }
  }

  Widget _buildParamsTab(BuildContext context, ComposerViewModel vm) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              const Text('Query Parameters', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton.icon(
                onPressed: vm.addQueryParam,
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Add Param', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: vm.currentRequest.queryParams.length,
            itemBuilder: (context, index) {
              final p = vm.currentRequest.queryParams[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Checkbox(
                      value: p.isEnabled,
                      onChanged: (v) => vm.updateQueryParam(index, p.key, p.value, v ?? true),
                    ),
                    Expanded(
                      child: SizedBox(
                        height: 32,
                        child: TextFormField(
                          initialValue: p.key,
                          onChanged: (v) => vm.updateQueryParam(index, v, p.value, p.isEnabled),
                          decoration: const InputDecoration(hintText: 'Key'),
                          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 32,
                        child: TextFormField(
                          initialValue: p.value,
                          onChanged: (v) => vm.updateQueryParam(index, p.key, v, p.isEnabled),
                          decoration: const InputDecoration(hintText: 'Value'),
                          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.textMuted),
                      onPressed: () => vm.removeQueryParam(index),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeadersTab(BuildContext context, ComposerViewModel vm) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              const Text('Request Headers', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton.icon(
                onPressed: vm.addHeader,
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Add Header', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: vm.currentRequest.headers.length,
            itemBuilder: (context, index) {
              final h = vm.currentRequest.headers[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Checkbox(
                      value: h.isEnabled,
                      onChanged: (v) => vm.updateHeader(index, h.key, h.value, v ?? true),
                    ),
                    Expanded(
                      child: SizedBox(
                        height: 32,
                        child: TextFormField(
                          initialValue: h.key,
                          onChanged: (v) => vm.updateHeader(index, v, h.value, h.isEnabled),
                          decoration: const InputDecoration(hintText: 'Header Name'),
                          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 32,
                        child: TextFormField(
                          initialValue: h.value,
                          onChanged: (v) => vm.updateHeader(index, h.key, v, h.isEnabled),
                          decoration: const InputDecoration(hintText: 'Value'),
                          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.textMuted),
                      onPressed: () => vm.removeHeader(index),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBodyTab(BuildContext context, ComposerViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              const Text('Body Type:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(width: 8),
              for (final type in ['none', 'json', 'text', 'form'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(type.toUpperCase(), style: const TextStyle(fontSize: 10)),
                    selected: vm.currentRequest.bodyType == type,
                    onSelected: (selected) {
                      if (selected) vm.updateBodyType(type);
                    },
                  ),
                ),
              const Spacer(),
              if (vm.currentRequest.bodyType == 'json')
                TextButton.icon(
                  onPressed: vm.formatRequestBodyJson,
                  icon: const Icon(Icons.auto_fix_high, size: 14),
                  label: const Text('Prettify JSON', style: TextStyle(fontSize: 11)),
                ),
            ],
          ),
        ),
        if (vm.currentRequest.bodyType != 'none')
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: _bodyController,
                onChanged: vm.updateBodyContent,
                maxLines: null,
                expands: true,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: const InputDecoration(
                  hintText: 'Enter request body...',
                  alignLabelWithHint: true,
                ),
              ),
            ),
          )
        else
          const Expanded(
            child: Center(
              child: Text('This request does not have a body', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ),
          ),
      ],
    );
  }

  Widget _buildAuthTab(BuildContext context, ComposerViewModel vm) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Type: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: vm.currentRequest.authType,
                dropdownColor: AppColors.surfaceLight,
                items: [
                  const DropdownMenuItem(value: 'none', child: Text('No Auth')),
                  const DropdownMenuItem(value: 'bearer', child: Text('Bearer Token')),
                  const DropdownMenuItem(value: 'basic', child: Text('Basic Auth')),
                ],
                onChanged: (val) {
                  if (val != null) vm.updateAuthType(val);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (vm.currentRequest.authType == 'bearer') ...[
            const Text('Token', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _bearerController,
              onChanged: vm.updateBearerToken,
              decoration: const InputDecoration(hintText: 'Paste Bearer Token here'),
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ],
          if (vm.currentRequest.authType == 'basic') ...[
            const Text('Username', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _userController,
              onChanged: (v) => vm.updateBasicAuth(v, _passController.text),
              decoration: const InputDecoration(hintText: 'Username'),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            const Text('Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _passController,
              obscureText: true,
              onChanged: (v) => vm.updateBasicAuth(_userController.text, v),
              decoration: const InputDecoration(hintText: 'Password'),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResponseArea(BuildContext context, ComposerViewModel vm) {
    final res = vm.response;

    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Response metrics bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: AppColors.surfaceLight,
            child: Row(
              children: [
                const Text('Response', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const Spacer(),
                if (res != null) ...[
                  StatusBadge(statusCode: res.statusCode, statusReason: res.statusReason),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.borderSubtle,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('${res.durationMs} ms', style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.borderSubtle,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('${(res.sizeBytes / 1024).toStringAsFixed(2)} KB', style: const TextStyle(fontSize: 11)),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 14),
                    tooltip: 'Copy Body',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: res.body));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Response copied to clipboard!')),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          // Response body
          Expanded(
            child: res == null
                ? const Center(
                    child: Text(
                      'Hit "Send" to execute request and inspect response',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  )
                : DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        const TabBar(
                          isScrollable: true,
                          labelColor: AppColors.primaryHover,
                          tabs: [
                            Tab(text: 'Body'),
                            Tab(text: 'Headers'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: SingleChildScrollView(
                                  child: SelectableText(
                                    res.formattedBody.isEmpty ? '[No response body]' : res.formattedBody,
                                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.4),
                                  ),
                                ),
                              ),
                              ListView(
                                padding: const EdgeInsets.all(12),
                                children: res.headers.entries.map((e) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    child: Row(
                                      children: [
                                        SelectableText('${e.key}: ', style: const TextStyle(color: AppColors.primaryHover, fontSize: 12, fontFamily: 'monospace')),
                                        Expanded(
                                          child: SelectableText(e.value, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showCreateCollectionDialog(BuildContext context, ComposerViewModel vm) {
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Collection'),
        content: TextField(
          controller: textCtrl,
          decoration: const InputDecoration(hintText: 'Collection Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (textCtrl.text.trim().isNotEmpty) {
                vm.createCollection(textCtrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showSaveRequestDialog(BuildContext context, ComposerViewModel vm) {
    final nameCtrl = TextEditingController(text: vm.currentRequest.name);
    var selectedColId = vm.collections.isNotEmpty ? vm.collections.first.id : '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Save Request to Collection'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Request Name'),
              ),
              const SizedBox(height: 12),
              if (vm.collections.isNotEmpty)
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: selectedColId,
                  decoration: const InputDecoration(labelText: 'Target Collection'),
                  dropdownColor: AppColors.surfaceLight,
                  items: vm.collections
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedColId = v);
                  },
                )
              else
                const Text('No collections available. Create one first!'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                vm.updateRequestName(nameCtrl.text.trim());
                if (selectedColId.isNotEmpty) {
                  vm.saveToCollection(selectedColId);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Request saved to collection!')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
