import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/desktop_split_pane.dart';
import '../../../core/widgets/method_badge.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../../domain/models/mock_rule.dart';
import '../view_models/mocks_view_model.dart';

class MocksView extends StatefulWidget {
  const MocksView({super.key});

  @override
  State<MocksView> createState() => _MocksViewState();
}

class _MocksViewState extends State<MocksView> {
  late TextEditingController _nameController;
  late TextEditingController _urlPatternController;
  late TextEditingController _matchBodyController;
  late TextEditingController _bodyController;
  late TextEditingController _delayController;
  late TextEditingController _statusCodeController;
  late TextEditingController _statusReasonController;

  @override
  void initState() {
    super.initState();
    final vm = context.read<MocksViewModel>();
    final rule = vm.editingRule;
    _nameController = TextEditingController(text: rule?.name ?? '');
    _urlPatternController = TextEditingController(text: rule?.urlPattern ?? '');
    _matchBodyController = TextEditingController(text: rule?.matchBody ?? '');
    _bodyController = TextEditingController(text: rule?.responseBody ?? '');
    _delayController = TextEditingController(text: rule?.responseDelayMs.toString() ?? '0');
    _statusCodeController = TextEditingController(text: rule?.responseStatusCode.toString() ?? '200');
    _statusReasonController = TextEditingController(text: rule?.responseStatusReason ?? 'OK');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlPatternController.dispose();
    _matchBodyController.dispose();
    _bodyController.dispose();
    _delayController.dispose();
    _statusCodeController.dispose();
    _statusReasonController.dispose();
    super.dispose();
  }

  void _syncControllers(MocksViewModel vm) {
    final rule = vm.editingRule;
    if (rule == null) return;
    if (_nameController.text != rule.name) _nameController.text = rule.name;
    if (_urlPatternController.text != rule.urlPattern) _urlPatternController.text = rule.urlPattern;
    if (_matchBodyController.text != rule.matchBody) _matchBodyController.text = rule.matchBody;
    if (_bodyController.text != rule.responseBody) _bodyController.text = rule.responseBody;
    if (_delayController.text != rule.responseDelayMs.toString()) {
      _delayController.text = rule.responseDelayMs.toString();
    }
    if (_statusCodeController.text != rule.responseStatusCode.toString()) {
      _statusCodeController.text = rule.responseStatusCode.toString();
    }
    if (_statusReasonController.text != rule.responseStatusReason) {
      _statusReasonController.text = rule.responseStatusReason;
    }
  }

  void _insertVariableIntoBody(String variableName, MocksViewModel vm) {
    final text = _bodyController.text;
    final selection = _bodyController.selection;
    final placeholder = '{{$variableName}}';

    if (selection.isValid && selection.start >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, placeholder);
      _bodyController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + placeholder.length),
      );
    } else {
      final newText = text.isEmpty ? placeholder : '$text $placeholder';
      _bodyController.text = newText;
    }
    vm.updateEditingField(responseBody: _bodyController.text);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MocksViewModel>();
    _syncControllers(vm);

    return Scaffold(
      body: DesktopSplitPane(
        initialRatio: 0.32,
        minFirstRatio: 0.22,
        maxFirstRatio: 0.48,
        firstChild: _buildRulesList(context, vm),
        secondChild: _buildRuleEditor(context, vm),
      ),
    );
  }

  Widget _buildRulesList(BuildContext context, MocksViewModel vm) {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          // Toolbar with Projects & Import/Export
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: AppColors.surfaceLight,
            child: Column(
              children: [
                // Project Switcher Row
                Row(
                  children: [
                    Icon(Icons.folder_open_rounded, size: 16, color: AppColors.primaryHover),
                    const SizedBox(width: 6),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: vm.projects.contains(vm.selectedProject) ? vm.selectedProject : 'All Projects',
                          isExpanded: true,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMain),
                          dropdownColor: AppColors.surfaceLight,
                          items: vm.projects.map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(p, overflow: TextOverflow.ellipsis),
                          )).toList(),
                          onChanged: (val) {
                            if (val != null) vm.setSelectedProject(val);
                          },
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.create_new_folder_outlined, size: 16, color: AppColors.textSecondary),
                      tooltip: 'New Project',
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      onPressed: () => _showNewProjectDialog(context, vm),
                    ),
                    if (vm.selectedProject != 'All Projects' && vm.selectedProject != 'Default Project') ...[
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.methodDelete),
                        tooltip: 'Delete Project "${vm.selectedProject}"',
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        onPressed: () => _confirmDeleteProject(context, vm, vm.selectedProject),
                      ),
                    ],
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(Icons.file_upload_outlined, size: 16, color: AppColors.textSecondary),
                      tooltip: 'Import Rules (.json file)',
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      onPressed: () => _handleImport(context, vm),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(Icons.file_download_outlined, size: 16, color: AppColors.textSecondary),
                      tooltip: 'Export Rules (.json file)',
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      onPressed: () => _handleExport(context, vm),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: Icon(Icons.add_circle, size: 20, color: AppColors.primary),
                      tooltip: 'New Mock Rule',
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      onPressed: () => vm.createNewRule(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 34,
                  child: TextField(
                    onChanged: vm.setSearchFilter,
                    style: const TextStyle(fontSize: 12),
                    textAlignVertical: TextAlignVertical.center,
                    decoration: const InputDecoration(
                      hintText: 'Filter rules in project...',
                      prefixIcon: Icon(Icons.search, size: 14),
                      prefixIconConstraints: BoxConstraints(minWidth: 32, minHeight: 32),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Rules List
          Expanded(
            child: vm.rules.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.rule_folder_outlined, size: 36, color: AppColors.primaryHover),
                          const SizedBox(height: 10),
                          Text(
                            vm.selectedProject != 'All Projects'
                                ? 'Project: "${vm.selectedProject}"'
                                : 'No Mock Rules',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMain),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            vm.selectedProject != 'All Projects'
                                ? 'This project has no rules yet.\nClick "+" to create a rule or import a JSON file.'
                                : 'No mock rules found.\nClick "+" to create a rule or import a JSON file.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4),
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: () => vm.createNewRule(),
                            icon: const Icon(Icons.add, size: 14),
                            label: Text(
                              vm.selectedProject != 'All Projects'
                                  ? 'Add Rule to "${vm.selectedProject}"'
                                  : 'New Mock Rule',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: vm.rules.length,
                    itemBuilder: (context, index) {
                      final rule = vm.rules[index];
                      final isSelected = vm.editingRule?.id == rule.id;

                      return InkWell(
                        onTap: () => vm.selectRule(rule),
                        child: Container(
                          color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Transform.scale(
                                    scale: 0.75,
                                    child: Switch(
                                      value: rule.isEnabled,
                                      onChanged: (val) => vm.toggleRule(rule.id, val),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  MethodBadge(method: rule.matchMethod),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      rule.name,
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  StatusBadge(statusCode: rule.responseStatusCode, isMocked: true),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 48, top: 2),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        rule.urlPattern.isEmpty ? '*' : rule.urlPattern,
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (rule.conditions.isNotEmpty) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        child: Text(
                                          '${rule.conditions.length} ${rule.conditionLogic}',
                                          style: TextStyle(fontSize: 8, color: AppColors.primaryHover, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleEditor(BuildContext context, MocksViewModel vm) {
    final rule = vm.editingRule;

    if (rule == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.folder_open_outlined, size: 48, color: AppColors.primaryHover),
              const SizedBox(height: 16),
              Text(
                vm.selectedProject != 'All Projects'
                    ? 'Project: ${vm.selectedProject}'
                    : 'No Mock Rule Selected',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textMain),
              ),
              const SizedBox(height: 8),
              Text(
                vm.selectedProject != 'All Projects'
                    ? 'This project currently has no mock rules selected.\nClick below to create the first rule in "${vm.selectedProject}".'
                    : 'Select a mock rule from the list on the left, or create a new one.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => vm.createNewRule(),
                icon: const Icon(Icons.add, size: 16),
                label: Text(
                  vm.selectedProject != 'All Projects'
                      ? 'Add First Rule to "${vm.selectedProject}"'
                      : 'Create New Mock Rule',
                ),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Editor Header (Responsive & Sleek)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              // Rule active status toggle
              Tooltip(
                message: rule.isEnabled ? 'Mock Rule is Active' : 'Mock Rule is Disabled',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch.adaptive(
                      value: rule.isEnabled,
                      activeThumbColor: AppColors.primary,
                      onChanged: (v) => vm.updateEditingField(isEnabled: v),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rule.isEnabled ? 'Active' : 'Disabled',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: rule.isEnabled ? AppColors.statusSuccess : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Rule Name (Flexible, expands nicely)
              Expanded(
                child: TextField(
                  controller: _nameController,
                  onChanged: (v) => vm.updateEditingField(name: v),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Rule Name...',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.normal),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Project Indicator / Selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder_outlined, size: 14, color: AppColors.primaryHover),
                    const SizedBox(width: 6),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: vm.projects.contains(rule.projectName) ? rule.projectName : 'Default Project',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMain),
                        dropdownColor: AppColors.surface,
                        isDense: true,
                        items: vm.projects.where((p) => p != 'All Projects').map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) vm.updateEditingField(projectName: val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Delete Rule Button
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.methodDelete),
                tooltip: 'Delete Rule',
                onPressed: () => vm.deleteRule(rule.id),
              ),
              const SizedBox(width: 6),
              // Save Rule Button
              ElevatedButton.icon(
                onPressed: () async {
                  await vm.saveCurrentRule();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mock rule saved successfully!')),
                    );
                  }
                },
                icon: const Icon(Icons.check, size: 15),
                label: const Text('Save Rule'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
        ),

        // Matching & Response Form
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Matching Criteria Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.tune_rounded, size: 16, color: AppColors.primaryHover),
                          const SizedBox(width: 8),
                          Text(
                            '1. Request Matching Criteria',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMain),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Unified Modern URL Endpoint Bar ──
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: rule.isRegex ? AppColors.primary.withValues(alpha: 0.7) : AppColors.border,
                            width: rule.isRegex ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // HTTP Method dropdown badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getMethodColor(rule.matchMethod).withValues(alpha: 0.12),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(7),
                                  bottomLeft: Radius.circular(7),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: rule.matchMethod,
                                  isDense: true,
                                  dropdownColor: AppColors.surface,
                                  icon: Icon(Icons.arrow_drop_down, size: 16, color: _getMethodColor(rule.matchMethod)),
                                  selectedItemBuilder: (context) {
                                    return ['ALL', 'GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS'].map((m) {
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
                                  items: ['ALL', 'GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS'].map((m) {
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
                                  onChanged: (v) {
                                    if (v != null) vm.updateEditingField(matchMethod: v);
                                  },
                                ),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 28,
                              color: AppColors.border,
                            ),
                            // URL Pattern TextField
                            Expanded(
                              child: TextField(
                                controller: _urlPatternController,
                                onChanged: (v) => vm.updateEditingField(urlPattern: v),
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: rule.isRegex
                                      ? r'RegExp pattern (e.g. ^/api/v1/.*$)'
                                      : 'URL pattern (e.g. /api/users/* or *dashboard*)',
                                  hintStyle: TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.textMuted),
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
                            // Clear button
                            if (_urlPatternController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 14),
                                tooltip: 'Clear pattern',
                                color: AppColors.textMuted,
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  _urlPatternController.clear();
                                  vm.updateEditingField(urlPattern: '');
                                },
                              ),
                            const SizedBox(width: 4),
                            // RegExp toggle badge button
                            Tooltip(
                              message: 'Toggle Regular Expression (RegExp) pattern matching',
                              child: InkWell(
                                onTap: () => vm.updateEditingField(isRegex: !rule.isRegex),
                                borderRadius: BorderRadius.circular(5),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: rule.isRegex ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: rule.isRegex ? AppColors.primary : AppColors.border,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '.*',
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                          color: rule.isRegex ? AppColors.primary : AppColors.textMuted,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'RegExp',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: rule.isRegex ? FontWeight.bold : FontWeight.normal,
                                          color: rule.isRegex ? AppColors.primary : AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Helper text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 12, color: AppColors.textMuted),
                              const SizedBox(width: 6),
                              Text(
                                rule.isRegex
                                    ? 'RegExp active: Evaluates URL / Path using regular expression matching.'
                                    : 'Wildcard mode: Supports * for partial paths (e.g. */api/* or *dashboard*).',
                                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 14),

                      // Conditions with AND / OR Logic
                      _buildConditionsSection(context, vm, rule),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Simulated Response Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.send_outlined, size: 16, color: AppColors.primaryHover),
                          const SizedBox(width: 8),
                          Text(
                            '2. Mock Response Configuration',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMain),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Status & Timing Bar ──
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Status code & Reason container
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _getStatusColor(rule.responseStatusCode),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Status',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                                ),
                                const SizedBox(width: 6),
                                SizedBox(
                                  width: 45,
                                  child: TextField(
                                    controller: _statusCodeController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace'),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      hintText: '200',
                                    ),
                                    onChanged: (v) {
                                      final code = int.tryParse(v);
                                      if (code != null) vm.updateEditingField(responseStatusCode: code);
                                    },
                                  ),
                                ),
                                Container(width: 1, height: 16, color: AppColors.border, margin: const EdgeInsets.symmetric(horizontal: 6)),
                                SizedBox(
                                  width: 80,
                                  child: TextField(
                                    controller: _statusReasonController,
                                    style: TextStyle(fontSize: 12, color: AppColors.textMain),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      hintText: 'OK',
                                    ),
                                    onChanged: (v) => vm.updateEditingField(responseStatusReason: v),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Delay
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.timer_outlined, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  'Delay',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                                ),
                                const SizedBox(width: 6),
                                SizedBox(
                                  width: 40,
                                  child: TextField(
                                    controller: _delayController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'monospace'),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      hintText: '0',
                                    ),
                                    onChanged: (v) {
                                      final delay = int.tryParse(v);
                                      if (delay != null) vm.updateEditingField(responseDelayMs: delay);
                                    },
                                  ),
                                ),
                                Text('ms', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              ],
                            ),
                          ),

                          // Status code quick presets
                          ...[
                            const MapEntry(200, 'OK'),
                            const MapEntry(201, 'Created'),
                            const MapEntry(400, 'Bad Request'),
                            const MapEntry(404, 'Not Found'),
                            const MapEntry(500, 'Server Error'),
                          ].map((preset) {
                            final isSelected = rule.responseStatusCode == preset.key;
                            return InkWell(
                              onTap: () {
                                _statusCodeController.text = preset.key.toString();
                                _statusReasonController.text = preset.value;
                                vm.updateEditingField(
                                  responseStatusCode: preset.key,
                                  responseStatusReason: preset.value,
                                );
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSelected ? _getStatusColor(preset.key).withValues(alpha: 0.15) : AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isSelected ? _getStatusColor(preset.key) : AppColors.border,
                                  ),
                                ),
                                child: Text(
                                  '${preset.key}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? _getStatusColor(preset.key) : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Mock Response Headers
                      _buildKeyValueListSection(
                        context: context,
                        title: 'Mock Response Headers (${rule.responseHeaders.length})',
                        addLabel: 'Add Header',
                        items: rule.responseHeaders,
                        onAdd: (k, v) => vm.addResponseHeader(k, v),
                        onRemove: (k) => vm.removeResponseHeader(k),
                        quickAddOptions: const [
                          MapEntry('content-type', 'application/json; charset=utf-8'),
                          MapEntry('access-control-allow-origin', '*'),
                          MapEntry('cache-control', 'no-cache'),
                        ],
                        emptyMessage: 'No custom response headers configured.',
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      // Custom Variables
                      _buildCustomVariablesSection(context, vm, rule),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      // Response Body Editor with Integrated Variables Toolbar
                      _buildResponseBodySection(context, vm, rule),
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

  // --- Conditions Section with AND / OR Logic ---
  Widget _buildConditionsSection(BuildContext context, MocksViewModel vm, MockRule rule) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Icon(Icons.rule_folder_outlined, size: 16, color: AppColors.primaryHover),
              const SizedBox(width: 8),
              Text(
                'Matching Conditions (${rule.conditions.length})',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMain),
              ),
              const SizedBox(width: 14),
              // Logic Selector: AND vs OR
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    _buildLogicTab(
                      label: 'AND (Match ALL)',
                      isSelected: rule.conditionLogic.toUpperCase() == 'AND',
                      onTap: () => vm.setConditionLogic('AND'),
                    ),
                    _buildLogicTab(
                      label: 'OR (Match ANY)',
                      isSelected: rule.conditionLogic.toUpperCase() == 'OR',
                      onTap: () => vm.setConditionLogic('OR'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => vm.addCondition(),
                icon: const Icon(Icons.add, size: 13),
                label: const Text('Add Condition', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        if (rule.conditions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, size: 15, color: AppColors.statusSuccess),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No additional conditions. Matches all requests matching the URL Pattern.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    vm.addCondition(
                      source: ConditionSource.any,
                      field: 'isUserType',
                      operator: ConditionOperator.equals,
                      value: 'project manager',
                    );
                    vm.addCondition(
                      source: ConditionSource.any,
                      field: 'userid',
                      operator: ConditionOperator.equals,
                      value: '5',
                    );
                  },
                  child: const Text('Add Example (isUserType & userid)', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          )
        else
          ...rule.conditions.asMap().entries.map((entry) {
            final idx = entry.key;
            final cond = entry.value;

            return _ConditionRowItem(
              key: ValueKey('cond_${cond.id}'),
              index: idx,
              condition: cond,
              onChanged: (updated) => vm.updateCondition(idx, updated),
              onRemove: () => vm.removeCondition(idx),
            );
          }),
      ],
    );
  }

  Widget _buildLogicTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // --- Custom Variables Section ---
  Widget _buildCustomVariablesSection(BuildContext context, MocksViewModel vm, MockRule rule) {
    return _buildKeyValueListSection(
      context: context,
      title: 'Custom Variables (${rule.customVariables.length})',
      addLabel: 'Add Variable',
      items: rule.customVariables,
      onAdd: (k, v) => vm.addCustomVariable(k, v),
      onRemove: (k) => vm.removeCustomVariable(k),
      quickAddOptions: const [
        MapEntry('user_role', 'Administrator'),
        MapEntry('company', 'ApiLab Enterprise'),
        MapEntry('custom_variable', 'Custom Value'),
      ],
      emptyMessage: 'No custom variables defined. Variables can be referenced in Response Body as {{variable_name}}.',
    );
  }

  // --- Response Body Section with Integrated Variables Toolbar ---
  Widget _buildResponseBodySection(BuildContext context, MocksViewModel vm, MockRule rule) {
    final variableChips = <String>{
      'uuid',
      'timestamp',
      'date',
      'random_int',
      'method',
      'url',
      'path',
    };

    for (final c in rule.conditions) {
      if (c.field.trim().isNotEmpty) {
        variableChips.add(c.field.trim());
      }
    }

    rule.customVariables.forEach((k, _) {
      if (k.trim().isNotEmpty) {
        variableChips.add(k.trim());
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title and quick actions
        Row(
          children: [
            Icon(Icons.data_object_rounded, size: 15, color: AppColors.primaryHover),
            const SizedBox(width: 8),
            Text(
              'Response Body (JSON / Text)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMain),
            ),
            const Spacer(),
            // Prettify JSON button
            TextButton.icon(
              onPressed: vm.formatEditingBodyJson,
              icon: const Icon(Icons.auto_fix_high, size: 13),
              label: const Text('Prettify JSON', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
            const SizedBox(width: 4),
            // Copy body button
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _bodyController.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Response body copied to clipboard!')),
                );
              },
              icon: const Icon(Icons.copy, size: 13),
              label: const Text('Copy', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Variable Insertion Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(Icons.code_rounded, size: 13, color: AppColors.primaryHover),
              const SizedBox(width: 6),
              Text(
                'Insert Variable:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: variableChips.map((v) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          backgroundColor: AppColors.surface,
                          side: BorderSide(color: AppColors.borderSubtle),
                          label: Text(
                            '{{$v}}',
                            style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.primaryHover),
                          ),
                          onPressed: () => _insertVariableIntoBody(v, vm),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Editor Box
        Container(
          height: 260,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(6),
            ),
            border: Border(
              left: BorderSide(color: AppColors.border),
              right: BorderSide(color: AppColors.border),
              bottom: BorderSide(color: AppColors.border),
            ),
          ),
          child: TextField(
            controller: _bodyController,
            onChanged: (v) => vm.updateEditingField(responseBody: v),
            maxLines: null,
            expands: true,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.45),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
              hintText: '{\n  "user_type": "{{isUserType}}",\n  "userid": {{userid}},\n  "Others": "{{custom_variable}}"\n}',
              hintStyle: TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.textMuted),
            ),
          ),
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

  Color _getStatusColor(int code) {
    if (code >= 200 && code < 300) return AppColors.statusSuccess;
    if (code >= 300 && code < 400) return AppColors.statusRedirect;
    if (code >= 400 && code < 500) return AppColors.statusClientError;
    if (code >= 500) return AppColors.statusServerError;
    return AppColors.textSecondary;
  }

  // --- Dialogs: Projects, Import, Export, AI ---

  void _showNewProjectDialog(BuildContext context, MocksViewModel vm) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.create_new_folder_outlined, color: AppColors.primaryHover, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Create New Project',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 360,
          child: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Project Name',
              hintText: 'e.g. E-Commerce APIs, Auth Service',
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                vm.createProject(name);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Project "$name" created!')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProject(BuildContext context, MocksViewModel vm, String projectName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.methodDelete, size: 20),
            SizedBox(width: 8),
            Text('Delete Project'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete project "$projectName"?\n\nAll mock rules in this project will also be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.methodDelete),
            onPressed: () async {
              Navigator.pop(ctx);
              await vm.deleteProject(projectName);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Project "$projectName" deleted')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExport(BuildContext context, MocksViewModel vm) async {
    try {
      if (Platform.isMacOS) {
        await FilePickerPlatform.instance.skipEntitlementsChecks();
      }
      final selectedDirectory = await FilePicker.getDirectoryPath(
        dialogTitle: 'Select Folder to Export Mock Rules (.json)',
      );
      if (selectedDirectory != null) {
        final path = await vm.exportToFolder(
          selectedDirectory,
          project: vm.selectedProject != 'All Projects' ? vm.selectedProject : null,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mock rules exported to: $path')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export rules: $e')),
        );
      }
    }
  }

  Future<void> _handleImport(BuildContext context, MocksViewModel vm) async {
    try {
      if (Platform.isMacOS) {
        await FilePickerPlatform.instance.skipEntitlementsChecks();
      }
      final result = await FilePicker.pickFile(
        dialogTitle: 'Select Mock Rules JSON File to Import',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null && result.path != null) {
        final filePath = result.path!;
        final count = await vm.importFromFile(
          filePath,
          targetProject: vm.selectedProject != 'All Projects' ? vm.selectedProject : null,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully imported $count mock rules into "${vm.selectedProject != 'All Projects' ? vm.selectedProject : 'Default Project'}"!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import rules: $e')),
        );
      }
    }
  }


  Widget _buildKeyValueListSection({
    required BuildContext context,
    required String title,
    required String addLabel,
    required Map<String, String> items,
    required Function(String key, String value) onAdd,
    required Function(String key) onRemove,
    List<MapEntry<String, String>> quickAddOptions = const [],
    String emptyMessage = 'No items configured.',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textMain),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _showAddKeyValueDialog(
                context: context,
                title: addLabel,
                keyLabel: 'Key / Name',
                valueLabel: 'Expected Value',
                onAdd: onAdd,
              ),
              icon: const Icon(Icons.add, size: 13),
              label: Text(addLabel, style: const TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        if (quickAddOptions.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: quickAddOptions.map((opt) {
              String displayLabel = opt.key;
              if (opt.key == 'content-type') {
                displayLabel = '+ JSON';
              } else if (opt.key == 'access-control-allow-origin') {
                displayLabel = '+ CORS (*)';
              } else if (opt.key == 'cache-control') {
                displayLabel = '+ No-Cache';
              } else if (opt.key.length > 20) {
                displayLabel = '+ ${opt.key.substring(0, 18)}…';
              } else {
                displayLabel = '+ ${opt.key}';
              }

              return ActionChip(
                visualDensity: VisualDensity.compact,
                backgroundColor: AppColors.surfaceLight,
                side: BorderSide(color: AppColors.borderSubtle),
                tooltip: '${opt.key}: ${opt.value}',
                label: Text(displayLabel, style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
                onPressed: () => onAdd(opt.key, opt.value),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 6),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(emptyMessage, style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          )
        else
          ...items.entries.map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Text(
                      entry.key,
                      style: TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: AppColors.primaryHover),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textMain),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.copy_outlined, size: 13, color: AppColors.textMuted),
                    tooltip: 'Copy value',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: entry.value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Copied "${entry.value}" to clipboard'), duration: const Duration(seconds: 1)),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.close, size: 14, color: AppColors.textMuted),
                    tooltip: 'Remove',
                    onPressed: () => onRemove(entry.key),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  void _showAddKeyValueDialog({
    required BuildContext context,
    required String title,
    required String keyLabel,
    required String valueLabel,
    required Function(String key, String value) onAdd,
  }) {
    final keyCtrl = TextEditingController();
    final valCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 15)),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyCtrl,
                autofocus: true,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: InputDecoration(labelText: keyLabel),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: valCtrl,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: InputDecoration(labelText: valueLabel),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final k = keyCtrl.text.trim();
              final v = valCtrl.text.trim();
              if (k.isNotEmpty) {
                onAdd(k, v);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _ConditionRowItem extends StatefulWidget {
  final int index;
  final MockCondition condition;
  final ValueChanged<MockCondition> onChanged;
  final VoidCallback onRemove;

  const _ConditionRowItem({
    super.key,
    required this.index,
    required this.condition,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<_ConditionRowItem> createState() => _ConditionRowItemState();
}

class _ConditionRowItemState extends State<_ConditionRowItem> {
  late TextEditingController _fieldController;
  late TextEditingController _valController;
  final FocusNode _fieldFocusNode = FocusNode();
  final FocusNode _valFocusNode = FocusNode();
  bool _isFieldFocused = false;
  bool _isValFocused = false;

  @override
  void initState() {
    super.initState();
    _fieldController = TextEditingController(text: widget.condition.field);
    _valController = TextEditingController(text: widget.condition.value);

    _fieldFocusNode.addListener(() {
      if (mounted) setState(() => _isFieldFocused = _fieldFocusNode.hasFocus);
    });
    _valFocusNode.addListener(() {
      if (mounted) setState(() => _isValFocused = _valFocusNode.hasFocus);
    });
  }

  @override
  void didUpdateWidget(covariant _ConditionRowItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_fieldController.text != widget.condition.field) {
      final sel = _fieldController.selection;
      _fieldController.text = widget.condition.field;
      if (sel.start <= widget.condition.field.length && sel.end <= widget.condition.field.length) {
        _fieldController.selection = sel;
      }
    }
    if (_valController.text != widget.condition.value) {
      final sel = _valController.selection;
      _valController.text = widget.condition.value;
      if (sel.start <= widget.condition.value.length && sel.end <= widget.condition.value.length) {
        _valController.selection = sel;
      }
    }
  }

  @override
  void dispose() {
    _fieldController.dispose();
    _valController.dispose();
    _fieldFocusNode.dispose();
    _valFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cond = widget.condition;
    const double rowHeight = 34.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Active toggle checkbox
          SizedBox(
            height: rowHeight,
            child: Checkbox(
              value: cond.isEnabled,
              visualDensity: VisualDensity.compact,
              onChanged: (val) => widget.onChanged(cond.copyWith(isEnabled: val ?? true)),
            ),
          ),
          const SizedBox(width: 4),

          // Source dropdown
          Container(
            height: rowHeight,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ConditionSource>(
                value: cond.source,
                isDense: true,
                dropdownColor: AppColors.surface,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMain),
                items: const [
                  DropdownMenuItem(value: ConditionSource.any, child: Text('Any (Auto)')),
                  DropdownMenuItem(value: ConditionSource.query, child: Text('Query Param')),
                  DropdownMenuItem(value: ConditionSource.body, child: Text('JSON Body')),
                  DropdownMenuItem(value: ConditionSource.header, child: Text('Header')),
                ],
                onChanged: (v) {
                  if (v != null) widget.onChanged(cond.copyWith(source: v));
                },
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Field name input box
          Expanded(
            flex: 2,
            child: Container(
              height: rowHeight,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _isFieldFocused ? AppColors.primary : AppColors.border,
                  width: _isFieldFocused ? 1.2 : 1.0,
                ),
              ),
              alignment: Alignment.centerLeft,
              child: TextField(
                controller: _fieldController,
                focusNode: _fieldFocusNode,
                onChanged: (v) => widget.onChanged(cond.copyWith(field: v)),
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  isCollapsed: true,
                  hintText: 'Field (e.g. isUserType)',
                  hintStyle: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  filled: false,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Operator dropdown
          Container(
            height: rowHeight,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ConditionOperator>(
                value: cond.operator,
                isDense: true,
                dropdownColor: AppColors.surface,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryHover),
                items: const [
                  DropdownMenuItem(value: ConditionOperator.equals, child: Text('= (equals)')),
                  DropdownMenuItem(value: ConditionOperator.notEquals, child: Text('!= (not equals)')),
                  DropdownMenuItem(value: ConditionOperator.contains, child: Text('contains')),
                  DropdownMenuItem(value: ConditionOperator.greaterThan, child: Text('> (greater)')),
                  DropdownMenuItem(value: ConditionOperator.lessThan, child: Text('< (less)')),
                  DropdownMenuItem(value: ConditionOperator.greaterThanOrEqual, child: Text('>= (greater/equal)')),
                  DropdownMenuItem(value: ConditionOperator.lessThanOrEqual, child: Text('<= (less/equal)')),
                  DropdownMenuItem(value: ConditionOperator.regex, child: Text('regex (pattern)')),
                ],
                onChanged: (v) {
                  if (v != null) widget.onChanged(cond.copyWith(operator: v));
                },
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Value input box
          Expanded(
            flex: 3,
            child: Container(
              height: rowHeight,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _isValFocused ? AppColors.primary : AppColors.border,
                  width: _isValFocused ? 1.2 : 1.0,
                ),
              ),
              alignment: Alignment.centerLeft,
              child: TextField(
                controller: _valController,
                focusNode: _valFocusNode,
                onChanged: (v) => widget.onChanged(cond.copyWith(value: v)),
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  isCollapsed: true,
                  hintText: 'Value (e.g. project manager)',
                  hintStyle: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  filled: false,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Remove condition button
          SizedBox(
            height: rowHeight,
            width: rowHeight,
            child: IconButton(
              icon: Icon(Icons.close, size: 16, color: AppColors.textMuted),
              tooltip: 'Remove Condition',
              padding: EdgeInsets.zero,
              onPressed: widget.onRemove,
            ),
          ),
        ],
      ),
    );
  }
}
