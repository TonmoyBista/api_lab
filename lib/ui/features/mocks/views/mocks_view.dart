import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
                    const Icon(Icons.folder_open_rounded, size: 16, color: AppColors.primaryHover),
                    const SizedBox(width: 6),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: vm.projects.contains(vm.selectedProject) ? vm.selectedProject : 'All Projects',
                          isExpanded: true,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMain),
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
                      icon: const Icon(Icons.create_new_folder_outlined, size: 16, color: AppColors.textSecondary),
                      tooltip: 'New Project',
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      onPressed: () => _showNewProjectDialog(context, vm),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.file_upload_outlined, size: 16, color: AppColors.textSecondary),
                      tooltip: 'Import Rules (.json file)',
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      onPressed: () => _handleImport(context, vm),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.file_download_outlined, size: 16, color: AppColors.textSecondary),
                      tooltip: 'Export Rules (.json file)',
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      onPressed: () => _handleExport(context, vm),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.add_circle, size: 20, color: AppColors.primary),
                      tooltip: 'New Mock Rule',
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      onPressed: () => vm.createNewRule(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 32,
                  child: TextField(
                    onChanged: vm.setSearchFilter,
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'Filter rules in project...',
                      prefixIcon: Icon(Icons.search, size: 14),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          const Icon(Icons.rule_folder_outlined, size: 36, color: AppColors.primaryHover),
                          const SizedBox(height: 10),
                          Text(
                            vm.selectedProject != 'All Projects'
                                ? 'Project: "${vm.selectedProject}"'
                                : 'No Mock Rules',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMain),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            vm.selectedProject != 'All Projects'
                                ? 'This project has no rules yet.\nClick "+" to create a rule or import a JSON file.'
                                : 'No mock rules found.\nClick "+" to create a rule or import a JSON file.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4),
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
                                        style: const TextStyle(
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
                                          style: const TextStyle(fontSize: 8, color: AppColors.primaryHover, fontWeight: FontWeight.bold),
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
              const Icon(Icons.folder_open_outlined, size: 48, color: AppColors.primaryHover),
              const SizedBox(height: 16),
              Text(
                vm.selectedProject != 'All Projects'
                    ? 'Project: ${vm.selectedProject}'
                    : 'No Mock Rule Selected',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textMain),
              ),
              const SizedBox(height: 8),
              Text(
                vm.selectedProject != 'All Projects'
                    ? 'This project currently has no mock rules selected.\nClick below to create the first rule in "${vm.selectedProject}".'
                    : 'Select a mock rule from the list on the left, or create a new one.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5),
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
        // Editor Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.surfaceLight,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _nameController,
                    onChanged: (v) => vm.updateEditingField(name: v),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      hintText: 'Rule Name...',
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.methodDelete),
                  tooltip: 'Delete Rule',
                  onPressed: () => vm.deleteRule(rule.id),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showAiMockModal(context, vm),
                  icon: const Icon(Icons.auto_awesome, size: 15),
                  label: const Text('Generate with AI'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusMock,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    await vm.saveCurrentRule();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Mock rule saved successfully!')),
                      );
                    }
                  },
                  icon: const Icon(Icons.save_outlined, size: 15),
                  label: const Text('Save Rule'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),

        // Matching & Response Form
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Matching Criteria Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              '1. Request Matching Criteria',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Project Indicator / Selector
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.folder_outlined, size: 13, color: AppColors.primaryHover),
                                const SizedBox(width: 4),
                                DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: vm.projects.contains(rule.projectName) ? rule.projectName : 'Default Project',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMain),
                                    dropdownColor: AppColors.surfaceLight,
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
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // HTTP Method
                          SizedBox(
                            width: 140,
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: rule.matchMethod,
                              decoration: const InputDecoration(labelText: 'Method'),
                              dropdownColor: AppColors.surfaceLight,
                              items: ['ALL', 'GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS']
                                  .map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis)))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) vm.updateEditingField(matchMethod: v);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // URL Pattern
                          Expanded(
                            child: TextField(
                              controller: _urlPatternController,
                              onChanged: (v) => vm.updateEditingField(urlPattern: v),
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                              decoration: const InputDecoration(
                                labelText: 'URL Pattern (supports wildcards * or regex)',
                                hintText: '*/api/v1/users*',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: rule.isRegex,
                            onChanged: (v) => vm.updateEditingField(isRegex: v ?? false),
                          ),
                          const Expanded(
                            child: Text(
                              'Treat URL pattern as regular expression (RegExp)',
                              style: TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('2. Mock Response Configuration', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Status Code
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: _statusCodeController,
                              keyboardType: TextInputType.number,
                              onChanged: (v) {
                                final code = int.tryParse(v);
                                if (code != null) vm.updateEditingField(responseStatusCode: code);
                              },
                              decoration: const InputDecoration(labelText: 'Status Code', hintText: '200'),
                            ),
                          ),
                          // Status Reason
                          SizedBox(
                            width: 120,
                            child: TextField(
                              controller: _statusReasonController,
                              onChanged: (v) => vm.updateEditingField(responseStatusReason: v),
                              decoration: const InputDecoration(labelText: 'Status Reason', hintText: 'OK'),
                            ),
                          ),
                          // Simulated Delay
                          SizedBox(
                            width: 120,
                            child: TextField(
                              controller: _delayController,
                              keyboardType: TextInputType.number,
                              onChanged: (v) {
                                final delay = int.tryParse(v);
                                if (delay != null) vm.updateEditingField(responseDelayMs: delay);
                              },
                              decoration: const InputDecoration(labelText: 'Delay (ms)', hintText: '100'),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: vm.formatEditingBodyJson,
                            icon: const Icon(Icons.auto_fix_high, size: 14),
                            label: const Text('Prettify JSON', style: TextStyle(fontSize: 12)),
                          ),
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

                      // Dynamic Variables & Custom Variables System
                      _buildVariablesSection(context, vm, rule),
                      const SizedBox(height: 16),

                      // Response Body Editor
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: const [
                          Text('Response Body (JSON / Text):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                          Text('Supports variables like {{isUserType}}, {{userid}}', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 280,
                        child: TextField(
                          controller: _bodyController,
                          onChanged: (v) => vm.updateEditingField(responseBody: v),
                          maxLines: null,
                          expands: true,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.4),
                          decoration: const InputDecoration(
                            alignLabelWithHint: true,
                            hintText: '{\n  "user_type": "{{isUserType}}",\n  "userid": {{userid}},\n  "Others": "{{custom_variable}}"\n}',
                          ),
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

  // --- Conditions Section with AND / OR Logic ---
  Widget _buildConditionsSection(BuildContext context, MocksViewModel vm, MockRule rule) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Icon(Icons.rule_folder_outlined, size: 16, color: AppColors.primaryHover),
              const SizedBox(width: 8),
              Text(
                'Matching Conditions (${rule.conditions.length})',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textMain),
              ),
              const SizedBox(width: 16),
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
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => vm.addCondition(),
                icon: const Icon(Icons.add, size: 13),
                label: const Text('Add Condition', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceLight,
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'No conditions defined. Matches any request that satisfies URL Pattern.\nAdd conditions to match specific query params, json body, or headers.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.4),
                  ),
                ),
                OutlinedButton(
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

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Active checkbox
                    Checkbox(
                      value: cond.isEnabled,
                      onChanged: (val) => vm.updateCondition(idx, cond.copyWith(isEnabled: val ?? true)),
                    ),
                    // Source dropdown
                    SizedBox(
                      width: 135,
                      child: DropdownButtonFormField<ConditionSource>(
                        isExpanded: true,
                        initialValue: cond.source,
                        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                        dropdownColor: AppColors.surfaceLight,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMain),
                        items: const [
                          DropdownMenuItem(value: ConditionSource.any, child: Text('Any (Auto)', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: ConditionSource.query, child: Text('Query Param', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: ConditionSource.body, child: Text('JSON Body', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: ConditionSource.header, child: Text('Header', overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (v) {
                          if (v != null) vm.updateCondition(idx, cond.copyWith(source: v));
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Field name (e.g. isUserType, userid)
                    SizedBox(
                      width: 160,
                      child: TextFormField(
                        initialValue: cond.field,
                        onChanged: (v) => vm.updateCondition(idx, cond.copyWith(field: v)),
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                        decoration: const InputDecoration(
                          hintText: 'Field (e.g. isUserType)',
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Operator dropdown (=, !=, contain, >, <, >=, <=, regex)
                    SizedBox(
                      width: 155,
                      child: DropdownButtonFormField<ConditionOperator>(
                        isExpanded: true,
                        initialValue: cond.operator,
                        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                        dropdownColor: AppColors.surfaceLight,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMain),
                        items: const [
                          DropdownMenuItem(value: ConditionOperator.equals, child: Text('= (equals)', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: ConditionOperator.notEquals, child: Text('!= (not equals)', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: ConditionOperator.contains, child: Text('contain (contains)', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: ConditionOperator.greaterThan, child: Text('> (greater than)', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: ConditionOperator.lessThan, child: Text('< (less than)', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: ConditionOperator.greaterThanOrEqual, child: Text('>= (greater/equal)', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: ConditionOperator.lessThanOrEqual, child: Text('<= (less/equal)', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: ConditionOperator.regex, child: Text('regex (pattern)', overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (v) {
                          if (v != null) vm.updateCondition(idx, cond.copyWith(operator: v));
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Value
                    SizedBox(
                      width: 180,
                      child: TextFormField(
                        initialValue: cond.value,
                        onChanged: (v) => vm.updateCondition(idx, cond.copyWith(value: v)),
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                        decoration: const InputDecoration(
                          hintText: 'Value (e.g. project manager, 5)',
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                      tooltip: 'Remove Condition',
                      onPressed: () => vm.removeCondition(idx),
                    ),
                  ],
                ),
              ),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

  // --- Dynamic Variables & Custom Variables System ---
  Widget _buildVariablesSection(BuildContext context, MocksViewModel vm, MockRule rule) {
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
        _buildKeyValueListSection(
          context: context,
          title: 'Custom Variables (${rule.customVariables.length})',
          addLabel: 'Add Variable',
          items: rule.customVariables,
          onAdd: (k, v) => vm.addCustomVariable(k, v),
          onRemove: (k) => vm.removeCustomVariable(k),
          quickAddOptions: const [
            MapEntry('custom_variable', 'Custom Value'),
            MapEntry('user_role', 'Administrator'),
            MapEntry('company', 'ApiLab Enterprise'),
          ],
          emptyMessage: 'No custom variables defined. You can define variables here and use them in Response Body as {{variable_name}}.',
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.code_rounded, size: 14, color: AppColors.primaryHover),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Insert Variable into Response Body (Click Chip to Insert):',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMain),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: variableChips.map((v) {
                  return ActionChip(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.surface,
                    label: Text('{{$v}}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.primaryHover)),
                    onPressed: () => _insertVariableIntoBody(v, vm),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Dialogs: Projects, Import, Export, AI ---

  void _showNewProjectDialog(BuildContext context, MocksViewModel vm) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.create_new_folder_outlined, color: AppColors.primaryHover, size: 20),
            SizedBox(width: 8),
            Expanded(
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

  void _showAiMockModal(BuildContext context, MocksViewModel vm) {
    final promptCtrl = TextEditingController(text: 'Generate realistic payload with 3-5 sample records');
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.statusMock, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Generate Mock Data with AI',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Describe what data you need or specify fields and requirements:',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: promptCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'e.g., 5 customer profiles with avatars, addresses, phone numbers, and loyalty points',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await vm.generateWithAi(prompt: promptCtrl.text.trim());
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mock generated and applied!')),
                  );
                }
              },
              icon: const Icon(Icons.auto_awesome, size: 14),
              label: const Text('Generate & Apply'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusMock),
            ),
          ],
        ),
      ),
    );
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
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textMain),
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
              return ActionChip(
                visualDensity: VisualDensity.compact,
                backgroundColor: AppColors.surfaceLight,
                label: Text('${opt.key}: ${opt.value}', style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
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
            child: Text(emptyMessage, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
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
                  Expanded(
                    flex: 2,
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Text(
                      entry.value,
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textSecondary),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close, size: 14, color: AppColors.textMuted),
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
