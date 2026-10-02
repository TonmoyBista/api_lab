import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../domain/models/mock_rule.dart';
import '../../../../domain/repositories/repositories.dart';

class MocksViewModel extends ChangeNotifier {
  final IMockRuleRepository _mockRuleRepository;

  StreamSubscription<List<MockRule>>? _subscription;
  List<MockRule> _rules = [];
  MockRule? _editingRule;
  String _searchFilter = '';
  String _selectedProject = 'All Projects';

  MocksViewModel({
    required this._mockRuleRepository,
  }) {
    _init();
  }

  void _init() {
    _rules = _mockRuleRepository.currentRules;
    if (_rules.isNotEmpty) {
      _editingRule = _rules.first;
    }
    _subscription = _mockRuleRepository.rulesStream.listen((rules) {
      _rules = rules;
      if (_editingRule != null) {
        final current = _rules.where((r) => r.id == _editingRule!.id).firstOrNull;
        if (current != null) {
          _editingRule = current;
        }
      }
      notifyListeners();
    });
  }

  final Set<String> _explicitProjects = {'Default Project'};

  List<String> get projects {
    final set = <String>{..._explicitProjects, ..._mockRuleRepository.currentProjects};
    for (final r in _rules) {
      if (r.projectName.trim().isNotEmpty) {
        set.add(r.projectName.trim());
      }
    }
    return ['All Projects', ...set];
  }

  String get selectedProject => _selectedProject;

  void setSelectedProject(String project) {
    _selectedProject = project;
    notifyListeners();
  }

  void createProject(String projectName) {
    final trimmed = projectName.trim();
    if (trimmed.isEmpty) return;
    _explicitProjects.add(trimmed);
    _mockRuleRepository.createProject(trimmed);
    _selectedProject = trimmed;
    _editingRule = null;
    notifyListeners();
  }

  void setRuleProject(String projectName) {
    if (_editingRule == null) return;
    final trimmed = projectName.trim();
    if (trimmed.isEmpty) return;
    _explicitProjects.add(trimmed);
    _editingRule = _editingRule!.copyWith(projectName: trimmed);
    notifyListeners();
  }

  List<MockRule> get rules {
    var list = _rules;
    if (_selectedProject != 'All Projects') {
      list = list.where((r) => r.projectName == _selectedProject).toList();
    }
    if (_searchFilter.trim().isEmpty) return list;
    final q = _searchFilter.trim().toLowerCase();
    return list.where((r) => 
      r.name.toLowerCase().contains(q) ||
      r.urlPattern.toLowerCase().contains(q) ||
      r.matchMethod.toLowerCase().contains(q) ||
      r.projectName.toLowerCase().contains(q)
    ).toList();
  }

  MockRule? get editingRule => _editingRule;
  String get searchFilter => _searchFilter;

  void setSearchFilter(String filter) {
    _searchFilter = filter;
    notifyListeners();
  }

  void selectRule(MockRule? rule) {
    _editingRule = rule;
    notifyListeners();
  }

  void createNewRule({MockRule? template}) {
    const uuid = Uuid();
    final defaultProjectName = _selectedProject != 'All Projects' ? _selectedProject : 'Default Project';

    _editingRule = template != null 
        ? template.copyWith(
            id: uuid.v4(),
            projectName: template.projectName.isNotEmpty ? template.projectName : defaultProjectName,
          )
        : MockRule(
            id: uuid.v4(),
            name: 'New Mock Rule',
            projectName: defaultProjectName,
            matchMethod: 'GET',
            urlPattern: '*/api/example*',
            conditionLogic: 'AND',
            conditions: [
              const MockCondition(
                id: 'c1',
                source: ConditionSource.any,
                field: 'isUserType',
                operator: ConditionOperator.equals,
                value: 'project manager',
              ),
              const MockCondition(
                id: 'c2',
                source: ConditionSource.any,
                field: 'userid',
                operator: ConditionOperator.equals,
                value: '5',
              ),
            ],
            customVariables: {
              'custom_variable': 'Custom Variable Value',
            },
            responseStatusCode: 200,
            responseHeaders: {'content-type': 'application/json'},
            responseBody: '{\n  "user_type": "{{isUserType}}",\n  "userid": {{userid}},\n  "Others": "{{custom_variable}}"\n}',
            responseDelayMs: 50,
          );
    notifyListeners();
  }

  void updateEditingField({
    String? name,
    String? projectName,
    String? matchMethod,
    String? urlPattern,
    String? conditionLogic,
    List<MockCondition>? conditions,
    Map<String, String>? matchQueryParams,
    Map<String, String>? matchHeaders,
    String? matchBody,
    Map<String, String>? customVariables,
    int? responseStatusCode,
    String? responseStatusReason,
    Map<String, String>? responseHeaders,
    String? responseBody,
    int? responseDelayMs,
    String? description,
    bool? isRegex,
  }) {
    if (_editingRule == null) return;
    _editingRule = _editingRule!.copyWith(
      name: name,
      projectName: projectName,
      matchMethod: matchMethod,
      urlPattern: urlPattern,
      conditionLogic: conditionLogic,
      conditions: conditions,
      matchQueryParams: matchQueryParams,
      matchHeaders: matchHeaders,
      matchBody: matchBody,
      customVariables: customVariables,
      responseStatusCode: responseStatusCode,
      responseStatusReason: responseStatusReason,
      responseHeaders: responseHeaders,
      responseBody: responseBody,
      responseDelayMs: responseDelayMs,
      description: description,
      isRegex: isRegex,
    );
    notifyListeners();
  }

  // --- Conditions Management (AND / OR, Operators: =, !=, contain, >, <, >=, <=) ---

  void setConditionLogic(String logic) {
    if (_editingRule == null) return;
    _editingRule = _editingRule!.copyWith(conditionLogic: logic.toUpperCase());
    notifyListeners();
  }

  void addCondition({
    ConditionSource source = ConditionSource.any,
    String field = '',
    ConditionOperator operator = ConditionOperator.equals,
    String value = '',
  }) {
    if (_editingRule == null) return;
    final newCondition = MockCondition(
      id: const Uuid().v4(),
      source: source,
      field: field,
      operator: operator,
      value: value,
      isEnabled: true,
    );
    final list = List<MockCondition>.from(_editingRule!.conditions)..add(newCondition);
    _editingRule = _editingRule!.copyWith(conditions: list);
    notifyListeners();
  }

  void updateCondition(int index, MockCondition condition) {
    if (_editingRule == null || index < 0 || index >= _editingRule!.conditions.length) return;
    final list = List<MockCondition>.from(_editingRule!.conditions);
    list[index] = condition;
    _editingRule = _editingRule!.copyWith(conditions: list);
    notifyListeners();
  }

  void removeCondition(int index) {
    if (_editingRule == null || index < 0 || index >= _editingRule!.conditions.length) return;
    final list = List<MockCondition>.from(_editingRule!.conditions)..removeAt(index);
    _editingRule = _editingRule!.copyWith(conditions: list);
    notifyListeners();
  }

  // --- Custom Variables Management ---

  void addCustomVariable(String key, String value) {
    if (_editingRule == null) return;
    final map = Map<String, String>.from(_editingRule!.customVariables);
    map[key.trim()] = value;
    _editingRule = _editingRule!.copyWith(customVariables: map);
    notifyListeners();
  }

  void removeCustomVariable(String key) {
    if (_editingRule == null) return;
    final map = Map<String, String>.from(_editingRule!.customVariables)..remove(key.trim());
    _editingRule = _editingRule!.copyWith(customVariables: map);
    notifyListeners();
  }

  // --- Legacy Matchers (Query, Headers) ---

  void addMatchQueryParam(String key, String value) {
    if (_editingRule == null) return;
    final map = Map<String, String>.from(_editingRule!.matchQueryParams);
    map[key] = value;
    _editingRule = _editingRule!.copyWith(matchQueryParams: map);
    notifyListeners();
  }

  void removeMatchQueryParam(String key) {
    if (_editingRule == null) return;
    final map = Map<String, String>.from(_editingRule!.matchQueryParams)..remove(key);
    _editingRule = _editingRule!.copyWith(matchQueryParams: map);
    notifyListeners();
  }

  void addMatchHeader(String key, String value) {
    if (_editingRule == null) return;
    final map = Map<String, String>.from(_editingRule!.matchHeaders);
    map[key.toLowerCase()] = value;
    _editingRule = _editingRule!.copyWith(matchHeaders: map);
    notifyListeners();
  }

  void removeMatchHeader(String key) {
    if (_editingRule == null) return;
    final map = Map<String, String>.from(_editingRule!.matchHeaders)..remove(key.toLowerCase());
    _editingRule = _editingRule!.copyWith(matchHeaders: map);
    notifyListeners();
  }

  void addResponseHeader(String key, String value) {
    if (_editingRule == null) return;
    final map = Map<String, String>.from(_editingRule!.responseHeaders);
    map[key.toLowerCase()] = value;
    _editingRule = _editingRule!.copyWith(responseHeaders: map);
    notifyListeners();
  }

  void removeResponseHeader(String key) {
    if (_editingRule == null) return;
    final map = Map<String, String>.from(_editingRule!.responseHeaders)..remove(key.toLowerCase());
    _editingRule = _editingRule!.copyWith(responseHeaders: map);
    notifyListeners();
  }

  Future<void> saveCurrentRule() async {
    if (_editingRule == null) return;
    final exists = _rules.any((r) => r.id == _editingRule!.id);
    if (exists) {
      await _mockRuleRepository.updateRule(_editingRule!);
    } else {
      await _mockRuleRepository.addRule(_editingRule!);
    }
    notifyListeners();
  }

  Future<void> toggleRule(String id, bool isEnabled) async {
    await _mockRuleRepository.toggleRule(id, isEnabled);
  }

  Future<void> deleteRule(String id) async {
    if (_editingRule?.id == id) {
      _editingRule = _rules.where((r) => r.id != id).firstOrNull;
    }
    await _mockRuleRepository.deleteRule(id);
  }

  void formatEditingBodyJson() {
    if (_editingRule == null || _editingRule!.responseBody.trim().isEmpty) return;
    try {
      final decoded = jsonDecode(_editingRule!.responseBody);
      const encoder = JsonEncoder.withIndent('  ');
      final formatted = encoder.convert(decoded);
      _editingRule = _editingRule!.copyWith(responseBody: formatted);
      notifyListeners();
    } catch (_) {}
  }

  // --- Import & Export Functionality ---

  String exportRulesJson({String? project}) {
    final targetProj = project ?? _selectedProject;
    final list = (targetProj == 'All Projects')
        ? _rules
        : _rules.where((r) => r.projectName == targetProj).toList();

    final exportData = {
      'apilab_version': '1.0',
      'exported_at': DateTime.now().toIso8601String(),
      'project': targetProj,
      'rules_count': list.length,
      'rules': list.map((r) => r.toJson()).toList(),
    };

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(exportData);
  }

  Future<String> exportToFile({String? project, String? customPath}) async {
    final jsonContent = exportRulesJson(project: project);
    final targetProj = (project ?? _selectedProject).replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final filename = 'apilab_mock_rules_${targetProj}_${DateTime.now().millisecondsSinceEpoch}.json';

    Directory targetDir;
    try {
      targetDir = await getApplicationDocumentsDirectory();
    } catch (_) {
      targetDir = Directory.current;
    }

    final filePath = customPath != null && customPath.trim().isNotEmpty
        ? customPath.trim()
        : '${targetDir.path}/$filename';

    final file = File(filePath);
    await file.writeAsString(jsonContent);
    return file.path;
  }

  Future<String> exportToFolder(String folderPath, {String? project}) async {
    final jsonContent = exportRulesJson(project: project);
    final targetProj = (project ?? _selectedProject).replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final filename = 'apilab_mock_rules_${targetProj}_${DateTime.now().millisecondsSinceEpoch}.json';
    final filePath = '$folderPath/$filename';
    final file = File(filePath);
    await file.writeAsString(jsonContent);
    return file.path;
  }

  Future<int> importRulesJson(String jsonString, {String? targetProject}) async {
    if (jsonString.trim().isEmpty) return 0;
    final dynamic decoded = jsonDecode(jsonString);
    var count = 0;
    const uuid = Uuid();

    List<dynamic> ruleList;
    if (decoded is List) {
      ruleList = decoded;
    } else if (decoded is Map && decoded.containsKey('rules') && decoded['rules'] is List) {
      ruleList = decoded['rules'] as List;
    } else if (decoded is Map) {
      ruleList = [decoded];
    } else {
      return 0;
    }

    for (final item in ruleList) {
      if (item is Map) {
        try {
          var rule = MockRule.fromJson(Map<String, dynamic>.from(item));
          // If importing into specific project or new rule
          rule = rule.copyWith(
            id: uuid.v4(),
            projectName: (targetProject != null && targetProject.isNotEmpty && targetProject != 'All Projects')
                ? targetProject
                : (rule.projectName.isNotEmpty ? rule.projectName : 'Default Project'),
          );
          _explicitProjects.add(rule.projectName);
          await _mockRuleRepository.addRule(rule);
          count++;
        } catch (_) {}
      }
    }

    notifyListeners();
    return count;
  }

  Future<int> importFromFile(String filePath, {String? targetProject}) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File does not exist at $filePath');
    }
    final content = await file.readAsString();
    return importRulesJson(content, targetProject: targetProject);
  }

  Future<void> deleteProject(String projectName) async {
    final trimmed = projectName.trim();
    if (trimmed.isEmpty ||
        trimmed.toLowerCase() == 'default project' ||
        trimmed.toLowerCase() == 'all projects') {
      return;
    }
    _explicitProjects.removeWhere((p) => p.trim().toLowerCase() == trimmed.toLowerCase());
    await _mockRuleRepository.deleteProject(trimmed);
    if (_selectedProject.toLowerCase() == trimmed.toLowerCase()) {
      _selectedProject = 'All Projects';
    }
    _rules = _mockRuleRepository.currentRules;
    if (_rules.isNotEmpty) {
      _editingRule = _rules.first;
    } else {
      _editingRule = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
