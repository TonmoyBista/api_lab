// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MockProjectsTableTable extends MockProjectsTable
    with TableInfo<$MockProjectsTableTable, MockProjectsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MockProjectsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, description, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mock_projects_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<MockProjectsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MockProjectsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MockProjectsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MockProjectsTableTable createAlias(String alias) {
    return $MockProjectsTableTable(attachedDatabase, alias);
  }
}

class MockProjectsTableData extends DataClass
    implements Insertable<MockProjectsTableData> {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  const MockProjectsTableData({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MockProjectsTableCompanion toCompanion(bool nullToAbsent) {
    return MockProjectsTableCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      createdAt: Value(createdAt),
    );
  }

  factory MockProjectsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MockProjectsTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MockProjectsTableData copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
  }) => MockProjectsTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    createdAt: createdAt ?? this.createdAt,
  );
  MockProjectsTableData copyWithCompanion(MockProjectsTableCompanion data) {
    return MockProjectsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MockProjectsTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, description, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MockProjectsTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.createdAt == this.createdAt);
}

class MockProjectsTableCompanion
    extends UpdateCompanion<MockProjectsTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> description;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MockProjectsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MockProjectsTableCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<MockProjectsTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MockProjectsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? description,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return MockProjectsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MockProjectsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MockRulesTableTable extends MockRulesTable
    with TableInfo<$MockRulesTableTable, MockRulesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MockRulesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('default'),
  );
  static const VerificationMeta _projectNameMeta = const VerificationMeta(
    'projectName',
  );
  @override
  late final GeneratedColumn<String> projectName = GeneratedColumn<String>(
    'project_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Default Project'),
  );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _matchMethodMeta = const VerificationMeta(
    'matchMethod',
  );
  @override
  late final GeneratedColumn<String> matchMethod = GeneratedColumn<String>(
    'match_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ALL'),
  );
  static const VerificationMeta _urlPatternMeta = const VerificationMeta(
    'urlPattern',
  );
  @override
  late final GeneratedColumn<String> urlPattern = GeneratedColumn<String>(
    'url_pattern',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isRegexMeta = const VerificationMeta(
    'isRegex',
  );
  @override
  late final GeneratedColumn<bool> isRegex = GeneratedColumn<bool>(
    'is_regex',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_regex" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _conditionLogicMeta = const VerificationMeta(
    'conditionLogic',
  );
  @override
  late final GeneratedColumn<String> conditionLogic = GeneratedColumn<String>(
    'condition_logic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('AND'),
  );
  static const VerificationMeta _conditionsJsonMeta = const VerificationMeta(
    'conditionsJson',
  );
  @override
  late final GeneratedColumn<String> conditionsJson = GeneratedColumn<String>(
    'conditions_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _matchQueryParamsJsonMeta =
      const VerificationMeta('matchQueryParamsJson');
  @override
  late final GeneratedColumn<String> matchQueryParamsJson =
      GeneratedColumn<String>(
        'match_query_params_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
      );
  static const VerificationMeta _matchHeadersJsonMeta = const VerificationMeta(
    'matchHeadersJson',
  );
  @override
  late final GeneratedColumn<String> matchHeadersJson = GeneratedColumn<String>(
    'match_headers_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _matchBodyMeta = const VerificationMeta(
    'matchBody',
  );
  @override
  late final GeneratedColumn<String> matchBody = GeneratedColumn<String>(
    'match_body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _customVariablesJsonMeta =
      const VerificationMeta('customVariablesJson');
  @override
  late final GeneratedColumn<String> customVariablesJson =
      GeneratedColumn<String>(
        'custom_variables_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
      );
  static const VerificationMeta _responseStatusCodeMeta =
      const VerificationMeta('responseStatusCode');
  @override
  late final GeneratedColumn<int> responseStatusCode = GeneratedColumn<int>(
    'response_status_code',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(200),
  );
  static const VerificationMeta _responseStatusReasonMeta =
      const VerificationMeta('responseStatusReason');
  @override
  late final GeneratedColumn<String> responseStatusReason =
      GeneratedColumn<String>(
        'response_status_reason',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('OK'),
      );
  static const VerificationMeta _responseHeadersJsonMeta =
      const VerificationMeta('responseHeadersJson');
  @override
  late final GeneratedColumn<String> responseHeadersJson =
      GeneratedColumn<String>(
        'response_headers_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
      );
  static const VerificationMeta _responseBodyMeta = const VerificationMeta(
    'responseBody',
  );
  @override
  late final GeneratedColumn<String> responseBody = GeneratedColumn<String>(
    'response_body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _responseDelayMsMeta = const VerificationMeta(
    'responseDelayMs',
  );
  @override
  late final GeneratedColumn<int> responseDelayMs = GeneratedColumn<int>(
    'response_delay_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isAiGeneratedMeta = const VerificationMeta(
    'isAiGenerated',
  );
  @override
  late final GeneratedColumn<bool> isAiGenerated = GeneratedColumn<bool>(
    'is_ai_generated',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_ai_generated" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    projectId,
    projectName,
    isEnabled,
    matchMethod,
    urlPattern,
    isRegex,
    conditionLogic,
    conditionsJson,
    matchQueryParamsJson,
    matchHeadersJson,
    matchBody,
    customVariablesJson,
    responseStatusCode,
    responseStatusReason,
    responseHeadersJson,
    responseBody,
    responseDelayMs,
    description,
    isAiGenerated,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mock_rules_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<MockRulesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    }
    if (data.containsKey('project_name')) {
      context.handle(
        _projectNameMeta,
        projectName.isAcceptableOrUnknown(
          data['project_name']!,
          _projectNameMeta,
        ),
      );
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    }
    if (data.containsKey('match_method')) {
      context.handle(
        _matchMethodMeta,
        matchMethod.isAcceptableOrUnknown(
          data['match_method']!,
          _matchMethodMeta,
        ),
      );
    }
    if (data.containsKey('url_pattern')) {
      context.handle(
        _urlPatternMeta,
        urlPattern.isAcceptableOrUnknown(data['url_pattern']!, _urlPatternMeta),
      );
    } else if (isInserting) {
      context.missing(_urlPatternMeta);
    }
    if (data.containsKey('is_regex')) {
      context.handle(
        _isRegexMeta,
        isRegex.isAcceptableOrUnknown(data['is_regex']!, _isRegexMeta),
      );
    }
    if (data.containsKey('condition_logic')) {
      context.handle(
        _conditionLogicMeta,
        conditionLogic.isAcceptableOrUnknown(
          data['condition_logic']!,
          _conditionLogicMeta,
        ),
      );
    }
    if (data.containsKey('conditions_json')) {
      context.handle(
        _conditionsJsonMeta,
        conditionsJson.isAcceptableOrUnknown(
          data['conditions_json']!,
          _conditionsJsonMeta,
        ),
      );
    }
    if (data.containsKey('match_query_params_json')) {
      context.handle(
        _matchQueryParamsJsonMeta,
        matchQueryParamsJson.isAcceptableOrUnknown(
          data['match_query_params_json']!,
          _matchQueryParamsJsonMeta,
        ),
      );
    }
    if (data.containsKey('match_headers_json')) {
      context.handle(
        _matchHeadersJsonMeta,
        matchHeadersJson.isAcceptableOrUnknown(
          data['match_headers_json']!,
          _matchHeadersJsonMeta,
        ),
      );
    }
    if (data.containsKey('match_body')) {
      context.handle(
        _matchBodyMeta,
        matchBody.isAcceptableOrUnknown(data['match_body']!, _matchBodyMeta),
      );
    }
    if (data.containsKey('custom_variables_json')) {
      context.handle(
        _customVariablesJsonMeta,
        customVariablesJson.isAcceptableOrUnknown(
          data['custom_variables_json']!,
          _customVariablesJsonMeta,
        ),
      );
    }
    if (data.containsKey('response_status_code')) {
      context.handle(
        _responseStatusCodeMeta,
        responseStatusCode.isAcceptableOrUnknown(
          data['response_status_code']!,
          _responseStatusCodeMeta,
        ),
      );
    }
    if (data.containsKey('response_status_reason')) {
      context.handle(
        _responseStatusReasonMeta,
        responseStatusReason.isAcceptableOrUnknown(
          data['response_status_reason']!,
          _responseStatusReasonMeta,
        ),
      );
    }
    if (data.containsKey('response_headers_json')) {
      context.handle(
        _responseHeadersJsonMeta,
        responseHeadersJson.isAcceptableOrUnknown(
          data['response_headers_json']!,
          _responseHeadersJsonMeta,
        ),
      );
    }
    if (data.containsKey('response_body')) {
      context.handle(
        _responseBodyMeta,
        responseBody.isAcceptableOrUnknown(
          data['response_body']!,
          _responseBodyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_responseBodyMeta);
    }
    if (data.containsKey('response_delay_ms')) {
      context.handle(
        _responseDelayMsMeta,
        responseDelayMs.isAcceptableOrUnknown(
          data['response_delay_ms']!,
          _responseDelayMsMeta,
        ),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('is_ai_generated')) {
      context.handle(
        _isAiGeneratedMeta,
        isAiGenerated.isAcceptableOrUnknown(
          data['is_ai_generated']!,
          _isAiGeneratedMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MockRulesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MockRulesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      projectName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_name'],
      )!,
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
      matchMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}match_method'],
      )!,
      urlPattern: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url_pattern'],
      )!,
      isRegex: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_regex'],
      )!,
      conditionLogic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}condition_logic'],
      )!,
      conditionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conditions_json'],
      )!,
      matchQueryParamsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}match_query_params_json'],
      )!,
      matchHeadersJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}match_headers_json'],
      )!,
      matchBody: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}match_body'],
      )!,
      customVariablesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_variables_json'],
      )!,
      responseStatusCode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}response_status_code'],
      )!,
      responseStatusReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}response_status_reason'],
      )!,
      responseHeadersJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}response_headers_json'],
      )!,
      responseBody: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}response_body'],
      )!,
      responseDelayMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}response_delay_ms'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      isAiGenerated: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_ai_generated'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MockRulesTableTable createAlias(String alias) {
    return $MockRulesTableTable(attachedDatabase, alias);
  }
}

class MockRulesTableData extends DataClass
    implements Insertable<MockRulesTableData> {
  final String id;
  final String name;
  final String projectId;
  final String projectName;
  final bool isEnabled;
  final String matchMethod;
  final String urlPattern;
  final bool isRegex;
  final String conditionLogic;
  final String conditionsJson;
  final String matchQueryParamsJson;
  final String matchHeadersJson;
  final String matchBody;
  final String customVariablesJson;
  final int responseStatusCode;
  final String responseStatusReason;
  final String responseHeadersJson;
  final String responseBody;
  final int responseDelayMs;
  final String description;
  final bool isAiGenerated;
  final DateTime createdAt;
  const MockRulesTableData({
    required this.id,
    required this.name,
    required this.projectId,
    required this.projectName,
    required this.isEnabled,
    required this.matchMethod,
    required this.urlPattern,
    required this.isRegex,
    required this.conditionLogic,
    required this.conditionsJson,
    required this.matchQueryParamsJson,
    required this.matchHeadersJson,
    required this.matchBody,
    required this.customVariablesJson,
    required this.responseStatusCode,
    required this.responseStatusReason,
    required this.responseHeadersJson,
    required this.responseBody,
    required this.responseDelayMs,
    required this.description,
    required this.isAiGenerated,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['project_id'] = Variable<String>(projectId);
    map['project_name'] = Variable<String>(projectName);
    map['is_enabled'] = Variable<bool>(isEnabled);
    map['match_method'] = Variable<String>(matchMethod);
    map['url_pattern'] = Variable<String>(urlPattern);
    map['is_regex'] = Variable<bool>(isRegex);
    map['condition_logic'] = Variable<String>(conditionLogic);
    map['conditions_json'] = Variable<String>(conditionsJson);
    map['match_query_params_json'] = Variable<String>(matchQueryParamsJson);
    map['match_headers_json'] = Variable<String>(matchHeadersJson);
    map['match_body'] = Variable<String>(matchBody);
    map['custom_variables_json'] = Variable<String>(customVariablesJson);
    map['response_status_code'] = Variable<int>(responseStatusCode);
    map['response_status_reason'] = Variable<String>(responseStatusReason);
    map['response_headers_json'] = Variable<String>(responseHeadersJson);
    map['response_body'] = Variable<String>(responseBody);
    map['response_delay_ms'] = Variable<int>(responseDelayMs);
    map['description'] = Variable<String>(description);
    map['is_ai_generated'] = Variable<bool>(isAiGenerated);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MockRulesTableCompanion toCompanion(bool nullToAbsent) {
    return MockRulesTableCompanion(
      id: Value(id),
      name: Value(name),
      projectId: Value(projectId),
      projectName: Value(projectName),
      isEnabled: Value(isEnabled),
      matchMethod: Value(matchMethod),
      urlPattern: Value(urlPattern),
      isRegex: Value(isRegex),
      conditionLogic: Value(conditionLogic),
      conditionsJson: Value(conditionsJson),
      matchQueryParamsJson: Value(matchQueryParamsJson),
      matchHeadersJson: Value(matchHeadersJson),
      matchBody: Value(matchBody),
      customVariablesJson: Value(customVariablesJson),
      responseStatusCode: Value(responseStatusCode),
      responseStatusReason: Value(responseStatusReason),
      responseHeadersJson: Value(responseHeadersJson),
      responseBody: Value(responseBody),
      responseDelayMs: Value(responseDelayMs),
      description: Value(description),
      isAiGenerated: Value(isAiGenerated),
      createdAt: Value(createdAt),
    );
  }

  factory MockRulesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MockRulesTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      projectId: serializer.fromJson<String>(json['projectId']),
      projectName: serializer.fromJson<String>(json['projectName']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      matchMethod: serializer.fromJson<String>(json['matchMethod']),
      urlPattern: serializer.fromJson<String>(json['urlPattern']),
      isRegex: serializer.fromJson<bool>(json['isRegex']),
      conditionLogic: serializer.fromJson<String>(json['conditionLogic']),
      conditionsJson: serializer.fromJson<String>(json['conditionsJson']),
      matchQueryParamsJson: serializer.fromJson<String>(
        json['matchQueryParamsJson'],
      ),
      matchHeadersJson: serializer.fromJson<String>(json['matchHeadersJson']),
      matchBody: serializer.fromJson<String>(json['matchBody']),
      customVariablesJson: serializer.fromJson<String>(
        json['customVariablesJson'],
      ),
      responseStatusCode: serializer.fromJson<int>(json['responseStatusCode']),
      responseStatusReason: serializer.fromJson<String>(
        json['responseStatusReason'],
      ),
      responseHeadersJson: serializer.fromJson<String>(
        json['responseHeadersJson'],
      ),
      responseBody: serializer.fromJson<String>(json['responseBody']),
      responseDelayMs: serializer.fromJson<int>(json['responseDelayMs']),
      description: serializer.fromJson<String>(json['description']),
      isAiGenerated: serializer.fromJson<bool>(json['isAiGenerated']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'projectId': serializer.toJson<String>(projectId),
      'projectName': serializer.toJson<String>(projectName),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'matchMethod': serializer.toJson<String>(matchMethod),
      'urlPattern': serializer.toJson<String>(urlPattern),
      'isRegex': serializer.toJson<bool>(isRegex),
      'conditionLogic': serializer.toJson<String>(conditionLogic),
      'conditionsJson': serializer.toJson<String>(conditionsJson),
      'matchQueryParamsJson': serializer.toJson<String>(matchQueryParamsJson),
      'matchHeadersJson': serializer.toJson<String>(matchHeadersJson),
      'matchBody': serializer.toJson<String>(matchBody),
      'customVariablesJson': serializer.toJson<String>(customVariablesJson),
      'responseStatusCode': serializer.toJson<int>(responseStatusCode),
      'responseStatusReason': serializer.toJson<String>(responseStatusReason),
      'responseHeadersJson': serializer.toJson<String>(responseHeadersJson),
      'responseBody': serializer.toJson<String>(responseBody),
      'responseDelayMs': serializer.toJson<int>(responseDelayMs),
      'description': serializer.toJson<String>(description),
      'isAiGenerated': serializer.toJson<bool>(isAiGenerated),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MockRulesTableData copyWith({
    String? id,
    String? name,
    String? projectId,
    String? projectName,
    bool? isEnabled,
    String? matchMethod,
    String? urlPattern,
    bool? isRegex,
    String? conditionLogic,
    String? conditionsJson,
    String? matchQueryParamsJson,
    String? matchHeadersJson,
    String? matchBody,
    String? customVariablesJson,
    int? responseStatusCode,
    String? responseStatusReason,
    String? responseHeadersJson,
    String? responseBody,
    int? responseDelayMs,
    String? description,
    bool? isAiGenerated,
    DateTime? createdAt,
  }) => MockRulesTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    projectId: projectId ?? this.projectId,
    projectName: projectName ?? this.projectName,
    isEnabled: isEnabled ?? this.isEnabled,
    matchMethod: matchMethod ?? this.matchMethod,
    urlPattern: urlPattern ?? this.urlPattern,
    isRegex: isRegex ?? this.isRegex,
    conditionLogic: conditionLogic ?? this.conditionLogic,
    conditionsJson: conditionsJson ?? this.conditionsJson,
    matchQueryParamsJson: matchQueryParamsJson ?? this.matchQueryParamsJson,
    matchHeadersJson: matchHeadersJson ?? this.matchHeadersJson,
    matchBody: matchBody ?? this.matchBody,
    customVariablesJson: customVariablesJson ?? this.customVariablesJson,
    responseStatusCode: responseStatusCode ?? this.responseStatusCode,
    responseStatusReason: responseStatusReason ?? this.responseStatusReason,
    responseHeadersJson: responseHeadersJson ?? this.responseHeadersJson,
    responseBody: responseBody ?? this.responseBody,
    responseDelayMs: responseDelayMs ?? this.responseDelayMs,
    description: description ?? this.description,
    isAiGenerated: isAiGenerated ?? this.isAiGenerated,
    createdAt: createdAt ?? this.createdAt,
  );
  MockRulesTableData copyWithCompanion(MockRulesTableCompanion data) {
    return MockRulesTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      projectName: data.projectName.present
          ? data.projectName.value
          : this.projectName,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      matchMethod: data.matchMethod.present
          ? data.matchMethod.value
          : this.matchMethod,
      urlPattern: data.urlPattern.present
          ? data.urlPattern.value
          : this.urlPattern,
      isRegex: data.isRegex.present ? data.isRegex.value : this.isRegex,
      conditionLogic: data.conditionLogic.present
          ? data.conditionLogic.value
          : this.conditionLogic,
      conditionsJson: data.conditionsJson.present
          ? data.conditionsJson.value
          : this.conditionsJson,
      matchQueryParamsJson: data.matchQueryParamsJson.present
          ? data.matchQueryParamsJson.value
          : this.matchQueryParamsJson,
      matchHeadersJson: data.matchHeadersJson.present
          ? data.matchHeadersJson.value
          : this.matchHeadersJson,
      matchBody: data.matchBody.present ? data.matchBody.value : this.matchBody,
      customVariablesJson: data.customVariablesJson.present
          ? data.customVariablesJson.value
          : this.customVariablesJson,
      responseStatusCode: data.responseStatusCode.present
          ? data.responseStatusCode.value
          : this.responseStatusCode,
      responseStatusReason: data.responseStatusReason.present
          ? data.responseStatusReason.value
          : this.responseStatusReason,
      responseHeadersJson: data.responseHeadersJson.present
          ? data.responseHeadersJson.value
          : this.responseHeadersJson,
      responseBody: data.responseBody.present
          ? data.responseBody.value
          : this.responseBody,
      responseDelayMs: data.responseDelayMs.present
          ? data.responseDelayMs.value
          : this.responseDelayMs,
      description: data.description.present
          ? data.description.value
          : this.description,
      isAiGenerated: data.isAiGenerated.present
          ? data.isAiGenerated.value
          : this.isAiGenerated,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MockRulesTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('projectId: $projectId, ')
          ..write('projectName: $projectName, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('matchMethod: $matchMethod, ')
          ..write('urlPattern: $urlPattern, ')
          ..write('isRegex: $isRegex, ')
          ..write('conditionLogic: $conditionLogic, ')
          ..write('conditionsJson: $conditionsJson, ')
          ..write('matchQueryParamsJson: $matchQueryParamsJson, ')
          ..write('matchHeadersJson: $matchHeadersJson, ')
          ..write('matchBody: $matchBody, ')
          ..write('customVariablesJson: $customVariablesJson, ')
          ..write('responseStatusCode: $responseStatusCode, ')
          ..write('responseStatusReason: $responseStatusReason, ')
          ..write('responseHeadersJson: $responseHeadersJson, ')
          ..write('responseBody: $responseBody, ')
          ..write('responseDelayMs: $responseDelayMs, ')
          ..write('description: $description, ')
          ..write('isAiGenerated: $isAiGenerated, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    name,
    projectId,
    projectName,
    isEnabled,
    matchMethod,
    urlPattern,
    isRegex,
    conditionLogic,
    conditionsJson,
    matchQueryParamsJson,
    matchHeadersJson,
    matchBody,
    customVariablesJson,
    responseStatusCode,
    responseStatusReason,
    responseHeadersJson,
    responseBody,
    responseDelayMs,
    description,
    isAiGenerated,
    createdAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MockRulesTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.projectId == this.projectId &&
          other.projectName == this.projectName &&
          other.isEnabled == this.isEnabled &&
          other.matchMethod == this.matchMethod &&
          other.urlPattern == this.urlPattern &&
          other.isRegex == this.isRegex &&
          other.conditionLogic == this.conditionLogic &&
          other.conditionsJson == this.conditionsJson &&
          other.matchQueryParamsJson == this.matchQueryParamsJson &&
          other.matchHeadersJson == this.matchHeadersJson &&
          other.matchBody == this.matchBody &&
          other.customVariablesJson == this.customVariablesJson &&
          other.responseStatusCode == this.responseStatusCode &&
          other.responseStatusReason == this.responseStatusReason &&
          other.responseHeadersJson == this.responseHeadersJson &&
          other.responseBody == this.responseBody &&
          other.responseDelayMs == this.responseDelayMs &&
          other.description == this.description &&
          other.isAiGenerated == this.isAiGenerated &&
          other.createdAt == this.createdAt);
}

class MockRulesTableCompanion extends UpdateCompanion<MockRulesTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> projectId;
  final Value<String> projectName;
  final Value<bool> isEnabled;
  final Value<String> matchMethod;
  final Value<String> urlPattern;
  final Value<bool> isRegex;
  final Value<String> conditionLogic;
  final Value<String> conditionsJson;
  final Value<String> matchQueryParamsJson;
  final Value<String> matchHeadersJson;
  final Value<String> matchBody;
  final Value<String> customVariablesJson;
  final Value<int> responseStatusCode;
  final Value<String> responseStatusReason;
  final Value<String> responseHeadersJson;
  final Value<String> responseBody;
  final Value<int> responseDelayMs;
  final Value<String> description;
  final Value<bool> isAiGenerated;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MockRulesTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.projectId = const Value.absent(),
    this.projectName = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.matchMethod = const Value.absent(),
    this.urlPattern = const Value.absent(),
    this.isRegex = const Value.absent(),
    this.conditionLogic = const Value.absent(),
    this.conditionsJson = const Value.absent(),
    this.matchQueryParamsJson = const Value.absent(),
    this.matchHeadersJson = const Value.absent(),
    this.matchBody = const Value.absent(),
    this.customVariablesJson = const Value.absent(),
    this.responseStatusCode = const Value.absent(),
    this.responseStatusReason = const Value.absent(),
    this.responseHeadersJson = const Value.absent(),
    this.responseBody = const Value.absent(),
    this.responseDelayMs = const Value.absent(),
    this.description = const Value.absent(),
    this.isAiGenerated = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MockRulesTableCompanion.insert({
    required String id,
    required String name,
    this.projectId = const Value.absent(),
    this.projectName = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.matchMethod = const Value.absent(),
    required String urlPattern,
    this.isRegex = const Value.absent(),
    this.conditionLogic = const Value.absent(),
    this.conditionsJson = const Value.absent(),
    this.matchQueryParamsJson = const Value.absent(),
    this.matchHeadersJson = const Value.absent(),
    this.matchBody = const Value.absent(),
    this.customVariablesJson = const Value.absent(),
    this.responseStatusCode = const Value.absent(),
    this.responseStatusReason = const Value.absent(),
    this.responseHeadersJson = const Value.absent(),
    required String responseBody,
    this.responseDelayMs = const Value.absent(),
    this.description = const Value.absent(),
    this.isAiGenerated = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       urlPattern = Value(urlPattern),
       responseBody = Value(responseBody);
  static Insertable<MockRulesTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? projectId,
    Expression<String>? projectName,
    Expression<bool>? isEnabled,
    Expression<String>? matchMethod,
    Expression<String>? urlPattern,
    Expression<bool>? isRegex,
    Expression<String>? conditionLogic,
    Expression<String>? conditionsJson,
    Expression<String>? matchQueryParamsJson,
    Expression<String>? matchHeadersJson,
    Expression<String>? matchBody,
    Expression<String>? customVariablesJson,
    Expression<int>? responseStatusCode,
    Expression<String>? responseStatusReason,
    Expression<String>? responseHeadersJson,
    Expression<String>? responseBody,
    Expression<int>? responseDelayMs,
    Expression<String>? description,
    Expression<bool>? isAiGenerated,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (projectId != null) 'project_id': projectId,
      if (projectName != null) 'project_name': projectName,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (matchMethod != null) 'match_method': matchMethod,
      if (urlPattern != null) 'url_pattern': urlPattern,
      if (isRegex != null) 'is_regex': isRegex,
      if (conditionLogic != null) 'condition_logic': conditionLogic,
      if (conditionsJson != null) 'conditions_json': conditionsJson,
      if (matchQueryParamsJson != null)
        'match_query_params_json': matchQueryParamsJson,
      if (matchHeadersJson != null) 'match_headers_json': matchHeadersJson,
      if (matchBody != null) 'match_body': matchBody,
      if (customVariablesJson != null)
        'custom_variables_json': customVariablesJson,
      if (responseStatusCode != null)
        'response_status_code': responseStatusCode,
      if (responseStatusReason != null)
        'response_status_reason': responseStatusReason,
      if (responseHeadersJson != null)
        'response_headers_json': responseHeadersJson,
      if (responseBody != null) 'response_body': responseBody,
      if (responseDelayMs != null) 'response_delay_ms': responseDelayMs,
      if (description != null) 'description': description,
      if (isAiGenerated != null) 'is_ai_generated': isAiGenerated,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MockRulesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? projectId,
    Value<String>? projectName,
    Value<bool>? isEnabled,
    Value<String>? matchMethod,
    Value<String>? urlPattern,
    Value<bool>? isRegex,
    Value<String>? conditionLogic,
    Value<String>? conditionsJson,
    Value<String>? matchQueryParamsJson,
    Value<String>? matchHeadersJson,
    Value<String>? matchBody,
    Value<String>? customVariablesJson,
    Value<int>? responseStatusCode,
    Value<String>? responseStatusReason,
    Value<String>? responseHeadersJson,
    Value<String>? responseBody,
    Value<int>? responseDelayMs,
    Value<String>? description,
    Value<bool>? isAiGenerated,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return MockRulesTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      isEnabled: isEnabled ?? this.isEnabled,
      matchMethod: matchMethod ?? this.matchMethod,
      urlPattern: urlPattern ?? this.urlPattern,
      isRegex: isRegex ?? this.isRegex,
      conditionLogic: conditionLogic ?? this.conditionLogic,
      conditionsJson: conditionsJson ?? this.conditionsJson,
      matchQueryParamsJson: matchQueryParamsJson ?? this.matchQueryParamsJson,
      matchHeadersJson: matchHeadersJson ?? this.matchHeadersJson,
      matchBody: matchBody ?? this.matchBody,
      customVariablesJson: customVariablesJson ?? this.customVariablesJson,
      responseStatusCode: responseStatusCode ?? this.responseStatusCode,
      responseStatusReason: responseStatusReason ?? this.responseStatusReason,
      responseHeadersJson: responseHeadersJson ?? this.responseHeadersJson,
      responseBody: responseBody ?? this.responseBody,
      responseDelayMs: responseDelayMs ?? this.responseDelayMs,
      description: description ?? this.description,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (projectName.present) {
      map['project_name'] = Variable<String>(projectName.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (matchMethod.present) {
      map['match_method'] = Variable<String>(matchMethod.value);
    }
    if (urlPattern.present) {
      map['url_pattern'] = Variable<String>(urlPattern.value);
    }
    if (isRegex.present) {
      map['is_regex'] = Variable<bool>(isRegex.value);
    }
    if (conditionLogic.present) {
      map['condition_logic'] = Variable<String>(conditionLogic.value);
    }
    if (conditionsJson.present) {
      map['conditions_json'] = Variable<String>(conditionsJson.value);
    }
    if (matchQueryParamsJson.present) {
      map['match_query_params_json'] = Variable<String>(
        matchQueryParamsJson.value,
      );
    }
    if (matchHeadersJson.present) {
      map['match_headers_json'] = Variable<String>(matchHeadersJson.value);
    }
    if (matchBody.present) {
      map['match_body'] = Variable<String>(matchBody.value);
    }
    if (customVariablesJson.present) {
      map['custom_variables_json'] = Variable<String>(
        customVariablesJson.value,
      );
    }
    if (responseStatusCode.present) {
      map['response_status_code'] = Variable<int>(responseStatusCode.value);
    }
    if (responseStatusReason.present) {
      map['response_status_reason'] = Variable<String>(
        responseStatusReason.value,
      );
    }
    if (responseHeadersJson.present) {
      map['response_headers_json'] = Variable<String>(
        responseHeadersJson.value,
      );
    }
    if (responseBody.present) {
      map['response_body'] = Variable<String>(responseBody.value);
    }
    if (responseDelayMs.present) {
      map['response_delay_ms'] = Variable<int>(responseDelayMs.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (isAiGenerated.present) {
      map['is_ai_generated'] = Variable<bool>(isAiGenerated.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MockRulesTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('projectId: $projectId, ')
          ..write('projectName: $projectName, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('matchMethod: $matchMethod, ')
          ..write('urlPattern: $urlPattern, ')
          ..write('isRegex: $isRegex, ')
          ..write('conditionLogic: $conditionLogic, ')
          ..write('conditionsJson: $conditionsJson, ')
          ..write('matchQueryParamsJson: $matchQueryParamsJson, ')
          ..write('matchHeadersJson: $matchHeadersJson, ')
          ..write('matchBody: $matchBody, ')
          ..write('customVariablesJson: $customVariablesJson, ')
          ..write('responseStatusCode: $responseStatusCode, ')
          ..write('responseStatusReason: $responseStatusReason, ')
          ..write('responseHeadersJson: $responseHeadersJson, ')
          ..write('responseBody: $responseBody, ')
          ..write('responseDelayMs: $responseDelayMs, ')
          ..write('description: $description, ')
          ..write('isAiGenerated: $isAiGenerated, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MockProjectsTableTable mockProjectsTable =
      $MockProjectsTableTable(this);
  late final $MockRulesTableTable mockRulesTable = $MockRulesTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    mockProjectsTable,
    mockRulesTable,
  ];
}

typedef $$MockProjectsTableTableCreateCompanionBuilder =
    MockProjectsTableCompanion Function({
      required String id,
      required String name,
      Value<String> description,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$MockProjectsTableTableUpdateCompanionBuilder =
    MockProjectsTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> description,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$MockProjectsTableTableFilterComposer
    extends Composer<_$AppDatabase, $MockProjectsTableTable> {
  $$MockProjectsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MockProjectsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MockProjectsTableTable> {
  $$MockProjectsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MockProjectsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MockProjectsTableTable> {
  $$MockProjectsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MockProjectsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MockProjectsTableTable,
          MockProjectsTableData,
          $$MockProjectsTableTableFilterComposer,
          $$MockProjectsTableTableOrderingComposer,
          $$MockProjectsTableTableAnnotationComposer,
          $$MockProjectsTableTableCreateCompanionBuilder,
          $$MockProjectsTableTableUpdateCompanionBuilder,
          (
            MockProjectsTableData,
            BaseReferences<
              _$AppDatabase,
              $MockProjectsTableTable,
              MockProjectsTableData
            >,
          ),
          MockProjectsTableData,
          PrefetchHooks Function()
        > {
  $$MockProjectsTableTableTableManager(
    _$AppDatabase db,
    $MockProjectsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MockProjectsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MockProjectsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MockProjectsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MockProjectsTableCompanion(
                id: id,
                name: name,
                description: description,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MockProjectsTableCompanion.insert(
                id: id,
                name: name,
                description: description,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MockProjectsTableTable, MockProjectsTableData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $MockProjectsTableTable,
                    MockProjectsTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MockProjectsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MockProjectsTableTable,
      MockProjectsTableData,
      $$MockProjectsTableTableFilterComposer,
      $$MockProjectsTableTableOrderingComposer,
      $$MockProjectsTableTableAnnotationComposer,
      $$MockProjectsTableTableCreateCompanionBuilder,
      $$MockProjectsTableTableUpdateCompanionBuilder,
      (
        MockProjectsTableData,
        BaseReferences<
          _$AppDatabase,
          $MockProjectsTableTable,
          MockProjectsTableData
        >,
      ),
      MockProjectsTableData,
      PrefetchHooks Function()
    >;
typedef $$MockRulesTableTableCreateCompanionBuilder =
    MockRulesTableCompanion Function({
      required String id,
      required String name,
      Value<String> projectId,
      Value<String> projectName,
      Value<bool> isEnabled,
      Value<String> matchMethod,
      required String urlPattern,
      Value<bool> isRegex,
      Value<String> conditionLogic,
      Value<String> conditionsJson,
      Value<String> matchQueryParamsJson,
      Value<String> matchHeadersJson,
      Value<String> matchBody,
      Value<String> customVariablesJson,
      Value<int> responseStatusCode,
      Value<String> responseStatusReason,
      Value<String> responseHeadersJson,
      required String responseBody,
      Value<int> responseDelayMs,
      Value<String> description,
      Value<bool> isAiGenerated,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$MockRulesTableTableUpdateCompanionBuilder =
    MockRulesTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> projectId,
      Value<String> projectName,
      Value<bool> isEnabled,
      Value<String> matchMethod,
      Value<String> urlPattern,
      Value<bool> isRegex,
      Value<String> conditionLogic,
      Value<String> conditionsJson,
      Value<String> matchQueryParamsJson,
      Value<String> matchHeadersJson,
      Value<String> matchBody,
      Value<String> customVariablesJson,
      Value<int> responseStatusCode,
      Value<String> responseStatusReason,
      Value<String> responseHeadersJson,
      Value<String> responseBody,
      Value<int> responseDelayMs,
      Value<String> description,
      Value<bool> isAiGenerated,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$MockRulesTableTableFilterComposer
    extends Composer<_$AppDatabase, $MockRulesTableTable> {
  $$MockRulesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matchMethod => $composableBuilder(
    column: $table.matchMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get urlPattern => $composableBuilder(
    column: $table.urlPattern,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRegex => $composableBuilder(
    column: $table.isRegex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conditionLogic => $composableBuilder(
    column: $table.conditionLogic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conditionsJson => $composableBuilder(
    column: $table.conditionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matchQueryParamsJson => $composableBuilder(
    column: $table.matchQueryParamsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matchHeadersJson => $composableBuilder(
    column: $table.matchHeadersJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matchBody => $composableBuilder(
    column: $table.matchBody,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customVariablesJson => $composableBuilder(
    column: $table.customVariablesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get responseStatusCode => $composableBuilder(
    column: $table.responseStatusCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get responseStatusReason => $composableBuilder(
    column: $table.responseStatusReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get responseHeadersJson => $composableBuilder(
    column: $table.responseHeadersJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get responseBody => $composableBuilder(
    column: $table.responseBody,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get responseDelayMs => $composableBuilder(
    column: $table.responseDelayMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAiGenerated => $composableBuilder(
    column: $table.isAiGenerated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MockRulesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MockRulesTableTable> {
  $$MockRulesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matchMethod => $composableBuilder(
    column: $table.matchMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get urlPattern => $composableBuilder(
    column: $table.urlPattern,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRegex => $composableBuilder(
    column: $table.isRegex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conditionLogic => $composableBuilder(
    column: $table.conditionLogic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conditionsJson => $composableBuilder(
    column: $table.conditionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matchQueryParamsJson => $composableBuilder(
    column: $table.matchQueryParamsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matchHeadersJson => $composableBuilder(
    column: $table.matchHeadersJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matchBody => $composableBuilder(
    column: $table.matchBody,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customVariablesJson => $composableBuilder(
    column: $table.customVariablesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get responseStatusCode => $composableBuilder(
    column: $table.responseStatusCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get responseStatusReason => $composableBuilder(
    column: $table.responseStatusReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get responseHeadersJson => $composableBuilder(
    column: $table.responseHeadersJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get responseBody => $composableBuilder(
    column: $table.responseBody,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get responseDelayMs => $composableBuilder(
    column: $table.responseDelayMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAiGenerated => $composableBuilder(
    column: $table.isAiGenerated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MockRulesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MockRulesTableTable> {
  $$MockRulesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumn<String> get matchMethod => $composableBuilder(
    column: $table.matchMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get urlPattern => $composableBuilder(
    column: $table.urlPattern,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isRegex =>
      $composableBuilder(column: $table.isRegex, builder: (column) => column);

  GeneratedColumn<String> get conditionLogic => $composableBuilder(
    column: $table.conditionLogic,
    builder: (column) => column,
  );

  GeneratedColumn<String> get conditionsJson => $composableBuilder(
    column: $table.conditionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get matchQueryParamsJson => $composableBuilder(
    column: $table.matchQueryParamsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get matchHeadersJson => $composableBuilder(
    column: $table.matchHeadersJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get matchBody =>
      $composableBuilder(column: $table.matchBody, builder: (column) => column);

  GeneratedColumn<String> get customVariablesJson => $composableBuilder(
    column: $table.customVariablesJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get responseStatusCode => $composableBuilder(
    column: $table.responseStatusCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get responseStatusReason => $composableBuilder(
    column: $table.responseStatusReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get responseHeadersJson => $composableBuilder(
    column: $table.responseHeadersJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get responseBody => $composableBuilder(
    column: $table.responseBody,
    builder: (column) => column,
  );

  GeneratedColumn<int> get responseDelayMs => $composableBuilder(
    column: $table.responseDelayMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isAiGenerated => $composableBuilder(
    column: $table.isAiGenerated,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MockRulesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MockRulesTableTable,
          MockRulesTableData,
          $$MockRulesTableTableFilterComposer,
          $$MockRulesTableTableOrderingComposer,
          $$MockRulesTableTableAnnotationComposer,
          $$MockRulesTableTableCreateCompanionBuilder,
          $$MockRulesTableTableUpdateCompanionBuilder,
          (
            MockRulesTableData,
            BaseReferences<
              _$AppDatabase,
              $MockRulesTableTable,
              MockRulesTableData
            >,
          ),
          MockRulesTableData,
          PrefetchHooks Function()
        > {
  $$MockRulesTableTableTableManager(
    _$AppDatabase db,
    $MockRulesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MockRulesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MockRulesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MockRulesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> projectName = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<String> matchMethod = const Value.absent(),
                Value<String> urlPattern = const Value.absent(),
                Value<bool> isRegex = const Value.absent(),
                Value<String> conditionLogic = const Value.absent(),
                Value<String> conditionsJson = const Value.absent(),
                Value<String> matchQueryParamsJson = const Value.absent(),
                Value<String> matchHeadersJson = const Value.absent(),
                Value<String> matchBody = const Value.absent(),
                Value<String> customVariablesJson = const Value.absent(),
                Value<int> responseStatusCode = const Value.absent(),
                Value<String> responseStatusReason = const Value.absent(),
                Value<String> responseHeadersJson = const Value.absent(),
                Value<String> responseBody = const Value.absent(),
                Value<int> responseDelayMs = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<bool> isAiGenerated = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MockRulesTableCompanion(
                id: id,
                name: name,
                projectId: projectId,
                projectName: projectName,
                isEnabled: isEnabled,
                matchMethod: matchMethod,
                urlPattern: urlPattern,
                isRegex: isRegex,
                conditionLogic: conditionLogic,
                conditionsJson: conditionsJson,
                matchQueryParamsJson: matchQueryParamsJson,
                matchHeadersJson: matchHeadersJson,
                matchBody: matchBody,
                customVariablesJson: customVariablesJson,
                responseStatusCode: responseStatusCode,
                responseStatusReason: responseStatusReason,
                responseHeadersJson: responseHeadersJson,
                responseBody: responseBody,
                responseDelayMs: responseDelayMs,
                description: description,
                isAiGenerated: isAiGenerated,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> projectId = const Value.absent(),
                Value<String> projectName = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<String> matchMethod = const Value.absent(),
                required String urlPattern,
                Value<bool> isRegex = const Value.absent(),
                Value<String> conditionLogic = const Value.absent(),
                Value<String> conditionsJson = const Value.absent(),
                Value<String> matchQueryParamsJson = const Value.absent(),
                Value<String> matchHeadersJson = const Value.absent(),
                Value<String> matchBody = const Value.absent(),
                Value<String> customVariablesJson = const Value.absent(),
                Value<int> responseStatusCode = const Value.absent(),
                Value<String> responseStatusReason = const Value.absent(),
                Value<String> responseHeadersJson = const Value.absent(),
                required String responseBody,
                Value<int> responseDelayMs = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<bool> isAiGenerated = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MockRulesTableCompanion.insert(
                id: id,
                name: name,
                projectId: projectId,
                projectName: projectName,
                isEnabled: isEnabled,
                matchMethod: matchMethod,
                urlPattern: urlPattern,
                isRegex: isRegex,
                conditionLogic: conditionLogic,
                conditionsJson: conditionsJson,
                matchQueryParamsJson: matchQueryParamsJson,
                matchHeadersJson: matchHeadersJson,
                matchBody: matchBody,
                customVariablesJson: customVariablesJson,
                responseStatusCode: responseStatusCode,
                responseStatusReason: responseStatusReason,
                responseHeadersJson: responseHeadersJson,
                responseBody: responseBody,
                responseDelayMs: responseDelayMs,
                description: description,
                isAiGenerated: isAiGenerated,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MockRulesTableTable, MockRulesTableData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $MockRulesTableTable,
                    MockRulesTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MockRulesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MockRulesTableTable,
      MockRulesTableData,
      $$MockRulesTableTableFilterComposer,
      $$MockRulesTableTableOrderingComposer,
      $$MockRulesTableTableAnnotationComposer,
      $$MockRulesTableTableCreateCompanionBuilder,
      $$MockRulesTableTableUpdateCompanionBuilder,
      (
        MockRulesTableData,
        BaseReferences<_$AppDatabase, $MockRulesTableTable, MockRulesTableData>,
      ),
      MockRulesTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MockProjectsTableTableTableManager get mockProjectsTable =>
      $$MockProjectsTableTableTableManager(_db, _db.mockProjectsTable);
  $$MockRulesTableTableTableManager get mockRulesTable =>
      $$MockRulesTableTableTableManager(_db, _db.mockRulesTable);
}
