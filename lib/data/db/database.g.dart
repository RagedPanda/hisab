// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
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
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bankNameMeta = const VerificationMeta(
    'bankName',
  );
  @override
  late final GeneratedColumn<String> bankName = GeneratedColumn<String>(
    'bank_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _last4Meta = const VerificationMeta('last4');
  @override
  late final GeneratedColumn<String> last4 = GeneratedColumn<String>(
    'last4',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _smsKeyMeta = const VerificationMeta('smsKey');
  @override
  late final GeneratedColumn<String> smsKey = GeneratedColumn<String>(
    'sms_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _balanceMinorMeta = const VerificationMeta(
    'balanceMinor',
  );
  @override
  late final GeneratedColumn<int> balanceMinor = GeneratedColumn<int>(
    'balance_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _balanceAsOfMeta = const VerificationMeta(
    'balanceAsOf',
  );
  @override
  late final GeneratedColumn<DateTime> balanceAsOf = GeneratedColumn<DateTime>(
    'balance_as_of',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _includeInTotalMeta = const VerificationMeta(
    'includeInTotal',
  );
  @override
  late final GeneratedColumn<bool> includeInTotal = GeneratedColumn<bool>(
    'include_in_total',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("include_in_total" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statementDayMeta = const VerificationMeta(
    'statementDay',
  );
  @override
  late final GeneratedColumn<int> statementDay = GeneratedColumn<int>(
    'statement_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueDayMeta = const VerificationMeta('dueDay');
  @override
  late final GeneratedColumn<int> dueDay = GeneratedColumn<int>(
    'due_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creditLimitMinorMeta = const VerificationMeta(
    'creditLimitMinor',
  );
  @override
  late final GeneratedColumn<int> creditLimitMinor = GeneratedColumn<int>(
    'credit_limit_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastStatementMinorMeta =
      const VerificationMeta('lastStatementMinor');
  @override
  late final GeneratedColumn<int> lastStatementMinor = GeneratedColumn<int>(
    'last_statement_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastStatementAtMeta = const VerificationMeta(
    'lastStatementAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastStatementAt =
      GeneratedColumn<DateTime>(
        'last_statement_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    deletedAt,
    id,
    name,
    type,
    bankName,
    last4,
    smsKey,
    balanceMinor,
    balanceAsOf,
    includeInTotal,
    color,
    sortOrder,
    statementDay,
    dueDay,
    creditLimitMinor,
    lastStatementMinor,
    lastStatementAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Account> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
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
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('bank_name')) {
      context.handle(
        _bankNameMeta,
        bankName.isAcceptableOrUnknown(data['bank_name']!, _bankNameMeta),
      );
    }
    if (data.containsKey('last4')) {
      context.handle(
        _last4Meta,
        last4.isAcceptableOrUnknown(data['last4']!, _last4Meta),
      );
    }
    if (data.containsKey('sms_key')) {
      context.handle(
        _smsKeyMeta,
        smsKey.isAcceptableOrUnknown(data['sms_key']!, _smsKeyMeta),
      );
    }
    if (data.containsKey('balance_minor')) {
      context.handle(
        _balanceMinorMeta,
        balanceMinor.isAcceptableOrUnknown(
          data['balance_minor']!,
          _balanceMinorMeta,
        ),
      );
    }
    if (data.containsKey('balance_as_of')) {
      context.handle(
        _balanceAsOfMeta,
        balanceAsOf.isAcceptableOrUnknown(
          data['balance_as_of']!,
          _balanceAsOfMeta,
        ),
      );
    }
    if (data.containsKey('include_in_total')) {
      context.handle(
        _includeInTotalMeta,
        includeInTotal.isAcceptableOrUnknown(
          data['include_in_total']!,
          _includeInTotalMeta,
        ),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('statement_day')) {
      context.handle(
        _statementDayMeta,
        statementDay.isAcceptableOrUnknown(
          data['statement_day']!,
          _statementDayMeta,
        ),
      );
    }
    if (data.containsKey('due_day')) {
      context.handle(
        _dueDayMeta,
        dueDay.isAcceptableOrUnknown(data['due_day']!, _dueDayMeta),
      );
    }
    if (data.containsKey('credit_limit_minor')) {
      context.handle(
        _creditLimitMinorMeta,
        creditLimitMinor.isAcceptableOrUnknown(
          data['credit_limit_minor']!,
          _creditLimitMinorMeta,
        ),
      );
    }
    if (data.containsKey('last_statement_minor')) {
      context.handle(
        _lastStatementMinorMeta,
        lastStatementMinor.isAcceptableOrUnknown(
          data['last_statement_minor']!,
          _lastStatementMinorMeta,
        ),
      );
    }
    if (data.containsKey('last_statement_at')) {
      context.handle(
        _lastStatementAtMeta,
        lastStatementAt.isAcceptableOrUnknown(
          data['last_statement_at']!,
          _lastStatementAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      bankName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_name'],
      ),
      last4: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last4'],
      ),
      smsKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sms_key'],
      ),
      balanceMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}balance_minor'],
      )!,
      balanceAsOf: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}balance_as_of'],
      ),
      includeInTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}include_in_total'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      statementDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}statement_day'],
      ),
      dueDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_day'],
      ),
      creditLimitMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}credit_limit_minor'],
      ),
      lastStatementMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_statement_minor'],
      ),
      lastStatementAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_statement_at'],
      ),
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class Account extends DataClass implements Insertable<Account> {
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String id;
  final String name;

  /// bank | cash | card | wallet
  final String type;
  final String? bankName;
  final String? last4;

  /// Key produced by the SMS parser ("HDFC Bank:ac:1234") so later messages
  /// map to this account automatically.
  final String? smsKey;
  final int balanceMinor;
  final DateTime? balanceAsOf;
  final bool includeInTotal;
  final int color;
  final int sortOrder;

  /// Credit cards only: day of month the statement is generated (1-31; short
  /// months clamp to their last day) and the day the bill is due.
  final int? statementDay;
  final int? dueDay;
  final int? creditLimitMinor;

  /// Amount billed on the most recent statement and that statement's date.
  final int? lastStatementMinor;
  final DateTime? lastStatementAt;
  const Account({
    required this.updatedAt,
    this.deletedAt,
    required this.id,
    required this.name,
    required this.type,
    this.bankName,
    this.last4,
    this.smsKey,
    required this.balanceMinor,
    this.balanceAsOf,
    required this.includeInTotal,
    required this.color,
    required this.sortOrder,
    this.statementDay,
    this.dueDay,
    this.creditLimitMinor,
    this.lastStatementMinor,
    this.lastStatementAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || bankName != null) {
      map['bank_name'] = Variable<String>(bankName);
    }
    if (!nullToAbsent || last4 != null) {
      map['last4'] = Variable<String>(last4);
    }
    if (!nullToAbsent || smsKey != null) {
      map['sms_key'] = Variable<String>(smsKey);
    }
    map['balance_minor'] = Variable<int>(balanceMinor);
    if (!nullToAbsent || balanceAsOf != null) {
      map['balance_as_of'] = Variable<DateTime>(balanceAsOf);
    }
    map['include_in_total'] = Variable<bool>(includeInTotal);
    map['color'] = Variable<int>(color);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || statementDay != null) {
      map['statement_day'] = Variable<int>(statementDay);
    }
    if (!nullToAbsent || dueDay != null) {
      map['due_day'] = Variable<int>(dueDay);
    }
    if (!nullToAbsent || creditLimitMinor != null) {
      map['credit_limit_minor'] = Variable<int>(creditLimitMinor);
    }
    if (!nullToAbsent || lastStatementMinor != null) {
      map['last_statement_minor'] = Variable<int>(lastStatementMinor);
    }
    if (!nullToAbsent || lastStatementAt != null) {
      map['last_statement_at'] = Variable<DateTime>(lastStatementAt);
    }
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      name: Value(name),
      type: Value(type),
      bankName: bankName == null && nullToAbsent
          ? const Value.absent()
          : Value(bankName),
      last4: last4 == null && nullToAbsent
          ? const Value.absent()
          : Value(last4),
      smsKey: smsKey == null && nullToAbsent
          ? const Value.absent()
          : Value(smsKey),
      balanceMinor: Value(balanceMinor),
      balanceAsOf: balanceAsOf == null && nullToAbsent
          ? const Value.absent()
          : Value(balanceAsOf),
      includeInTotal: Value(includeInTotal),
      color: Value(color),
      sortOrder: Value(sortOrder),
      statementDay: statementDay == null && nullToAbsent
          ? const Value.absent()
          : Value(statementDay),
      dueDay: dueDay == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDay),
      creditLimitMinor: creditLimitMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(creditLimitMinor),
      lastStatementMinor: lastStatementMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(lastStatementMinor),
      lastStatementAt: lastStatementAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastStatementAt),
    );
  }

  factory Account.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      bankName: serializer.fromJson<String?>(json['bankName']),
      last4: serializer.fromJson<String?>(json['last4']),
      smsKey: serializer.fromJson<String?>(json['smsKey']),
      balanceMinor: serializer.fromJson<int>(json['balanceMinor']),
      balanceAsOf: serializer.fromJson<DateTime?>(json['balanceAsOf']),
      includeInTotal: serializer.fromJson<bool>(json['includeInTotal']),
      color: serializer.fromJson<int>(json['color']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      statementDay: serializer.fromJson<int?>(json['statementDay']),
      dueDay: serializer.fromJson<int?>(json['dueDay']),
      creditLimitMinor: serializer.fromJson<int?>(json['creditLimitMinor']),
      lastStatementMinor: serializer.fromJson<int?>(json['lastStatementMinor']),
      lastStatementAt: serializer.fromJson<DateTime?>(json['lastStatementAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'bankName': serializer.toJson<String?>(bankName),
      'last4': serializer.toJson<String?>(last4),
      'smsKey': serializer.toJson<String?>(smsKey),
      'balanceMinor': serializer.toJson<int>(balanceMinor),
      'balanceAsOf': serializer.toJson<DateTime?>(balanceAsOf),
      'includeInTotal': serializer.toJson<bool>(includeInTotal),
      'color': serializer.toJson<int>(color),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'statementDay': serializer.toJson<int?>(statementDay),
      'dueDay': serializer.toJson<int?>(dueDay),
      'creditLimitMinor': serializer.toJson<int?>(creditLimitMinor),
      'lastStatementMinor': serializer.toJson<int?>(lastStatementMinor),
      'lastStatementAt': serializer.toJson<DateTime?>(lastStatementAt),
    };
  }

  Account copyWith({
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? id,
    String? name,
    String? type,
    Value<String?> bankName = const Value.absent(),
    Value<String?> last4 = const Value.absent(),
    Value<String?> smsKey = const Value.absent(),
    int? balanceMinor,
    Value<DateTime?> balanceAsOf = const Value.absent(),
    bool? includeInTotal,
    int? color,
    int? sortOrder,
    Value<int?> statementDay = const Value.absent(),
    Value<int?> dueDay = const Value.absent(),
    Value<int?> creditLimitMinor = const Value.absent(),
    Value<int?> lastStatementMinor = const Value.absent(),
    Value<DateTime?> lastStatementAt = const Value.absent(),
  }) => Account(
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    bankName: bankName.present ? bankName.value : this.bankName,
    last4: last4.present ? last4.value : this.last4,
    smsKey: smsKey.present ? smsKey.value : this.smsKey,
    balanceMinor: balanceMinor ?? this.balanceMinor,
    balanceAsOf: balanceAsOf.present ? balanceAsOf.value : this.balanceAsOf,
    includeInTotal: includeInTotal ?? this.includeInTotal,
    color: color ?? this.color,
    sortOrder: sortOrder ?? this.sortOrder,
    statementDay: statementDay.present ? statementDay.value : this.statementDay,
    dueDay: dueDay.present ? dueDay.value : this.dueDay,
    creditLimitMinor: creditLimitMinor.present
        ? creditLimitMinor.value
        : this.creditLimitMinor,
    lastStatementMinor: lastStatementMinor.present
        ? lastStatementMinor.value
        : this.lastStatementMinor,
    lastStatementAt: lastStatementAt.present
        ? lastStatementAt.value
        : this.lastStatementAt,
  );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      bankName: data.bankName.present ? data.bankName.value : this.bankName,
      last4: data.last4.present ? data.last4.value : this.last4,
      smsKey: data.smsKey.present ? data.smsKey.value : this.smsKey,
      balanceMinor: data.balanceMinor.present
          ? data.balanceMinor.value
          : this.balanceMinor,
      balanceAsOf: data.balanceAsOf.present
          ? data.balanceAsOf.value
          : this.balanceAsOf,
      includeInTotal: data.includeInTotal.present
          ? data.includeInTotal.value
          : this.includeInTotal,
      color: data.color.present ? data.color.value : this.color,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      statementDay: data.statementDay.present
          ? data.statementDay.value
          : this.statementDay,
      dueDay: data.dueDay.present ? data.dueDay.value : this.dueDay,
      creditLimitMinor: data.creditLimitMinor.present
          ? data.creditLimitMinor.value
          : this.creditLimitMinor,
      lastStatementMinor: data.lastStatementMinor.present
          ? data.lastStatementMinor.value
          : this.lastStatementMinor,
      lastStatementAt: data.lastStatementAt.present
          ? data.lastStatementAt.value
          : this.lastStatementAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('bankName: $bankName, ')
          ..write('last4: $last4, ')
          ..write('smsKey: $smsKey, ')
          ..write('balanceMinor: $balanceMinor, ')
          ..write('balanceAsOf: $balanceAsOf, ')
          ..write('includeInTotal: $includeInTotal, ')
          ..write('color: $color, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('statementDay: $statementDay, ')
          ..write('dueDay: $dueDay, ')
          ..write('creditLimitMinor: $creditLimitMinor, ')
          ..write('lastStatementMinor: $lastStatementMinor, ')
          ..write('lastStatementAt: $lastStatementAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    updatedAt,
    deletedAt,
    id,
    name,
    type,
    bankName,
    last4,
    smsKey,
    balanceMinor,
    balanceAsOf,
    includeInTotal,
    color,
    sortOrder,
    statementDay,
    dueDay,
    creditLimitMinor,
    lastStatementMinor,
    lastStatementAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.bankName == this.bankName &&
          other.last4 == this.last4 &&
          other.smsKey == this.smsKey &&
          other.balanceMinor == this.balanceMinor &&
          other.balanceAsOf == this.balanceAsOf &&
          other.includeInTotal == this.includeInTotal &&
          other.color == this.color &&
          other.sortOrder == this.sortOrder &&
          other.statementDay == this.statementDay &&
          other.dueDay == this.dueDay &&
          other.creditLimitMinor == this.creditLimitMinor &&
          other.lastStatementMinor == this.lastStatementMinor &&
          other.lastStatementAt == this.lastStatementAt);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> id;
  final Value<String> name;
  final Value<String> type;
  final Value<String?> bankName;
  final Value<String?> last4;
  final Value<String?> smsKey;
  final Value<int> balanceMinor;
  final Value<DateTime?> balanceAsOf;
  final Value<bool> includeInTotal;
  final Value<int> color;
  final Value<int> sortOrder;
  final Value<int?> statementDay;
  final Value<int?> dueDay;
  final Value<int?> creditLimitMinor;
  final Value<int?> lastStatementMinor;
  final Value<DateTime?> lastStatementAt;
  final Value<int> rowid;
  const AccountsCompanion({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.bankName = const Value.absent(),
    this.last4 = const Value.absent(),
    this.smsKey = const Value.absent(),
    this.balanceMinor = const Value.absent(),
    this.balanceAsOf = const Value.absent(),
    this.includeInTotal = const Value.absent(),
    this.color = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.statementDay = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.creditLimitMinor = const Value.absent(),
    this.lastStatementMinor = const Value.absent(),
    this.lastStatementAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String id,
    required String name,
    required String type,
    this.bankName = const Value.absent(),
    this.last4 = const Value.absent(),
    this.smsKey = const Value.absent(),
    this.balanceMinor = const Value.absent(),
    this.balanceAsOf = const Value.absent(),
    this.includeInTotal = const Value.absent(),
    required int color,
    this.sortOrder = const Value.absent(),
    this.statementDay = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.creditLimitMinor = const Value.absent(),
    this.lastStatementMinor = const Value.absent(),
    this.lastStatementAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       type = Value(type),
       color = Value(color);
  static Insertable<Account> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? bankName,
    Expression<String>? last4,
    Expression<String>? smsKey,
    Expression<int>? balanceMinor,
    Expression<DateTime>? balanceAsOf,
    Expression<bool>? includeInTotal,
    Expression<int>? color,
    Expression<int>? sortOrder,
    Expression<int>? statementDay,
    Expression<int>? dueDay,
    Expression<int>? creditLimitMinor,
    Expression<int>? lastStatementMinor,
    Expression<DateTime>? lastStatementAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (bankName != null) 'bank_name': bankName,
      if (last4 != null) 'last4': last4,
      if (smsKey != null) 'sms_key': smsKey,
      if (balanceMinor != null) 'balance_minor': balanceMinor,
      if (balanceAsOf != null) 'balance_as_of': balanceAsOf,
      if (includeInTotal != null) 'include_in_total': includeInTotal,
      if (color != null) 'color': color,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (statementDay != null) 'statement_day': statementDay,
      if (dueDay != null) 'due_day': dueDay,
      if (creditLimitMinor != null) 'credit_limit_minor': creditLimitMinor,
      if (lastStatementMinor != null)
        'last_statement_minor': lastStatementMinor,
      if (lastStatementAt != null) 'last_statement_at': lastStatementAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? id,
    Value<String>? name,
    Value<String>? type,
    Value<String?>? bankName,
    Value<String?>? last4,
    Value<String?>? smsKey,
    Value<int>? balanceMinor,
    Value<DateTime?>? balanceAsOf,
    Value<bool>? includeInTotal,
    Value<int>? color,
    Value<int>? sortOrder,
    Value<int?>? statementDay,
    Value<int?>? dueDay,
    Value<int?>? creditLimitMinor,
    Value<int?>? lastStatementMinor,
    Value<DateTime?>? lastStatementAt,
    Value<int>? rowid,
  }) {
    return AccountsCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      bankName: bankName ?? this.bankName,
      last4: last4 ?? this.last4,
      smsKey: smsKey ?? this.smsKey,
      balanceMinor: balanceMinor ?? this.balanceMinor,
      balanceAsOf: balanceAsOf ?? this.balanceAsOf,
      includeInTotal: includeInTotal ?? this.includeInTotal,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      statementDay: statementDay ?? this.statementDay,
      dueDay: dueDay ?? this.dueDay,
      creditLimitMinor: creditLimitMinor ?? this.creditLimitMinor,
      lastStatementMinor: lastStatementMinor ?? this.lastStatementMinor,
      lastStatementAt: lastStatementAt ?? this.lastStatementAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (bankName.present) {
      map['bank_name'] = Variable<String>(bankName.value);
    }
    if (last4.present) {
      map['last4'] = Variable<String>(last4.value);
    }
    if (smsKey.present) {
      map['sms_key'] = Variable<String>(smsKey.value);
    }
    if (balanceMinor.present) {
      map['balance_minor'] = Variable<int>(balanceMinor.value);
    }
    if (balanceAsOf.present) {
      map['balance_as_of'] = Variable<DateTime>(balanceAsOf.value);
    }
    if (includeInTotal.present) {
      map['include_in_total'] = Variable<bool>(includeInTotal.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (statementDay.present) {
      map['statement_day'] = Variable<int>(statementDay.value);
    }
    if (dueDay.present) {
      map['due_day'] = Variable<int>(dueDay.value);
    }
    if (creditLimitMinor.present) {
      map['credit_limit_minor'] = Variable<int>(creditLimitMinor.value);
    }
    if (lastStatementMinor.present) {
      map['last_statement_minor'] = Variable<int>(lastStatementMinor.value);
    }
    if (lastStatementAt.present) {
      map['last_statement_at'] = Variable<DateTime>(lastStatementAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('bankName: $bankName, ')
          ..write('last4: $last4, ')
          ..write('smsKey: $smsKey, ')
          ..write('balanceMinor: $balanceMinor, ')
          ..write('balanceAsOf: $balanceAsOf, ')
          ..write('includeInTotal: $includeInTotal, ')
          ..write('color: $color, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('statementDay: $statementDay, ')
          ..write('dueDay: $dueDay, ')
          ..write('creditLimitMinor: $creditLimitMinor, ')
          ..write('lastStatementMinor: $lastStatementMinor, ')
          ..write('lastStatementAt: $lastStatementAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seedKeyMeta = const VerificationMeta(
    'seedKey',
  );
  @override
  late final GeneratedColumn<String> seedKey = GeneratedColumn<String>(
    'seed_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _unitsMeta = const VerificationMeta('units');
  @override
  late final GeneratedColumn<String> units = GeneratedColumn<String>(
    'units',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _packKeyMeta = const VerificationMeta(
    'packKey',
  );
  @override
  late final GeneratedColumn<String> packKey = GeneratedColumn<String>(
    'pack_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    deletedAt,
    id,
    seedKey,
    name,
    icon,
    color,
    kind,
    parentId,
    sortOrder,
    isArchived,
    units,
    packKey,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('seed_key')) {
      context.handle(
        _seedKeyMeta,
        seedKey.isAcceptableOrUnknown(data['seed_key']!, _seedKeyMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    } else if (isInserting) {
      context.missing(_iconMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('units')) {
      context.handle(
        _unitsMeta,
        units.isAcceptableOrUnknown(data['units']!, _unitsMeta),
      );
    }
    if (data.containsKey('pack_key')) {
      context.handle(
        _packKeyMeta,
        packKey.isAcceptableOrUnknown(data['pack_key']!, _packKeyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      seedKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seed_key'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      units: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}units'],
      )!,
      packKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pack_key'],
      ),
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String id;

  /// Catalog key for seeded categories; null for user-created ones.
  final String? seedKey;
  final String name;
  final String icon;
  final int color;

  /// expense | income | transfer
  final String kind;
  final String? parentId;
  final int sortOrder;
  final bool isArchived;

  /// Comma separated suggested units for item entry ("L,ml,kg").
  final String units;

  /// Category pack this row came from (Settings > Categories > Add a pack);
  /// null for catalog and user-created categories.
  final String? packKey;
  const Category({
    required this.updatedAt,
    this.deletedAt,
    required this.id,
    this.seedKey,
    required this.name,
    required this.icon,
    required this.color,
    required this.kind,
    this.parentId,
    required this.sortOrder,
    required this.isArchived,
    required this.units,
    this.packKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || seedKey != null) {
      map['seed_key'] = Variable<String>(seedKey);
    }
    map['name'] = Variable<String>(name);
    map['icon'] = Variable<String>(icon);
    map['color'] = Variable<int>(color);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_archived'] = Variable<bool>(isArchived);
    map['units'] = Variable<String>(units);
    if (!nullToAbsent || packKey != null) {
      map['pack_key'] = Variable<String>(packKey);
    }
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      seedKey: seedKey == null && nullToAbsent
          ? const Value.absent()
          : Value(seedKey),
      name: Value(name),
      icon: Value(icon),
      color: Value(color),
      kind: Value(kind),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      sortOrder: Value(sortOrder),
      isArchived: Value(isArchived),
      units: Value(units),
      packKey: packKey == null && nullToAbsent
          ? const Value.absent()
          : Value(packKey),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<String>(json['id']),
      seedKey: serializer.fromJson<String?>(json['seedKey']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String>(json['icon']),
      color: serializer.fromJson<int>(json['color']),
      kind: serializer.fromJson<String>(json['kind']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      units: serializer.fromJson<String>(json['units']),
      packKey: serializer.fromJson<String?>(json['packKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<String>(id),
      'seedKey': serializer.toJson<String?>(seedKey),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String>(icon),
      'color': serializer.toJson<int>(color),
      'kind': serializer.toJson<String>(kind),
      'parentId': serializer.toJson<String?>(parentId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isArchived': serializer.toJson<bool>(isArchived),
      'units': serializer.toJson<String>(units),
      'packKey': serializer.toJson<String?>(packKey),
    };
  }

  Category copyWith({
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? id,
    Value<String?> seedKey = const Value.absent(),
    String? name,
    String? icon,
    int? color,
    String? kind,
    Value<String?> parentId = const Value.absent(),
    int? sortOrder,
    bool? isArchived,
    String? units,
    Value<String?> packKey = const Value.absent(),
  }) => Category(
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    seedKey: seedKey.present ? seedKey.value : this.seedKey,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    kind: kind ?? this.kind,
    parentId: parentId.present ? parentId.value : this.parentId,
    sortOrder: sortOrder ?? this.sortOrder,
    isArchived: isArchived ?? this.isArchived,
    units: units ?? this.units,
    packKey: packKey.present ? packKey.value : this.packKey,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      seedKey: data.seedKey.present ? data.seedKey.value : this.seedKey,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      color: data.color.present ? data.color.value : this.color,
      kind: data.kind.present ? data.kind.value : this.kind,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      units: data.units.present ? data.units.value : this.units,
      packKey: data.packKey.present ? data.packKey.value : this.packKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('seedKey: $seedKey, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('kind: $kind, ')
          ..write('parentId: $parentId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isArchived: $isArchived, ')
          ..write('units: $units, ')
          ..write('packKey: $packKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    updatedAt,
    deletedAt,
    id,
    seedKey,
    name,
    icon,
    color,
    kind,
    parentId,
    sortOrder,
    isArchived,
    units,
    packKey,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.seedKey == this.seedKey &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.color == this.color &&
          other.kind == this.kind &&
          other.parentId == this.parentId &&
          other.sortOrder == this.sortOrder &&
          other.isArchived == this.isArchived &&
          other.units == this.units &&
          other.packKey == this.packKey);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> id;
  final Value<String?> seedKey;
  final Value<String> name;
  final Value<String> icon;
  final Value<int> color;
  final Value<String> kind;
  final Value<String?> parentId;
  final Value<int> sortOrder;
  final Value<bool> isArchived;
  final Value<String> units;
  final Value<String?> packKey;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.seedKey = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.kind = const Value.absent(),
    this.parentId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.units = const Value.absent(),
    this.packKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String id,
    this.seedKey = const Value.absent(),
    required String name,
    required String icon,
    required int color,
    required String kind,
    this.parentId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.units = const Value.absent(),
    this.packKey = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       icon = Value(icon),
       color = Value(color),
       kind = Value(kind);
  static Insertable<Category> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? id,
    Expression<String>? seedKey,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<int>? color,
    Expression<String>? kind,
    Expression<String>? parentId,
    Expression<int>? sortOrder,
    Expression<bool>? isArchived,
    Expression<String>? units,
    Expression<String>? packKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (seedKey != null) 'seed_key': seedKey,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (kind != null) 'kind': kind,
      if (parentId != null) 'parent_id': parentId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isArchived != null) 'is_archived': isArchived,
      if (units != null) 'units': units,
      if (packKey != null) 'pack_key': packKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? id,
    Value<String?>? seedKey,
    Value<String>? name,
    Value<String>? icon,
    Value<int>? color,
    Value<String>? kind,
    Value<String?>? parentId,
    Value<int>? sortOrder,
    Value<bool>? isArchived,
    Value<String>? units,
    Value<String?>? packKey,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      seedKey: seedKey ?? this.seedKey,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      kind: kind ?? this.kind,
      parentId: parentId ?? this.parentId,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
      units: units ?? this.units,
      packKey: packKey ?? this.packKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (seedKey.present) {
      map['seed_key'] = Variable<String>(seedKey.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (units.present) {
      map['units'] = Variable<String>(units.value);
    }
    if (packKey.present) {
      map['pack_key'] = Variable<String>(packKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('seedKey: $seedKey, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('kind: $kind, ')
          ..write('parentId: $parentId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isArchived: $isArchived, ')
          ..write('units: $units, ')
          ..write('packKey: $packKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EntriesTable extends Entries with TableInfo<$EntriesTable, Entry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('INR'),
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _toAccountIdMeta = const VerificationMeta(
    'toAccountId',
  );
  @override
  late final GeneratedColumn<String> toAccountId = GeneratedColumn<String>(
    'to_account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _payeeMeta = const VerificationMeta('payee');
  @override
  late final GeneratedColumn<String> payee = GeneratedColumn<String>(
    'payee',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _smsIdMeta = const VerificationMeta('smsId');
  @override
  late final GeneratedColumn<String> smsId = GeneratedColumn<String>(
    'sms_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paidByMemberIdMeta = const VerificationMeta(
    'paidByMemberId',
  );
  @override
  late final GeneratedColumn<String> paidByMemberId = GeneratedColumn<String>(
    'paid_by_member_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _splitMethodMeta = const VerificationMeta(
    'splitMethod',
  );
  @override
  late final GeneratedColumn<String> splitMethod = GeneratedColumn<String>(
    'split_method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recurringIdMeta = const VerificationMeta(
    'recurringId',
  );
  @override
  late final GeneratedColumn<String> recurringId = GeneratedColumn<String>(
    'recurring_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    updatedAt,
    deletedAt,
    id,
    kind,
    amountMinor,
    currency,
    occurredAt,
    categoryId,
    accountId,
    toAccountId,
    note,
    payee,
    source,
    smsId,
    groupId,
    paidByMemberId,
    splitMethod,
    tags,
    projectId,
    recurringId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<Entry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('to_account_id')) {
      context.handle(
        _toAccountIdMeta,
        toAccountId.isAcceptableOrUnknown(
          data['to_account_id']!,
          _toAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('payee')) {
      context.handle(
        _payeeMeta,
        payee.isAcceptableOrUnknown(data['payee']!, _payeeMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('sms_id')) {
      context.handle(
        _smsIdMeta,
        smsId.isAcceptableOrUnknown(data['sms_id']!, _smsIdMeta),
      );
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    }
    if (data.containsKey('paid_by_member_id')) {
      context.handle(
        _paidByMemberIdMeta,
        paidByMemberId.isAcceptableOrUnknown(
          data['paid_by_member_id']!,
          _paidByMemberIdMeta,
        ),
      );
    }
    if (data.containsKey('split_method')) {
      context.handle(
        _splitMethodMeta,
        splitMethod.isAcceptableOrUnknown(
          data['split_method']!,
          _splitMethodMeta,
        ),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    }
    if (data.containsKey('recurring_id')) {
      context.handle(
        _recurringIdMeta,
        recurringId.isAcceptableOrUnknown(
          data['recurring_id']!,
          _recurringIdMeta,
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
  Entry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Entry(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      toAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_account_id'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      payee: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payee'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      smsId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sms_id'],
      ),
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      ),
      paidByMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paid_by_member_id'],
      ),
      splitMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}split_method'],
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      ),
      recurringId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurring_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $EntriesTable createAlias(String alias) {
    return $EntriesTable(attachedDatabase, alias);
  }
}

class Entry extends DataClass implements Insertable<Entry> {
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String id;

  /// expense | income | transfer
  final String kind;
  final int amountMinor;
  final String currency;
  final DateTime occurredAt;
  final String? categoryId;
  final String? accountId;
  final String? toAccountId;
  final String note;
  final String? payee;

  /// manual | sms | import | recurring
  final String source;
  final String? smsId;
  final String? groupId;
  final String? paidByMemberId;
  final String? splitMethod;
  final String tags;

  /// Project (vehicle, trip, construction...) this entry is tracked under.
  final String? projectId;

  /// Recurring rule that produced (or started) this entry.
  final String? recurringId;
  final DateTime createdAt;
  const Entry({
    required this.updatedAt,
    this.deletedAt,
    required this.id,
    required this.kind,
    required this.amountMinor,
    required this.currency,
    required this.occurredAt,
    this.categoryId,
    this.accountId,
    this.toAccountId,
    required this.note,
    this.payee,
    required this.source,
    this.smsId,
    this.groupId,
    this.paidByMemberId,
    this.splitMethod,
    required this.tags,
    this.projectId,
    this.recurringId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['amount_minor'] = Variable<int>(amountMinor);
    map['currency'] = Variable<String>(currency);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    if (!nullToAbsent || toAccountId != null) {
      map['to_account_id'] = Variable<String>(toAccountId);
    }
    map['note'] = Variable<String>(note);
    if (!nullToAbsent || payee != null) {
      map['payee'] = Variable<String>(payee);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || smsId != null) {
      map['sms_id'] = Variable<String>(smsId);
    }
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
    }
    if (!nullToAbsent || paidByMemberId != null) {
      map['paid_by_member_id'] = Variable<String>(paidByMemberId);
    }
    if (!nullToAbsent || splitMethod != null) {
      map['split_method'] = Variable<String>(splitMethod);
    }
    map['tags'] = Variable<String>(tags);
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<String>(projectId);
    }
    if (!nullToAbsent || recurringId != null) {
      map['recurring_id'] = Variable<String>(recurringId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EntriesCompanion toCompanion(bool nullToAbsent) {
    return EntriesCompanion(
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      kind: Value(kind),
      amountMinor: Value(amountMinor),
      currency: Value(currency),
      occurredAt: Value(occurredAt),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      toAccountId: toAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(toAccountId),
      note: Value(note),
      payee: payee == null && nullToAbsent
          ? const Value.absent()
          : Value(payee),
      source: Value(source),
      smsId: smsId == null && nullToAbsent
          ? const Value.absent()
          : Value(smsId),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      paidByMemberId: paidByMemberId == null && nullToAbsent
          ? const Value.absent()
          : Value(paidByMemberId),
      splitMethod: splitMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(splitMethod),
      tags: Value(tags),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      recurringId: recurringId == null && nullToAbsent
          ? const Value.absent()
          : Value(recurringId),
      createdAt: Value(createdAt),
    );
  }

  factory Entry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Entry(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      currency: serializer.fromJson<String>(json['currency']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      toAccountId: serializer.fromJson<String?>(json['toAccountId']),
      note: serializer.fromJson<String>(json['note']),
      payee: serializer.fromJson<String?>(json['payee']),
      source: serializer.fromJson<String>(json['source']),
      smsId: serializer.fromJson<String?>(json['smsId']),
      groupId: serializer.fromJson<String?>(json['groupId']),
      paidByMemberId: serializer.fromJson<String?>(json['paidByMemberId']),
      splitMethod: serializer.fromJson<String?>(json['splitMethod']),
      tags: serializer.fromJson<String>(json['tags']),
      projectId: serializer.fromJson<String?>(json['projectId']),
      recurringId: serializer.fromJson<String?>(json['recurringId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'currency': serializer.toJson<String>(currency),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'categoryId': serializer.toJson<String?>(categoryId),
      'accountId': serializer.toJson<String?>(accountId),
      'toAccountId': serializer.toJson<String?>(toAccountId),
      'note': serializer.toJson<String>(note),
      'payee': serializer.toJson<String?>(payee),
      'source': serializer.toJson<String>(source),
      'smsId': serializer.toJson<String?>(smsId),
      'groupId': serializer.toJson<String?>(groupId),
      'paidByMemberId': serializer.toJson<String?>(paidByMemberId),
      'splitMethod': serializer.toJson<String?>(splitMethod),
      'tags': serializer.toJson<String>(tags),
      'projectId': serializer.toJson<String?>(projectId),
      'recurringId': serializer.toJson<String?>(recurringId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Entry copyWith({
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? id,
    String? kind,
    int? amountMinor,
    String? currency,
    DateTime? occurredAt,
    Value<String?> categoryId = const Value.absent(),
    Value<String?> accountId = const Value.absent(),
    Value<String?> toAccountId = const Value.absent(),
    String? note,
    Value<String?> payee = const Value.absent(),
    String? source,
    Value<String?> smsId = const Value.absent(),
    Value<String?> groupId = const Value.absent(),
    Value<String?> paidByMemberId = const Value.absent(),
    Value<String?> splitMethod = const Value.absent(),
    String? tags,
    Value<String?> projectId = const Value.absent(),
    Value<String?> recurringId = const Value.absent(),
    DateTime? createdAt,
  }) => Entry(
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    kind: kind ?? this.kind,
    amountMinor: amountMinor ?? this.amountMinor,
    currency: currency ?? this.currency,
    occurredAt: occurredAt ?? this.occurredAt,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    accountId: accountId.present ? accountId.value : this.accountId,
    toAccountId: toAccountId.present ? toAccountId.value : this.toAccountId,
    note: note ?? this.note,
    payee: payee.present ? payee.value : this.payee,
    source: source ?? this.source,
    smsId: smsId.present ? smsId.value : this.smsId,
    groupId: groupId.present ? groupId.value : this.groupId,
    paidByMemberId: paidByMemberId.present
        ? paidByMemberId.value
        : this.paidByMemberId,
    splitMethod: splitMethod.present ? splitMethod.value : this.splitMethod,
    tags: tags ?? this.tags,
    projectId: projectId.present ? projectId.value : this.projectId,
    recurringId: recurringId.present ? recurringId.value : this.recurringId,
    createdAt: createdAt ?? this.createdAt,
  );
  Entry copyWithCompanion(EntriesCompanion data) {
    return Entry(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      currency: data.currency.present ? data.currency.value : this.currency,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      toAccountId: data.toAccountId.present
          ? data.toAccountId.value
          : this.toAccountId,
      note: data.note.present ? data.note.value : this.note,
      payee: data.payee.present ? data.payee.value : this.payee,
      source: data.source.present ? data.source.value : this.source,
      smsId: data.smsId.present ? data.smsId.value : this.smsId,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      paidByMemberId: data.paidByMemberId.present
          ? data.paidByMemberId.value
          : this.paidByMemberId,
      splitMethod: data.splitMethod.present
          ? data.splitMethod.value
          : this.splitMethod,
      tags: data.tags.present ? data.tags.value : this.tags,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      recurringId: data.recurringId.present
          ? data.recurringId.value
          : this.recurringId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Entry(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('note: $note, ')
          ..write('payee: $payee, ')
          ..write('source: $source, ')
          ..write('smsId: $smsId, ')
          ..write('groupId: $groupId, ')
          ..write('paidByMemberId: $paidByMemberId, ')
          ..write('splitMethod: $splitMethod, ')
          ..write('tags: $tags, ')
          ..write('projectId: $projectId, ')
          ..write('recurringId: $recurringId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    updatedAt,
    deletedAt,
    id,
    kind,
    amountMinor,
    currency,
    occurredAt,
    categoryId,
    accountId,
    toAccountId,
    note,
    payee,
    source,
    smsId,
    groupId,
    paidByMemberId,
    splitMethod,
    tags,
    projectId,
    recurringId,
    createdAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Entry &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.amountMinor == this.amountMinor &&
          other.currency == this.currency &&
          other.occurredAt == this.occurredAt &&
          other.categoryId == this.categoryId &&
          other.accountId == this.accountId &&
          other.toAccountId == this.toAccountId &&
          other.note == this.note &&
          other.payee == this.payee &&
          other.source == this.source &&
          other.smsId == this.smsId &&
          other.groupId == this.groupId &&
          other.paidByMemberId == this.paidByMemberId &&
          other.splitMethod == this.splitMethod &&
          other.tags == this.tags &&
          other.projectId == this.projectId &&
          other.recurringId == this.recurringId &&
          other.createdAt == this.createdAt);
}

class EntriesCompanion extends UpdateCompanion<Entry> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> id;
  final Value<String> kind;
  final Value<int> amountMinor;
  final Value<String> currency;
  final Value<DateTime> occurredAt;
  final Value<String?> categoryId;
  final Value<String?> accountId;
  final Value<String?> toAccountId;
  final Value<String> note;
  final Value<String?> payee;
  final Value<String> source;
  final Value<String?> smsId;
  final Value<String?> groupId;
  final Value<String?> paidByMemberId;
  final Value<String?> splitMethod;
  final Value<String> tags;
  final Value<String?> projectId;
  final Value<String?> recurringId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const EntriesCompanion({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.currency = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.toAccountId = const Value.absent(),
    this.note = const Value.absent(),
    this.payee = const Value.absent(),
    this.source = const Value.absent(),
    this.smsId = const Value.absent(),
    this.groupId = const Value.absent(),
    this.paidByMemberId = const Value.absent(),
    this.splitMethod = const Value.absent(),
    this.tags = const Value.absent(),
    this.projectId = const Value.absent(),
    this.recurringId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntriesCompanion.insert({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String id,
    required String kind,
    required int amountMinor,
    this.currency = const Value.absent(),
    required DateTime occurredAt,
    this.categoryId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.toAccountId = const Value.absent(),
    this.note = const Value.absent(),
    this.payee = const Value.absent(),
    this.source = const Value.absent(),
    this.smsId = const Value.absent(),
    this.groupId = const Value.absent(),
    this.paidByMemberId = const Value.absent(),
    this.splitMethod = const Value.absent(),
    this.tags = const Value.absent(),
    this.projectId = const Value.absent(),
    this.recurringId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       amountMinor = Value(amountMinor),
       occurredAt = Value(occurredAt);
  static Insertable<Entry> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? id,
    Expression<String>? kind,
    Expression<int>? amountMinor,
    Expression<String>? currency,
    Expression<DateTime>? occurredAt,
    Expression<String>? categoryId,
    Expression<String>? accountId,
    Expression<String>? toAccountId,
    Expression<String>? note,
    Expression<String>? payee,
    Expression<String>? source,
    Expression<String>? smsId,
    Expression<String>? groupId,
    Expression<String>? paidByMemberId,
    Expression<String>? splitMethod,
    Expression<String>? tags,
    Expression<String>? projectId,
    Expression<String>? recurringId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (currency != null) 'currency': currency,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (categoryId != null) 'category_id': categoryId,
      if (accountId != null) 'account_id': accountId,
      if (toAccountId != null) 'to_account_id': toAccountId,
      if (note != null) 'note': note,
      if (payee != null) 'payee': payee,
      if (source != null) 'source': source,
      if (smsId != null) 'sms_id': smsId,
      if (groupId != null) 'group_id': groupId,
      if (paidByMemberId != null) 'paid_by_member_id': paidByMemberId,
      if (splitMethod != null) 'split_method': splitMethod,
      if (tags != null) 'tags': tags,
      if (projectId != null) 'project_id': projectId,
      if (recurringId != null) 'recurring_id': recurringId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntriesCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? id,
    Value<String>? kind,
    Value<int>? amountMinor,
    Value<String>? currency,
    Value<DateTime>? occurredAt,
    Value<String?>? categoryId,
    Value<String?>? accountId,
    Value<String?>? toAccountId,
    Value<String>? note,
    Value<String?>? payee,
    Value<String>? source,
    Value<String?>? smsId,
    Value<String?>? groupId,
    Value<String?>? paidByMemberId,
    Value<String?>? splitMethod,
    Value<String>? tags,
    Value<String?>? projectId,
    Value<String?>? recurringId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return EntriesCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      kind: kind ?? this.kind,
      amountMinor: amountMinor ?? this.amountMinor,
      currency: currency ?? this.currency,
      occurredAt: occurredAt ?? this.occurredAt,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      note: note ?? this.note,
      payee: payee ?? this.payee,
      source: source ?? this.source,
      smsId: smsId ?? this.smsId,
      groupId: groupId ?? this.groupId,
      paidByMemberId: paidByMemberId ?? this.paidByMemberId,
      splitMethod: splitMethod ?? this.splitMethod,
      tags: tags ?? this.tags,
      projectId: projectId ?? this.projectId,
      recurringId: recurringId ?? this.recurringId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (toAccountId.present) {
      map['to_account_id'] = Variable<String>(toAccountId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (payee.present) {
      map['payee'] = Variable<String>(payee.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (smsId.present) {
      map['sms_id'] = Variable<String>(smsId.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (paidByMemberId.present) {
      map['paid_by_member_id'] = Variable<String>(paidByMemberId.value);
    }
    if (splitMethod.present) {
      map['split_method'] = Variable<String>(splitMethod.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (recurringId.present) {
      map['recurring_id'] = Variable<String>(recurringId.value);
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
    return (StringBuffer('EntriesCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('note: $note, ')
          ..write('payee: $payee, ')
          ..write('source: $source, ')
          ..write('smsId: $smsId, ')
          ..write('groupId: $groupId, ')
          ..write('paidByMemberId: $paidByMemberId, ')
          ..write('splitMethod: $splitMethod, ')
          ..write('tags: $tags, ')
          ..write('projectId: $projectId, ')
          ..write('recurringId: $recurringId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EntryItemsTable extends EntryItems
    with TableInfo<$EntryItemsTable, EntryItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntryItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
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
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitPriceMinorMeta = const VerificationMeta(
    'unitPriceMinor',
  );
  @override
  late final GeneratedColumn<int> unitPriceMinor = GeneratedColumn<int>(
    'unit_price_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isSharedMeta = const VerificationMeta(
    'isShared',
  );
  @override
  late final GeneratedColumn<bool> isShared = GeneratedColumn<bool>(
    'is_shared',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_shared" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    deletedAt,
    id,
    entryId,
    name,
    quantity,
    unit,
    unitPriceMinor,
    amountMinor,
    sortOrder,
    isShared,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entry_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntryItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('unit_price_minor')) {
      context.handle(
        _unitPriceMinorMeta,
        unitPriceMinor.isAcceptableOrUnknown(
          data['unit_price_minor']!,
          _unitPriceMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_unitPriceMinorMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('is_shared')) {
      context.handle(
        _isSharedMeta,
        isShared.isAcceptableOrUnknown(data['is_shared']!, _isSharedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EntryItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntryItem(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      unitPriceMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_price_minor'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isShared: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_shared'],
      )!,
    );
  }

  @override
  $EntryItemsTable createAlias(String alias) {
    return $EntryItemsTable(attachedDatabase, alias);
  }
}

class EntryItem extends DataClass implements Insertable<EntryItem> {
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String id;
  final String entryId;
  final String name;
  final double quantity;
  final String? unit;
  final int unitPriceMinor;
  final int amountMinor;
  final int sortOrder;

  /// A common line (tax, delivery, service charge) in a by-item group split:
  /// split equally among everyone holding a non-shared item.
  final bool isShared;
  const EntryItem({
    required this.updatedAt,
    this.deletedAt,
    required this.id,
    required this.entryId,
    required this.name,
    required this.quantity,
    this.unit,
    required this.unitPriceMinor,
    required this.amountMinor,
    required this.sortOrder,
    required this.isShared,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<String>(id);
    map['entry_id'] = Variable<String>(entryId);
    map['name'] = Variable<String>(name);
    map['quantity'] = Variable<double>(quantity);
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['unit_price_minor'] = Variable<int>(unitPriceMinor);
    map['amount_minor'] = Variable<int>(amountMinor);
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_shared'] = Variable<bool>(isShared);
    return map;
  }

  EntryItemsCompanion toCompanion(bool nullToAbsent) {
    return EntryItemsCompanion(
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      entryId: Value(entryId),
      name: Value(name),
      quantity: Value(quantity),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      unitPriceMinor: Value(unitPriceMinor),
      amountMinor: Value(amountMinor),
      sortOrder: Value(sortOrder),
      isShared: Value(isShared),
    );
  }

  factory EntryItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntryItem(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<String>(json['id']),
      entryId: serializer.fromJson<String>(json['entryId']),
      name: serializer.fromJson<String>(json['name']),
      quantity: serializer.fromJson<double>(json['quantity']),
      unit: serializer.fromJson<String?>(json['unit']),
      unitPriceMinor: serializer.fromJson<int>(json['unitPriceMinor']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isShared: serializer.fromJson<bool>(json['isShared']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<String>(id),
      'entryId': serializer.toJson<String>(entryId),
      'name': serializer.toJson<String>(name),
      'quantity': serializer.toJson<double>(quantity),
      'unit': serializer.toJson<String?>(unit),
      'unitPriceMinor': serializer.toJson<int>(unitPriceMinor),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isShared': serializer.toJson<bool>(isShared),
    };
  }

  EntryItem copyWith({
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? id,
    String? entryId,
    String? name,
    double? quantity,
    Value<String?> unit = const Value.absent(),
    int? unitPriceMinor,
    int? amountMinor,
    int? sortOrder,
    bool? isShared,
  }) => EntryItem(
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    entryId: entryId ?? this.entryId,
    name: name ?? this.name,
    quantity: quantity ?? this.quantity,
    unit: unit.present ? unit.value : this.unit,
    unitPriceMinor: unitPriceMinor ?? this.unitPriceMinor,
    amountMinor: amountMinor ?? this.amountMinor,
    sortOrder: sortOrder ?? this.sortOrder,
    isShared: isShared ?? this.isShared,
  );
  EntryItem copyWithCompanion(EntryItemsCompanion data) {
    return EntryItem(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      name: data.name.present ? data.name.value : this.name,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      unitPriceMinor: data.unitPriceMinor.present
          ? data.unitPriceMinor.value
          : this.unitPriceMinor,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isShared: data.isShared.present ? data.isShared.value : this.isShared,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntryItem(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('unitPriceMinor: $unitPriceMinor, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isShared: $isShared')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    updatedAt,
    deletedAt,
    id,
    entryId,
    name,
    quantity,
    unit,
    unitPriceMinor,
    amountMinor,
    sortOrder,
    isShared,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntryItem &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.name == this.name &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.unitPriceMinor == this.unitPriceMinor &&
          other.amountMinor == this.amountMinor &&
          other.sortOrder == this.sortOrder &&
          other.isShared == this.isShared);
}

class EntryItemsCompanion extends UpdateCompanion<EntryItem> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> id;
  final Value<String> entryId;
  final Value<String> name;
  final Value<double> quantity;
  final Value<String?> unit;
  final Value<int> unitPriceMinor;
  final Value<int> amountMinor;
  final Value<int> sortOrder;
  final Value<bool> isShared;
  final Value<int> rowid;
  const EntryItemsCompanion({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.name = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.unitPriceMinor = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isShared = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntryItemsCompanion.insert({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String id,
    required String entryId,
    required String name,
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    required int unitPriceMinor,
    required int amountMinor,
    this.sortOrder = const Value.absent(),
    this.isShared = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entryId = Value(entryId),
       name = Value(name),
       unitPriceMinor = Value(unitPriceMinor),
       amountMinor = Value(amountMinor);
  static Insertable<EntryItem> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? id,
    Expression<String>? entryId,
    Expression<String>? name,
    Expression<double>? quantity,
    Expression<String>? unit,
    Expression<int>? unitPriceMinor,
    Expression<int>? amountMinor,
    Expression<int>? sortOrder,
    Expression<bool>? isShared,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (name != null) 'name': name,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (unitPriceMinor != null) 'unit_price_minor': unitPriceMinor,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isShared != null) 'is_shared': isShared,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntryItemsCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? id,
    Value<String>? entryId,
    Value<String>? name,
    Value<double>? quantity,
    Value<String?>? unit,
    Value<int>? unitPriceMinor,
    Value<int>? amountMinor,
    Value<int>? sortOrder,
    Value<bool>? isShared,
    Value<int>? rowid,
  }) {
    return EntryItemsCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPriceMinor: unitPriceMinor ?? this.unitPriceMinor,
      amountMinor: amountMinor ?? this.amountMinor,
      sortOrder: sortOrder ?? this.sortOrder,
      isShared: isShared ?? this.isShared,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (unitPriceMinor.present) {
      map['unit_price_minor'] = Variable<int>(unitPriceMinor.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isShared.present) {
      map['is_shared'] = Variable<bool>(isShared.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntryItemsCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('unitPriceMinor: $unitPriceMinor, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isShared: $isShared, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GroupsTable extends Groups with TableInfo<$GroupsTable, Group> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
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
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('group'),
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('INR'),
  );
  static const VerificationMeta _simplifyDebtsMeta = const VerificationMeta(
    'simplifyDebts',
  );
  @override
  late final GeneratedColumn<bool> simplifyDebts = GeneratedColumn<bool>(
    'simplify_debts',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("simplify_debts" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _inviteCodeMeta = const VerificationMeta(
    'inviteCode',
  );
  @override
  late final GeneratedColumn<String> inviteCode = GeneratedColumn<String>(
    'invite_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('other'),
  );
  static const VerificationMeta _defaultSplitMethodMeta =
      const VerificationMeta('defaultSplitMethod');
  @override
  late final GeneratedColumn<String> defaultSplitMethod =
      GeneratedColumn<String>(
        'default_split_method',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('equal'),
      );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _currencyLabelMeta = const VerificationMeta(
    'currencyLabel',
  );
  @override
  late final GeneratedColumn<String> currencyLabel = GeneratedColumn<String>(
    'currency_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    deletedAt,
    id,
    name,
    icon,
    currency,
    simplifyDebts,
    inviteCode,
    projectId,
    createdAt,
    type,
    defaultSplitMethod,
    notes,
    currencyLabel,
    archivedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<Group> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
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
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('simplify_debts')) {
      context.handle(
        _simplifyDebtsMeta,
        simplifyDebts.isAcceptableOrUnknown(
          data['simplify_debts']!,
          _simplifyDebtsMeta,
        ),
      );
    }
    if (data.containsKey('invite_code')) {
      context.handle(
        _inviteCodeMeta,
        inviteCode.isAcceptableOrUnknown(data['invite_code']!, _inviteCodeMeta),
      );
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('default_split_method')) {
      context.handle(
        _defaultSplitMethodMeta,
        defaultSplitMethod.isAcceptableOrUnknown(
          data['default_split_method']!,
          _defaultSplitMethodMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('currency_label')) {
      context.handle(
        _currencyLabelMeta,
        currencyLabel.isAcceptableOrUnknown(
          data['currency_label']!,
          _currencyLabelMeta,
        ),
      );
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Group map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Group(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      simplifyDebts: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}simplify_debts'],
      )!,
      inviteCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invite_code'],
      ),
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      defaultSplitMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_split_method'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      currencyLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_label'],
      ),
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
    );
  }

  @override
  $GroupsTable createAlias(String alias) {
    return $GroupsTable(attachedDatabase, alias);
  }
}

class Group extends DataClass implements Insertable<Group> {
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String id;
  final String name;
  final String icon;
  final String currency;
  final bool simplifyDebts;

  /// Short code shared with friends so other devices can join (sync plan).
  final String? inviteCode;

  /// Project this group's expenses roll up into (no UI yet; see roadmap R1).
  final String? projectId;
  final DateTime createdAt;

  /// Trip, home, couple or other (see `GroupType`); sets the default icon and
  /// the empty-state wording (v7, group settings).
  final String type;

  /// Split method pre-selected for new expenses: equal, shares or percent (v7).
  final String defaultSplitMethod;

  /// Free-text notes shown as a card on the Expenses tab (v7).
  final String notes;

  /// Currency symbol shown for this group's amounts; null follows the app
  /// setting. A label only: amounts are never converted (v7).
  final String? currencyLabel;

  /// When the group was archived (or left); null while active (v7).
  final DateTime? archivedAt;
  const Group({
    required this.updatedAt,
    this.deletedAt,
    required this.id,
    required this.name,
    required this.icon,
    required this.currency,
    required this.simplifyDebts,
    this.inviteCode,
    this.projectId,
    required this.createdAt,
    required this.type,
    required this.defaultSplitMethod,
    required this.notes,
    this.currencyLabel,
    this.archivedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['icon'] = Variable<String>(icon);
    map['currency'] = Variable<String>(currency);
    map['simplify_debts'] = Variable<bool>(simplifyDebts);
    if (!nullToAbsent || inviteCode != null) {
      map['invite_code'] = Variable<String>(inviteCode);
    }
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<String>(projectId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['type'] = Variable<String>(type);
    map['default_split_method'] = Variable<String>(defaultSplitMethod);
    map['notes'] = Variable<String>(notes);
    if (!nullToAbsent || currencyLabel != null) {
      map['currency_label'] = Variable<String>(currencyLabel);
    }
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    return map;
  }

  GroupsCompanion toCompanion(bool nullToAbsent) {
    return GroupsCompanion(
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      name: Value(name),
      icon: Value(icon),
      currency: Value(currency),
      simplifyDebts: Value(simplifyDebts),
      inviteCode: inviteCode == null && nullToAbsent
          ? const Value.absent()
          : Value(inviteCode),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      createdAt: Value(createdAt),
      type: Value(type),
      defaultSplitMethod: Value(defaultSplitMethod),
      notes: Value(notes),
      currencyLabel: currencyLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(currencyLabel),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
    );
  }

  factory Group.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Group(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String>(json['icon']),
      currency: serializer.fromJson<String>(json['currency']),
      simplifyDebts: serializer.fromJson<bool>(json['simplifyDebts']),
      inviteCode: serializer.fromJson<String?>(json['inviteCode']),
      projectId: serializer.fromJson<String?>(json['projectId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      type: serializer.fromJson<String>(json['type']),
      defaultSplitMethod: serializer.fromJson<String>(
        json['defaultSplitMethod'],
      ),
      notes: serializer.fromJson<String>(json['notes']),
      currencyLabel: serializer.fromJson<String?>(json['currencyLabel']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String>(icon),
      'currency': serializer.toJson<String>(currency),
      'simplifyDebts': serializer.toJson<bool>(simplifyDebts),
      'inviteCode': serializer.toJson<String?>(inviteCode),
      'projectId': serializer.toJson<String?>(projectId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'type': serializer.toJson<String>(type),
      'defaultSplitMethod': serializer.toJson<String>(defaultSplitMethod),
      'notes': serializer.toJson<String>(notes),
      'currencyLabel': serializer.toJson<String?>(currencyLabel),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
    };
  }

  Group copyWith({
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? id,
    String? name,
    String? icon,
    String? currency,
    bool? simplifyDebts,
    Value<String?> inviteCode = const Value.absent(),
    Value<String?> projectId = const Value.absent(),
    DateTime? createdAt,
    String? type,
    String? defaultSplitMethod,
    String? notes,
    Value<String?> currencyLabel = const Value.absent(),
    Value<DateTime?> archivedAt = const Value.absent(),
  }) => Group(
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    currency: currency ?? this.currency,
    simplifyDebts: simplifyDebts ?? this.simplifyDebts,
    inviteCode: inviteCode.present ? inviteCode.value : this.inviteCode,
    projectId: projectId.present ? projectId.value : this.projectId,
    createdAt: createdAt ?? this.createdAt,
    type: type ?? this.type,
    defaultSplitMethod: defaultSplitMethod ?? this.defaultSplitMethod,
    notes: notes ?? this.notes,
    currencyLabel: currencyLabel.present
        ? currencyLabel.value
        : this.currencyLabel,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
  );
  Group copyWithCompanion(GroupsCompanion data) {
    return Group(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      currency: data.currency.present ? data.currency.value : this.currency,
      simplifyDebts: data.simplifyDebts.present
          ? data.simplifyDebts.value
          : this.simplifyDebts,
      inviteCode: data.inviteCode.present
          ? data.inviteCode.value
          : this.inviteCode,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      type: data.type.present ? data.type.value : this.type,
      defaultSplitMethod: data.defaultSplitMethod.present
          ? data.defaultSplitMethod.value
          : this.defaultSplitMethod,
      notes: data.notes.present ? data.notes.value : this.notes,
      currencyLabel: data.currencyLabel.present
          ? data.currencyLabel.value
          : this.currencyLabel,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Group(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('currency: $currency, ')
          ..write('simplifyDebts: $simplifyDebts, ')
          ..write('inviteCode: $inviteCode, ')
          ..write('projectId: $projectId, ')
          ..write('createdAt: $createdAt, ')
          ..write('type: $type, ')
          ..write('defaultSplitMethod: $defaultSplitMethod, ')
          ..write('notes: $notes, ')
          ..write('currencyLabel: $currencyLabel, ')
          ..write('archivedAt: $archivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    updatedAt,
    deletedAt,
    id,
    name,
    icon,
    currency,
    simplifyDebts,
    inviteCode,
    projectId,
    createdAt,
    type,
    defaultSplitMethod,
    notes,
    currencyLabel,
    archivedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Group &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.currency == this.currency &&
          other.simplifyDebts == this.simplifyDebts &&
          other.inviteCode == this.inviteCode &&
          other.projectId == this.projectId &&
          other.createdAt == this.createdAt &&
          other.type == this.type &&
          other.defaultSplitMethod == this.defaultSplitMethod &&
          other.notes == this.notes &&
          other.currencyLabel == this.currencyLabel &&
          other.archivedAt == this.archivedAt);
}

class GroupsCompanion extends UpdateCompanion<Group> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> id;
  final Value<String> name;
  final Value<String> icon;
  final Value<String> currency;
  final Value<bool> simplifyDebts;
  final Value<String?> inviteCode;
  final Value<String?> projectId;
  final Value<DateTime> createdAt;
  final Value<String> type;
  final Value<String> defaultSplitMethod;
  final Value<String> notes;
  final Value<String?> currencyLabel;
  final Value<DateTime?> archivedAt;
  final Value<int> rowid;
  const GroupsCompanion({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.currency = const Value.absent(),
    this.simplifyDebts = const Value.absent(),
    this.inviteCode = const Value.absent(),
    this.projectId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.type = const Value.absent(),
    this.defaultSplitMethod = const Value.absent(),
    this.notes = const Value.absent(),
    this.currencyLabel = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupsCompanion.insert({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String id,
    required String name,
    this.icon = const Value.absent(),
    this.currency = const Value.absent(),
    this.simplifyDebts = const Value.absent(),
    this.inviteCode = const Value.absent(),
    this.projectId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.type = const Value.absent(),
    this.defaultSplitMethod = const Value.absent(),
    this.notes = const Value.absent(),
    this.currencyLabel = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Group> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<String>? currency,
    Expression<bool>? simplifyDebts,
    Expression<String>? inviteCode,
    Expression<String>? projectId,
    Expression<DateTime>? createdAt,
    Expression<String>? type,
    Expression<String>? defaultSplitMethod,
    Expression<String>? notes,
    Expression<String>? currencyLabel,
    Expression<DateTime>? archivedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (currency != null) 'currency': currency,
      if (simplifyDebts != null) 'simplify_debts': simplifyDebts,
      if (inviteCode != null) 'invite_code': inviteCode,
      if (projectId != null) 'project_id': projectId,
      if (createdAt != null) 'created_at': createdAt,
      if (type != null) 'type': type,
      if (defaultSplitMethod != null)
        'default_split_method': defaultSplitMethod,
      if (notes != null) 'notes': notes,
      if (currencyLabel != null) 'currency_label': currencyLabel,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupsCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? id,
    Value<String>? name,
    Value<String>? icon,
    Value<String>? currency,
    Value<bool>? simplifyDebts,
    Value<String?>? inviteCode,
    Value<String?>? projectId,
    Value<DateTime>? createdAt,
    Value<String>? type,
    Value<String>? defaultSplitMethod,
    Value<String>? notes,
    Value<String?>? currencyLabel,
    Value<DateTime?>? archivedAt,
    Value<int>? rowid,
  }) {
    return GroupsCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      currency: currency ?? this.currency,
      simplifyDebts: simplifyDebts ?? this.simplifyDebts,
      inviteCode: inviteCode ?? this.inviteCode,
      projectId: projectId ?? this.projectId,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      defaultSplitMethod: defaultSplitMethod ?? this.defaultSplitMethod,
      notes: notes ?? this.notes,
      currencyLabel: currencyLabel ?? this.currencyLabel,
      archivedAt: archivedAt ?? this.archivedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (simplifyDebts.present) {
      map['simplify_debts'] = Variable<bool>(simplifyDebts.value);
    }
    if (inviteCode.present) {
      map['invite_code'] = Variable<String>(inviteCode.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (defaultSplitMethod.present) {
      map['default_split_method'] = Variable<String>(defaultSplitMethod.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (currencyLabel.present) {
      map['currency_label'] = Variable<String>(currencyLabel.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupsCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('currency: $currency, ')
          ..write('simplifyDebts: $simplifyDebts, ')
          ..write('inviteCode: $inviteCode, ')
          ..write('projectId: $projectId, ')
          ..write('createdAt: $createdAt, ')
          ..write('type: $type, ')
          ..write('defaultSplitMethod: $defaultSplitMethod, ')
          ..write('notes: $notes, ')
          ..write('currencyLabel: $currencyLabel, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MembersTable extends Members with TableInfo<$MembersTable, Member> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
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
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _upiIdMeta = const VerificationMeta('upiId');
  @override
  late final GeneratedColumn<String> upiId = GeneratedColumn<String>(
    'upi_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isMeMeta = const VerificationMeta('isMe');
  @override
  late final GeneratedColumn<bool> isMe = GeneratedColumn<bool>(
    'is_me',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_me" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
    'weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    deletedAt,
    id,
    groupId,
    name,
    phone,
    email,
    upiId,
    isMe,
    weight,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'members';
  @override
  VerificationContext validateIntegrity(
    Insertable<Member> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('upi_id')) {
      context.handle(
        _upiIdMeta,
        upiId.isAcceptableOrUnknown(data['upi_id']!, _upiIdMeta),
      );
    }
    if (data.containsKey('is_me')) {
      context.handle(
        _isMeMeta,
        isMe.isAcceptableOrUnknown(data['is_me']!, _isMeMeta),
      );
    }
    if (data.containsKey('weight')) {
      context.handle(
        _weightMeta,
        weight.isAcceptableOrUnknown(data['weight']!, _weightMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Member map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Member(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      upiId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upi_id'],
      ),
      isMe: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_me'],
      )!,
      weight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight'],
      )!,
    );
  }

  @override
  $MembersTable createAlias(String alias) {
    return $MembersTable(attachedDatabase, alias);
  }
}

class Member extends DataClass implements Insertable<Member> {
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String id;
  final String groupId;
  final String name;
  final String? phone;
  final String? email;

  /// UPI ID (VPA) for "Pay with UPI" links. Plain text, kept on this device.
  final String? upiId;
  final bool isMe;

  /// Default weight for equal splits (2 = counts as two people).
  final double weight;
  const Member({
    required this.updatedAt,
    this.deletedAt,
    required this.id,
    required this.groupId,
    required this.name,
    this.phone,
    this.email,
    this.upiId,
    required this.isMe,
    required this.weight,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || upiId != null) {
      map['upi_id'] = Variable<String>(upiId);
    }
    map['is_me'] = Variable<bool>(isMe);
    map['weight'] = Variable<double>(weight);
    return map;
  }

  MembersCompanion toCompanion(bool nullToAbsent) {
    return MembersCompanion(
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      groupId: Value(groupId),
      name: Value(name),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      upiId: upiId == null && nullToAbsent
          ? const Value.absent()
          : Value(upiId),
      isMe: Value(isMe),
      weight: Value(weight),
    );
  }

  factory Member.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Member(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String?>(json['phone']),
      email: serializer.fromJson<String?>(json['email']),
      upiId: serializer.fromJson<String?>(json['upiId']),
      isMe: serializer.fromJson<bool>(json['isMe']),
      weight: serializer.fromJson<double>(json['weight']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String?>(phone),
      'email': serializer.toJson<String?>(email),
      'upiId': serializer.toJson<String?>(upiId),
      'isMe': serializer.toJson<bool>(isMe),
      'weight': serializer.toJson<double>(weight),
    };
  }

  Member copyWith({
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? id,
    String? groupId,
    String? name,
    Value<String?> phone = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<String?> upiId = const Value.absent(),
    bool? isMe,
    double? weight,
  }) => Member(
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    name: name ?? this.name,
    phone: phone.present ? phone.value : this.phone,
    email: email.present ? email.value : this.email,
    upiId: upiId.present ? upiId.value : this.upiId,
    isMe: isMe ?? this.isMe,
    weight: weight ?? this.weight,
  );
  Member copyWithCompanion(MembersCompanion data) {
    return Member(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      email: data.email.present ? data.email.value : this.email,
      upiId: data.upiId.present ? data.upiId.value : this.upiId,
      isMe: data.isMe.present ? data.isMe.value : this.isMe,
      weight: data.weight.present ? data.weight.value : this.weight,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Member(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('upiId: $upiId, ')
          ..write('isMe: $isMe, ')
          ..write('weight: $weight')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    updatedAt,
    deletedAt,
    id,
    groupId,
    name,
    phone,
    email,
    upiId,
    isMe,
    weight,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Member &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.email == this.email &&
          other.upiId == this.upiId &&
          other.isMe == this.isMe &&
          other.weight == this.weight);
}

class MembersCompanion extends UpdateCompanion<Member> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> name;
  final Value<String?> phone;
  final Value<String?> email;
  final Value<String?> upiId;
  final Value<bool> isMe;
  final Value<double> weight;
  final Value<int> rowid;
  const MembersCompanion({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.upiId = const Value.absent(),
    this.isMe = const Value.absent(),
    this.weight = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MembersCompanion.insert({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String id,
    required String groupId,
    required String name,
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.upiId = const Value.absent(),
    this.isMe = const Value.absent(),
    this.weight = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       name = Value(name);
  static Insertable<Member> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? email,
    Expression<String>? upiId,
    Expression<bool>? isMe,
    Expression<double>? weight,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (upiId != null) 'upi_id': upiId,
      if (isMe != null) 'is_me': isMe,
      if (weight != null) 'weight': weight,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MembersCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? id,
    Value<String>? groupId,
    Value<String>? name,
    Value<String?>? phone,
    Value<String?>? email,
    Value<String?>? upiId,
    Value<bool>? isMe,
    Value<double>? weight,
    Value<int>? rowid,
  }) {
    return MembersCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      upiId: upiId ?? this.upiId,
      isMe: isMe ?? this.isMe,
      weight: weight ?? this.weight,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (upiId.present) {
      map['upi_id'] = Variable<String>(upiId.value);
    }
    if (isMe.present) {
      map['is_me'] = Variable<bool>(isMe.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MembersCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('upiId: $upiId, ')
          ..write('isMe: $isMe, ')
          ..write('weight: $weight, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SplitsTable extends Splits with TableInfo<$SplitsTable, Split> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SplitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shareValueMeta = const VerificationMeta(
    'shareValue',
  );
  @override
  late final GeneratedColumn<double> shareValue = GeneratedColumn<double>(
    'share_value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    deletedAt,
    id,
    entryId,
    memberId,
    amountMinor,
    shareValue,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'splits';
  @override
  VerificationContext validateIntegrity(
    Insertable<Split> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('share_value')) {
      context.handle(
        _shareValueMeta,
        shareValue.isAcceptableOrUnknown(data['share_value']!, _shareValueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Split map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Split(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      shareValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}share_value'],
      ),
    );
  }

  @override
  $SplitsTable createAlias(String alias) {
    return $SplitsTable(attachedDatabase, alias);
  }
}

class Split extends DataClass implements Insertable<Split> {
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String id;
  final String entryId;
  final String memberId;
  final int amountMinor;

  /// Raw input that produced the amount (percent, shares, exact...).
  final double? shareValue;
  const Split({
    required this.updatedAt,
    this.deletedAt,
    required this.id,
    required this.entryId,
    required this.memberId,
    required this.amountMinor,
    this.shareValue,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<String>(id);
    map['entry_id'] = Variable<String>(entryId);
    map['member_id'] = Variable<String>(memberId);
    map['amount_minor'] = Variable<int>(amountMinor);
    if (!nullToAbsent || shareValue != null) {
      map['share_value'] = Variable<double>(shareValue);
    }
    return map;
  }

  SplitsCompanion toCompanion(bool nullToAbsent) {
    return SplitsCompanion(
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      entryId: Value(entryId),
      memberId: Value(memberId),
      amountMinor: Value(amountMinor),
      shareValue: shareValue == null && nullToAbsent
          ? const Value.absent()
          : Value(shareValue),
    );
  }

  factory Split.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Split(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<String>(json['id']),
      entryId: serializer.fromJson<String>(json['entryId']),
      memberId: serializer.fromJson<String>(json['memberId']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      shareValue: serializer.fromJson<double?>(json['shareValue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<String>(id),
      'entryId': serializer.toJson<String>(entryId),
      'memberId': serializer.toJson<String>(memberId),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'shareValue': serializer.toJson<double?>(shareValue),
    };
  }

  Split copyWith({
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? id,
    String? entryId,
    String? memberId,
    int? amountMinor,
    Value<double?> shareValue = const Value.absent(),
  }) => Split(
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    entryId: entryId ?? this.entryId,
    memberId: memberId ?? this.memberId,
    amountMinor: amountMinor ?? this.amountMinor,
    shareValue: shareValue.present ? shareValue.value : this.shareValue,
  );
  Split copyWithCompanion(SplitsCompanion data) {
    return Split(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      shareValue: data.shareValue.present
          ? data.shareValue.value
          : this.shareValue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Split(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('memberId: $memberId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('shareValue: $shareValue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    updatedAt,
    deletedAt,
    id,
    entryId,
    memberId,
    amountMinor,
    shareValue,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Split &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.memberId == this.memberId &&
          other.amountMinor == this.amountMinor &&
          other.shareValue == this.shareValue);
}

class SplitsCompanion extends UpdateCompanion<Split> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> id;
  final Value<String> entryId;
  final Value<String> memberId;
  final Value<int> amountMinor;
  final Value<double?> shareValue;
  final Value<int> rowid;
  const SplitsCompanion({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.shareValue = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SplitsCompanion.insert({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String id,
    required String entryId,
    required String memberId,
    required int amountMinor,
    this.shareValue = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entryId = Value(entryId),
       memberId = Value(memberId),
       amountMinor = Value(amountMinor);
  static Insertable<Split> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? id,
    Expression<String>? entryId,
    Expression<String>? memberId,
    Expression<int>? amountMinor,
    Expression<double>? shareValue,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (memberId != null) 'member_id': memberId,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (shareValue != null) 'share_value': shareValue,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SplitsCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? id,
    Value<String>? entryId,
    Value<String>? memberId,
    Value<int>? amountMinor,
    Value<double?>? shareValue,
    Value<int>? rowid,
  }) {
    return SplitsCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      memberId: memberId ?? this.memberId,
      amountMinor: amountMinor ?? this.amountMinor,
      shareValue: shareValue ?? this.shareValue,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (shareValue.present) {
      map['share_value'] = Variable<double>(shareValue.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SplitsCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('memberId: $memberId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('shareValue: $shareValue, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettlementsTable extends Settlements
    with TableInfo<$SettlementsTable, Settlement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettlementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromMemberIdMeta = const VerificationMeta(
    'fromMemberId',
  );
  @override
  late final GeneratedColumn<String> fromMemberId = GeneratedColumn<String>(
    'from_member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toMemberIdMeta = const VerificationMeta(
    'toMemberId',
  );
  @override
  late final GeneratedColumn<String> toMemberId = GeneratedColumn<String>(
    'to_member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('cash'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    deletedAt,
    id,
    groupId,
    fromMemberId,
    toMemberId,
    amountMinor,
    occurredAt,
    note,
    method,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settlements';
  @override
  VerificationContext validateIntegrity(
    Insertable<Settlement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('from_member_id')) {
      context.handle(
        _fromMemberIdMeta,
        fromMemberId.isAcceptableOrUnknown(
          data['from_member_id']!,
          _fromMemberIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fromMemberIdMeta);
    }
    if (data.containsKey('to_member_id')) {
      context.handle(
        _toMemberIdMeta,
        toMemberId.isAcceptableOrUnknown(
          data['to_member_id']!,
          _toMemberIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_toMemberIdMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Settlement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Settlement(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      fromMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_member_id'],
      )!,
      toMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_member_id'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      )!,
    );
  }

  @override
  $SettlementsTable createAlias(String alias) {
    return $SettlementsTable(attachedDatabase, alias);
  }
}

class Settlement extends DataClass implements Insertable<Settlement> {
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String id;
  final String groupId;
  final String fromMemberId;
  final String toMemberId;
  final int amountMinor;
  final DateTime occurredAt;
  final String note;

  /// cash | upi | bank | other
  final String method;
  const Settlement({
    required this.updatedAt,
    this.deletedAt,
    required this.id,
    required this.groupId,
    required this.fromMemberId,
    required this.toMemberId,
    required this.amountMinor,
    required this.occurredAt,
    required this.note,
    required this.method,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['from_member_id'] = Variable<String>(fromMemberId);
    map['to_member_id'] = Variable<String>(toMemberId);
    map['amount_minor'] = Variable<int>(amountMinor);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['note'] = Variable<String>(note);
    map['method'] = Variable<String>(method);
    return map;
  }

  SettlementsCompanion toCompanion(bool nullToAbsent) {
    return SettlementsCompanion(
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      groupId: Value(groupId),
      fromMemberId: Value(fromMemberId),
      toMemberId: Value(toMemberId),
      amountMinor: Value(amountMinor),
      occurredAt: Value(occurredAt),
      note: Value(note),
      method: Value(method),
    );
  }

  factory Settlement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Settlement(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      fromMemberId: serializer.fromJson<String>(json['fromMemberId']),
      toMemberId: serializer.fromJson<String>(json['toMemberId']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      note: serializer.fromJson<String>(json['note']),
      method: serializer.fromJson<String>(json['method']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'fromMemberId': serializer.toJson<String>(fromMemberId),
      'toMemberId': serializer.toJson<String>(toMemberId),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'note': serializer.toJson<String>(note),
      'method': serializer.toJson<String>(method),
    };
  }

  Settlement copyWith({
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? id,
    String? groupId,
    String? fromMemberId,
    String? toMemberId,
    int? amountMinor,
    DateTime? occurredAt,
    String? note,
    String? method,
  }) => Settlement(
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    fromMemberId: fromMemberId ?? this.fromMemberId,
    toMemberId: toMemberId ?? this.toMemberId,
    amountMinor: amountMinor ?? this.amountMinor,
    occurredAt: occurredAt ?? this.occurredAt,
    note: note ?? this.note,
    method: method ?? this.method,
  );
  Settlement copyWithCompanion(SettlementsCompanion data) {
    return Settlement(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      fromMemberId: data.fromMemberId.present
          ? data.fromMemberId.value
          : this.fromMemberId,
      toMemberId: data.toMemberId.present
          ? data.toMemberId.value
          : this.toMemberId,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      note: data.note.present ? data.note.value : this.note,
      method: data.method.present ? data.method.value : this.method,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Settlement(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('fromMemberId: $fromMemberId, ')
          ..write('toMemberId: $toMemberId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('note: $note, ')
          ..write('method: $method')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    updatedAt,
    deletedAt,
    id,
    groupId,
    fromMemberId,
    toMemberId,
    amountMinor,
    occurredAt,
    note,
    method,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Settlement &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.fromMemberId == this.fromMemberId &&
          other.toMemberId == this.toMemberId &&
          other.amountMinor == this.amountMinor &&
          other.occurredAt == this.occurredAt &&
          other.note == this.note &&
          other.method == this.method);
}

class SettlementsCompanion extends UpdateCompanion<Settlement> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> fromMemberId;
  final Value<String> toMemberId;
  final Value<int> amountMinor;
  final Value<DateTime> occurredAt;
  final Value<String> note;
  final Value<String> method;
  final Value<int> rowid;
  const SettlementsCompanion({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.fromMemberId = const Value.absent(),
    this.toMemberId = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.note = const Value.absent(),
    this.method = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettlementsCompanion.insert({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String id,
    required String groupId,
    required String fromMemberId,
    required String toMemberId,
    required int amountMinor,
    required DateTime occurredAt,
    this.note = const Value.absent(),
    this.method = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       fromMemberId = Value(fromMemberId),
       toMemberId = Value(toMemberId),
       amountMinor = Value(amountMinor),
       occurredAt = Value(occurredAt);
  static Insertable<Settlement> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? fromMemberId,
    Expression<String>? toMemberId,
    Expression<int>? amountMinor,
    Expression<DateTime>? occurredAt,
    Expression<String>? note,
    Expression<String>? method,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (fromMemberId != null) 'from_member_id': fromMemberId,
      if (toMemberId != null) 'to_member_id': toMemberId,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (note != null) 'note': note,
      if (method != null) 'method': method,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettlementsCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? id,
    Value<String>? groupId,
    Value<String>? fromMemberId,
    Value<String>? toMemberId,
    Value<int>? amountMinor,
    Value<DateTime>? occurredAt,
    Value<String>? note,
    Value<String>? method,
    Value<int>? rowid,
  }) {
    return SettlementsCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      fromMemberId: fromMemberId ?? this.fromMemberId,
      toMemberId: toMemberId ?? this.toMemberId,
      amountMinor: amountMinor ?? this.amountMinor,
      occurredAt: occurredAt ?? this.occurredAt,
      note: note ?? this.note,
      method: method ?? this.method,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (fromMemberId.present) {
      map['from_member_id'] = Variable<String>(fromMemberId.value);
    }
    if (toMemberId.present) {
      map['to_member_id'] = Variable<String>(toMemberId.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettlementsCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('fromMemberId: $fromMemberId, ')
          ..write('toMemberId: $toMemberId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('note: $note, ')
          ..write('method: $method, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetsTable extends Budgets with TableInfo<$BudgetsTable, Budget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _periodMeta = const VerificationMeta('period');
  @override
  late final GeneratedColumn<String> period = GeneratedColumn<String>(
    'period',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('monthly'),
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    deletedAt,
    id,
    categoryId,
    period,
    amountMinor,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  VerificationContext validateIntegrity(
    Insertable<Budget> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('period')) {
      context.handle(
        _periodMeta,
        period.isAcceptableOrUnknown(data['period']!, _periodMeta),
      );
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Budget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Budget(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      period: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}period'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
    );
  }

  @override
  $BudgetsTable createAlias(String alias) {
    return $BudgetsTable(attachedDatabase, alias);
  }
}

class Budget extends DataClass implements Insertable<Budget> {
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String id;

  /// null = overall budget across all expense categories.
  final String? categoryId;

  /// weekly | monthly | yearly
  final String period;
  final int amountMinor;
  const Budget({
    required this.updatedAt,
    this.deletedAt,
    required this.id,
    this.categoryId,
    required this.period,
    required this.amountMinor,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['period'] = Variable<String>(period);
    map['amount_minor'] = Variable<int>(amountMinor);
    return map;
  }

  BudgetsCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCompanion(
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      period: Value(period),
      amountMinor: Value(amountMinor),
    );
  }

  factory Budget.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Budget(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<String>(json['id']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      period: serializer.fromJson<String>(json['period']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<String>(id),
      'categoryId': serializer.toJson<String?>(categoryId),
      'period': serializer.toJson<String>(period),
      'amountMinor': serializer.toJson<int>(amountMinor),
    };
  }

  Budget copyWith({
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? id,
    Value<String?> categoryId = const Value.absent(),
    String? period,
    int? amountMinor,
  }) => Budget(
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    period: period ?? this.period,
    amountMinor: amountMinor ?? this.amountMinor,
  );
  Budget copyWithCompanion(BudgetsCompanion data) {
    return Budget(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      period: data.period.present ? data.period.value : this.period,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Budget(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('period: $period, ')
          ..write('amountMinor: $amountMinor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(updatedAt, deletedAt, id, categoryId, period, amountMinor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Budget &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.period == this.period &&
          other.amountMinor == this.amountMinor);
}

class BudgetsCompanion extends UpdateCompanion<Budget> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> id;
  final Value<String?> categoryId;
  final Value<String> period;
  final Value<int> amountMinor;
  final Value<int> rowid;
  const BudgetsCompanion({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.period = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetsCompanion.insert({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String id,
    this.categoryId = const Value.absent(),
    this.period = const Value.absent(),
    required int amountMinor,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       amountMinor = Value(amountMinor);
  static Insertable<Budget> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? id,
    Expression<String>? categoryId,
    Expression<String>? period,
    Expression<int>? amountMinor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (period != null) 'period': period,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetsCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? id,
    Value<String?>? categoryId,
    Value<String>? period,
    Value<int>? amountMinor,
    Value<int>? rowid,
  }) {
    return BudgetsCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      period: period ?? this.period,
      amountMinor: amountMinor ?? this.amountMinor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (period.present) {
      map['period'] = Variable<String>(period.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('period: $period, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SmsLogTable extends SmsLog with TableInfo<$SmsLogTable, SmsLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SmsLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderMeta = const VerificationMeta('sender');
  @override
  late final GeneratedColumn<String> sender = GeneratedColumn<String>(
    'sender',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receivedAtMeta = const VerificationMeta(
    'receivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
    'received_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parsedJsonMeta = const VerificationMeta(
    'parsedJson',
  );
  @override
  late final GeneratedColumn<String> parsedJson = GeneratedColumn<String>(
    'parsed_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _matchedReminderIdMeta = const VerificationMeta(
    'matchedReminderId',
  );
  @override
  late final GeneratedColumn<String> matchedReminderId =
      GeneratedColumn<String>(
        'matched_reminder_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _transactionKeyMeta = const VerificationMeta(
    'transactionKey',
  );
  @override
  late final GeneratedColumn<String> transactionKey = GeneratedColumn<String>(
    'transaction_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _clearedAtMeta = const VerificationMeta(
    'clearedAt',
  );
  @override
  late final GeneratedColumn<DateTime> clearedAt = GeneratedColumn<DateTime>(
    'cleared_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sender,
    body,
    receivedAt,
    status,
    parsedJson,
    entryId,
    matchedReminderId,
    transactionKey,
    createdAt,
    clearedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sms_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<SmsLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sender')) {
      context.handle(
        _senderMeta,
        sender.isAcceptableOrUnknown(data['sender']!, _senderMeta),
      );
    } else if (isInserting) {
      context.missing(_senderMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('received_at')) {
      context.handle(
        _receivedAtMeta,
        receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_receivedAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('parsed_json')) {
      context.handle(
        _parsedJsonMeta,
        parsedJson.isAcceptableOrUnknown(data['parsed_json']!, _parsedJsonMeta),
      );
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    }
    if (data.containsKey('matched_reminder_id')) {
      context.handle(
        _matchedReminderIdMeta,
        matchedReminderId.isAcceptableOrUnknown(
          data['matched_reminder_id']!,
          _matchedReminderIdMeta,
        ),
      );
    }
    if (data.containsKey('transaction_key')) {
      context.handle(
        _transactionKeyMeta,
        transactionKey.isAcceptableOrUnknown(
          data['transaction_key']!,
          _transactionKeyMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('cleared_at')) {
      context.handle(
        _clearedAtMeta,
        clearedAt.isAcceptableOrUnknown(data['cleared_at']!, _clearedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SmsLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SmsLogData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      receivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}received_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      parsedJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parsed_json'],
      ),
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      ),
      matchedReminderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}matched_reminder_id'],
      ),
      transactionKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_key'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      clearedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cleared_at'],
      ),
    );
  }

  @override
  $SmsLogTable createAlias(String alias) {
    return $SmsLogTable(attachedDatabase, alias);
  }
}

class SmsLogData extends DataClass implements Insertable<SmsLogData> {
  /// Hash of sender+body+timestamp so a message is only processed once.
  final String id;
  final String sender;
  final String body;
  final DateTime receivedAt;

  /// See SmsLogStatus: pending | added | ignored | skipped | not_bank | duplicate | undone
  final String status;
  final String? parsedJson;
  final String? entryId;

  /// Reminder this message paid, when it matched one (R2 auto-done).
  final String? matchedReminderId;

  /// The bank transaction this message reports (see smsTransactionKey), so
  /// the same payment pasted again or read from the inbox is not added twice.
  final String? transactionKey;
  final DateTime createdAt;

  /// Set when the user clears the SMS history. The row stays (with its body
  /// wiped) so the message is still recognised and never processed twice.
  final DateTime? clearedAt;
  const SmsLogData({
    required this.id,
    required this.sender,
    required this.body,
    required this.receivedAt,
    required this.status,
    this.parsedJson,
    this.entryId,
    this.matchedReminderId,
    this.transactionKey,
    required this.createdAt,
    this.clearedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sender'] = Variable<String>(sender);
    map['body'] = Variable<String>(body);
    map['received_at'] = Variable<DateTime>(receivedAt);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || parsedJson != null) {
      map['parsed_json'] = Variable<String>(parsedJson);
    }
    if (!nullToAbsent || entryId != null) {
      map['entry_id'] = Variable<String>(entryId);
    }
    if (!nullToAbsent || matchedReminderId != null) {
      map['matched_reminder_id'] = Variable<String>(matchedReminderId);
    }
    if (!nullToAbsent || transactionKey != null) {
      map['transaction_key'] = Variable<String>(transactionKey);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || clearedAt != null) {
      map['cleared_at'] = Variable<DateTime>(clearedAt);
    }
    return map;
  }

  SmsLogCompanion toCompanion(bool nullToAbsent) {
    return SmsLogCompanion(
      id: Value(id),
      sender: Value(sender),
      body: Value(body),
      receivedAt: Value(receivedAt),
      status: Value(status),
      parsedJson: parsedJson == null && nullToAbsent
          ? const Value.absent()
          : Value(parsedJson),
      entryId: entryId == null && nullToAbsent
          ? const Value.absent()
          : Value(entryId),
      matchedReminderId: matchedReminderId == null && nullToAbsent
          ? const Value.absent()
          : Value(matchedReminderId),
      transactionKey: transactionKey == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionKey),
      createdAt: Value(createdAt),
      clearedAt: clearedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(clearedAt),
    );
  }

  factory SmsLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SmsLogData(
      id: serializer.fromJson<String>(json['id']),
      sender: serializer.fromJson<String>(json['sender']),
      body: serializer.fromJson<String>(json['body']),
      receivedAt: serializer.fromJson<DateTime>(json['receivedAt']),
      status: serializer.fromJson<String>(json['status']),
      parsedJson: serializer.fromJson<String?>(json['parsedJson']),
      entryId: serializer.fromJson<String?>(json['entryId']),
      matchedReminderId: serializer.fromJson<String?>(
        json['matchedReminderId'],
      ),
      transactionKey: serializer.fromJson<String?>(json['transactionKey']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      clearedAt: serializer.fromJson<DateTime?>(json['clearedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sender': serializer.toJson<String>(sender),
      'body': serializer.toJson<String>(body),
      'receivedAt': serializer.toJson<DateTime>(receivedAt),
      'status': serializer.toJson<String>(status),
      'parsedJson': serializer.toJson<String?>(parsedJson),
      'entryId': serializer.toJson<String?>(entryId),
      'matchedReminderId': serializer.toJson<String?>(matchedReminderId),
      'transactionKey': serializer.toJson<String?>(transactionKey),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'clearedAt': serializer.toJson<DateTime?>(clearedAt),
    };
  }

  SmsLogData copyWith({
    String? id,
    String? sender,
    String? body,
    DateTime? receivedAt,
    String? status,
    Value<String?> parsedJson = const Value.absent(),
    Value<String?> entryId = const Value.absent(),
    Value<String?> matchedReminderId = const Value.absent(),
    Value<String?> transactionKey = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> clearedAt = const Value.absent(),
  }) => SmsLogData(
    id: id ?? this.id,
    sender: sender ?? this.sender,
    body: body ?? this.body,
    receivedAt: receivedAt ?? this.receivedAt,
    status: status ?? this.status,
    parsedJson: parsedJson.present ? parsedJson.value : this.parsedJson,
    entryId: entryId.present ? entryId.value : this.entryId,
    matchedReminderId: matchedReminderId.present
        ? matchedReminderId.value
        : this.matchedReminderId,
    transactionKey: transactionKey.present
        ? transactionKey.value
        : this.transactionKey,
    createdAt: createdAt ?? this.createdAt,
    clearedAt: clearedAt.present ? clearedAt.value : this.clearedAt,
  );
  SmsLogData copyWithCompanion(SmsLogCompanion data) {
    return SmsLogData(
      id: data.id.present ? data.id.value : this.id,
      sender: data.sender.present ? data.sender.value : this.sender,
      body: data.body.present ? data.body.value : this.body,
      receivedAt: data.receivedAt.present
          ? data.receivedAt.value
          : this.receivedAt,
      status: data.status.present ? data.status.value : this.status,
      parsedJson: data.parsedJson.present
          ? data.parsedJson.value
          : this.parsedJson,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      matchedReminderId: data.matchedReminderId.present
          ? data.matchedReminderId.value
          : this.matchedReminderId,
      transactionKey: data.transactionKey.present
          ? data.transactionKey.value
          : this.transactionKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      clearedAt: data.clearedAt.present ? data.clearedAt.value : this.clearedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SmsLogData(')
          ..write('id: $id, ')
          ..write('sender: $sender, ')
          ..write('body: $body, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('status: $status, ')
          ..write('parsedJson: $parsedJson, ')
          ..write('entryId: $entryId, ')
          ..write('matchedReminderId: $matchedReminderId, ')
          ..write('transactionKey: $transactionKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('clearedAt: $clearedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sender,
    body,
    receivedAt,
    status,
    parsedJson,
    entryId,
    matchedReminderId,
    transactionKey,
    createdAt,
    clearedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SmsLogData &&
          other.id == this.id &&
          other.sender == this.sender &&
          other.body == this.body &&
          other.receivedAt == this.receivedAt &&
          other.status == this.status &&
          other.parsedJson == this.parsedJson &&
          other.entryId == this.entryId &&
          other.matchedReminderId == this.matchedReminderId &&
          other.transactionKey == this.transactionKey &&
          other.createdAt == this.createdAt &&
          other.clearedAt == this.clearedAt);
}

class SmsLogCompanion extends UpdateCompanion<SmsLogData> {
  final Value<String> id;
  final Value<String> sender;
  final Value<String> body;
  final Value<DateTime> receivedAt;
  final Value<String> status;
  final Value<String?> parsedJson;
  final Value<String?> entryId;
  final Value<String?> matchedReminderId;
  final Value<String?> transactionKey;
  final Value<DateTime> createdAt;
  final Value<DateTime?> clearedAt;
  final Value<int> rowid;
  const SmsLogCompanion({
    this.id = const Value.absent(),
    this.sender = const Value.absent(),
    this.body = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.parsedJson = const Value.absent(),
    this.entryId = const Value.absent(),
    this.matchedReminderId = const Value.absent(),
    this.transactionKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.clearedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SmsLogCompanion.insert({
    required String id,
    required String sender,
    required String body,
    required DateTime receivedAt,
    required String status,
    this.parsedJson = const Value.absent(),
    this.entryId = const Value.absent(),
    this.matchedReminderId = const Value.absent(),
    this.transactionKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.clearedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sender = Value(sender),
       body = Value(body),
       receivedAt = Value(receivedAt),
       status = Value(status);
  static Insertable<SmsLogData> custom({
    Expression<String>? id,
    Expression<String>? sender,
    Expression<String>? body,
    Expression<DateTime>? receivedAt,
    Expression<String>? status,
    Expression<String>? parsedJson,
    Expression<String>? entryId,
    Expression<String>? matchedReminderId,
    Expression<String>? transactionKey,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? clearedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sender != null) 'sender': sender,
      if (body != null) 'body': body,
      if (receivedAt != null) 'received_at': receivedAt,
      if (status != null) 'status': status,
      if (parsedJson != null) 'parsed_json': parsedJson,
      if (entryId != null) 'entry_id': entryId,
      if (matchedReminderId != null) 'matched_reminder_id': matchedReminderId,
      if (transactionKey != null) 'transaction_key': transactionKey,
      if (createdAt != null) 'created_at': createdAt,
      if (clearedAt != null) 'cleared_at': clearedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SmsLogCompanion copyWith({
    Value<String>? id,
    Value<String>? sender,
    Value<String>? body,
    Value<DateTime>? receivedAt,
    Value<String>? status,
    Value<String?>? parsedJson,
    Value<String?>? entryId,
    Value<String?>? matchedReminderId,
    Value<String?>? transactionKey,
    Value<DateTime>? createdAt,
    Value<DateTime?>? clearedAt,
    Value<int>? rowid,
  }) {
    return SmsLogCompanion(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      body: body ?? this.body,
      receivedAt: receivedAt ?? this.receivedAt,
      status: status ?? this.status,
      parsedJson: parsedJson ?? this.parsedJson,
      entryId: entryId ?? this.entryId,
      matchedReminderId: matchedReminderId ?? this.matchedReminderId,
      transactionKey: transactionKey ?? this.transactionKey,
      createdAt: createdAt ?? this.createdAt,
      clearedAt: clearedAt ?? this.clearedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sender.present) {
      map['sender'] = Variable<String>(sender.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (parsedJson.present) {
      map['parsed_json'] = Variable<String>(parsedJson.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (matchedReminderId.present) {
      map['matched_reminder_id'] = Variable<String>(matchedReminderId.value);
    }
    if (transactionKey.present) {
      map['transaction_key'] = Variable<String>(transactionKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (clearedAt.present) {
      map['cleared_at'] = Variable<DateTime>(clearedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SmsLogCompanion(')
          ..write('id: $id, ')
          ..write('sender: $sender, ')
          ..write('body: $body, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('status: $status, ')
          ..write('parsedJson: $parsedJson, ')
          ..write('entryId: $entryId, ')
          ..write('matchedReminderId: $matchedReminderId, ')
          ..write('transactionKey: $transactionKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('clearedAt: $clearedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProjectsTable extends Projects with TableInfo<$ProjectsTable, Project> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
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
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('folder'),
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateKeyMeta = const VerificationMeta(
    'templateKey',
  );
  @override
  late final GeneratedColumn<String> templateKey = GeneratedColumn<String>(
    'template_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _budgetMinorMeta = const VerificationMeta(
    'budgetMinor',
  );
  @override
  late final GeneratedColumn<int> budgetMinor = GeneratedColumn<int>(
    'budget_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('INR'),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
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
  List<GeneratedColumn> get $columns => [
    updatedAt,
    deletedAt,
    id,
    name,
    icon,
    color,
    templateKey,
    status,
    startDate,
    endDate,
    budgetMinor,
    currency,
    notes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(
    Insertable<Project> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
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
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('template_key')) {
      context.handle(
        _templateKeyMeta,
        templateKey.isAcceptableOrUnknown(
          data['template_key']!,
          _templateKeyMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('budget_minor')) {
      context.handle(
        _budgetMinorMeta,
        budgetMinor.isAcceptableOrUnknown(
          data['budget_minor']!,
          _budgetMinorMeta,
        ),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
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
  Project map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Project(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      templateKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_key'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      ),
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      ),
      budgetMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}budget_minor'],
      ),
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }
}

class Project extends DataClass implements Insertable<Project> {
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String id;
  final String name;
  final String icon;
  final int color;

  /// Key of the template the project was created from; null for blank.
  final String? templateKey;

  /// active | completed | archived
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;

  /// null = no budget set for this project.
  final int? budgetMinor;
  final String currency;
  final String notes;
  final DateTime createdAt;
  const Project({
    required this.updatedAt,
    this.deletedAt,
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.templateKey,
    required this.status,
    this.startDate,
    this.endDate,
    this.budgetMinor,
    required this.currency,
    required this.notes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['icon'] = Variable<String>(icon);
    map['color'] = Variable<int>(color);
    if (!nullToAbsent || templateKey != null) {
      map['template_key'] = Variable<String>(templateKey);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<DateTime>(startDate);
    }
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    if (!nullToAbsent || budgetMinor != null) {
      map['budget_minor'] = Variable<int>(budgetMinor);
    }
    map['currency'] = Variable<String>(currency);
    map['notes'] = Variable<String>(notes);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      name: Value(name),
      icon: Value(icon),
      color: Value(color),
      templateKey: templateKey == null && nullToAbsent
          ? const Value.absent()
          : Value(templateKey),
      status: Value(status),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      budgetMinor: budgetMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(budgetMinor),
      currency: Value(currency),
      notes: Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory Project.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Project(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String>(json['icon']),
      color: serializer.fromJson<int>(json['color']),
      templateKey: serializer.fromJson<String?>(json['templateKey']),
      status: serializer.fromJson<String>(json['status']),
      startDate: serializer.fromJson<DateTime?>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      budgetMinor: serializer.fromJson<int?>(json['budgetMinor']),
      currency: serializer.fromJson<String>(json['currency']),
      notes: serializer.fromJson<String>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String>(icon),
      'color': serializer.toJson<int>(color),
      'templateKey': serializer.toJson<String?>(templateKey),
      'status': serializer.toJson<String>(status),
      'startDate': serializer.toJson<DateTime?>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'budgetMinor': serializer.toJson<int?>(budgetMinor),
      'currency': serializer.toJson<String>(currency),
      'notes': serializer.toJson<String>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Project copyWith({
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? id,
    String? name,
    String? icon,
    int? color,
    Value<String?> templateKey = const Value.absent(),
    String? status,
    Value<DateTime?> startDate = const Value.absent(),
    Value<DateTime?> endDate = const Value.absent(),
    Value<int?> budgetMinor = const Value.absent(),
    String? currency,
    String? notes,
    DateTime? createdAt,
  }) => Project(
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    templateKey: templateKey.present ? templateKey.value : this.templateKey,
    status: status ?? this.status,
    startDate: startDate.present ? startDate.value : this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    budgetMinor: budgetMinor.present ? budgetMinor.value : this.budgetMinor,
    currency: currency ?? this.currency,
    notes: notes ?? this.notes,
    createdAt: createdAt ?? this.createdAt,
  );
  Project copyWithCompanion(ProjectsCompanion data) {
    return Project(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      color: data.color.present ? data.color.value : this.color,
      templateKey: data.templateKey.present
          ? data.templateKey.value
          : this.templateKey,
      status: data.status.present ? data.status.value : this.status,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      budgetMinor: data.budgetMinor.present
          ? data.budgetMinor.value
          : this.budgetMinor,
      currency: data.currency.present ? data.currency.value : this.currency,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Project(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('templateKey: $templateKey, ')
          ..write('status: $status, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('budgetMinor: $budgetMinor, ')
          ..write('currency: $currency, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    updatedAt,
    deletedAt,
    id,
    name,
    icon,
    color,
    templateKey,
    status,
    startDate,
    endDate,
    budgetMinor,
    currency,
    notes,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Project &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.color == this.color &&
          other.templateKey == this.templateKey &&
          other.status == this.status &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.budgetMinor == this.budgetMinor &&
          other.currency == this.currency &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class ProjectsCompanion extends UpdateCompanion<Project> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> id;
  final Value<String> name;
  final Value<String> icon;
  final Value<int> color;
  final Value<String?> templateKey;
  final Value<String> status;
  final Value<DateTime?> startDate;
  final Value<DateTime?> endDate;
  final Value<int?> budgetMinor;
  final Value<String> currency;
  final Value<String> notes;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ProjectsCompanion({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.templateKey = const Value.absent(),
    this.status = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.budgetMinor = const Value.absent(),
    this.currency = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectsCompanion.insert({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String id,
    required String name,
    this.icon = const Value.absent(),
    required int color,
    this.templateKey = const Value.absent(),
    this.status = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.budgetMinor = const Value.absent(),
    this.currency = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       color = Value(color);
  static Insertable<Project> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<int>? color,
    Expression<String>? templateKey,
    Expression<String>? status,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<int>? budgetMinor,
    Expression<String>? currency,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (templateKey != null) 'template_key': templateKey,
      if (status != null) 'status': status,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (budgetMinor != null) 'budget_minor': budgetMinor,
      if (currency != null) 'currency': currency,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectsCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? id,
    Value<String>? name,
    Value<String>? icon,
    Value<int>? color,
    Value<String?>? templateKey,
    Value<String>? status,
    Value<DateTime?>? startDate,
    Value<DateTime?>? endDate,
    Value<int?>? budgetMinor,
    Value<String>? currency,
    Value<String>? notes,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ProjectsCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      templateKey: templateKey ?? this.templateKey,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      budgetMinor: budgetMinor ?? this.budgetMinor,
      currency: currency ?? this.currency,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (templateKey.present) {
      map['template_key'] = Variable<String>(templateKey.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (budgetMinor.present) {
      map['budget_minor'] = Variable<int>(budgetMinor.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
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
    return (StringBuffer('ProjectsCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('templateKey: $templateKey, ')
          ..write('status: $status, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('budgetMinor: $budgetMinor, ')
          ..write('currency: $currency, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProjectFieldsTable extends ProjectFields
    with TableInfo<$ProjectFieldsTable, ProjectField> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectFieldsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _choicesMeta = const VerificationMeta(
    'choices',
  );
  @override
  late final GeneratedColumn<String> choices = GeneratedColumn<String>(
    'choices',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
    'scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('entry'),
  );
  static const VerificationMeta _numberValueMeta = const VerificationMeta(
    'numberValue',
  );
  @override
  late final GeneratedColumn<double> numberValue = GeneratedColumn<double>(
    'number_value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _textValueMeta = const VerificationMeta(
    'textValue',
  );
  @override
  late final GeneratedColumn<String> textValue = GeneratedColumn<String>(
    'text_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    deletedAt,
    id,
    projectId,
    key,
    label,
    type,
    unit,
    choices,
    sortOrder,
    scope,
    numberValue,
    textValue,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'project_fields';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProjectField> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('choices')) {
      context.handle(
        _choicesMeta,
        choices.isAcceptableOrUnknown(data['choices']!, _choicesMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('scope')) {
      context.handle(
        _scopeMeta,
        scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta),
      );
    }
    if (data.containsKey('number_value')) {
      context.handle(
        _numberValueMeta,
        numberValue.isAcceptableOrUnknown(
          data['number_value']!,
          _numberValueMeta,
        ),
      );
    }
    if (data.containsKey('text_value')) {
      context.handle(
        _textValueMeta,
        textValue.isAcceptableOrUnknown(data['text_value']!, _textValueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProjectField map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProjectField(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      choices: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}choices'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      scope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope'],
      )!,
      numberValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}number_value'],
      ),
      textValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_value'],
      ),
    );
  }

  @override
  $ProjectFieldsTable createAlias(String alias) {
    return $ProjectFieldsTable(attachedDatabase, alias);
  }
}

class ProjectField extends DataClass implements Insertable<ProjectField> {
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String id;
  final String projectId;

  /// Stable key: a template field key (`odometer`) or a generated one for custom fields.
  final String key;

  /// User-facing label for custom fields; template fields are labelled from the ARB files.
  final String label;

  /// number | text | date | choice | unit
  final String type;
  final String? unit;

  /// JSON array of option keys (choice) or unit options (unit).
  final String choices;
  final int sortOrder;

  /// project | entry
  final String scope;

  /// The value of a project-scope field.
  final double? numberValue;
  final String? textValue;
  const ProjectField({
    required this.updatedAt,
    this.deletedAt,
    required this.id,
    required this.projectId,
    required this.key,
    required this.label,
    required this.type,
    this.unit,
    required this.choices,
    required this.sortOrder,
    required this.scope,
    this.numberValue,
    this.textValue,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['key'] = Variable<String>(key);
    map['label'] = Variable<String>(label);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['choices'] = Variable<String>(choices);
    map['sort_order'] = Variable<int>(sortOrder);
    map['scope'] = Variable<String>(scope);
    if (!nullToAbsent || numberValue != null) {
      map['number_value'] = Variable<double>(numberValue);
    }
    if (!nullToAbsent || textValue != null) {
      map['text_value'] = Variable<String>(textValue);
    }
    return map;
  }

  ProjectFieldsCompanion toCompanion(bool nullToAbsent) {
    return ProjectFieldsCompanion(
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      projectId: Value(projectId),
      key: Value(key),
      label: Value(label),
      type: Value(type),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      choices: Value(choices),
      sortOrder: Value(sortOrder),
      scope: Value(scope),
      numberValue: numberValue == null && nullToAbsent
          ? const Value.absent()
          : Value(numberValue),
      textValue: textValue == null && nullToAbsent
          ? const Value.absent()
          : Value(textValue),
    );
  }

  factory ProjectField.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProjectField(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      key: serializer.fromJson<String>(json['key']),
      label: serializer.fromJson<String>(json['label']),
      type: serializer.fromJson<String>(json['type']),
      unit: serializer.fromJson<String?>(json['unit']),
      choices: serializer.fromJson<String>(json['choices']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      scope: serializer.fromJson<String>(json['scope']),
      numberValue: serializer.fromJson<double?>(json['numberValue']),
      textValue: serializer.fromJson<String?>(json['textValue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'key': serializer.toJson<String>(key),
      'label': serializer.toJson<String>(label),
      'type': serializer.toJson<String>(type),
      'unit': serializer.toJson<String?>(unit),
      'choices': serializer.toJson<String>(choices),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'scope': serializer.toJson<String>(scope),
      'numberValue': serializer.toJson<double?>(numberValue),
      'textValue': serializer.toJson<String?>(textValue),
    };
  }

  ProjectField copyWith({
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? id,
    String? projectId,
    String? key,
    String? label,
    String? type,
    Value<String?> unit = const Value.absent(),
    String? choices,
    int? sortOrder,
    String? scope,
    Value<double?> numberValue = const Value.absent(),
    Value<String?> textValue = const Value.absent(),
  }) => ProjectField(
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    key: key ?? this.key,
    label: label ?? this.label,
    type: type ?? this.type,
    unit: unit.present ? unit.value : this.unit,
    choices: choices ?? this.choices,
    sortOrder: sortOrder ?? this.sortOrder,
    scope: scope ?? this.scope,
    numberValue: numberValue.present ? numberValue.value : this.numberValue,
    textValue: textValue.present ? textValue.value : this.textValue,
  );
  ProjectField copyWithCompanion(ProjectFieldsCompanion data) {
    return ProjectField(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      key: data.key.present ? data.key.value : this.key,
      label: data.label.present ? data.label.value : this.label,
      type: data.type.present ? data.type.value : this.type,
      unit: data.unit.present ? data.unit.value : this.unit,
      choices: data.choices.present ? data.choices.value : this.choices,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      scope: data.scope.present ? data.scope.value : this.scope,
      numberValue: data.numberValue.present
          ? data.numberValue.value
          : this.numberValue,
      textValue: data.textValue.present ? data.textValue.value : this.textValue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProjectField(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('key: $key, ')
          ..write('label: $label, ')
          ..write('type: $type, ')
          ..write('unit: $unit, ')
          ..write('choices: $choices, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('scope: $scope, ')
          ..write('numberValue: $numberValue, ')
          ..write('textValue: $textValue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    updatedAt,
    deletedAt,
    id,
    projectId,
    key,
    label,
    type,
    unit,
    choices,
    sortOrder,
    scope,
    numberValue,
    textValue,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProjectField &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.key == this.key &&
          other.label == this.label &&
          other.type == this.type &&
          other.unit == this.unit &&
          other.choices == this.choices &&
          other.sortOrder == this.sortOrder &&
          other.scope == this.scope &&
          other.numberValue == this.numberValue &&
          other.textValue == this.textValue);
}

class ProjectFieldsCompanion extends UpdateCompanion<ProjectField> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> key;
  final Value<String> label;
  final Value<String> type;
  final Value<String?> unit;
  final Value<String> choices;
  final Value<int> sortOrder;
  final Value<String> scope;
  final Value<double?> numberValue;
  final Value<String?> textValue;
  final Value<int> rowid;
  const ProjectFieldsCompanion({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.key = const Value.absent(),
    this.label = const Value.absent(),
    this.type = const Value.absent(),
    this.unit = const Value.absent(),
    this.choices = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.scope = const Value.absent(),
    this.numberValue = const Value.absent(),
    this.textValue = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectFieldsCompanion.insert({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String id,
    required String projectId,
    required String key,
    this.label = const Value.absent(),
    required String type,
    this.unit = const Value.absent(),
    this.choices = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.scope = const Value.absent(),
    this.numberValue = const Value.absent(),
    this.textValue = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       key = Value(key),
       type = Value(type);
  static Insertable<ProjectField> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? key,
    Expression<String>? label,
    Expression<String>? type,
    Expression<String>? unit,
    Expression<String>? choices,
    Expression<int>? sortOrder,
    Expression<String>? scope,
    Expression<double>? numberValue,
    Expression<String>? textValue,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (key != null) 'key': key,
      if (label != null) 'label': label,
      if (type != null) 'type': type,
      if (unit != null) 'unit': unit,
      if (choices != null) 'choices': choices,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (scope != null) 'scope': scope,
      if (numberValue != null) 'number_value': numberValue,
      if (textValue != null) 'text_value': textValue,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectFieldsCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? id,
    Value<String>? projectId,
    Value<String>? key,
    Value<String>? label,
    Value<String>? type,
    Value<String?>? unit,
    Value<String>? choices,
    Value<int>? sortOrder,
    Value<String>? scope,
    Value<double?>? numberValue,
    Value<String?>? textValue,
    Value<int>? rowid,
  }) {
    return ProjectFieldsCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      key: key ?? this.key,
      label: label ?? this.label,
      type: type ?? this.type,
      unit: unit ?? this.unit,
      choices: choices ?? this.choices,
      sortOrder: sortOrder ?? this.sortOrder,
      scope: scope ?? this.scope,
      numberValue: numberValue ?? this.numberValue,
      textValue: textValue ?? this.textValue,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (choices.present) {
      map['choices'] = Variable<String>(choices.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (numberValue.present) {
      map['number_value'] = Variable<double>(numberValue.value);
    }
    if (textValue.present) {
      map['text_value'] = Variable<String>(textValue.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectFieldsCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('key: $key, ')
          ..write('label: $label, ')
          ..write('type: $type, ')
          ..write('unit: $unit, ')
          ..write('choices: $choices, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('scope: $scope, ')
          ..write('numberValue: $numberValue, ')
          ..write('textValue: $textValue, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EntryFieldValuesTable extends EntryFieldValues
    with TableInfo<$EntryFieldValuesTable, EntryFieldValue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntryFieldValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldKeyMeta = const VerificationMeta(
    'fieldKey',
  );
  @override
  late final GeneratedColumn<String> fieldKey = GeneratedColumn<String>(
    'field_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numberValueMeta = const VerificationMeta(
    'numberValue',
  );
  @override
  late final GeneratedColumn<double> numberValue = GeneratedColumn<double>(
    'number_value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _textValueMeta = const VerificationMeta(
    'textValue',
  );
  @override
  late final GeneratedColumn<String> textValue = GeneratedColumn<String>(
    'text_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateValueMeta = const VerificationMeta(
    'dateValue',
  );
  @override
  late final GeneratedColumn<DateTime> dateValue = GeneratedColumn<DateTime>(
    'date_value',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    deletedAt,
    id,
    entryId,
    fieldKey,
    numberValue,
    textValue,
    dateValue,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entry_field_values';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntryFieldValue> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('field_key')) {
      context.handle(
        _fieldKeyMeta,
        fieldKey.isAcceptableOrUnknown(data['field_key']!, _fieldKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldKeyMeta);
    }
    if (data.containsKey('number_value')) {
      context.handle(
        _numberValueMeta,
        numberValue.isAcceptableOrUnknown(
          data['number_value']!,
          _numberValueMeta,
        ),
      );
    }
    if (data.containsKey('text_value')) {
      context.handle(
        _textValueMeta,
        textValue.isAcceptableOrUnknown(data['text_value']!, _textValueMeta),
      );
    }
    if (data.containsKey('date_value')) {
      context.handle(
        _dateValueMeta,
        dateValue.isAcceptableOrUnknown(data['date_value']!, _dateValueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EntryFieldValue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntryFieldValue(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      fieldKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_key'],
      )!,
      numberValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}number_value'],
      ),
      textValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_value'],
      ),
      dateValue: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_value'],
      ),
    );
  }

  @override
  $EntryFieldValuesTable createAlias(String alias) {
    return $EntryFieldValuesTable(attachedDatabase, alias);
  }
}

class EntryFieldValue extends DataClass implements Insertable<EntryFieldValue> {
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String id;
  final String entryId;
  final String fieldKey;
  final double? numberValue;
  final String? textValue;
  final DateTime? dateValue;
  const EntryFieldValue({
    required this.updatedAt,
    this.deletedAt,
    required this.id,
    required this.entryId,
    required this.fieldKey,
    this.numberValue,
    this.textValue,
    this.dateValue,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<String>(id);
    map['entry_id'] = Variable<String>(entryId);
    map['field_key'] = Variable<String>(fieldKey);
    if (!nullToAbsent || numberValue != null) {
      map['number_value'] = Variable<double>(numberValue);
    }
    if (!nullToAbsent || textValue != null) {
      map['text_value'] = Variable<String>(textValue);
    }
    if (!nullToAbsent || dateValue != null) {
      map['date_value'] = Variable<DateTime>(dateValue);
    }
    return map;
  }

  EntryFieldValuesCompanion toCompanion(bool nullToAbsent) {
    return EntryFieldValuesCompanion(
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      entryId: Value(entryId),
      fieldKey: Value(fieldKey),
      numberValue: numberValue == null && nullToAbsent
          ? const Value.absent()
          : Value(numberValue),
      textValue: textValue == null && nullToAbsent
          ? const Value.absent()
          : Value(textValue),
      dateValue: dateValue == null && nullToAbsent
          ? const Value.absent()
          : Value(dateValue),
    );
  }

  factory EntryFieldValue.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntryFieldValue(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<String>(json['id']),
      entryId: serializer.fromJson<String>(json['entryId']),
      fieldKey: serializer.fromJson<String>(json['fieldKey']),
      numberValue: serializer.fromJson<double?>(json['numberValue']),
      textValue: serializer.fromJson<String?>(json['textValue']),
      dateValue: serializer.fromJson<DateTime?>(json['dateValue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<String>(id),
      'entryId': serializer.toJson<String>(entryId),
      'fieldKey': serializer.toJson<String>(fieldKey),
      'numberValue': serializer.toJson<double?>(numberValue),
      'textValue': serializer.toJson<String?>(textValue),
      'dateValue': serializer.toJson<DateTime?>(dateValue),
    };
  }

  EntryFieldValue copyWith({
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? id,
    String? entryId,
    String? fieldKey,
    Value<double?> numberValue = const Value.absent(),
    Value<String?> textValue = const Value.absent(),
    Value<DateTime?> dateValue = const Value.absent(),
  }) => EntryFieldValue(
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    entryId: entryId ?? this.entryId,
    fieldKey: fieldKey ?? this.fieldKey,
    numberValue: numberValue.present ? numberValue.value : this.numberValue,
    textValue: textValue.present ? textValue.value : this.textValue,
    dateValue: dateValue.present ? dateValue.value : this.dateValue,
  );
  EntryFieldValue copyWithCompanion(EntryFieldValuesCompanion data) {
    return EntryFieldValue(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      fieldKey: data.fieldKey.present ? data.fieldKey.value : this.fieldKey,
      numberValue: data.numberValue.present
          ? data.numberValue.value
          : this.numberValue,
      textValue: data.textValue.present ? data.textValue.value : this.textValue,
      dateValue: data.dateValue.present ? data.dateValue.value : this.dateValue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntryFieldValue(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('fieldKey: $fieldKey, ')
          ..write('numberValue: $numberValue, ')
          ..write('textValue: $textValue, ')
          ..write('dateValue: $dateValue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    updatedAt,
    deletedAt,
    id,
    entryId,
    fieldKey,
    numberValue,
    textValue,
    dateValue,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntryFieldValue &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.fieldKey == this.fieldKey &&
          other.numberValue == this.numberValue &&
          other.textValue == this.textValue &&
          other.dateValue == this.dateValue);
}

class EntryFieldValuesCompanion extends UpdateCompanion<EntryFieldValue> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> id;
  final Value<String> entryId;
  final Value<String> fieldKey;
  final Value<double?> numberValue;
  final Value<String?> textValue;
  final Value<DateTime?> dateValue;
  final Value<int> rowid;
  const EntryFieldValuesCompanion({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.fieldKey = const Value.absent(),
    this.numberValue = const Value.absent(),
    this.textValue = const Value.absent(),
    this.dateValue = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntryFieldValuesCompanion.insert({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String id,
    required String entryId,
    required String fieldKey,
    this.numberValue = const Value.absent(),
    this.textValue = const Value.absent(),
    this.dateValue = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entryId = Value(entryId),
       fieldKey = Value(fieldKey);
  static Insertable<EntryFieldValue> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? id,
    Expression<String>? entryId,
    Expression<String>? fieldKey,
    Expression<double>? numberValue,
    Expression<String>? textValue,
    Expression<DateTime>? dateValue,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (fieldKey != null) 'field_key': fieldKey,
      if (numberValue != null) 'number_value': numberValue,
      if (textValue != null) 'text_value': textValue,
      if (dateValue != null) 'date_value': dateValue,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntryFieldValuesCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? id,
    Value<String>? entryId,
    Value<String>? fieldKey,
    Value<double?>? numberValue,
    Value<String?>? textValue,
    Value<DateTime?>? dateValue,
    Value<int>? rowid,
  }) {
    return EntryFieldValuesCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      fieldKey: fieldKey ?? this.fieldKey,
      numberValue: numberValue ?? this.numberValue,
      textValue: textValue ?? this.textValue,
      dateValue: dateValue ?? this.dateValue,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (fieldKey.present) {
      map['field_key'] = Variable<String>(fieldKey.value);
    }
    if (numberValue.present) {
      map['number_value'] = Variable<double>(numberValue.value);
    }
    if (textValue.present) {
      map['text_value'] = Variable<String>(textValue.value);
    }
    if (dateValue.present) {
      map['date_value'] = Variable<DateTime>(dateValue.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntryFieldValuesCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('fieldKey: $fieldKey, ')
          ..write('numberValue: $numberValue, ')
          ..write('textValue: $textValue, ')
          ..write('dateValue: $dateValue, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, Reminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
    'due_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<DateTime> sentAt = GeneratedColumn<DateTime>(
    'sent_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _doneAtMeta = const VerificationMeta('doneAt');
  @override
  late final GeneratedColumn<DateTime> doneAt = GeneratedColumn<DateTime>(
    'done_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _channelMeta = const VerificationMeta(
    'channel',
  );
  @override
  late final GeneratedColumn<String> channel = GeneratedColumn<String>(
    'channel',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('share'),
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _toleranceMinorMeta = const VerificationMeta(
    'toleranceMinor',
  );
  @override
  late final GeneratedColumn<int> toleranceMinor = GeneratedColumn<int>(
    'tolerance_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _matchKeywordsMeta = const VerificationMeta(
    'matchKeywords',
  );
  @override
  late final GeneratedColumn<String> matchKeywords = GeneratedColumn<String>(
    'match_keywords',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recurringIdMeta = const VerificationMeta(
    'recurringId',
  );
  @override
  late final GeneratedColumn<String> recurringId = GeneratedColumn<String>(
    'recurring_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  @override
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
    'asset_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repeatMeta = const VerificationMeta('repeat');
  @override
  late final GeneratedColumn<String> repeat = GeneratedColumn<String>(
    'repeat',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('once'),
  );
  static const VerificationMeta _repeatDayMeta = const VerificationMeta(
    'repeatDay',
  );
  @override
  late final GeneratedColumn<int> repeatDay = GeneratedColumn<int>(
    'repeat_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remindDaysBeforeMeta = const VerificationMeta(
    'remindDaysBefore',
  );
  @override
  late final GeneratedColumn<String> remindDaysBefore = GeneratedColumn<String>(
    'remind_days_before',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('0'),
  );
  static const VerificationMeta _notifyAtMinuteMeta = const VerificationMeta(
    'notifyAtMinute',
  );
  @override
  late final GeneratedColumn<int> notifyAtMinute = GeneratedColumn<int>(
    'notify_at_minute',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _snoozedUntilMeta = const VerificationMeta(
    'snoozedUntil',
  );
  @override
  late final GeneratedColumn<DateTime> snoozedUntil = GeneratedColumn<DateTime>(
    'snoozed_until',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextIdMeta = const VerificationMeta('nextId');
  @override
  late final GeneratedColumn<String> nextId = GeneratedColumn<String>(
    'next_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _documentNumberMeta = const VerificationMeta(
    'documentNumber',
  );
  @override
  late final GeneratedColumn<String> documentNumber = GeneratedColumn<String>(
    'document_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _presetKeyMeta = const VerificationMeta(
    'presetKey',
  );
  @override
  late final GeneratedColumn<String> presetKey = GeneratedColumn<String>(
    'preset_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    deletedAt,
    id,
    kind,
    groupId,
    memberId,
    entryId,
    dueAt,
    sentAt,
    doneAt,
    channel,
    message,
    title,
    notes,
    amountMinor,
    toleranceMinor,
    matchKeywords,
    categoryId,
    accountId,
    recurringId,
    assetId,
    repeat,
    repeatDay,
    remindDaysBefore,
    notifyAtMinute,
    status,
    snoozedUntil,
    nextId,
    projectId,
    documentNumber,
    presetKey,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Reminder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    }
    if (data.containsKey('done_at')) {
      context.handle(
        _doneAtMeta,
        doneAt.isAcceptableOrUnknown(data['done_at']!, _doneAtMeta),
      );
    }
    if (data.containsKey('channel')) {
      context.handle(
        _channelMeta,
        channel.isAcceptableOrUnknown(data['channel']!, _channelMeta),
      );
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    }
    if (data.containsKey('tolerance_minor')) {
      context.handle(
        _toleranceMinorMeta,
        toleranceMinor.isAcceptableOrUnknown(
          data['tolerance_minor']!,
          _toleranceMinorMeta,
        ),
      );
    }
    if (data.containsKey('match_keywords')) {
      context.handle(
        _matchKeywordsMeta,
        matchKeywords.isAcceptableOrUnknown(
          data['match_keywords']!,
          _matchKeywordsMeta,
        ),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('recurring_id')) {
      context.handle(
        _recurringIdMeta,
        recurringId.isAcceptableOrUnknown(
          data['recurring_id']!,
          _recurringIdMeta,
        ),
      );
    }
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    }
    if (data.containsKey('repeat')) {
      context.handle(
        _repeatMeta,
        repeat.isAcceptableOrUnknown(data['repeat']!, _repeatMeta),
      );
    }
    if (data.containsKey('repeat_day')) {
      context.handle(
        _repeatDayMeta,
        repeatDay.isAcceptableOrUnknown(data['repeat_day']!, _repeatDayMeta),
      );
    }
    if (data.containsKey('remind_days_before')) {
      context.handle(
        _remindDaysBeforeMeta,
        remindDaysBefore.isAcceptableOrUnknown(
          data['remind_days_before']!,
          _remindDaysBeforeMeta,
        ),
      );
    }
    if (data.containsKey('notify_at_minute')) {
      context.handle(
        _notifyAtMinuteMeta,
        notifyAtMinute.isAcceptableOrUnknown(
          data['notify_at_minute']!,
          _notifyAtMinuteMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('snoozed_until')) {
      context.handle(
        _snoozedUntilMeta,
        snoozedUntil.isAcceptableOrUnknown(
          data['snoozed_until']!,
          _snoozedUntilMeta,
        ),
      );
    }
    if (data.containsKey('next_id')) {
      context.handle(
        _nextIdMeta,
        nextId.isAcceptableOrUnknown(data['next_id']!, _nextIdMeta),
      );
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    }
    if (data.containsKey('document_number')) {
      context.handle(
        _documentNumberMeta,
        documentNumber.isAcceptableOrUnknown(
          data['document_number']!,
          _documentNumberMeta,
        ),
      );
    }
    if (data.containsKey('preset_key')) {
      context.handle(
        _presetKeyMeta,
        presetKey.isAcceptableOrUnknown(data['preset_key']!, _presetKeyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Reminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reminder(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      ),
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      ),
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      ),
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      ),
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sent_at'],
      ),
      doneAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}done_at'],
      ),
      channel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      ),
      toleranceMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tolerance_minor'],
      )!,
      matchKeywords: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}match_keywords'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      recurringId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurring_id'],
      ),
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_id'],
      ),
      repeat: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repeat'],
      )!,
      repeatDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repeat_day'],
      ),
      remindDaysBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remind_days_before'],
      )!,
      notifyAtMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}notify_at_minute'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      snoozedUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}snoozed_until'],
      ),
      nextId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}next_id'],
      ),
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      ),
      documentNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_number'],
      )!,
      presetKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preset_key'],
      ),
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }
}

class Reminder extends DataClass implements Insertable<Reminder> {
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String id;

  /// settle_up, or a due-reminder kind: bill | emi | card | subscription | insurance | document | custom
  final String kind;
  final String? groupId;

  /// Who the reminder is about (the member asked to pay, for settle_up).
  final String? memberId;
  final String? entryId;

  /// When it should fire; null for reminders sent on the spot.
  final DateTime? dueAt;
  final DateTime? sentAt;
  final DateTime? doneAt;

  /// share | copy | whatsapp | sms | notification
  final String channel;
  final String message;

  /// What the notification says ("Electricity bill"); empty for settle_up rows.
  final String title;
  final String notes;

  /// Expected amount, null for non-money reminders (documents, custom).
  final int? amountMinor;

  /// Amount tolerance for SMS auto-match, in minor units.
  final int toleranceMinor;

  /// Lower-cased keywords matched against bank SMS: "tata power|tpddl".
  final String matchKeywords;
  final String? categoryId;
  final String? accountId;

  /// Recurring rule that produced this reminder (recurring_rules.id).
  final String? recurringId;

  /// Insurance policy, document or asset the reminder is about.
  final String? assetId;

  /// once | weekly | monthly | quarterly | yearly
  final String repeat;

  /// Day of month a repeating reminder falls on, kept so 31 Jan -> 28 Feb -> 31 Mar.
  final int? repeatDay;

  /// Days before dueAt to notify, comma separated ("3,0" = 3 days before and on the day).
  final String remindDaysBefore;

  /// Local time of day to notify, in minutes after midnight; null = no notification.
  final int? notifyAtMinute;

  /// pending | done | skipped (snoozed = pending with [snoozedUntil] in the future)
  final String status;
  final DateTime? snoozedUntil;

  /// The next occurrence spawned when this repeating reminder was paid or skipped,
  /// so undo can remove it again.
  final String? nextId;

  /// Project the reminder belongs to (projects.id), e.g. the Vehicle project's PUC.
  final String? projectId;

  /// Policy, registration or document number, kept for reference.
  final String documentNumber;

  /// Document preset the reminder was made from (lib/domain/reminders/document_presets.dart).
  final String? presetKey;
  const Reminder({
    required this.updatedAt,
    this.deletedAt,
    required this.id,
    required this.kind,
    this.groupId,
    this.memberId,
    this.entryId,
    this.dueAt,
    this.sentAt,
    this.doneAt,
    required this.channel,
    required this.message,
    required this.title,
    required this.notes,
    this.amountMinor,
    required this.toleranceMinor,
    required this.matchKeywords,
    this.categoryId,
    this.accountId,
    this.recurringId,
    this.assetId,
    required this.repeat,
    this.repeatDay,
    required this.remindDaysBefore,
    this.notifyAtMinute,
    required this.status,
    this.snoozedUntil,
    this.nextId,
    this.projectId,
    required this.documentNumber,
    this.presetKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
    }
    if (!nullToAbsent || memberId != null) {
      map['member_id'] = Variable<String>(memberId);
    }
    if (!nullToAbsent || entryId != null) {
      map['entry_id'] = Variable<String>(entryId);
    }
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<DateTime>(dueAt);
    }
    if (!nullToAbsent || sentAt != null) {
      map['sent_at'] = Variable<DateTime>(sentAt);
    }
    if (!nullToAbsent || doneAt != null) {
      map['done_at'] = Variable<DateTime>(doneAt);
    }
    map['channel'] = Variable<String>(channel);
    map['message'] = Variable<String>(message);
    map['title'] = Variable<String>(title);
    map['notes'] = Variable<String>(notes);
    if (!nullToAbsent || amountMinor != null) {
      map['amount_minor'] = Variable<int>(amountMinor);
    }
    map['tolerance_minor'] = Variable<int>(toleranceMinor);
    map['match_keywords'] = Variable<String>(matchKeywords);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    if (!nullToAbsent || recurringId != null) {
      map['recurring_id'] = Variable<String>(recurringId);
    }
    if (!nullToAbsent || assetId != null) {
      map['asset_id'] = Variable<String>(assetId);
    }
    map['repeat'] = Variable<String>(repeat);
    if (!nullToAbsent || repeatDay != null) {
      map['repeat_day'] = Variable<int>(repeatDay);
    }
    map['remind_days_before'] = Variable<String>(remindDaysBefore);
    if (!nullToAbsent || notifyAtMinute != null) {
      map['notify_at_minute'] = Variable<int>(notifyAtMinute);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || snoozedUntil != null) {
      map['snoozed_until'] = Variable<DateTime>(snoozedUntil);
    }
    if (!nullToAbsent || nextId != null) {
      map['next_id'] = Variable<String>(nextId);
    }
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<String>(projectId);
    }
    map['document_number'] = Variable<String>(documentNumber);
    if (!nullToAbsent || presetKey != null) {
      map['preset_key'] = Variable<String>(presetKey);
    }
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      kind: Value(kind),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      memberId: memberId == null && nullToAbsent
          ? const Value.absent()
          : Value(memberId),
      entryId: entryId == null && nullToAbsent
          ? const Value.absent()
          : Value(entryId),
      dueAt: dueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAt),
      sentAt: sentAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sentAt),
      doneAt: doneAt == null && nullToAbsent
          ? const Value.absent()
          : Value(doneAt),
      channel: Value(channel),
      message: Value(message),
      title: Value(title),
      notes: Value(notes),
      amountMinor: amountMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(amountMinor),
      toleranceMinor: Value(toleranceMinor),
      matchKeywords: Value(matchKeywords),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      recurringId: recurringId == null && nullToAbsent
          ? const Value.absent()
          : Value(recurringId),
      assetId: assetId == null && nullToAbsent
          ? const Value.absent()
          : Value(assetId),
      repeat: Value(repeat),
      repeatDay: repeatDay == null && nullToAbsent
          ? const Value.absent()
          : Value(repeatDay),
      remindDaysBefore: Value(remindDaysBefore),
      notifyAtMinute: notifyAtMinute == null && nullToAbsent
          ? const Value.absent()
          : Value(notifyAtMinute),
      status: Value(status),
      snoozedUntil: snoozedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(snoozedUntil),
      nextId: nextId == null && nullToAbsent
          ? const Value.absent()
          : Value(nextId),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      documentNumber: Value(documentNumber),
      presetKey: presetKey == null && nullToAbsent
          ? const Value.absent()
          : Value(presetKey),
    );
  }

  factory Reminder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reminder(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      groupId: serializer.fromJson<String?>(json['groupId']),
      memberId: serializer.fromJson<String?>(json['memberId']),
      entryId: serializer.fromJson<String?>(json['entryId']),
      dueAt: serializer.fromJson<DateTime?>(json['dueAt']),
      sentAt: serializer.fromJson<DateTime?>(json['sentAt']),
      doneAt: serializer.fromJson<DateTime?>(json['doneAt']),
      channel: serializer.fromJson<String>(json['channel']),
      message: serializer.fromJson<String>(json['message']),
      title: serializer.fromJson<String>(json['title']),
      notes: serializer.fromJson<String>(json['notes']),
      amountMinor: serializer.fromJson<int?>(json['amountMinor']),
      toleranceMinor: serializer.fromJson<int>(json['toleranceMinor']),
      matchKeywords: serializer.fromJson<String>(json['matchKeywords']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      recurringId: serializer.fromJson<String?>(json['recurringId']),
      assetId: serializer.fromJson<String?>(json['assetId']),
      repeat: serializer.fromJson<String>(json['repeat']),
      repeatDay: serializer.fromJson<int?>(json['repeatDay']),
      remindDaysBefore: serializer.fromJson<String>(json['remindDaysBefore']),
      notifyAtMinute: serializer.fromJson<int?>(json['notifyAtMinute']),
      status: serializer.fromJson<String>(json['status']),
      snoozedUntil: serializer.fromJson<DateTime?>(json['snoozedUntil']),
      nextId: serializer.fromJson<String?>(json['nextId']),
      projectId: serializer.fromJson<String?>(json['projectId']),
      documentNumber: serializer.fromJson<String>(json['documentNumber']),
      presetKey: serializer.fromJson<String?>(json['presetKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'groupId': serializer.toJson<String?>(groupId),
      'memberId': serializer.toJson<String?>(memberId),
      'entryId': serializer.toJson<String?>(entryId),
      'dueAt': serializer.toJson<DateTime?>(dueAt),
      'sentAt': serializer.toJson<DateTime?>(sentAt),
      'doneAt': serializer.toJson<DateTime?>(doneAt),
      'channel': serializer.toJson<String>(channel),
      'message': serializer.toJson<String>(message),
      'title': serializer.toJson<String>(title),
      'notes': serializer.toJson<String>(notes),
      'amountMinor': serializer.toJson<int?>(amountMinor),
      'toleranceMinor': serializer.toJson<int>(toleranceMinor),
      'matchKeywords': serializer.toJson<String>(matchKeywords),
      'categoryId': serializer.toJson<String?>(categoryId),
      'accountId': serializer.toJson<String?>(accountId),
      'recurringId': serializer.toJson<String?>(recurringId),
      'assetId': serializer.toJson<String?>(assetId),
      'repeat': serializer.toJson<String>(repeat),
      'repeatDay': serializer.toJson<int?>(repeatDay),
      'remindDaysBefore': serializer.toJson<String>(remindDaysBefore),
      'notifyAtMinute': serializer.toJson<int?>(notifyAtMinute),
      'status': serializer.toJson<String>(status),
      'snoozedUntil': serializer.toJson<DateTime?>(snoozedUntil),
      'nextId': serializer.toJson<String?>(nextId),
      'projectId': serializer.toJson<String?>(projectId),
      'documentNumber': serializer.toJson<String>(documentNumber),
      'presetKey': serializer.toJson<String?>(presetKey),
    };
  }

  Reminder copyWith({
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? id,
    String? kind,
    Value<String?> groupId = const Value.absent(),
    Value<String?> memberId = const Value.absent(),
    Value<String?> entryId = const Value.absent(),
    Value<DateTime?> dueAt = const Value.absent(),
    Value<DateTime?> sentAt = const Value.absent(),
    Value<DateTime?> doneAt = const Value.absent(),
    String? channel,
    String? message,
    String? title,
    String? notes,
    Value<int?> amountMinor = const Value.absent(),
    int? toleranceMinor,
    String? matchKeywords,
    Value<String?> categoryId = const Value.absent(),
    Value<String?> accountId = const Value.absent(),
    Value<String?> recurringId = const Value.absent(),
    Value<String?> assetId = const Value.absent(),
    String? repeat,
    Value<int?> repeatDay = const Value.absent(),
    String? remindDaysBefore,
    Value<int?> notifyAtMinute = const Value.absent(),
    String? status,
    Value<DateTime?> snoozedUntil = const Value.absent(),
    Value<String?> nextId = const Value.absent(),
    Value<String?> projectId = const Value.absent(),
    String? documentNumber,
    Value<String?> presetKey = const Value.absent(),
  }) => Reminder(
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    kind: kind ?? this.kind,
    groupId: groupId.present ? groupId.value : this.groupId,
    memberId: memberId.present ? memberId.value : this.memberId,
    entryId: entryId.present ? entryId.value : this.entryId,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    sentAt: sentAt.present ? sentAt.value : this.sentAt,
    doneAt: doneAt.present ? doneAt.value : this.doneAt,
    channel: channel ?? this.channel,
    message: message ?? this.message,
    title: title ?? this.title,
    notes: notes ?? this.notes,
    amountMinor: amountMinor.present ? amountMinor.value : this.amountMinor,
    toleranceMinor: toleranceMinor ?? this.toleranceMinor,
    matchKeywords: matchKeywords ?? this.matchKeywords,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    accountId: accountId.present ? accountId.value : this.accountId,
    recurringId: recurringId.present ? recurringId.value : this.recurringId,
    assetId: assetId.present ? assetId.value : this.assetId,
    repeat: repeat ?? this.repeat,
    repeatDay: repeatDay.present ? repeatDay.value : this.repeatDay,
    remindDaysBefore: remindDaysBefore ?? this.remindDaysBefore,
    notifyAtMinute: notifyAtMinute.present
        ? notifyAtMinute.value
        : this.notifyAtMinute,
    status: status ?? this.status,
    snoozedUntil: snoozedUntil.present ? snoozedUntil.value : this.snoozedUntil,
    nextId: nextId.present ? nextId.value : this.nextId,
    projectId: projectId.present ? projectId.value : this.projectId,
    documentNumber: documentNumber ?? this.documentNumber,
    presetKey: presetKey.present ? presetKey.value : this.presetKey,
  );
  Reminder copyWithCompanion(RemindersCompanion data) {
    return Reminder(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      doneAt: data.doneAt.present ? data.doneAt.value : this.doneAt,
      channel: data.channel.present ? data.channel.value : this.channel,
      message: data.message.present ? data.message.value : this.message,
      title: data.title.present ? data.title.value : this.title,
      notes: data.notes.present ? data.notes.value : this.notes,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      toleranceMinor: data.toleranceMinor.present
          ? data.toleranceMinor.value
          : this.toleranceMinor,
      matchKeywords: data.matchKeywords.present
          ? data.matchKeywords.value
          : this.matchKeywords,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      recurringId: data.recurringId.present
          ? data.recurringId.value
          : this.recurringId,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      repeat: data.repeat.present ? data.repeat.value : this.repeat,
      repeatDay: data.repeatDay.present ? data.repeatDay.value : this.repeatDay,
      remindDaysBefore: data.remindDaysBefore.present
          ? data.remindDaysBefore.value
          : this.remindDaysBefore,
      notifyAtMinute: data.notifyAtMinute.present
          ? data.notifyAtMinute.value
          : this.notifyAtMinute,
      status: data.status.present ? data.status.value : this.status,
      snoozedUntil: data.snoozedUntil.present
          ? data.snoozedUntil.value
          : this.snoozedUntil,
      nextId: data.nextId.present ? data.nextId.value : this.nextId,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      documentNumber: data.documentNumber.present
          ? data.documentNumber.value
          : this.documentNumber,
      presetKey: data.presetKey.present ? data.presetKey.value : this.presetKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reminder(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('groupId: $groupId, ')
          ..write('memberId: $memberId, ')
          ..write('entryId: $entryId, ')
          ..write('dueAt: $dueAt, ')
          ..write('sentAt: $sentAt, ')
          ..write('doneAt: $doneAt, ')
          ..write('channel: $channel, ')
          ..write('message: $message, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('toleranceMinor: $toleranceMinor, ')
          ..write('matchKeywords: $matchKeywords, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('recurringId: $recurringId, ')
          ..write('assetId: $assetId, ')
          ..write('repeat: $repeat, ')
          ..write('repeatDay: $repeatDay, ')
          ..write('remindDaysBefore: $remindDaysBefore, ')
          ..write('notifyAtMinute: $notifyAtMinute, ')
          ..write('status: $status, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('nextId: $nextId, ')
          ..write('projectId: $projectId, ')
          ..write('documentNumber: $documentNumber, ')
          ..write('presetKey: $presetKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    updatedAt,
    deletedAt,
    id,
    kind,
    groupId,
    memberId,
    entryId,
    dueAt,
    sentAt,
    doneAt,
    channel,
    message,
    title,
    notes,
    amountMinor,
    toleranceMinor,
    matchKeywords,
    categoryId,
    accountId,
    recurringId,
    assetId,
    repeat,
    repeatDay,
    remindDaysBefore,
    notifyAtMinute,
    status,
    snoozedUntil,
    nextId,
    projectId,
    documentNumber,
    presetKey,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reminder &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.groupId == this.groupId &&
          other.memberId == this.memberId &&
          other.entryId == this.entryId &&
          other.dueAt == this.dueAt &&
          other.sentAt == this.sentAt &&
          other.doneAt == this.doneAt &&
          other.channel == this.channel &&
          other.message == this.message &&
          other.title == this.title &&
          other.notes == this.notes &&
          other.amountMinor == this.amountMinor &&
          other.toleranceMinor == this.toleranceMinor &&
          other.matchKeywords == this.matchKeywords &&
          other.categoryId == this.categoryId &&
          other.accountId == this.accountId &&
          other.recurringId == this.recurringId &&
          other.assetId == this.assetId &&
          other.repeat == this.repeat &&
          other.repeatDay == this.repeatDay &&
          other.remindDaysBefore == this.remindDaysBefore &&
          other.notifyAtMinute == this.notifyAtMinute &&
          other.status == this.status &&
          other.snoozedUntil == this.snoozedUntil &&
          other.nextId == this.nextId &&
          other.projectId == this.projectId &&
          other.documentNumber == this.documentNumber &&
          other.presetKey == this.presetKey);
}

class RemindersCompanion extends UpdateCompanion<Reminder> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> id;
  final Value<String> kind;
  final Value<String?> groupId;
  final Value<String?> memberId;
  final Value<String?> entryId;
  final Value<DateTime?> dueAt;
  final Value<DateTime?> sentAt;
  final Value<DateTime?> doneAt;
  final Value<String> channel;
  final Value<String> message;
  final Value<String> title;
  final Value<String> notes;
  final Value<int?> amountMinor;
  final Value<int> toleranceMinor;
  final Value<String> matchKeywords;
  final Value<String?> categoryId;
  final Value<String?> accountId;
  final Value<String?> recurringId;
  final Value<String?> assetId;
  final Value<String> repeat;
  final Value<int?> repeatDay;
  final Value<String> remindDaysBefore;
  final Value<int?> notifyAtMinute;
  final Value<String> status;
  final Value<DateTime?> snoozedUntil;
  final Value<String?> nextId;
  final Value<String?> projectId;
  final Value<String> documentNumber;
  final Value<String?> presetKey;
  final Value<int> rowid;
  const RemindersCompanion({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.groupId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.entryId = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.doneAt = const Value.absent(),
    this.channel = const Value.absent(),
    this.message = const Value.absent(),
    this.title = const Value.absent(),
    this.notes = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.toleranceMinor = const Value.absent(),
    this.matchKeywords = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.recurringId = const Value.absent(),
    this.assetId = const Value.absent(),
    this.repeat = const Value.absent(),
    this.repeatDay = const Value.absent(),
    this.remindDaysBefore = const Value.absent(),
    this.notifyAtMinute = const Value.absent(),
    this.status = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
    this.nextId = const Value.absent(),
    this.projectId = const Value.absent(),
    this.documentNumber = const Value.absent(),
    this.presetKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemindersCompanion.insert({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String id,
    required String kind,
    this.groupId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.entryId = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.doneAt = const Value.absent(),
    this.channel = const Value.absent(),
    this.message = const Value.absent(),
    this.title = const Value.absent(),
    this.notes = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.toleranceMinor = const Value.absent(),
    this.matchKeywords = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.recurringId = const Value.absent(),
    this.assetId = const Value.absent(),
    this.repeat = const Value.absent(),
    this.repeatDay = const Value.absent(),
    this.remindDaysBefore = const Value.absent(),
    this.notifyAtMinute = const Value.absent(),
    this.status = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
    this.nextId = const Value.absent(),
    this.projectId = const Value.absent(),
    this.documentNumber = const Value.absent(),
    this.presetKey = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind);
  static Insertable<Reminder> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? groupId,
    Expression<String>? memberId,
    Expression<String>? entryId,
    Expression<DateTime>? dueAt,
    Expression<DateTime>? sentAt,
    Expression<DateTime>? doneAt,
    Expression<String>? channel,
    Expression<String>? message,
    Expression<String>? title,
    Expression<String>? notes,
    Expression<int>? amountMinor,
    Expression<int>? toleranceMinor,
    Expression<String>? matchKeywords,
    Expression<String>? categoryId,
    Expression<String>? accountId,
    Expression<String>? recurringId,
    Expression<String>? assetId,
    Expression<String>? repeat,
    Expression<int>? repeatDay,
    Expression<String>? remindDaysBefore,
    Expression<int>? notifyAtMinute,
    Expression<String>? status,
    Expression<DateTime>? snoozedUntil,
    Expression<String>? nextId,
    Expression<String>? projectId,
    Expression<String>? documentNumber,
    Expression<String>? presetKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (groupId != null) 'group_id': groupId,
      if (memberId != null) 'member_id': memberId,
      if (entryId != null) 'entry_id': entryId,
      if (dueAt != null) 'due_at': dueAt,
      if (sentAt != null) 'sent_at': sentAt,
      if (doneAt != null) 'done_at': doneAt,
      if (channel != null) 'channel': channel,
      if (message != null) 'message': message,
      if (title != null) 'title': title,
      if (notes != null) 'notes': notes,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (toleranceMinor != null) 'tolerance_minor': toleranceMinor,
      if (matchKeywords != null) 'match_keywords': matchKeywords,
      if (categoryId != null) 'category_id': categoryId,
      if (accountId != null) 'account_id': accountId,
      if (recurringId != null) 'recurring_id': recurringId,
      if (assetId != null) 'asset_id': assetId,
      if (repeat != null) 'repeat': repeat,
      if (repeatDay != null) 'repeat_day': repeatDay,
      if (remindDaysBefore != null) 'remind_days_before': remindDaysBefore,
      if (notifyAtMinute != null) 'notify_at_minute': notifyAtMinute,
      if (status != null) 'status': status,
      if (snoozedUntil != null) 'snoozed_until': snoozedUntil,
      if (nextId != null) 'next_id': nextId,
      if (projectId != null) 'project_id': projectId,
      if (documentNumber != null) 'document_number': documentNumber,
      if (presetKey != null) 'preset_key': presetKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemindersCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? id,
    Value<String>? kind,
    Value<String?>? groupId,
    Value<String?>? memberId,
    Value<String?>? entryId,
    Value<DateTime?>? dueAt,
    Value<DateTime?>? sentAt,
    Value<DateTime?>? doneAt,
    Value<String>? channel,
    Value<String>? message,
    Value<String>? title,
    Value<String>? notes,
    Value<int?>? amountMinor,
    Value<int>? toleranceMinor,
    Value<String>? matchKeywords,
    Value<String?>? categoryId,
    Value<String?>? accountId,
    Value<String?>? recurringId,
    Value<String?>? assetId,
    Value<String>? repeat,
    Value<int?>? repeatDay,
    Value<String>? remindDaysBefore,
    Value<int?>? notifyAtMinute,
    Value<String>? status,
    Value<DateTime?>? snoozedUntil,
    Value<String?>? nextId,
    Value<String?>? projectId,
    Value<String>? documentNumber,
    Value<String?>? presetKey,
    Value<int>? rowid,
  }) {
    return RemindersCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      kind: kind ?? this.kind,
      groupId: groupId ?? this.groupId,
      memberId: memberId ?? this.memberId,
      entryId: entryId ?? this.entryId,
      dueAt: dueAt ?? this.dueAt,
      sentAt: sentAt ?? this.sentAt,
      doneAt: doneAt ?? this.doneAt,
      channel: channel ?? this.channel,
      message: message ?? this.message,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      amountMinor: amountMinor ?? this.amountMinor,
      toleranceMinor: toleranceMinor ?? this.toleranceMinor,
      matchKeywords: matchKeywords ?? this.matchKeywords,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      recurringId: recurringId ?? this.recurringId,
      assetId: assetId ?? this.assetId,
      repeat: repeat ?? this.repeat,
      repeatDay: repeatDay ?? this.repeatDay,
      remindDaysBefore: remindDaysBefore ?? this.remindDaysBefore,
      notifyAtMinute: notifyAtMinute ?? this.notifyAtMinute,
      status: status ?? this.status,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      nextId: nextId ?? this.nextId,
      projectId: projectId ?? this.projectId,
      documentNumber: documentNumber ?? this.documentNumber,
      presetKey: presetKey ?? this.presetKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<DateTime>(sentAt.value);
    }
    if (doneAt.present) {
      map['done_at'] = Variable<DateTime>(doneAt.value);
    }
    if (channel.present) {
      map['channel'] = Variable<String>(channel.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (toleranceMinor.present) {
      map['tolerance_minor'] = Variable<int>(toleranceMinor.value);
    }
    if (matchKeywords.present) {
      map['match_keywords'] = Variable<String>(matchKeywords.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (recurringId.present) {
      map['recurring_id'] = Variable<String>(recurringId.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (repeat.present) {
      map['repeat'] = Variable<String>(repeat.value);
    }
    if (repeatDay.present) {
      map['repeat_day'] = Variable<int>(repeatDay.value);
    }
    if (remindDaysBefore.present) {
      map['remind_days_before'] = Variable<String>(remindDaysBefore.value);
    }
    if (notifyAtMinute.present) {
      map['notify_at_minute'] = Variable<int>(notifyAtMinute.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (snoozedUntil.present) {
      map['snoozed_until'] = Variable<DateTime>(snoozedUntil.value);
    }
    if (nextId.present) {
      map['next_id'] = Variable<String>(nextId.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (documentNumber.present) {
      map['document_number'] = Variable<String>(documentNumber.value);
    }
    if (presetKey.present) {
      map['preset_key'] = Variable<String>(presetKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('groupId: $groupId, ')
          ..write('memberId: $memberId, ')
          ..write('entryId: $entryId, ')
          ..write('dueAt: $dueAt, ')
          ..write('sentAt: $sentAt, ')
          ..write('doneAt: $doneAt, ')
          ..write('channel: $channel, ')
          ..write('message: $message, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('toleranceMinor: $toleranceMinor, ')
          ..write('matchKeywords: $matchKeywords, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('recurringId: $recurringId, ')
          ..write('assetId: $assetId, ')
          ..write('repeat: $repeat, ')
          ..write('repeatDay: $repeatDay, ')
          ..write('remindDaysBefore: $remindDaysBefore, ')
          ..write('notifyAtMinute: $notifyAtMinute, ')
          ..write('status: $status, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('nextId: $nextId, ')
          ..write('projectId: $projectId, ')
          ..write('documentNumber: $documentNumber, ')
          ..write('presetKey: $presetKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EntryPayersTable extends EntryPayers
    with TableInfo<$EntryPayersTable, EntryPayer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntryPayersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    deletedAt,
    id,
    entryId,
    memberId,
    amountMinor,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entry_payers';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntryPayer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EntryPayer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntryPayer(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
    );
  }

  @override
  $EntryPayersTable createAlias(String alias) {
    return $EntryPayersTable(attachedDatabase, alias);
  }
}

class EntryPayer extends DataClass implements Insertable<EntryPayer> {
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String id;
  final String entryId;
  final String memberId;
  final int amountMinor;
  const EntryPayer({
    required this.updatedAt,
    this.deletedAt,
    required this.id,
    required this.entryId,
    required this.memberId,
    required this.amountMinor,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<String>(id);
    map['entry_id'] = Variable<String>(entryId);
    map['member_id'] = Variable<String>(memberId);
    map['amount_minor'] = Variable<int>(amountMinor);
    return map;
  }

  EntryPayersCompanion toCompanion(bool nullToAbsent) {
    return EntryPayersCompanion(
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      entryId: Value(entryId),
      memberId: Value(memberId),
      amountMinor: Value(amountMinor),
    );
  }

  factory EntryPayer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntryPayer(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<String>(json['id']),
      entryId: serializer.fromJson<String>(json['entryId']),
      memberId: serializer.fromJson<String>(json['memberId']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<String>(id),
      'entryId': serializer.toJson<String>(entryId),
      'memberId': serializer.toJson<String>(memberId),
      'amountMinor': serializer.toJson<int>(amountMinor),
    };
  }

  EntryPayer copyWith({
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? id,
    String? entryId,
    String? memberId,
    int? amountMinor,
  }) => EntryPayer(
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    entryId: entryId ?? this.entryId,
    memberId: memberId ?? this.memberId,
    amountMinor: amountMinor ?? this.amountMinor,
  );
  EntryPayer copyWithCompanion(EntryPayersCompanion data) {
    return EntryPayer(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntryPayer(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('memberId: $memberId, ')
          ..write('amountMinor: $amountMinor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(updatedAt, deletedAt, id, entryId, memberId, amountMinor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntryPayer &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.memberId == this.memberId &&
          other.amountMinor == this.amountMinor);
}

class EntryPayersCompanion extends UpdateCompanion<EntryPayer> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> id;
  final Value<String> entryId;
  final Value<String> memberId;
  final Value<int> amountMinor;
  final Value<int> rowid;
  const EntryPayersCompanion({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntryPayersCompanion.insert({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String id,
    required String entryId,
    required String memberId,
    required int amountMinor,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entryId = Value(entryId),
       memberId = Value(memberId),
       amountMinor = Value(amountMinor);
  static Insertable<EntryPayer> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? id,
    Expression<String>? entryId,
    Expression<String>? memberId,
    Expression<int>? amountMinor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (memberId != null) 'member_id': memberId,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntryPayersCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? id,
    Value<String>? entryId,
    Value<String>? memberId,
    Value<int>? amountMinor,
    Value<int>? rowid,
  }) {
    return EntryPayersCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      memberId: memberId ?? this.memberId,
      amountMinor: amountMinor ?? this.amountMinor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntryPayersCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('memberId: $memberId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecurringRulesTable extends RecurringRules
    with TableInfo<$RecurringRulesTable, RecurringRule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurringRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
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
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('INR'),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _toAccountIdMeta = const VerificationMeta(
    'toAccountId',
  );
  @override
  late final GeneratedColumn<String> toAccountId = GeneratedColumn<String>(
    'to_account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payeeMeta = const VerificationMeta('payee');
  @override
  late final GeneratedColumn<String> payee = GeneratedColumn<String>(
    'payee',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _frequencyMeta = const VerificationMeta(
    'frequency',
  );
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
    'frequency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intervalMeta = const VerificationMeta(
    'interval',
  );
  @override
  late final GeneratedColumn<int> interval = GeneratedColumn<int>(
    'interval',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _dayOfMonthMeta = const VerificationMeta(
    'dayOfMonth',
  );
  @override
  late final GeneratedColumn<int> dayOfMonth = GeneratedColumn<int>(
    'day_of_month',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weekdayMeta = const VerificationMeta(
    'weekday',
  );
  @override
  late final GeneratedColumn<int> weekday = GeneratedColumn<int>(
    'weekday',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxCountMeta = const VerificationMeta(
    'maxCount',
  );
  @override
  late final GeneratedColumn<int> maxCount = GeneratedColumn<int>(
    'max_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _postedCountMeta = const VerificationMeta(
    'postedCount',
  );
  @override
  late final GeneratedColumn<int> postedCount = GeneratedColumn<int>(
    'posted_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _skippedCountMeta = const VerificationMeta(
    'skippedCount',
  );
  @override
  late final GeneratedColumn<int> skippedCount = GeneratedColumn<int>(
    'skipped_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextDueMeta = const VerificationMeta(
    'nextDue',
  );
  @override
  late final GeneratedColumn<DateTime> nextDue = GeneratedColumn<DateTime>(
    'next_due',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _autoPostMeta = const VerificationMeta(
    'autoPost',
  );
  @override
  late final GeneratedColumn<bool> autoPost = GeneratedColumn<bool>(
    'auto_post',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_post" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _remindDaysBeforeMeta = const VerificationMeta(
    'remindDaysBefore',
  );
  @override
  late final GeneratedColumn<String> remindDaysBefore = GeneratedColumn<String>(
    'remind_days_before',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isSubscriptionMeta = const VerificationMeta(
    'isSubscription',
  );
  @override
  late final GeneratedColumn<bool> isSubscription = GeneratedColumn<bool>(
    'is_subscription',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_subscription" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupSplitMeta = const VerificationMeta(
    'groupSplit',
  );
  @override
  late final GeneratedColumn<String> groupSplit = GeneratedColumn<String>(
    'group_split',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
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
    updatedAt,
    deletedAt,
    id,
    name,
    kind,
    amountMinor,
    currency,
    categoryId,
    accountId,
    toAccountId,
    payee,
    projectId,
    note,
    frequency,
    interval,
    dayOfMonth,
    weekday,
    startDate,
    endDate,
    maxCount,
    postedCount,
    skippedCount,
    nextDue,
    autoPost,
    remindDaysBefore,
    isSubscription,
    groupId,
    groupSplit,
    status,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurring_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecurringRule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
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
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('to_account_id')) {
      context.handle(
        _toAccountIdMeta,
        toAccountId.isAcceptableOrUnknown(
          data['to_account_id']!,
          _toAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('payee')) {
      context.handle(
        _payeeMeta,
        payee.isAcceptableOrUnknown(data['payee']!, _payeeMeta),
      );
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('frequency')) {
      context.handle(
        _frequencyMeta,
        frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta),
      );
    } else if (isInserting) {
      context.missing(_frequencyMeta);
    }
    if (data.containsKey('interval')) {
      context.handle(
        _intervalMeta,
        interval.isAcceptableOrUnknown(data['interval']!, _intervalMeta),
      );
    }
    if (data.containsKey('day_of_month')) {
      context.handle(
        _dayOfMonthMeta,
        dayOfMonth.isAcceptableOrUnknown(
          data['day_of_month']!,
          _dayOfMonthMeta,
        ),
      );
    }
    if (data.containsKey('weekday')) {
      context.handle(
        _weekdayMeta,
        weekday.isAcceptableOrUnknown(data['weekday']!, _weekdayMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('max_count')) {
      context.handle(
        _maxCountMeta,
        maxCount.isAcceptableOrUnknown(data['max_count']!, _maxCountMeta),
      );
    }
    if (data.containsKey('posted_count')) {
      context.handle(
        _postedCountMeta,
        postedCount.isAcceptableOrUnknown(
          data['posted_count']!,
          _postedCountMeta,
        ),
      );
    }
    if (data.containsKey('skipped_count')) {
      context.handle(
        _skippedCountMeta,
        skippedCount.isAcceptableOrUnknown(
          data['skipped_count']!,
          _skippedCountMeta,
        ),
      );
    }
    if (data.containsKey('next_due')) {
      context.handle(
        _nextDueMeta,
        nextDue.isAcceptableOrUnknown(data['next_due']!, _nextDueMeta),
      );
    }
    if (data.containsKey('auto_post')) {
      context.handle(
        _autoPostMeta,
        autoPost.isAcceptableOrUnknown(data['auto_post']!, _autoPostMeta),
      );
    }
    if (data.containsKey('remind_days_before')) {
      context.handle(
        _remindDaysBeforeMeta,
        remindDaysBefore.isAcceptableOrUnknown(
          data['remind_days_before']!,
          _remindDaysBeforeMeta,
        ),
      );
    }
    if (data.containsKey('is_subscription')) {
      context.handle(
        _isSubscriptionMeta,
        isSubscription.isAcceptableOrUnknown(
          data['is_subscription']!,
          _isSubscriptionMeta,
        ),
      );
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    }
    if (data.containsKey('group_split')) {
      context.handle(
        _groupSplitMeta,
        groupSplit.isAcceptableOrUnknown(data['group_split']!, _groupSplitMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
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
  RecurringRule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurringRule(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      toAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_account_id'],
      ),
      payee: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payee'],
      ),
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      frequency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frequency'],
      )!,
      interval: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval'],
      )!,
      dayOfMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_of_month'],
      ),
      weekday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekday'],
      ),
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      ),
      maxCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_count'],
      ),
      postedCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}posted_count'],
      )!,
      skippedCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}skipped_count'],
      )!,
      nextDue: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_due'],
      ),
      autoPost: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_post'],
      )!,
      remindDaysBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remind_days_before'],
      )!,
      isSubscription: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_subscription'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      ),
      groupSplit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_split'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $RecurringRulesTable createAlias(String alias) {
    return $RecurringRulesTable(attachedDatabase, alias);
  }
}

class RecurringRule extends DataClass implements Insertable<RecurringRule> {
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String id;

  /// Display name ("Rent", "Netflix"); empty falls back to payee or category.
  final String name;

  /// expense | income | transfer
  final String kind;
  final int amountMinor;
  final String currency;
  final String? categoryId;
  final String? accountId;
  final String? toAccountId;
  final String? payee;
  final String? projectId;
  final String note;

  /// daily | weekly | monthly | yearly; a custom schedule is one of these
  /// with [interval] above one.
  final String frequency;
  final int interval;

  /// 1..31, -1 = last day of the month, 0 = the month start day setting.
  final int? dayOfMonth;

  /// ISO weekday 1..7 for weekly rules.
  final int? weekday;
  final DateTime startDate;
  final DateTime? endDate;
  final int? maxCount;

  /// Occurrences already posted or skipped, counted against [maxCount].
  final int postedCount;

  /// How many of [postedCount] were skipped rather than added.
  final int skippedCount;

  /// Next occurrence not yet posted or skipped; null once the rule ended.
  final DateTime? nextDue;

  /// Post due occurrences without asking; false lists them as Upcoming to confirm.
  final bool autoPost;

  /// Comma separated days before the due date to notify ("3,0").
  final String remindDaysBefore;
  final bool isSubscription;

  /// Group a recurring group expense (rent, maid, wifi) is posted to.
  final String? groupId;

  /// How a group rule splits and who pays: `GroupExpenseTemplate` as JSON.
  final String? groupSplit;

  /// active | paused | ended
  final String status;
  final DateTime createdAt;
  const RecurringRule({
    required this.updatedAt,
    this.deletedAt,
    required this.id,
    required this.name,
    required this.kind,
    required this.amountMinor,
    required this.currency,
    this.categoryId,
    this.accountId,
    this.toAccountId,
    this.payee,
    this.projectId,
    required this.note,
    required this.frequency,
    required this.interval,
    this.dayOfMonth,
    this.weekday,
    required this.startDate,
    this.endDate,
    this.maxCount,
    required this.postedCount,
    required this.skippedCount,
    this.nextDue,
    required this.autoPost,
    required this.remindDaysBefore,
    required this.isSubscription,
    this.groupId,
    this.groupSplit,
    required this.status,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    map['amount_minor'] = Variable<int>(amountMinor);
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    if (!nullToAbsent || toAccountId != null) {
      map['to_account_id'] = Variable<String>(toAccountId);
    }
    if (!nullToAbsent || payee != null) {
      map['payee'] = Variable<String>(payee);
    }
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<String>(projectId);
    }
    map['note'] = Variable<String>(note);
    map['frequency'] = Variable<String>(frequency);
    map['interval'] = Variable<int>(interval);
    if (!nullToAbsent || dayOfMonth != null) {
      map['day_of_month'] = Variable<int>(dayOfMonth);
    }
    if (!nullToAbsent || weekday != null) {
      map['weekday'] = Variable<int>(weekday);
    }
    map['start_date'] = Variable<DateTime>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    if (!nullToAbsent || maxCount != null) {
      map['max_count'] = Variable<int>(maxCount);
    }
    map['posted_count'] = Variable<int>(postedCount);
    map['skipped_count'] = Variable<int>(skippedCount);
    if (!nullToAbsent || nextDue != null) {
      map['next_due'] = Variable<DateTime>(nextDue);
    }
    map['auto_post'] = Variable<bool>(autoPost);
    map['remind_days_before'] = Variable<String>(remindDaysBefore);
    map['is_subscription'] = Variable<bool>(isSubscription);
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
    }
    if (!nullToAbsent || groupSplit != null) {
      map['group_split'] = Variable<String>(groupSplit);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RecurringRulesCompanion toCompanion(bool nullToAbsent) {
    return RecurringRulesCompanion(
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      amountMinor: Value(amountMinor),
      currency: Value(currency),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      toAccountId: toAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(toAccountId),
      payee: payee == null && nullToAbsent
          ? const Value.absent()
          : Value(payee),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      note: Value(note),
      frequency: Value(frequency),
      interval: Value(interval),
      dayOfMonth: dayOfMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(dayOfMonth),
      weekday: weekday == null && nullToAbsent
          ? const Value.absent()
          : Value(weekday),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      maxCount: maxCount == null && nullToAbsent
          ? const Value.absent()
          : Value(maxCount),
      postedCount: Value(postedCount),
      skippedCount: Value(skippedCount),
      nextDue: nextDue == null && nullToAbsent
          ? const Value.absent()
          : Value(nextDue),
      autoPost: Value(autoPost),
      remindDaysBefore: Value(remindDaysBefore),
      isSubscription: Value(isSubscription),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      groupSplit: groupSplit == null && nullToAbsent
          ? const Value.absent()
          : Value(groupSplit),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory RecurringRule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurringRule(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      currency: serializer.fromJson<String>(json['currency']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      toAccountId: serializer.fromJson<String?>(json['toAccountId']),
      payee: serializer.fromJson<String?>(json['payee']),
      projectId: serializer.fromJson<String?>(json['projectId']),
      note: serializer.fromJson<String>(json['note']),
      frequency: serializer.fromJson<String>(json['frequency']),
      interval: serializer.fromJson<int>(json['interval']),
      dayOfMonth: serializer.fromJson<int?>(json['dayOfMonth']),
      weekday: serializer.fromJson<int?>(json['weekday']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      maxCount: serializer.fromJson<int?>(json['maxCount']),
      postedCount: serializer.fromJson<int>(json['postedCount']),
      skippedCount: serializer.fromJson<int>(json['skippedCount']),
      nextDue: serializer.fromJson<DateTime?>(json['nextDue']),
      autoPost: serializer.fromJson<bool>(json['autoPost']),
      remindDaysBefore: serializer.fromJson<String>(json['remindDaysBefore']),
      isSubscription: serializer.fromJson<bool>(json['isSubscription']),
      groupId: serializer.fromJson<String?>(json['groupId']),
      groupSplit: serializer.fromJson<String?>(json['groupSplit']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'currency': serializer.toJson<String>(currency),
      'categoryId': serializer.toJson<String?>(categoryId),
      'accountId': serializer.toJson<String?>(accountId),
      'toAccountId': serializer.toJson<String?>(toAccountId),
      'payee': serializer.toJson<String?>(payee),
      'projectId': serializer.toJson<String?>(projectId),
      'note': serializer.toJson<String>(note),
      'frequency': serializer.toJson<String>(frequency),
      'interval': serializer.toJson<int>(interval),
      'dayOfMonth': serializer.toJson<int?>(dayOfMonth),
      'weekday': serializer.toJson<int?>(weekday),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'maxCount': serializer.toJson<int?>(maxCount),
      'postedCount': serializer.toJson<int>(postedCount),
      'skippedCount': serializer.toJson<int>(skippedCount),
      'nextDue': serializer.toJson<DateTime?>(nextDue),
      'autoPost': serializer.toJson<bool>(autoPost),
      'remindDaysBefore': serializer.toJson<String>(remindDaysBefore),
      'isSubscription': serializer.toJson<bool>(isSubscription),
      'groupId': serializer.toJson<String?>(groupId),
      'groupSplit': serializer.toJson<String?>(groupSplit),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  RecurringRule copyWith({
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? id,
    String? name,
    String? kind,
    int? amountMinor,
    String? currency,
    Value<String?> categoryId = const Value.absent(),
    Value<String?> accountId = const Value.absent(),
    Value<String?> toAccountId = const Value.absent(),
    Value<String?> payee = const Value.absent(),
    Value<String?> projectId = const Value.absent(),
    String? note,
    String? frequency,
    int? interval,
    Value<int?> dayOfMonth = const Value.absent(),
    Value<int?> weekday = const Value.absent(),
    DateTime? startDate,
    Value<DateTime?> endDate = const Value.absent(),
    Value<int?> maxCount = const Value.absent(),
    int? postedCount,
    int? skippedCount,
    Value<DateTime?> nextDue = const Value.absent(),
    bool? autoPost,
    String? remindDaysBefore,
    bool? isSubscription,
    Value<String?> groupId = const Value.absent(),
    Value<String?> groupSplit = const Value.absent(),
    String? status,
    DateTime? createdAt,
  }) => RecurringRule(
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    amountMinor: amountMinor ?? this.amountMinor,
    currency: currency ?? this.currency,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    accountId: accountId.present ? accountId.value : this.accountId,
    toAccountId: toAccountId.present ? toAccountId.value : this.toAccountId,
    payee: payee.present ? payee.value : this.payee,
    projectId: projectId.present ? projectId.value : this.projectId,
    note: note ?? this.note,
    frequency: frequency ?? this.frequency,
    interval: interval ?? this.interval,
    dayOfMonth: dayOfMonth.present ? dayOfMonth.value : this.dayOfMonth,
    weekday: weekday.present ? weekday.value : this.weekday,
    startDate: startDate ?? this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    maxCount: maxCount.present ? maxCount.value : this.maxCount,
    postedCount: postedCount ?? this.postedCount,
    skippedCount: skippedCount ?? this.skippedCount,
    nextDue: nextDue.present ? nextDue.value : this.nextDue,
    autoPost: autoPost ?? this.autoPost,
    remindDaysBefore: remindDaysBefore ?? this.remindDaysBefore,
    isSubscription: isSubscription ?? this.isSubscription,
    groupId: groupId.present ? groupId.value : this.groupId,
    groupSplit: groupSplit.present ? groupSplit.value : this.groupSplit,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
  );
  RecurringRule copyWithCompanion(RecurringRulesCompanion data) {
    return RecurringRule(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      currency: data.currency.present ? data.currency.value : this.currency,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      toAccountId: data.toAccountId.present
          ? data.toAccountId.value
          : this.toAccountId,
      payee: data.payee.present ? data.payee.value : this.payee,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      note: data.note.present ? data.note.value : this.note,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      interval: data.interval.present ? data.interval.value : this.interval,
      dayOfMonth: data.dayOfMonth.present
          ? data.dayOfMonth.value
          : this.dayOfMonth,
      weekday: data.weekday.present ? data.weekday.value : this.weekday,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      maxCount: data.maxCount.present ? data.maxCount.value : this.maxCount,
      postedCount: data.postedCount.present
          ? data.postedCount.value
          : this.postedCount,
      skippedCount: data.skippedCount.present
          ? data.skippedCount.value
          : this.skippedCount,
      nextDue: data.nextDue.present ? data.nextDue.value : this.nextDue,
      autoPost: data.autoPost.present ? data.autoPost.value : this.autoPost,
      remindDaysBefore: data.remindDaysBefore.present
          ? data.remindDaysBefore.value
          : this.remindDaysBefore,
      isSubscription: data.isSubscription.present
          ? data.isSubscription.value
          : this.isSubscription,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      groupSplit: data.groupSplit.present
          ? data.groupSplit.value
          : this.groupSplit,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurringRule(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('payee: $payee, ')
          ..write('projectId: $projectId, ')
          ..write('note: $note, ')
          ..write('frequency: $frequency, ')
          ..write('interval: $interval, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('weekday: $weekday, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('maxCount: $maxCount, ')
          ..write('postedCount: $postedCount, ')
          ..write('skippedCount: $skippedCount, ')
          ..write('nextDue: $nextDue, ')
          ..write('autoPost: $autoPost, ')
          ..write('remindDaysBefore: $remindDaysBefore, ')
          ..write('isSubscription: $isSubscription, ')
          ..write('groupId: $groupId, ')
          ..write('groupSplit: $groupSplit, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    updatedAt,
    deletedAt,
    id,
    name,
    kind,
    amountMinor,
    currency,
    categoryId,
    accountId,
    toAccountId,
    payee,
    projectId,
    note,
    frequency,
    interval,
    dayOfMonth,
    weekday,
    startDate,
    endDate,
    maxCount,
    postedCount,
    skippedCount,
    nextDue,
    autoPost,
    remindDaysBefore,
    isSubscription,
    groupId,
    groupSplit,
    status,
    createdAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurringRule &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.amountMinor == this.amountMinor &&
          other.currency == this.currency &&
          other.categoryId == this.categoryId &&
          other.accountId == this.accountId &&
          other.toAccountId == this.toAccountId &&
          other.payee == this.payee &&
          other.projectId == this.projectId &&
          other.note == this.note &&
          other.frequency == this.frequency &&
          other.interval == this.interval &&
          other.dayOfMonth == this.dayOfMonth &&
          other.weekday == this.weekday &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.maxCount == this.maxCount &&
          other.postedCount == this.postedCount &&
          other.skippedCount == this.skippedCount &&
          other.nextDue == this.nextDue &&
          other.autoPost == this.autoPost &&
          other.remindDaysBefore == this.remindDaysBefore &&
          other.isSubscription == this.isSubscription &&
          other.groupId == this.groupId &&
          other.groupSplit == this.groupSplit &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class RecurringRulesCompanion extends UpdateCompanion<RecurringRule> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> id;
  final Value<String> name;
  final Value<String> kind;
  final Value<int> amountMinor;
  final Value<String> currency;
  final Value<String?> categoryId;
  final Value<String?> accountId;
  final Value<String?> toAccountId;
  final Value<String?> payee;
  final Value<String?> projectId;
  final Value<String> note;
  final Value<String> frequency;
  final Value<int> interval;
  final Value<int?> dayOfMonth;
  final Value<int?> weekday;
  final Value<DateTime> startDate;
  final Value<DateTime?> endDate;
  final Value<int?> maxCount;
  final Value<int> postedCount;
  final Value<int> skippedCount;
  final Value<DateTime?> nextDue;
  final Value<bool> autoPost;
  final Value<String> remindDaysBefore;
  final Value<bool> isSubscription;
  final Value<String?> groupId;
  final Value<String?> groupSplit;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const RecurringRulesCompanion({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.currency = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.toAccountId = const Value.absent(),
    this.payee = const Value.absent(),
    this.projectId = const Value.absent(),
    this.note = const Value.absent(),
    this.frequency = const Value.absent(),
    this.interval = const Value.absent(),
    this.dayOfMonth = const Value.absent(),
    this.weekday = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.maxCount = const Value.absent(),
    this.postedCount = const Value.absent(),
    this.skippedCount = const Value.absent(),
    this.nextDue = const Value.absent(),
    this.autoPost = const Value.absent(),
    this.remindDaysBefore = const Value.absent(),
    this.isSubscription = const Value.absent(),
    this.groupId = const Value.absent(),
    this.groupSplit = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecurringRulesCompanion.insert({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String id,
    this.name = const Value.absent(),
    required String kind,
    required int amountMinor,
    this.currency = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.toAccountId = const Value.absent(),
    this.payee = const Value.absent(),
    this.projectId = const Value.absent(),
    this.note = const Value.absent(),
    required String frequency,
    this.interval = const Value.absent(),
    this.dayOfMonth = const Value.absent(),
    this.weekday = const Value.absent(),
    required DateTime startDate,
    this.endDate = const Value.absent(),
    this.maxCount = const Value.absent(),
    this.postedCount = const Value.absent(),
    this.skippedCount = const Value.absent(),
    this.nextDue = const Value.absent(),
    this.autoPost = const Value.absent(),
    this.remindDaysBefore = const Value.absent(),
    this.isSubscription = const Value.absent(),
    this.groupId = const Value.absent(),
    this.groupSplit = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       amountMinor = Value(amountMinor),
       frequency = Value(frequency),
       startDate = Value(startDate);
  static Insertable<RecurringRule> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<int>? amountMinor,
    Expression<String>? currency,
    Expression<String>? categoryId,
    Expression<String>? accountId,
    Expression<String>? toAccountId,
    Expression<String>? payee,
    Expression<String>? projectId,
    Expression<String>? note,
    Expression<String>? frequency,
    Expression<int>? interval,
    Expression<int>? dayOfMonth,
    Expression<int>? weekday,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<int>? maxCount,
    Expression<int>? postedCount,
    Expression<int>? skippedCount,
    Expression<DateTime>? nextDue,
    Expression<bool>? autoPost,
    Expression<String>? remindDaysBefore,
    Expression<bool>? isSubscription,
    Expression<String>? groupId,
    Expression<String>? groupSplit,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (currency != null) 'currency': currency,
      if (categoryId != null) 'category_id': categoryId,
      if (accountId != null) 'account_id': accountId,
      if (toAccountId != null) 'to_account_id': toAccountId,
      if (payee != null) 'payee': payee,
      if (projectId != null) 'project_id': projectId,
      if (note != null) 'note': note,
      if (frequency != null) 'frequency': frequency,
      if (interval != null) 'interval': interval,
      if (dayOfMonth != null) 'day_of_month': dayOfMonth,
      if (weekday != null) 'weekday': weekday,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (maxCount != null) 'max_count': maxCount,
      if (postedCount != null) 'posted_count': postedCount,
      if (skippedCount != null) 'skipped_count': skippedCount,
      if (nextDue != null) 'next_due': nextDue,
      if (autoPost != null) 'auto_post': autoPost,
      if (remindDaysBefore != null) 'remind_days_before': remindDaysBefore,
      if (isSubscription != null) 'is_subscription': isSubscription,
      if (groupId != null) 'group_id': groupId,
      if (groupSplit != null) 'group_split': groupSplit,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecurringRulesCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? id,
    Value<String>? name,
    Value<String>? kind,
    Value<int>? amountMinor,
    Value<String>? currency,
    Value<String?>? categoryId,
    Value<String?>? accountId,
    Value<String?>? toAccountId,
    Value<String?>? payee,
    Value<String?>? projectId,
    Value<String>? note,
    Value<String>? frequency,
    Value<int>? interval,
    Value<int?>? dayOfMonth,
    Value<int?>? weekday,
    Value<DateTime>? startDate,
    Value<DateTime?>? endDate,
    Value<int?>? maxCount,
    Value<int>? postedCount,
    Value<int>? skippedCount,
    Value<DateTime?>? nextDue,
    Value<bool>? autoPost,
    Value<String>? remindDaysBefore,
    Value<bool>? isSubscription,
    Value<String?>? groupId,
    Value<String?>? groupSplit,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return RecurringRulesCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      amountMinor: amountMinor ?? this.amountMinor,
      currency: currency ?? this.currency,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      payee: payee ?? this.payee,
      projectId: projectId ?? this.projectId,
      note: note ?? this.note,
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      weekday: weekday ?? this.weekday,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      maxCount: maxCount ?? this.maxCount,
      postedCount: postedCount ?? this.postedCount,
      skippedCount: skippedCount ?? this.skippedCount,
      nextDue: nextDue ?? this.nextDue,
      autoPost: autoPost ?? this.autoPost,
      remindDaysBefore: remindDaysBefore ?? this.remindDaysBefore,
      isSubscription: isSubscription ?? this.isSubscription,
      groupId: groupId ?? this.groupId,
      groupSplit: groupSplit ?? this.groupSplit,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (toAccountId.present) {
      map['to_account_id'] = Variable<String>(toAccountId.value);
    }
    if (payee.present) {
      map['payee'] = Variable<String>(payee.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (interval.present) {
      map['interval'] = Variable<int>(interval.value);
    }
    if (dayOfMonth.present) {
      map['day_of_month'] = Variable<int>(dayOfMonth.value);
    }
    if (weekday.present) {
      map['weekday'] = Variable<int>(weekday.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (maxCount.present) {
      map['max_count'] = Variable<int>(maxCount.value);
    }
    if (postedCount.present) {
      map['posted_count'] = Variable<int>(postedCount.value);
    }
    if (skippedCount.present) {
      map['skipped_count'] = Variable<int>(skippedCount.value);
    }
    if (nextDue.present) {
      map['next_due'] = Variable<DateTime>(nextDue.value);
    }
    if (autoPost.present) {
      map['auto_post'] = Variable<bool>(autoPost.value);
    }
    if (remindDaysBefore.present) {
      map['remind_days_before'] = Variable<String>(remindDaysBefore.value);
    }
    if (isSubscription.present) {
      map['is_subscription'] = Variable<bool>(isSubscription.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (groupSplit.present) {
      map['group_split'] = Variable<String>(groupSplit.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
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
    return (StringBuffer('RecurringRulesCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('payee: $payee, ')
          ..write('projectId: $projectId, ')
          ..write('note: $note, ')
          ..write('frequency: $frequency, ')
          ..write('interval: $interval, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('weekday: $weekday, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('maxCount: $maxCount, ')
          ..write('postedCount: $postedCount, ')
          ..write('skippedCount: $skippedCount, ')
          ..write('nextDue: $nextDue, ')
          ..write('autoPost: $autoPost, ')
          ..write('remindDaysBefore: $remindDaysBefore, ')
          ..write('isSubscription: $isSubscription, ')
          ..write('groupId: $groupId, ')
          ..write('groupSplit: $groupSplit, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GroupActivitiesTable extends GroupActivities
    with TableInfo<$GroupActivitiesTable, GroupActivity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupActivitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectKindMeta = const VerificationMeta(
    'subjectKind',
  );
  @override
  late final GeneratedColumn<String> subjectKind = GeneratedColumn<String>(
    'subject_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectIdMeta = const VerificationMeta(
    'subjectId',
  );
  @override
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
    'subject_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actorMemberIdMeta = const VerificationMeta(
    'actorMemberId',
  );
  @override
  late final GeneratedColumn<String> actorMemberId = GeneratedColumn<String>(
    'actor_member_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _beforeJsonMeta = const VerificationMeta(
    'beforeJson',
  );
  @override
  late final GeneratedColumn<String> beforeJson = GeneratedColumn<String>(
    'before_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _afterJsonMeta = const VerificationMeta(
    'afterJson',
  );
  @override
  late final GeneratedColumn<String> afterJson = GeneratedColumn<String>(
    'after_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    deletedAt,
    id,
    groupId,
    action,
    subjectKind,
    subjectId,
    actorMemberId,
    occurredAt,
    beforeJson,
    afterJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'group_activities';
  @override
  VerificationContext validateIntegrity(
    Insertable<GroupActivity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('subject_kind')) {
      context.handle(
        _subjectKindMeta,
        subjectKind.isAcceptableOrUnknown(
          data['subject_kind']!,
          _subjectKindMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subjectKindMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(
        _subjectIdMeta,
        subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('actor_member_id')) {
      context.handle(
        _actorMemberIdMeta,
        actorMemberId.isAcceptableOrUnknown(
          data['actor_member_id']!,
          _actorMemberIdMeta,
        ),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('before_json')) {
      context.handle(
        _beforeJsonMeta,
        beforeJson.isAcceptableOrUnknown(data['before_json']!, _beforeJsonMeta),
      );
    }
    if (data.containsKey('after_json')) {
      context.handle(
        _afterJsonMeta,
        afterJson.isAcceptableOrUnknown(data['after_json']!, _afterJsonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GroupActivity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupActivity(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      subjectKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_kind'],
      )!,
      subjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_id'],
      )!,
      actorMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_member_id'],
      ),
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      beforeJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}before_json'],
      ),
      afterJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}after_json'],
      ),
    );
  }

  @override
  $GroupActivitiesTable createAlias(String alias) {
    return $GroupActivitiesTable(attachedDatabase, alias);
  }
}

class GroupActivity extends DataClass implements Insertable<GroupActivity> {
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String id;
  final String groupId;

  /// added | edited | deleted | restored
  final String action;

  /// expense | payment
  final String subjectKind;

  /// The entry or settlement id.
  final String subjectId;

  /// The member who made the change; the device's own member until sync.
  final String? actorMemberId;
  final DateTime occurredAt;
  final String? beforeJson;
  final String? afterJson;
  const GroupActivity({
    required this.updatedAt,
    this.deletedAt,
    required this.id,
    required this.groupId,
    required this.action,
    required this.subjectKind,
    required this.subjectId,
    this.actorMemberId,
    required this.occurredAt,
    this.beforeJson,
    this.afterJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['action'] = Variable<String>(action);
    map['subject_kind'] = Variable<String>(subjectKind);
    map['subject_id'] = Variable<String>(subjectId);
    if (!nullToAbsent || actorMemberId != null) {
      map['actor_member_id'] = Variable<String>(actorMemberId);
    }
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    if (!nullToAbsent || beforeJson != null) {
      map['before_json'] = Variable<String>(beforeJson);
    }
    if (!nullToAbsent || afterJson != null) {
      map['after_json'] = Variable<String>(afterJson);
    }
    return map;
  }

  GroupActivitiesCompanion toCompanion(bool nullToAbsent) {
    return GroupActivitiesCompanion(
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      groupId: Value(groupId),
      action: Value(action),
      subjectKind: Value(subjectKind),
      subjectId: Value(subjectId),
      actorMemberId: actorMemberId == null && nullToAbsent
          ? const Value.absent()
          : Value(actorMemberId),
      occurredAt: Value(occurredAt),
      beforeJson: beforeJson == null && nullToAbsent
          ? const Value.absent()
          : Value(beforeJson),
      afterJson: afterJson == null && nullToAbsent
          ? const Value.absent()
          : Value(afterJson),
    );
  }

  factory GroupActivity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupActivity(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      action: serializer.fromJson<String>(json['action']),
      subjectKind: serializer.fromJson<String>(json['subjectKind']),
      subjectId: serializer.fromJson<String>(json['subjectId']),
      actorMemberId: serializer.fromJson<String?>(json['actorMemberId']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      beforeJson: serializer.fromJson<String?>(json['beforeJson']),
      afterJson: serializer.fromJson<String?>(json['afterJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'action': serializer.toJson<String>(action),
      'subjectKind': serializer.toJson<String>(subjectKind),
      'subjectId': serializer.toJson<String>(subjectId),
      'actorMemberId': serializer.toJson<String?>(actorMemberId),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'beforeJson': serializer.toJson<String?>(beforeJson),
      'afterJson': serializer.toJson<String?>(afterJson),
    };
  }

  GroupActivity copyWith({
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? id,
    String? groupId,
    String? action,
    String? subjectKind,
    String? subjectId,
    Value<String?> actorMemberId = const Value.absent(),
    DateTime? occurredAt,
    Value<String?> beforeJson = const Value.absent(),
    Value<String?> afterJson = const Value.absent(),
  }) => GroupActivity(
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    action: action ?? this.action,
    subjectKind: subjectKind ?? this.subjectKind,
    subjectId: subjectId ?? this.subjectId,
    actorMemberId: actorMemberId.present
        ? actorMemberId.value
        : this.actorMemberId,
    occurredAt: occurredAt ?? this.occurredAt,
    beforeJson: beforeJson.present ? beforeJson.value : this.beforeJson,
    afterJson: afterJson.present ? afterJson.value : this.afterJson,
  );
  GroupActivity copyWithCompanion(GroupActivitiesCompanion data) {
    return GroupActivity(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      action: data.action.present ? data.action.value : this.action,
      subjectKind: data.subjectKind.present
          ? data.subjectKind.value
          : this.subjectKind,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      actorMemberId: data.actorMemberId.present
          ? data.actorMemberId.value
          : this.actorMemberId,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      beforeJson: data.beforeJson.present
          ? data.beforeJson.value
          : this.beforeJson,
      afterJson: data.afterJson.present ? data.afterJson.value : this.afterJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupActivity(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('action: $action, ')
          ..write('subjectKind: $subjectKind, ')
          ..write('subjectId: $subjectId, ')
          ..write('actorMemberId: $actorMemberId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('beforeJson: $beforeJson, ')
          ..write('afterJson: $afterJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    updatedAt,
    deletedAt,
    id,
    groupId,
    action,
    subjectKind,
    subjectId,
    actorMemberId,
    occurredAt,
    beforeJson,
    afterJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupActivity &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.action == this.action &&
          other.subjectKind == this.subjectKind &&
          other.subjectId == this.subjectId &&
          other.actorMemberId == this.actorMemberId &&
          other.occurredAt == this.occurredAt &&
          other.beforeJson == this.beforeJson &&
          other.afterJson == this.afterJson);
}

class GroupActivitiesCompanion extends UpdateCompanion<GroupActivity> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> action;
  final Value<String> subjectKind;
  final Value<String> subjectId;
  final Value<String?> actorMemberId;
  final Value<DateTime> occurredAt;
  final Value<String?> beforeJson;
  final Value<String?> afterJson;
  final Value<int> rowid;
  const GroupActivitiesCompanion({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.action = const Value.absent(),
    this.subjectKind = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.actorMemberId = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.beforeJson = const Value.absent(),
    this.afterJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupActivitiesCompanion.insert({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String id,
    required String groupId,
    required String action,
    required String subjectKind,
    required String subjectId,
    this.actorMemberId = const Value.absent(),
    required DateTime occurredAt,
    this.beforeJson = const Value.absent(),
    this.afterJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       action = Value(action),
       subjectKind = Value(subjectKind),
       subjectId = Value(subjectId),
       occurredAt = Value(occurredAt);
  static Insertable<GroupActivity> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? action,
    Expression<String>? subjectKind,
    Expression<String>? subjectId,
    Expression<String>? actorMemberId,
    Expression<DateTime>? occurredAt,
    Expression<String>? beforeJson,
    Expression<String>? afterJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (action != null) 'action': action,
      if (subjectKind != null) 'subject_kind': subjectKind,
      if (subjectId != null) 'subject_id': subjectId,
      if (actorMemberId != null) 'actor_member_id': actorMemberId,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (beforeJson != null) 'before_json': beforeJson,
      if (afterJson != null) 'after_json': afterJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupActivitiesCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? id,
    Value<String>? groupId,
    Value<String>? action,
    Value<String>? subjectKind,
    Value<String>? subjectId,
    Value<String?>? actorMemberId,
    Value<DateTime>? occurredAt,
    Value<String?>? beforeJson,
    Value<String?>? afterJson,
    Value<int>? rowid,
  }) {
    return GroupActivitiesCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      action: action ?? this.action,
      subjectKind: subjectKind ?? this.subjectKind,
      subjectId: subjectId ?? this.subjectId,
      actorMemberId: actorMemberId ?? this.actorMemberId,
      occurredAt: occurredAt ?? this.occurredAt,
      beforeJson: beforeJson ?? this.beforeJson,
      afterJson: afterJson ?? this.afterJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (subjectKind.present) {
      map['subject_kind'] = Variable<String>(subjectKind.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (actorMemberId.present) {
      map['actor_member_id'] = Variable<String>(actorMemberId.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (beforeJson.present) {
      map['before_json'] = Variable<String>(beforeJson.value);
    }
    if (afterJson.present) {
      map['after_json'] = Variable<String>(afterJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupActivitiesCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('action: $action, ')
          ..write('subjectKind: $subjectKind, ')
          ..write('subjectId: $subjectId, ')
          ..write('actorMemberId: $actorMemberId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('beforeJson: $beforeJson, ')
          ..write('afterJson: $afterJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItemAssignmentsTable extends ItemAssignments
    with TableInfo<$ItemAssignmentsTable, ItemAssignment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemAssignmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryItemIdMeta = const VerificationMeta(
    'entryItemId',
  );
  @override
  late final GeneratedColumn<String> entryItemId = GeneratedColumn<String>(
    'entry_item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    deletedAt,
    id,
    entryItemId,
    memberId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'item_assignments';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemAssignment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entry_item_id')) {
      context.handle(
        _entryItemIdMeta,
        entryItemId.isAcceptableOrUnknown(
          data['entry_item_id']!,
          _entryItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_entryItemIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {entryItemId, memberId},
  ];
  @override
  ItemAssignment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemAssignment(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entryItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_item_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
    );
  }

  @override
  $ItemAssignmentsTable createAlias(String alias) {
    return $ItemAssignmentsTable(attachedDatabase, alias);
  }
}

class ItemAssignment extends DataClass implements Insertable<ItemAssignment> {
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String id;
  final String entryItemId;
  final String memberId;
  const ItemAssignment({
    required this.updatedAt,
    this.deletedAt,
    required this.id,
    required this.entryItemId,
    required this.memberId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<String>(id);
    map['entry_item_id'] = Variable<String>(entryItemId);
    map['member_id'] = Variable<String>(memberId);
    return map;
  }

  ItemAssignmentsCompanion toCompanion(bool nullToAbsent) {
    return ItemAssignmentsCompanion(
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      entryItemId: Value(entryItemId),
      memberId: Value(memberId),
    );
  }

  factory ItemAssignment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemAssignment(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<String>(json['id']),
      entryItemId: serializer.fromJson<String>(json['entryItemId']),
      memberId: serializer.fromJson<String>(json['memberId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<String>(id),
      'entryItemId': serializer.toJson<String>(entryItemId),
      'memberId': serializer.toJson<String>(memberId),
    };
  }

  ItemAssignment copyWith({
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? id,
    String? entryItemId,
    String? memberId,
  }) => ItemAssignment(
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    entryItemId: entryItemId ?? this.entryItemId,
    memberId: memberId ?? this.memberId,
  );
  ItemAssignment copyWithCompanion(ItemAssignmentsCompanion data) {
    return ItemAssignment(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      entryItemId: data.entryItemId.present
          ? data.entryItemId.value
          : this.entryItemId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemAssignment(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('entryItemId: $entryItemId, ')
          ..write('memberId: $memberId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(updatedAt, deletedAt, id, entryItemId, memberId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemAssignment &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.entryItemId == this.entryItemId &&
          other.memberId == this.memberId);
}

class ItemAssignmentsCompanion extends UpdateCompanion<ItemAssignment> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> id;
  final Value<String> entryItemId;
  final Value<String> memberId;
  final Value<int> rowid;
  const ItemAssignmentsCompanion({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.entryItemId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemAssignmentsCompanion.insert({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String id,
    required String entryItemId,
    required String memberId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entryItemId = Value(entryItemId),
       memberId = Value(memberId);
  static Insertable<ItemAssignment> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? id,
    Expression<String>? entryItemId,
    Expression<String>? memberId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (entryItemId != null) 'entry_item_id': entryItemId,
      if (memberId != null) 'member_id': memberId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemAssignmentsCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? id,
    Value<String>? entryItemId,
    Value<String>? memberId,
    Value<int>? rowid,
  }) {
    return ItemAssignmentsCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      entryItemId: entryItemId ?? this.entryItemId,
      memberId: memberId ?? this.memberId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entryItemId.present) {
      map['entry_item_id'] = Variable<String>(entryItemId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemAssignmentsCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('entryItemId: $entryItemId, ')
          ..write('memberId: $memberId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PayeeCategoriesTable extends PayeeCategories
    with TableInfo<$PayeeCategoriesTable, PayeeCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PayeeCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payeeMeta = const VerificationMeta('payee');
  @override
  late final GeneratedColumn<String> payee = GeneratedColumn<String>(
    'payee',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    deletedAt,
    id,
    payee,
    categoryId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payee_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<PayeeCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('payee')) {
      context.handle(
        _payeeMeta,
        payee.isAcceptableOrUnknown(data['payee']!, _payeeMeta),
      );
    } else if (isInserting) {
      context.missing(_payeeMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PayeeCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PayeeCategory(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      payee: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payee'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
    );
  }

  @override
  $PayeeCategoriesTable createAlias(String alias) {
    return $PayeeCategoriesTable(attachedDatabase, alias);
  }
}

class PayeeCategory extends DataClass implements Insertable<PayeeCategory> {
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String id;

  /// Readable payee for the Settings list ("Rahul Sharma", "Swiggy").
  final String payee;
  final String categoryId;
  const PayeeCategory({
    required this.updatedAt,
    this.deletedAt,
    required this.id,
    required this.payee,
    required this.categoryId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<String>(id);
    map['payee'] = Variable<String>(payee);
    map['category_id'] = Variable<String>(categoryId);
    return map;
  }

  PayeeCategoriesCompanion toCompanion(bool nullToAbsent) {
    return PayeeCategoriesCompanion(
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      payee: Value(payee),
      categoryId: Value(categoryId),
    );
  }

  factory PayeeCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PayeeCategory(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<String>(json['id']),
      payee: serializer.fromJson<String>(json['payee']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<String>(id),
      'payee': serializer.toJson<String>(payee),
      'categoryId': serializer.toJson<String>(categoryId),
    };
  }

  PayeeCategory copyWith({
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? id,
    String? payee,
    String? categoryId,
  }) => PayeeCategory(
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    payee: payee ?? this.payee,
    categoryId: categoryId ?? this.categoryId,
  );
  PayeeCategory copyWithCompanion(PayeeCategoriesCompanion data) {
    return PayeeCategory(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      payee: data.payee.present ? data.payee.value : this.payee,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PayeeCategory(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('payee: $payee, ')
          ..write('categoryId: $categoryId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(updatedAt, deletedAt, id, payee, categoryId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PayeeCategory &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.payee == this.payee &&
          other.categoryId == this.categoryId);
}

class PayeeCategoriesCompanion extends UpdateCompanion<PayeeCategory> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> id;
  final Value<String> payee;
  final Value<String> categoryId;
  final Value<int> rowid;
  const PayeeCategoriesCompanion({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.payee = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PayeeCategoriesCompanion.insert({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String id,
    required String payee,
    required String categoryId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       payee = Value(payee),
       categoryId = Value(categoryId);
  static Insertable<PayeeCategory> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? id,
    Expression<String>? payee,
    Expression<String>? categoryId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (payee != null) 'payee': payee,
      if (categoryId != null) 'category_id': categoryId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PayeeCategoriesCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? id,
    Value<String>? payee,
    Value<String>? categoryId,
    Value<int>? rowid,
  }) {
    return PayeeCategoriesCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      payee: payee ?? this.payee,
      categoryId: categoryId ?? this.categoryId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (payee.present) {
      map['payee'] = Variable<String>(payee.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PayeeCategoriesCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('payee: $payee, ')
          ..write('categoryId: $categoryId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PeopleTable extends People with TableInfo<$PeopleTable, Person> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeopleTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
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
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [updatedAt, deletedAt, id, name, email];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'people';
  @override
  VerificationContext validateIntegrity(
    Insertable<Person> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
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
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Person map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Person(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
    );
  }

  @override
  $PeopleTable createAlias(String alias) {
    return $PeopleTable(attachedDatabase, alias);
  }
}

class Person extends DataClass implements Insertable<Person> {
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String id;
  final String name;
  final String email;
  const Person({
    required this.updatedAt,
    this.deletedAt,
    required this.id,
    required this.name,
    required this.email,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['email'] = Variable<String>(email);
    return map;
  }

  PeopleCompanion toCompanion(bool nullToAbsent) {
    return PeopleCompanion(
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      name: Value(name),
      email: Value(email),
    );
  }

  factory Person.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Person(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String>(json['email']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String>(email),
    };
  }

  Person copyWith({
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? id,
    String? name,
    String? email,
  }) => Person(
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
  );
  Person copyWithCompanion(PeopleCompanion data) {
    return Person(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Person(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(updatedAt, deletedAt, id, name, email);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Person &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.name == this.name &&
          other.email == this.email);
}

class PeopleCompanion extends UpdateCompanion<Person> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> id;
  final Value<String> name;
  final Value<String> email;
  final Value<int> rowid;
  const PeopleCompanion({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PeopleCompanion.insert({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String id,
    required String name,
    required String email,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       email = Value(email);
  static Insertable<Person> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? email,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PeopleCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? id,
    Value<String>? name,
    Value<String>? email,
    Value<int>? rowid,
  }) {
    return PeopleCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeopleCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuickEntriesTable extends QuickEntries
    with TableInfo<$QuickEntriesTable, QuickEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuickEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('expense'),
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payeeMeta = const VerificationMeta('payee');
  @override
  late final GeneratedColumn<String> payee = GeneratedColumn<String>(
    'payee',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    deletedAt,
    id,
    label,
    kind,
    amountMinor,
    categoryId,
    accountId,
    payee,
    note,
    tags,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quick_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuickEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('payee')) {
      context.handle(
        _payeeMeta,
        payee.isAcceptableOrUnknown(data['payee']!, _payeeMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuickEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuickEntry(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      payee: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payee'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $QuickEntriesTable createAlias(String alias) {
    return $QuickEntriesTable(attachedDatabase, alias);
  }
}

class QuickEntry extends DataClass implements Insertable<QuickEntry> {
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String id;
  final String label;
  final String kind;
  final int? amountMinor;
  final String? categoryId;
  final String? accountId;
  final String? payee;
  final String note;
  final String tags;
  final int sortOrder;
  const QuickEntry({
    required this.updatedAt,
    this.deletedAt,
    required this.id,
    required this.label,
    required this.kind,
    this.amountMinor,
    this.categoryId,
    this.accountId,
    this.payee,
    required this.note,
    required this.tags,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<String>(id);
    map['label'] = Variable<String>(label);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || amountMinor != null) {
      map['amount_minor'] = Variable<int>(amountMinor);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    if (!nullToAbsent || payee != null) {
      map['payee'] = Variable<String>(payee);
    }
    map['note'] = Variable<String>(note);
    map['tags'] = Variable<String>(tags);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  QuickEntriesCompanion toCompanion(bool nullToAbsent) {
    return QuickEntriesCompanion(
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      label: Value(label),
      kind: Value(kind),
      amountMinor: amountMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(amountMinor),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      payee: payee == null && nullToAbsent
          ? const Value.absent()
          : Value(payee),
      note: Value(note),
      tags: Value(tags),
      sortOrder: Value(sortOrder),
    );
  }

  factory QuickEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuickEntry(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<String>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      kind: serializer.fromJson<String>(json['kind']),
      amountMinor: serializer.fromJson<int?>(json['amountMinor']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      payee: serializer.fromJson<String?>(json['payee']),
      note: serializer.fromJson<String>(json['note']),
      tags: serializer.fromJson<String>(json['tags']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<String>(id),
      'label': serializer.toJson<String>(label),
      'kind': serializer.toJson<String>(kind),
      'amountMinor': serializer.toJson<int?>(amountMinor),
      'categoryId': serializer.toJson<String?>(categoryId),
      'accountId': serializer.toJson<String?>(accountId),
      'payee': serializer.toJson<String?>(payee),
      'note': serializer.toJson<String>(note),
      'tags': serializer.toJson<String>(tags),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  QuickEntry copyWith({
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? id,
    String? label,
    String? kind,
    Value<int?> amountMinor = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    Value<String?> accountId = const Value.absent(),
    Value<String?> payee = const Value.absent(),
    String? note,
    String? tags,
    int? sortOrder,
  }) => QuickEntry(
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    label: label ?? this.label,
    kind: kind ?? this.kind,
    amountMinor: amountMinor.present ? amountMinor.value : this.amountMinor,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    accountId: accountId.present ? accountId.value : this.accountId,
    payee: payee.present ? payee.value : this.payee,
    note: note ?? this.note,
    tags: tags ?? this.tags,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  QuickEntry copyWithCompanion(QuickEntriesCompanion data) {
    return QuickEntry(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      kind: data.kind.present ? data.kind.value : this.kind,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      payee: data.payee.present ? data.payee.value : this.payee,
      note: data.note.present ? data.note.value : this.note,
      tags: data.tags.present ? data.tags.value : this.tags,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuickEntry(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('kind: $kind, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('payee: $payee, ')
          ..write('note: $note, ')
          ..write('tags: $tags, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    updatedAt,
    deletedAt,
    id,
    label,
    kind,
    amountMinor,
    categoryId,
    accountId,
    payee,
    note,
    tags,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuickEntry &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.label == this.label &&
          other.kind == this.kind &&
          other.amountMinor == this.amountMinor &&
          other.categoryId == this.categoryId &&
          other.accountId == this.accountId &&
          other.payee == this.payee &&
          other.note == this.note &&
          other.tags == this.tags &&
          other.sortOrder == this.sortOrder);
}

class QuickEntriesCompanion extends UpdateCompanion<QuickEntry> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> id;
  final Value<String> label;
  final Value<String> kind;
  final Value<int?> amountMinor;
  final Value<String?> categoryId;
  final Value<String?> accountId;
  final Value<String?> payee;
  final Value<String> note;
  final Value<String> tags;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const QuickEntriesCompanion({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.kind = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.payee = const Value.absent(),
    this.note = const Value.absent(),
    this.tags = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuickEntriesCompanion.insert({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String id,
    required String label,
    this.kind = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.payee = const Value.absent(),
    this.note = const Value.absent(),
    this.tags = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       label = Value(label);
  static Insertable<QuickEntry> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? id,
    Expression<String>? label,
    Expression<String>? kind,
    Expression<int>? amountMinor,
    Expression<String>? categoryId,
    Expression<String>? accountId,
    Expression<String>? payee,
    Expression<String>? note,
    Expression<String>? tags,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (kind != null) 'kind': kind,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (categoryId != null) 'category_id': categoryId,
      if (accountId != null) 'account_id': accountId,
      if (payee != null) 'payee': payee,
      if (note != null) 'note': note,
      if (tags != null) 'tags': tags,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuickEntriesCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? id,
    Value<String>? label,
    Value<String>? kind,
    Value<int?>? amountMinor,
    Value<String?>? categoryId,
    Value<String?>? accountId,
    Value<String?>? payee,
    Value<String>? note,
    Value<String>? tags,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return QuickEntriesCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      label: label ?? this.label,
      kind: kind ?? this.kind,
      amountMinor: amountMinor ?? this.amountMinor,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      payee: payee ?? this.payee,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (payee.present) {
      map['payee'] = Variable<String>(payee.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuickEntriesCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('kind: $kind, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('payee: $payee, ')
          ..write('note: $note, ')
          ..write('tags: $tags, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $EntriesTable entries = $EntriesTable(this);
  late final $EntryItemsTable entryItems = $EntryItemsTable(this);
  late final $GroupsTable groups = $GroupsTable(this);
  late final $MembersTable members = $MembersTable(this);
  late final $SplitsTable splits = $SplitsTable(this);
  late final $SettlementsTable settlements = $SettlementsTable(this);
  late final $BudgetsTable budgets = $BudgetsTable(this);
  late final $SmsLogTable smsLog = $SmsLogTable(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $ProjectFieldsTable projectFields = $ProjectFieldsTable(this);
  late final $EntryFieldValuesTable entryFieldValues = $EntryFieldValuesTable(
    this,
  );
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $EntryPayersTable entryPayers = $EntryPayersTable(this);
  late final $RecurringRulesTable recurringRules = $RecurringRulesTable(this);
  late final $GroupActivitiesTable groupActivities = $GroupActivitiesTable(
    this,
  );
  late final $ItemAssignmentsTable itemAssignments = $ItemAssignmentsTable(
    this,
  );
  late final $PayeeCategoriesTable payeeCategories = $PayeeCategoriesTable(
    this,
  );
  late final $PeopleTable people = $PeopleTable(this);
  late final $QuickEntriesTable quickEntries = $QuickEntriesTable(this);
  late final Index entriesProjectId = Index(
    'entries_project_id',
    'CREATE INDEX entries_project_id ON entries (project_id)',
  );
  late final Index entriesRecurringId = Index(
    'entries_recurring_id',
    'CREATE INDEX entries_recurring_id ON entries (recurring_id)',
  );
  late final Index smsLogTransactionKey = Index(
    'sms_log_transaction_key',
    'CREATE INDEX sms_log_transaction_key ON sms_log (transaction_key)',
  );
  late final Index projectFieldsProjectId = Index(
    'project_fields_project_id',
    'CREATE INDEX project_fields_project_id ON project_fields (project_id)',
  );
  late final Index entryFieldValuesEntryId = Index(
    'entry_field_values_entry_id',
    'CREATE INDEX entry_field_values_entry_id ON entry_field_values (entry_id)',
  );
  late final Index remindersGroupId = Index(
    'reminders_group_id',
    'CREATE INDEX reminders_group_id ON reminders (group_id)',
  );
  late final Index remindersStatusDue = Index(
    'reminders_status_due',
    'CREATE INDEX reminders_status_due ON reminders (status, due_at)',
  );
  late final Index remindersProjectId = Index(
    'reminders_project_id',
    'CREATE INDEX reminders_project_id ON reminders (project_id)',
  );
  late final Index entryPayersEntryId = Index(
    'entry_payers_entry_id',
    'CREATE INDEX entry_payers_entry_id ON entry_payers (entry_id)',
  );
  late final Index groupActivitiesGroupId = Index(
    'group_activities_group_id',
    'CREATE INDEX group_activities_group_id ON group_activities (group_id)',
  );
  late final Index itemAssignmentsEntryItemId = Index(
    'item_assignments_entry_item_id',
    'CREATE INDEX item_assignments_entry_item_id ON item_assignments (entry_item_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    accounts,
    categories,
    entries,
    entryItems,
    groups,
    members,
    splits,
    settlements,
    budgets,
    smsLog,
    projects,
    projectFields,
    entryFieldValues,
    reminders,
    entryPayers,
    recurringRules,
    groupActivities,
    itemAssignments,
    payeeCategories,
    people,
    quickEntries,
    entriesProjectId,
    entriesRecurringId,
    smsLogTransactionKey,
    projectFieldsProjectId,
    entryFieldValuesEntryId,
    remindersGroupId,
    remindersStatusDue,
    remindersProjectId,
    entryPayersEntryId,
    groupActivitiesGroupId,
    itemAssignmentsEntryItemId,
  ];
}

typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required String id,
  required String name,
  required String type,
  Value<String?> bankName,
  Value<String?> last4,
  Value<String?> smsKey,
  Value<int> balanceMinor,
  Value<DateTime?> balanceAsOf,
  Value<bool> includeInTotal,
  required int color,
  Value<int> sortOrder,
  Value<int?> statementDay,
  Value<int?> dueDay,
  Value<int?> creditLimitMinor,
  Value<int?> lastStatementMinor,
  Value<DateTime?> lastStatementAt,
  Value<int> rowid,
});
typedef $$AccountsTableUpdateCompanionBuilder = AccountsCompanion Function({
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> id,
  Value<String> name,
  Value<String> type,
  Value<String?> bankName,
  Value<String?> last4,
  Value<String?> smsKey,
  Value<int> balanceMinor,
  Value<DateTime?> balanceAsOf,
  Value<bool> includeInTotal,
  Value<int> color,
  Value<int> sortOrder,
  Value<int?> statementDay,
  Value<int?> dueDay,
  Value<int?> creditLimitMinor,
  Value<int?> lastStatementMinor,
  Value<DateTime?> lastStatementAt,
  Value<int> rowid,
});

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankName => $composableBuilder(
    column: $table.bankName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get last4 => $composableBuilder(
    column: $table.last4,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get smsKey => $composableBuilder(
    column: $table.smsKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get balanceMinor => $composableBuilder(
    column: $table.balanceMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get balanceAsOf => $composableBuilder(
    column: $table.balanceAsOf,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get includeInTotal => $composableBuilder(
    column: $table.includeInTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get statementDay => $composableBuilder(
    column: $table.statementDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueDay => $composableBuilder(
    column: $table.dueDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get creditLimitMinor => $composableBuilder(
    column: $table.creditLimitMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastStatementMinor => $composableBuilder(
    column: $table.lastStatementMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastStatementAt => $composableBuilder(
    column: $table.lastStatementAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankName => $composableBuilder(
    column: $table.bankName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get last4 => $composableBuilder(
    column: $table.last4,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get smsKey => $composableBuilder(
    column: $table.smsKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get balanceMinor => $composableBuilder(
    column: $table.balanceMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get balanceAsOf => $composableBuilder(
    column: $table.balanceAsOf,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get includeInTotal => $composableBuilder(
    column: $table.includeInTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get statementDay => $composableBuilder(
    column: $table.statementDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueDay => $composableBuilder(
    column: $table.dueDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get creditLimitMinor => $composableBuilder(
    column: $table.creditLimitMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastStatementMinor => $composableBuilder(
    column: $table.lastStatementMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastStatementAt => $composableBuilder(
    column: $table.lastStatementAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get bankName =>
      $composableBuilder(column: $table.bankName, builder: (column) => column);

  GeneratedColumn<String> get last4 =>
      $composableBuilder(column: $table.last4, builder: (column) => column);

  GeneratedColumn<String> get smsKey =>
      $composableBuilder(column: $table.smsKey, builder: (column) => column);

  GeneratedColumn<int> get balanceMinor => $composableBuilder(
    column: $table.balanceMinor,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get balanceAsOf => $composableBuilder(
    column: $table.balanceAsOf,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get includeInTotal => $composableBuilder(
    column: $table.includeInTotal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get statementDay => $composableBuilder(
    column: $table.statementDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dueDay =>
      $composableBuilder(column: $table.dueDay, builder: (column) => column);

  GeneratedColumn<int> get creditLimitMinor => $composableBuilder(
    column: $table.creditLimitMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastStatementMinor => $composableBuilder(
    column: $table.lastStatementMinor,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastStatementAt => $composableBuilder(
    column: $table.lastStatementAt,
    builder: (column) => column,
  );
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          Account,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (Account, BaseReferences<_$AppDatabase, $AccountsTable, Account>),
          Account,
          PrefetchHooks Function()
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> bankName = const Value.absent(),
                Value<String?> last4 = const Value.absent(),
                Value<String?> smsKey = const Value.absent(),
                Value<int> balanceMinor = const Value.absent(),
                Value<DateTime?> balanceAsOf = const Value.absent(),
                Value<bool> includeInTotal = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int?> statementDay = const Value.absent(),
                Value<int?> dueDay = const Value.absent(),
                Value<int?> creditLimitMinor = const Value.absent(),
                Value<int?> lastStatementMinor = const Value.absent(),
                Value<DateTime?> lastStatementAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                name: name,
                type: type,
                bankName: bankName,
                last4: last4,
                smsKey: smsKey,
                balanceMinor: balanceMinor,
                balanceAsOf: balanceAsOf,
                includeInTotal: includeInTotal,
                color: color,
                sortOrder: sortOrder,
                statementDay: statementDay,
                dueDay: dueDay,
                creditLimitMinor: creditLimitMinor,
                lastStatementMinor: lastStatementMinor,
                lastStatementAt: lastStatementAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String id,
                required String name,
                required String type,
                Value<String?> bankName = const Value.absent(),
                Value<String?> last4 = const Value.absent(),
                Value<String?> smsKey = const Value.absent(),
                Value<int> balanceMinor = const Value.absent(),
                Value<DateTime?> balanceAsOf = const Value.absent(),
                Value<bool> includeInTotal = const Value.absent(),
                required int color,
                Value<int> sortOrder = const Value.absent(),
                Value<int?> statementDay = const Value.absent(),
                Value<int?> dueDay = const Value.absent(),
                Value<int?> creditLimitMinor = const Value.absent(),
                Value<int?> lastStatementMinor = const Value.absent(),
                Value<DateTime?> lastStatementAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                name: name,
                type: type,
                bankName: bankName,
                last4: last4,
                smsKey: smsKey,
                balanceMinor: balanceMinor,
                balanceAsOf: balanceAsOf,
                includeInTotal: includeInTotal,
                color: color,
                sortOrder: sortOrder,
                statementDay: statementDay,
                dueDay: dueDay,
                creditLimitMinor: creditLimitMinor,
                lastStatementMinor: lastStatementMinor,
                lastStatementAt: lastStatementAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AccountsTable, Account>(table),
                  BaseReferences<_$AppDatabase, $AccountsTable, Account>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      Account,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (Account, BaseReferences<_$AppDatabase, $AccountsTable, Account>),
      Account,
      PrefetchHooks Function()
    >;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required String id,
  Value<String?> seedKey,
  required String name,
  required String icon,
  required int color,
  required String kind,
  Value<String?> parentId,
  Value<int> sortOrder,
  Value<bool> isArchived,
  Value<String> units,
  Value<String?> packKey,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> id,
  Value<String?> seedKey,
  Value<String> name,
  Value<String> icon,
  Value<int> color,
  Value<String> kind,
  Value<String?> parentId,
  Value<int> sortOrder,
  Value<bool> isArchived,
  Value<String> units,
  Value<String?> packKey,
  Value<int> rowid,
});

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seedKey => $composableBuilder(
    column: $table.seedKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get units => $composableBuilder(
    column: $table.units,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get packKey => $composableBuilder(
    column: $table.packKey,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seedKey => $composableBuilder(
    column: $table.seedKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get units => $composableBuilder(
    column: $table.units,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get packKey => $composableBuilder(
    column: $table.packKey,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get seedKey =>
      $composableBuilder(column: $table.seedKey, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<String> get units =>
      $composableBuilder(column: $table.units, builder: (column) => column);

  GeneratedColumn<String> get packKey =>
      $composableBuilder(column: $table.packKey, builder: (column) => column);
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
          Category,
          PrefetchHooks Function()
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String?> seedKey = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<String> units = const Value.absent(),
                Value<String?> packKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                seedKey: seedKey,
                name: name,
                icon: icon,
                color: color,
                kind: kind,
                parentId: parentId,
                sortOrder: sortOrder,
                isArchived: isArchived,
                units: units,
                packKey: packKey,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String id,
                Value<String?> seedKey = const Value.absent(),
                required String name,
                required String icon,
                required int color,
                required String kind,
                Value<String?> parentId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<String> units = const Value.absent(),
                Value<String?> packKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                seedKey: seedKey,
                name: name,
                icon: icon,
                color: color,
                kind: kind,
                parentId: parentId,
                sortOrder: sortOrder,
                isArchived: isArchived,
                units: units,
                packKey: packKey,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriesTable, Category>(table),
                  BaseReferences<_$AppDatabase, $CategoriesTable, Category>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
      Category,
      PrefetchHooks Function()
    >;
typedef $$EntriesTableCreateCompanionBuilder = EntriesCompanion Function({
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required String id,
  required String kind,
  required int amountMinor,
  Value<String> currency,
  required DateTime occurredAt,
  Value<String?> categoryId,
  Value<String?> accountId,
  Value<String?> toAccountId,
  Value<String> note,
  Value<String?> payee,
  Value<String> source,
  Value<String?> smsId,
  Value<String?> groupId,
  Value<String?> paidByMemberId,
  Value<String?> splitMethod,
  Value<String> tags,
  Value<String?> projectId,
  Value<String?> recurringId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$EntriesTableUpdateCompanionBuilder = EntriesCompanion Function({
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> id,
  Value<String> kind,
  Value<int> amountMinor,
  Value<String> currency,
  Value<DateTime> occurredAt,
  Value<String?> categoryId,
  Value<String?> accountId,
  Value<String?> toAccountId,
  Value<String> note,
  Value<String?> payee,
  Value<String> source,
  Value<String?> smsId,
  Value<String?> groupId,
  Value<String?> paidByMemberId,
  Value<String?> splitMethod,
  Value<String> tags,
  Value<String?> projectId,
  Value<String?> recurringId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$EntriesTableFilterComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payee => $composableBuilder(
    column: $table.payee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get smsId => $composableBuilder(
    column: $table.smsId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paidByMemberId => $composableBuilder(
    column: $table.paidByMemberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get splitMethod => $composableBuilder(
    column: $table.splitMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurringId => $composableBuilder(
    column: $table.recurringId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payee => $composableBuilder(
    column: $table.payee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get smsId => $composableBuilder(
    column: $table.smsId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paidByMemberId => $composableBuilder(
    column: $table.paidByMemberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get splitMethod => $composableBuilder(
    column: $table.splitMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurringId => $composableBuilder(
    column: $table.recurringId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get payee =>
      $composableBuilder(column: $table.payee, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get smsId =>
      $composableBuilder(column: $table.smsId, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get paidByMemberId => $composableBuilder(
    column: $table.paidByMemberId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get splitMethod => $composableBuilder(
    column: $table.splitMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get recurringId => $composableBuilder(
    column: $table.recurringId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$EntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntriesTable,
          Entry,
          $$EntriesTableFilterComposer,
          $$EntriesTableOrderingComposer,
          $$EntriesTableAnnotationComposer,
          $$EntriesTableCreateCompanionBuilder,
          $$EntriesTableUpdateCompanionBuilder,
          (Entry, BaseReferences<_$AppDatabase, $EntriesTable, Entry>),
          Entry,
          PrefetchHooks Function()
        > {
  $$EntriesTableTableManager(_$AppDatabase db, $EntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<String?> toAccountId = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String?> payee = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> smsId = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<String?> paidByMemberId = const Value.absent(),
                Value<String?> splitMethod = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<String?> recurringId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntriesCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                kind: kind,
                amountMinor: amountMinor,
                currency: currency,
                occurredAt: occurredAt,
                categoryId: categoryId,
                accountId: accountId,
                toAccountId: toAccountId,
                note: note,
                payee: payee,
                source: source,
                smsId: smsId,
                groupId: groupId,
                paidByMemberId: paidByMemberId,
                splitMethod: splitMethod,
                tags: tags,
                projectId: projectId,
                recurringId: recurringId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String id,
                required String kind,
                required int amountMinor,
                Value<String> currency = const Value.absent(),
                required DateTime occurredAt,
                Value<String?> categoryId = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<String?> toAccountId = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String?> payee = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> smsId = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<String?> paidByMemberId = const Value.absent(),
                Value<String?> splitMethod = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<String?> recurringId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntriesCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                kind: kind,
                amountMinor: amountMinor,
                currency: currency,
                occurredAt: occurredAt,
                categoryId: categoryId,
                accountId: accountId,
                toAccountId: toAccountId,
                note: note,
                payee: payee,
                source: source,
                smsId: smsId,
                groupId: groupId,
                paidByMemberId: paidByMemberId,
                splitMethod: splitMethod,
                tags: tags,
                projectId: projectId,
                recurringId: recurringId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EntriesTable, Entry>(table),
                  BaseReferences<_$AppDatabase, $EntriesTable, Entry>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntriesTable,
      Entry,
      $$EntriesTableFilterComposer,
      $$EntriesTableOrderingComposer,
      $$EntriesTableAnnotationComposer,
      $$EntriesTableCreateCompanionBuilder,
      $$EntriesTableUpdateCompanionBuilder,
      (Entry, BaseReferences<_$AppDatabase, $EntriesTable, Entry>),
      Entry,
      PrefetchHooks Function()
    >;
typedef $$EntryItemsTableCreateCompanionBuilder = EntryItemsCompanion Function({
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required String id,
  required String entryId,
  required String name,
  Value<double> quantity,
  Value<String?> unit,
  required int unitPriceMinor,
  required int amountMinor,
  Value<int> sortOrder,
  Value<bool> isShared,
  Value<int> rowid,
});
typedef $$EntryItemsTableUpdateCompanionBuilder = EntryItemsCompanion Function({
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> id,
  Value<String> entryId,
  Value<String> name,
  Value<double> quantity,
  Value<String?> unit,
  Value<int> unitPriceMinor,
  Value<int> amountMinor,
  Value<int> sortOrder,
  Value<bool> isShared,
  Value<int> rowid,
});

class $$EntryItemsTableFilterComposer
    extends Composer<_$AppDatabase, $EntryItemsTable> {
  $$EntryItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitPriceMinor => $composableBuilder(
    column: $table.unitPriceMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isShared => $composableBuilder(
    column: $table.isShared,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EntryItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $EntryItemsTable> {
  $$EntryItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitPriceMinor => $composableBuilder(
    column: $table.unitPriceMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isShared => $composableBuilder(
    column: $table.isShared,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EntryItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntryItemsTable> {
  $$EntryItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get unitPriceMinor => $composableBuilder(
    column: $table.unitPriceMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isShared =>
      $composableBuilder(column: $table.isShared, builder: (column) => column);
}

class $$EntryItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntryItemsTable,
          EntryItem,
          $$EntryItemsTableFilterComposer,
          $$EntryItemsTableOrderingComposer,
          $$EntryItemsTableAnnotationComposer,
          $$EntryItemsTableCreateCompanionBuilder,
          $$EntryItemsTableUpdateCompanionBuilder,
          (
            EntryItem,
            BaseReferences<_$AppDatabase, $EntryItemsTable, EntryItem>,
          ),
          EntryItem,
          PrefetchHooks Function()
        > {
  $$EntryItemsTableTableManager(_$AppDatabase db, $EntryItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntryItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntryItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntryItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> entryId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<int> unitPriceMinor = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isShared = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntryItemsCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                entryId: entryId,
                name: name,
                quantity: quantity,
                unit: unit,
                unitPriceMinor: unitPriceMinor,
                amountMinor: amountMinor,
                sortOrder: sortOrder,
                isShared: isShared,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String id,
                required String entryId,
                required String name,
                Value<double> quantity = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                required int unitPriceMinor,
                required int amountMinor,
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isShared = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntryItemsCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                entryId: entryId,
                name: name,
                quantity: quantity,
                unit: unit,
                unitPriceMinor: unitPriceMinor,
                amountMinor: amountMinor,
                sortOrder: sortOrder,
                isShared: isShared,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EntryItemsTable, EntryItem>(table),
                  BaseReferences<_$AppDatabase, $EntryItemsTable, EntryItem>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EntryItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntryItemsTable,
      EntryItem,
      $$EntryItemsTableFilterComposer,
      $$EntryItemsTableOrderingComposer,
      $$EntryItemsTableAnnotationComposer,
      $$EntryItemsTableCreateCompanionBuilder,
      $$EntryItemsTableUpdateCompanionBuilder,
      (EntryItem, BaseReferences<_$AppDatabase, $EntryItemsTable, EntryItem>),
      EntryItem,
      PrefetchHooks Function()
    >;
typedef $$GroupsTableCreateCompanionBuilder = GroupsCompanion Function({
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required String id,
  required String name,
  Value<String> icon,
  Value<String> currency,
  Value<bool> simplifyDebts,
  Value<String?> inviteCode,
  Value<String?> projectId,
  Value<DateTime> createdAt,
  Value<String> type,
  Value<String> defaultSplitMethod,
  Value<String> notes,
  Value<String?> currencyLabel,
  Value<DateTime?> archivedAt,
  Value<int> rowid,
});
typedef $$GroupsTableUpdateCompanionBuilder = GroupsCompanion Function({
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> id,
  Value<String> name,
  Value<String> icon,
  Value<String> currency,
  Value<bool> simplifyDebts,
  Value<String?> inviteCode,
  Value<String?> projectId,
  Value<DateTime> createdAt,
  Value<String> type,
  Value<String> defaultSplitMethod,
  Value<String> notes,
  Value<String?> currencyLabel,
  Value<DateTime?> archivedAt,
  Value<int> rowid,
});

class $$GroupsTableFilterComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get simplifyDebts => $composableBuilder(
    column: $table.simplifyDebts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inviteCode => $composableBuilder(
    column: $table.inviteCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultSplitMethod => $composableBuilder(
    column: $table.defaultSplitMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyLabel => $composableBuilder(
    column: $table.currencyLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get simplifyDebts => $composableBuilder(
    column: $table.simplifyDebts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inviteCode => $composableBuilder(
    column: $table.inviteCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultSplitMethod => $composableBuilder(
    column: $table.defaultSplitMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyLabel => $composableBuilder(
    column: $table.currencyLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<bool> get simplifyDebts => $composableBuilder(
    column: $table.simplifyDebts,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inviteCode => $composableBuilder(
    column: $table.inviteCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get defaultSplitMethod => $composableBuilder(
    column: $table.defaultSplitMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get currencyLabel => $composableBuilder(
    column: $table.currencyLabel,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );
}

class $$GroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GroupsTable,
          Group,
          $$GroupsTableFilterComposer,
          $$GroupsTableOrderingComposer,
          $$GroupsTableAnnotationComposer,
          $$GroupsTableCreateCompanionBuilder,
          $$GroupsTableUpdateCompanionBuilder,
          (Group, BaseReferences<_$AppDatabase, $GroupsTable, Group>),
          Group,
          PrefetchHooks Function()
        > {
  $$GroupsTableTableManager(_$AppDatabase db, $GroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<bool> simplifyDebts = const Value.absent(),
                Value<String?> inviteCode = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> defaultSplitMethod = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String?> currencyLabel = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupsCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                name: name,
                icon: icon,
                currency: currency,
                simplifyDebts: simplifyDebts,
                inviteCode: inviteCode,
                projectId: projectId,
                createdAt: createdAt,
                type: type,
                defaultSplitMethod: defaultSplitMethod,
                notes: notes,
                currencyLabel: currencyLabel,
                archivedAt: archivedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String id,
                required String name,
                Value<String> icon = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<bool> simplifyDebts = const Value.absent(),
                Value<String?> inviteCode = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> defaultSplitMethod = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String?> currencyLabel = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupsCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                name: name,
                icon: icon,
                currency: currency,
                simplifyDebts: simplifyDebts,
                inviteCode: inviteCode,
                projectId: projectId,
                createdAt: createdAt,
                type: type,
                defaultSplitMethod: defaultSplitMethod,
                notes: notes,
                currencyLabel: currencyLabel,
                archivedAt: archivedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GroupsTable, Group>(table),
                  BaseReferences<_$AppDatabase, $GroupsTable, Group>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GroupsTable,
      Group,
      $$GroupsTableFilterComposer,
      $$GroupsTableOrderingComposer,
      $$GroupsTableAnnotationComposer,
      $$GroupsTableCreateCompanionBuilder,
      $$GroupsTableUpdateCompanionBuilder,
      (Group, BaseReferences<_$AppDatabase, $GroupsTable, Group>),
      Group,
      PrefetchHooks Function()
    >;
typedef $$MembersTableCreateCompanionBuilder = MembersCompanion Function({
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required String id,
  required String groupId,
  required String name,
  Value<String?> phone,
  Value<String?> email,
  Value<String?> upiId,
  Value<bool> isMe,
  Value<double> weight,
  Value<int> rowid,
});
typedef $$MembersTableUpdateCompanionBuilder = MembersCompanion Function({
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> id,
  Value<String> groupId,
  Value<String> name,
  Value<String?> phone,
  Value<String?> email,
  Value<String?> upiId,
  Value<bool> isMe,
  Value<double> weight,
  Value<int> rowid,
});

class $$MembersTableFilterComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get upiId => $composableBuilder(
    column: $table.upiId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMe => $composableBuilder(
    column: $table.isMe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MembersTableOrderingComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get upiId => $composableBuilder(
    column: $table.upiId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMe => $composableBuilder(
    column: $table.isMe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get upiId =>
      $composableBuilder(column: $table.upiId, builder: (column) => column);

  GeneratedColumn<bool> get isMe =>
      $composableBuilder(column: $table.isMe, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);
}

class $$MembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MembersTable,
          Member,
          $$MembersTableFilterComposer,
          $$MembersTableOrderingComposer,
          $$MembersTableAnnotationComposer,
          $$MembersTableCreateCompanionBuilder,
          $$MembersTableUpdateCompanionBuilder,
          (Member, BaseReferences<_$AppDatabase, $MembersTable, Member>),
          Member,
          PrefetchHooks Function()
        > {
  $$MembersTableTableManager(_$AppDatabase db, $MembersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> upiId = const Value.absent(),
                Value<bool> isMe = const Value.absent(),
                Value<double> weight = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MembersCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                groupId: groupId,
                name: name,
                phone: phone,
                email: email,
                upiId: upiId,
                isMe: isMe,
                weight: weight,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String id,
                required String groupId,
                required String name,
                Value<String?> phone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> upiId = const Value.absent(),
                Value<bool> isMe = const Value.absent(),
                Value<double> weight = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MembersCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                groupId: groupId,
                name: name,
                phone: phone,
                email: email,
                upiId: upiId,
                isMe: isMe,
                weight: weight,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MembersTable, Member>(table),
                  BaseReferences<_$AppDatabase, $MembersTable, Member>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MembersTable,
      Member,
      $$MembersTableFilterComposer,
      $$MembersTableOrderingComposer,
      $$MembersTableAnnotationComposer,
      $$MembersTableCreateCompanionBuilder,
      $$MembersTableUpdateCompanionBuilder,
      (Member, BaseReferences<_$AppDatabase, $MembersTable, Member>),
      Member,
      PrefetchHooks Function()
    >;
typedef $$SplitsTableCreateCompanionBuilder = SplitsCompanion Function({
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required String id,
  required String entryId,
  required String memberId,
  required int amountMinor,
  Value<double?> shareValue,
  Value<int> rowid,
});
typedef $$SplitsTableUpdateCompanionBuilder = SplitsCompanion Function({
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> id,
  Value<String> entryId,
  Value<String> memberId,
  Value<int> amountMinor,
  Value<double?> shareValue,
  Value<int> rowid,
});

class $$SplitsTableFilterComposer
    extends Composer<_$AppDatabase, $SplitsTable> {
  $$SplitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get shareValue => $composableBuilder(
    column: $table.shareValue,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SplitsTableOrderingComposer
    extends Composer<_$AppDatabase, $SplitsTable> {
  $$SplitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get shareValue => $composableBuilder(
    column: $table.shareValue,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SplitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SplitsTable> {
  $$SplitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<String> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<double> get shareValue => $composableBuilder(
    column: $table.shareValue,
    builder: (column) => column,
  );
}

class $$SplitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SplitsTable,
          Split,
          $$SplitsTableFilterComposer,
          $$SplitsTableOrderingComposer,
          $$SplitsTableAnnotationComposer,
          $$SplitsTableCreateCompanionBuilder,
          $$SplitsTableUpdateCompanionBuilder,
          (Split, BaseReferences<_$AppDatabase, $SplitsTable, Split>),
          Split,
          PrefetchHooks Function()
        > {
  $$SplitsTableTableManager(_$AppDatabase db, $SplitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SplitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SplitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SplitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> entryId = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<double?> shareValue = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SplitsCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                entryId: entryId,
                memberId: memberId,
                amountMinor: amountMinor,
                shareValue: shareValue,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String id,
                required String entryId,
                required String memberId,
                required int amountMinor,
                Value<double?> shareValue = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SplitsCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                entryId: entryId,
                memberId: memberId,
                amountMinor: amountMinor,
                shareValue: shareValue,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SplitsTable, Split>(table),
                  BaseReferences<_$AppDatabase, $SplitsTable, Split>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SplitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SplitsTable,
      Split,
      $$SplitsTableFilterComposer,
      $$SplitsTableOrderingComposer,
      $$SplitsTableAnnotationComposer,
      $$SplitsTableCreateCompanionBuilder,
      $$SplitsTableUpdateCompanionBuilder,
      (Split, BaseReferences<_$AppDatabase, $SplitsTable, Split>),
      Split,
      PrefetchHooks Function()
    >;
typedef $$SettlementsTableCreateCompanionBuilder =
    SettlementsCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String id,
      required String groupId,
      required String fromMemberId,
      required String toMemberId,
      required int amountMinor,
      required DateTime occurredAt,
      Value<String> note,
      Value<String> method,
      Value<int> rowid,
    });
typedef $$SettlementsTableUpdateCompanionBuilder =
    SettlementsCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> id,
      Value<String> groupId,
      Value<String> fromMemberId,
      Value<String> toMemberId,
      Value<int> amountMinor,
      Value<DateTime> occurredAt,
      Value<String> note,
      Value<String> method,
      Value<int> rowid,
    });

class $$SettlementsTableFilterComposer
    extends Composer<_$AppDatabase, $SettlementsTable> {
  $$SettlementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromMemberId => $composableBuilder(
    column: $table.fromMemberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toMemberId => $composableBuilder(
    column: $table.toMemberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettlementsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettlementsTable> {
  $$SettlementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromMemberId => $composableBuilder(
    column: $table.fromMemberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toMemberId => $composableBuilder(
    column: $table.toMemberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettlementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettlementsTable> {
  $$SettlementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get fromMemberId => $composableBuilder(
    column: $table.fromMemberId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get toMemberId => $composableBuilder(
    column: $table.toMemberId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);
}

class $$SettlementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettlementsTable,
          Settlement,
          $$SettlementsTableFilterComposer,
          $$SettlementsTableOrderingComposer,
          $$SettlementsTableAnnotationComposer,
          $$SettlementsTableCreateCompanionBuilder,
          $$SettlementsTableUpdateCompanionBuilder,
          (
            Settlement,
            BaseReferences<_$AppDatabase, $SettlementsTable, Settlement>,
          ),
          Settlement,
          PrefetchHooks Function()
        > {
  $$SettlementsTableTableManager(_$AppDatabase db, $SettlementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettlementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettlementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettlementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> fromMemberId = const Value.absent(),
                Value<String> toMemberId = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> method = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettlementsCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                groupId: groupId,
                fromMemberId: fromMemberId,
                toMemberId: toMemberId,
                amountMinor: amountMinor,
                occurredAt: occurredAt,
                note: note,
                method: method,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String id,
                required String groupId,
                required String fromMemberId,
                required String toMemberId,
                required int amountMinor,
                required DateTime occurredAt,
                Value<String> note = const Value.absent(),
                Value<String> method = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettlementsCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                groupId: groupId,
                fromMemberId: fromMemberId,
                toMemberId: toMemberId,
                amountMinor: amountMinor,
                occurredAt: occurredAt,
                note: note,
                method: method,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettlementsTable, Settlement>(table),
                  BaseReferences<_$AppDatabase, $SettlementsTable, Settlement>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettlementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettlementsTable,
      Settlement,
      $$SettlementsTableFilterComposer,
      $$SettlementsTableOrderingComposer,
      $$SettlementsTableAnnotationComposer,
      $$SettlementsTableCreateCompanionBuilder,
      $$SettlementsTableUpdateCompanionBuilder,
      (
        Settlement,
        BaseReferences<_$AppDatabase, $SettlementsTable, Settlement>,
      ),
      Settlement,
      PrefetchHooks Function()
    >;
typedef $$BudgetsTableCreateCompanionBuilder = BudgetsCompanion Function({
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required String id,
  Value<String?> categoryId,
  Value<String> period,
  required int amountMinor,
  Value<int> rowid,
});
typedef $$BudgetsTableUpdateCompanionBuilder = BudgetsCompanion Function({
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> id,
  Value<String?> categoryId,
  Value<String> period,
  Value<int> amountMinor,
  Value<int> rowid,
});

class $$BudgetsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get period => $composableBuilder(
    column: $table.period,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BudgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get period => $composableBuilder(
    column: $table.period,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BudgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get period =>
      $composableBuilder(column: $table.period, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );
}

class $$BudgetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetsTable,
          Budget,
          $$BudgetsTableFilterComposer,
          $$BudgetsTableOrderingComposer,
          $$BudgetsTableAnnotationComposer,
          $$BudgetsTableCreateCompanionBuilder,
          $$BudgetsTableUpdateCompanionBuilder,
          (Budget, BaseReferences<_$AppDatabase, $BudgetsTable, Budget>),
          Budget,
          PrefetchHooks Function()
        > {
  $$BudgetsTableTableManager(_$AppDatabase db, $BudgetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> period = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetsCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                categoryId: categoryId,
                period: period,
                amountMinor: amountMinor,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String id,
                Value<String?> categoryId = const Value.absent(),
                Value<String> period = const Value.absent(),
                required int amountMinor,
                Value<int> rowid = const Value.absent(),
              }) => BudgetsCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                categoryId: categoryId,
                period: period,
                amountMinor: amountMinor,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BudgetsTable, Budget>(table),
                  BaseReferences<_$AppDatabase, $BudgetsTable, Budget>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BudgetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetsTable,
      Budget,
      $$BudgetsTableFilterComposer,
      $$BudgetsTableOrderingComposer,
      $$BudgetsTableAnnotationComposer,
      $$BudgetsTableCreateCompanionBuilder,
      $$BudgetsTableUpdateCompanionBuilder,
      (Budget, BaseReferences<_$AppDatabase, $BudgetsTable, Budget>),
      Budget,
      PrefetchHooks Function()
    >;
typedef $$SmsLogTableCreateCompanionBuilder = SmsLogCompanion Function({
  required String id,
  required String sender,
  required String body,
  required DateTime receivedAt,
  required String status,
  Value<String?> parsedJson,
  Value<String?> entryId,
  Value<String?> matchedReminderId,
  Value<String?> transactionKey,
  Value<DateTime> createdAt,
  Value<DateTime?> clearedAt,
  Value<int> rowid,
});
typedef $$SmsLogTableUpdateCompanionBuilder = SmsLogCompanion Function({
  Value<String> id,
  Value<String> sender,
  Value<String> body,
  Value<DateTime> receivedAt,
  Value<String> status,
  Value<String?> parsedJson,
  Value<String?> entryId,
  Value<String?> matchedReminderId,
  Value<String?> transactionKey,
  Value<DateTime> createdAt,
  Value<DateTime?> clearedAt,
  Value<int> rowid,
});

class $$SmsLogTableFilterComposer
    extends Composer<_$AppDatabase, $SmsLogTable> {
  $$SmsLogTableFilterComposer({
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

  ColumnFilters<String> get sender => $composableBuilder(
    column: $table.sender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parsedJson => $composableBuilder(
    column: $table.parsedJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matchedReminderId => $composableBuilder(
    column: $table.matchedReminderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionKey => $composableBuilder(
    column: $table.transactionKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clearedAt => $composableBuilder(
    column: $table.clearedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SmsLogTableOrderingComposer
    extends Composer<_$AppDatabase, $SmsLogTable> {
  $$SmsLogTableOrderingComposer({
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

  ColumnOrderings<String> get sender => $composableBuilder(
    column: $table.sender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parsedJson => $composableBuilder(
    column: $table.parsedJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matchedReminderId => $composableBuilder(
    column: $table.matchedReminderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionKey => $composableBuilder(
    column: $table.transactionKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clearedAt => $composableBuilder(
    column: $table.clearedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SmsLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $SmsLogTable> {
  $$SmsLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sender =>
      $composableBuilder(column: $table.sender, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get parsedJson => $composableBuilder(
    column: $table.parsedJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<String> get matchedReminderId => $composableBuilder(
    column: $table.matchedReminderId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get transactionKey => $composableBuilder(
    column: $table.transactionKey,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get clearedAt =>
      $composableBuilder(column: $table.clearedAt, builder: (column) => column);
}

class $$SmsLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SmsLogTable,
          SmsLogData,
          $$SmsLogTableFilterComposer,
          $$SmsLogTableOrderingComposer,
          $$SmsLogTableAnnotationComposer,
          $$SmsLogTableCreateCompanionBuilder,
          $$SmsLogTableUpdateCompanionBuilder,
          (SmsLogData, BaseReferences<_$AppDatabase, $SmsLogTable, SmsLogData>),
          SmsLogData,
          PrefetchHooks Function()
        > {
  $$SmsLogTableTableManager(_$AppDatabase db, $SmsLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SmsLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SmsLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SmsLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sender = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> receivedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> parsedJson = const Value.absent(),
                Value<String?> entryId = const Value.absent(),
                Value<String?> matchedReminderId = const Value.absent(),
                Value<String?> transactionKey = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> clearedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SmsLogCompanion(
                id: id,
                sender: sender,
                body: body,
                receivedAt: receivedAt,
                status: status,
                parsedJson: parsedJson,
                entryId: entryId,
                matchedReminderId: matchedReminderId,
                transactionKey: transactionKey,
                createdAt: createdAt,
                clearedAt: clearedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sender,
                required String body,
                required DateTime receivedAt,
                required String status,
                Value<String?> parsedJson = const Value.absent(),
                Value<String?> entryId = const Value.absent(),
                Value<String?> matchedReminderId = const Value.absent(),
                Value<String?> transactionKey = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> clearedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SmsLogCompanion.insert(
                id: id,
                sender: sender,
                body: body,
                receivedAt: receivedAt,
                status: status,
                parsedJson: parsedJson,
                entryId: entryId,
                matchedReminderId: matchedReminderId,
                transactionKey: transactionKey,
                createdAt: createdAt,
                clearedAt: clearedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SmsLogTable, SmsLogData>(table),
                  BaseReferences<_$AppDatabase, $SmsLogTable, SmsLogData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SmsLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SmsLogTable,
      SmsLogData,
      $$SmsLogTableFilterComposer,
      $$SmsLogTableOrderingComposer,
      $$SmsLogTableAnnotationComposer,
      $$SmsLogTableCreateCompanionBuilder,
      $$SmsLogTableUpdateCompanionBuilder,
      (SmsLogData, BaseReferences<_$AppDatabase, $SmsLogTable, SmsLogData>),
      SmsLogData,
      PrefetchHooks Function()
    >;
typedef $$ProjectsTableCreateCompanionBuilder = ProjectsCompanion Function({
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required String id,
  required String name,
  Value<String> icon,
  required int color,
  Value<String?> templateKey,
  Value<String> status,
  Value<DateTime?> startDate,
  Value<DateTime?> endDate,
  Value<int?> budgetMinor,
  Value<String> currency,
  Value<String> notes,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$ProjectsTableUpdateCompanionBuilder = ProjectsCompanion Function({
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> id,
  Value<String> name,
  Value<String> icon,
  Value<int> color,
  Value<String?> templateKey,
  Value<String> status,
  Value<DateTime?> startDate,
  Value<DateTime?> endDate,
  Value<int?> budgetMinor,
  Value<String> currency,
  Value<String> notes,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$ProjectsTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateKey => $composableBuilder(
    column: $table.templateKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get budgetMinor => $composableBuilder(
    column: $table.budgetMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateKey => $composableBuilder(
    column: $table.templateKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get budgetMinor => $composableBuilder(
    column: $table.budgetMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get templateKey => $composableBuilder(
    column: $table.templateKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<int> get budgetMinor => $composableBuilder(
    column: $table.budgetMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ProjectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProjectsTable,
          Project,
          $$ProjectsTableFilterComposer,
          $$ProjectsTableOrderingComposer,
          $$ProjectsTableAnnotationComposer,
          $$ProjectsTableCreateCompanionBuilder,
          $$ProjectsTableUpdateCompanionBuilder,
          (Project, BaseReferences<_$AppDatabase, $ProjectsTable, Project>),
          Project,
          PrefetchHooks Function()
        > {
  $$ProjectsTableTableManager(_$AppDatabase db, $ProjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<String?> templateKey = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> startDate = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                Value<int?> budgetMinor = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                name: name,
                icon: icon,
                color: color,
                templateKey: templateKey,
                status: status,
                startDate: startDate,
                endDate: endDate,
                budgetMinor: budgetMinor,
                currency: currency,
                notes: notes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String id,
                required String name,
                Value<String> icon = const Value.absent(),
                required int color,
                Value<String?> templateKey = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> startDate = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                Value<int?> budgetMinor = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                name: name,
                icon: icon,
                color: color,
                templateKey: templateKey,
                status: status,
                startDate: startDate,
                endDate: endDate,
                budgetMinor: budgetMinor,
                currency: currency,
                notes: notes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProjectsTable, Project>(table),
                  BaseReferences<_$AppDatabase, $ProjectsTable, Project>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProjectsTable,
      Project,
      $$ProjectsTableFilterComposer,
      $$ProjectsTableOrderingComposer,
      $$ProjectsTableAnnotationComposer,
      $$ProjectsTableCreateCompanionBuilder,
      $$ProjectsTableUpdateCompanionBuilder,
      (Project, BaseReferences<_$AppDatabase, $ProjectsTable, Project>),
      Project,
      PrefetchHooks Function()
    >;
typedef $$ProjectFieldsTableCreateCompanionBuilder =
    ProjectFieldsCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String id,
      required String projectId,
      required String key,
      Value<String> label,
      required String type,
      Value<String?> unit,
      Value<String> choices,
      Value<int> sortOrder,
      Value<String> scope,
      Value<double?> numberValue,
      Value<String?> textValue,
      Value<int> rowid,
    });
typedef $$ProjectFieldsTableUpdateCompanionBuilder =
    ProjectFieldsCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> id,
      Value<String> projectId,
      Value<String> key,
      Value<String> label,
      Value<String> type,
      Value<String?> unit,
      Value<String> choices,
      Value<int> sortOrder,
      Value<String> scope,
      Value<double?> numberValue,
      Value<String?> textValue,
      Value<int> rowid,
    });

class $$ProjectFieldsTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectFieldsTable> {
  $$ProjectFieldsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get choices => $composableBuilder(
    column: $table.choices,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get numberValue => $composableBuilder(
    column: $table.numberValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textValue => $composableBuilder(
    column: $table.textValue,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProjectFieldsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectFieldsTable> {
  $$ProjectFieldsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get choices => $composableBuilder(
    column: $table.choices,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get numberValue => $composableBuilder(
    column: $table.numberValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textValue => $composableBuilder(
    column: $table.textValue,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProjectFieldsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectFieldsTable> {
  $$ProjectFieldsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get choices =>
      $composableBuilder(column: $table.choices, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<double> get numberValue => $composableBuilder(
    column: $table.numberValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get textValue =>
      $composableBuilder(column: $table.textValue, builder: (column) => column);
}

class $$ProjectFieldsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProjectFieldsTable,
          ProjectField,
          $$ProjectFieldsTableFilterComposer,
          $$ProjectFieldsTableOrderingComposer,
          $$ProjectFieldsTableAnnotationComposer,
          $$ProjectFieldsTableCreateCompanionBuilder,
          $$ProjectFieldsTableUpdateCompanionBuilder,
          (
            ProjectField,
            BaseReferences<_$AppDatabase, $ProjectFieldsTable, ProjectField>,
          ),
          ProjectField,
          PrefetchHooks Function()
        > {
  $$ProjectFieldsTableTableManager(_$AppDatabase db, $ProjectFieldsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectFieldsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectFieldsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectFieldsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String> choices = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> scope = const Value.absent(),
                Value<double?> numberValue = const Value.absent(),
                Value<String?> textValue = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectFieldsCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                projectId: projectId,
                key: key,
                label: label,
                type: type,
                unit: unit,
                choices: choices,
                sortOrder: sortOrder,
                scope: scope,
                numberValue: numberValue,
                textValue: textValue,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String id,
                required String projectId,
                required String key,
                Value<String> label = const Value.absent(),
                required String type,
                Value<String?> unit = const Value.absent(),
                Value<String> choices = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> scope = const Value.absent(),
                Value<double?> numberValue = const Value.absent(),
                Value<String?> textValue = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectFieldsCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                projectId: projectId,
                key: key,
                label: label,
                type: type,
                unit: unit,
                choices: choices,
                sortOrder: sortOrder,
                scope: scope,
                numberValue: numberValue,
                textValue: textValue,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProjectFieldsTable, ProjectField>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ProjectFieldsTable,
                    ProjectField
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProjectFieldsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProjectFieldsTable,
      ProjectField,
      $$ProjectFieldsTableFilterComposer,
      $$ProjectFieldsTableOrderingComposer,
      $$ProjectFieldsTableAnnotationComposer,
      $$ProjectFieldsTableCreateCompanionBuilder,
      $$ProjectFieldsTableUpdateCompanionBuilder,
      (
        ProjectField,
        BaseReferences<_$AppDatabase, $ProjectFieldsTable, ProjectField>,
      ),
      ProjectField,
      PrefetchHooks Function()
    >;
typedef $$EntryFieldValuesTableCreateCompanionBuilder =
    EntryFieldValuesCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String id,
      required String entryId,
      required String fieldKey,
      Value<double?> numberValue,
      Value<String?> textValue,
      Value<DateTime?> dateValue,
      Value<int> rowid,
    });
typedef $$EntryFieldValuesTableUpdateCompanionBuilder =
    EntryFieldValuesCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> id,
      Value<String> entryId,
      Value<String> fieldKey,
      Value<double?> numberValue,
      Value<String?> textValue,
      Value<DateTime?> dateValue,
      Value<int> rowid,
    });

class $$EntryFieldValuesTableFilterComposer
    extends Composer<_$AppDatabase, $EntryFieldValuesTable> {
  $$EntryFieldValuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldKey => $composableBuilder(
    column: $table.fieldKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get numberValue => $composableBuilder(
    column: $table.numberValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textValue => $composableBuilder(
    column: $table.textValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateValue => $composableBuilder(
    column: $table.dateValue,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EntryFieldValuesTableOrderingComposer
    extends Composer<_$AppDatabase, $EntryFieldValuesTable> {
  $$EntryFieldValuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldKey => $composableBuilder(
    column: $table.fieldKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get numberValue => $composableBuilder(
    column: $table.numberValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textValue => $composableBuilder(
    column: $table.textValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateValue => $composableBuilder(
    column: $table.dateValue,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EntryFieldValuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntryFieldValuesTable> {
  $$EntryFieldValuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<String> get fieldKey =>
      $composableBuilder(column: $table.fieldKey, builder: (column) => column);

  GeneratedColumn<double> get numberValue => $composableBuilder(
    column: $table.numberValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get textValue =>
      $composableBuilder(column: $table.textValue, builder: (column) => column);

  GeneratedColumn<DateTime> get dateValue =>
      $composableBuilder(column: $table.dateValue, builder: (column) => column);
}

class $$EntryFieldValuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntryFieldValuesTable,
          EntryFieldValue,
          $$EntryFieldValuesTableFilterComposer,
          $$EntryFieldValuesTableOrderingComposer,
          $$EntryFieldValuesTableAnnotationComposer,
          $$EntryFieldValuesTableCreateCompanionBuilder,
          $$EntryFieldValuesTableUpdateCompanionBuilder,
          (
            EntryFieldValue,
            BaseReferences<
              _$AppDatabase,
              $EntryFieldValuesTable,
              EntryFieldValue
            >,
          ),
          EntryFieldValue,
          PrefetchHooks Function()
        > {
  $$EntryFieldValuesTableTableManager(
    _$AppDatabase db,
    $EntryFieldValuesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntryFieldValuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntryFieldValuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntryFieldValuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> entryId = const Value.absent(),
                Value<String> fieldKey = const Value.absent(),
                Value<double?> numberValue = const Value.absent(),
                Value<String?> textValue = const Value.absent(),
                Value<DateTime?> dateValue = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntryFieldValuesCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                entryId: entryId,
                fieldKey: fieldKey,
                numberValue: numberValue,
                textValue: textValue,
                dateValue: dateValue,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String id,
                required String entryId,
                required String fieldKey,
                Value<double?> numberValue = const Value.absent(),
                Value<String?> textValue = const Value.absent(),
                Value<DateTime?> dateValue = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntryFieldValuesCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                entryId: entryId,
                fieldKey: fieldKey,
                numberValue: numberValue,
                textValue: textValue,
                dateValue: dateValue,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EntryFieldValuesTable, EntryFieldValue>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $EntryFieldValuesTable,
                    EntryFieldValue
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EntryFieldValuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntryFieldValuesTable,
      EntryFieldValue,
      $$EntryFieldValuesTableFilterComposer,
      $$EntryFieldValuesTableOrderingComposer,
      $$EntryFieldValuesTableAnnotationComposer,
      $$EntryFieldValuesTableCreateCompanionBuilder,
      $$EntryFieldValuesTableUpdateCompanionBuilder,
      (
        EntryFieldValue,
        BaseReferences<_$AppDatabase, $EntryFieldValuesTable, EntryFieldValue>,
      ),
      EntryFieldValue,
      PrefetchHooks Function()
    >;
typedef $$RemindersTableCreateCompanionBuilder = RemindersCompanion Function({
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required String id,
  required String kind,
  Value<String?> groupId,
  Value<String?> memberId,
  Value<String?> entryId,
  Value<DateTime?> dueAt,
  Value<DateTime?> sentAt,
  Value<DateTime?> doneAt,
  Value<String> channel,
  Value<String> message,
  Value<String> title,
  Value<String> notes,
  Value<int?> amountMinor,
  Value<int> toleranceMinor,
  Value<String> matchKeywords,
  Value<String?> categoryId,
  Value<String?> accountId,
  Value<String?> recurringId,
  Value<String?> assetId,
  Value<String> repeat,
  Value<int?> repeatDay,
  Value<String> remindDaysBefore,
  Value<int?> notifyAtMinute,
  Value<String> status,
  Value<DateTime?> snoozedUntil,
  Value<String?> nextId,
  Value<String?> projectId,
  Value<String> documentNumber,
  Value<String?> presetKey,
  Value<int> rowid,
});
typedef $$RemindersTableUpdateCompanionBuilder = RemindersCompanion Function({
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> id,
  Value<String> kind,
  Value<String?> groupId,
  Value<String?> memberId,
  Value<String?> entryId,
  Value<DateTime?> dueAt,
  Value<DateTime?> sentAt,
  Value<DateTime?> doneAt,
  Value<String> channel,
  Value<String> message,
  Value<String> title,
  Value<String> notes,
  Value<int?> amountMinor,
  Value<int> toleranceMinor,
  Value<String> matchKeywords,
  Value<String?> categoryId,
  Value<String?> accountId,
  Value<String?> recurringId,
  Value<String?> assetId,
  Value<String> repeat,
  Value<int?> repeatDay,
  Value<String> remindDaysBefore,
  Value<int?> notifyAtMinute,
  Value<String> status,
  Value<DateTime?> snoozedUntil,
  Value<String?> nextId,
  Value<String?> projectId,
  Value<String> documentNumber,
  Value<String?> presetKey,
  Value<int> rowid,
});

class $$RemindersTableFilterComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get doneAt => $composableBuilder(
    column: $table.doneAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get toleranceMinor => $composableBuilder(
    column: $table.toleranceMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matchKeywords => $composableBuilder(
    column: $table.matchKeywords,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurringId => $composableBuilder(
    column: $table.recurringId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repeat => $composableBuilder(
    column: $table.repeat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repeatDay => $composableBuilder(
    column: $table.repeatDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remindDaysBefore => $composableBuilder(
    column: $table.remindDaysBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get notifyAtMinute => $composableBuilder(
    column: $table.notifyAtMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nextId => $composableBuilder(
    column: $table.nextId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentNumber => $composableBuilder(
    column: $table.documentNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get presetKey => $composableBuilder(
    column: $table.presetKey,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get doneAt => $composableBuilder(
    column: $table.doneAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get toleranceMinor => $composableBuilder(
    column: $table.toleranceMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matchKeywords => $composableBuilder(
    column: $table.matchKeywords,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurringId => $composableBuilder(
    column: $table.recurringId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repeat => $composableBuilder(
    column: $table.repeat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repeatDay => $composableBuilder(
    column: $table.repeatDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remindDaysBefore => $composableBuilder(
    column: $table.remindDaysBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get notifyAtMinute => $composableBuilder(
    column: $table.notifyAtMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nextId => $composableBuilder(
    column: $table.nextId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentNumber => $composableBuilder(
    column: $table.documentNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get presetKey => $composableBuilder(
    column: $table.presetKey,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);

  GeneratedColumn<String> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<DateTime> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<DateTime> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);

  GeneratedColumn<DateTime> get doneAt =>
      $composableBuilder(column: $table.doneAt, builder: (column) => column);

  GeneratedColumn<String> get channel =>
      $composableBuilder(column: $table.channel, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get toleranceMinor => $composableBuilder(
    column: $table.toleranceMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get matchKeywords => $composableBuilder(
    column: $table.matchKeywords,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get recurringId => $composableBuilder(
    column: $table.recurringId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get assetId =>
      $composableBuilder(column: $table.assetId, builder: (column) => column);

  GeneratedColumn<String> get repeat =>
      $composableBuilder(column: $table.repeat, builder: (column) => column);

  GeneratedColumn<int> get repeatDay =>
      $composableBuilder(column: $table.repeatDay, builder: (column) => column);

  GeneratedColumn<String> get remindDaysBefore => $composableBuilder(
    column: $table.remindDaysBefore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get notifyAtMinute => $composableBuilder(
    column: $table.notifyAtMinute,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nextId =>
      $composableBuilder(column: $table.nextId, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get documentNumber => $composableBuilder(
    column: $table.documentNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get presetKey =>
      $composableBuilder(column: $table.presetKey, builder: (column) => column);
}

class $$RemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemindersTable,
          Reminder,
          $$RemindersTableFilterComposer,
          $$RemindersTableOrderingComposer,
          $$RemindersTableAnnotationComposer,
          $$RemindersTableCreateCompanionBuilder,
          $$RemindersTableUpdateCompanionBuilder,
          (Reminder, BaseReferences<_$AppDatabase, $RemindersTable, Reminder>),
          Reminder,
          PrefetchHooks Function()
        > {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<String?> memberId = const Value.absent(),
                Value<String?> entryId = const Value.absent(),
                Value<DateTime?> dueAt = const Value.absent(),
                Value<DateTime?> sentAt = const Value.absent(),
                Value<DateTime?> doneAt = const Value.absent(),
                Value<String> channel = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int?> amountMinor = const Value.absent(),
                Value<int> toleranceMinor = const Value.absent(),
                Value<String> matchKeywords = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<String?> recurringId = const Value.absent(),
                Value<String?> assetId = const Value.absent(),
                Value<String> repeat = const Value.absent(),
                Value<int?> repeatDay = const Value.absent(),
                Value<String> remindDaysBefore = const Value.absent(),
                Value<int?> notifyAtMinute = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> snoozedUntil = const Value.absent(),
                Value<String?> nextId = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<String> documentNumber = const Value.absent(),
                Value<String?> presetKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemindersCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                kind: kind,
                groupId: groupId,
                memberId: memberId,
                entryId: entryId,
                dueAt: dueAt,
                sentAt: sentAt,
                doneAt: doneAt,
                channel: channel,
                message: message,
                title: title,
                notes: notes,
                amountMinor: amountMinor,
                toleranceMinor: toleranceMinor,
                matchKeywords: matchKeywords,
                categoryId: categoryId,
                accountId: accountId,
                recurringId: recurringId,
                assetId: assetId,
                repeat: repeat,
                repeatDay: repeatDay,
                remindDaysBefore: remindDaysBefore,
                notifyAtMinute: notifyAtMinute,
                status: status,
                snoozedUntil: snoozedUntil,
                nextId: nextId,
                projectId: projectId,
                documentNumber: documentNumber,
                presetKey: presetKey,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String id,
                required String kind,
                Value<String?> groupId = const Value.absent(),
                Value<String?> memberId = const Value.absent(),
                Value<String?> entryId = const Value.absent(),
                Value<DateTime?> dueAt = const Value.absent(),
                Value<DateTime?> sentAt = const Value.absent(),
                Value<DateTime?> doneAt = const Value.absent(),
                Value<String> channel = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int?> amountMinor = const Value.absent(),
                Value<int> toleranceMinor = const Value.absent(),
                Value<String> matchKeywords = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<String?> recurringId = const Value.absent(),
                Value<String?> assetId = const Value.absent(),
                Value<String> repeat = const Value.absent(),
                Value<int?> repeatDay = const Value.absent(),
                Value<String> remindDaysBefore = const Value.absent(),
                Value<int?> notifyAtMinute = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> snoozedUntil = const Value.absent(),
                Value<String?> nextId = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<String> documentNumber = const Value.absent(),
                Value<String?> presetKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemindersCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                kind: kind,
                groupId: groupId,
                memberId: memberId,
                entryId: entryId,
                dueAt: dueAt,
                sentAt: sentAt,
                doneAt: doneAt,
                channel: channel,
                message: message,
                title: title,
                notes: notes,
                amountMinor: amountMinor,
                toleranceMinor: toleranceMinor,
                matchKeywords: matchKeywords,
                categoryId: categoryId,
                accountId: accountId,
                recurringId: recurringId,
                assetId: assetId,
                repeat: repeat,
                repeatDay: repeatDay,
                remindDaysBefore: remindDaysBefore,
                notifyAtMinute: notifyAtMinute,
                status: status,
                snoozedUntil: snoozedUntil,
                nextId: nextId,
                projectId: projectId,
                documentNumber: documentNumber,
                presetKey: presetKey,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RemindersTable, Reminder>(table),
                  BaseReferences<_$AppDatabase, $RemindersTable, Reminder>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemindersTable,
      Reminder,
      $$RemindersTableFilterComposer,
      $$RemindersTableOrderingComposer,
      $$RemindersTableAnnotationComposer,
      $$RemindersTableCreateCompanionBuilder,
      $$RemindersTableUpdateCompanionBuilder,
      (Reminder, BaseReferences<_$AppDatabase, $RemindersTable, Reminder>),
      Reminder,
      PrefetchHooks Function()
    >;
typedef $$EntryPayersTableCreateCompanionBuilder =
    EntryPayersCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String id,
      required String entryId,
      required String memberId,
      required int amountMinor,
      Value<int> rowid,
    });
typedef $$EntryPayersTableUpdateCompanionBuilder =
    EntryPayersCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> id,
      Value<String> entryId,
      Value<String> memberId,
      Value<int> amountMinor,
      Value<int> rowid,
    });

class $$EntryPayersTableFilterComposer
    extends Composer<_$AppDatabase, $EntryPayersTable> {
  $$EntryPayersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EntryPayersTableOrderingComposer
    extends Composer<_$AppDatabase, $EntryPayersTable> {
  $$EntryPayersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EntryPayersTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntryPayersTable> {
  $$EntryPayersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<String> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );
}

class $$EntryPayersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntryPayersTable,
          EntryPayer,
          $$EntryPayersTableFilterComposer,
          $$EntryPayersTableOrderingComposer,
          $$EntryPayersTableAnnotationComposer,
          $$EntryPayersTableCreateCompanionBuilder,
          $$EntryPayersTableUpdateCompanionBuilder,
          (
            EntryPayer,
            BaseReferences<_$AppDatabase, $EntryPayersTable, EntryPayer>,
          ),
          EntryPayer,
          PrefetchHooks Function()
        > {
  $$EntryPayersTableTableManager(_$AppDatabase db, $EntryPayersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntryPayersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntryPayersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntryPayersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> entryId = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntryPayersCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                entryId: entryId,
                memberId: memberId,
                amountMinor: amountMinor,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String id,
                required String entryId,
                required String memberId,
                required int amountMinor,
                Value<int> rowid = const Value.absent(),
              }) => EntryPayersCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                entryId: entryId,
                memberId: memberId,
                amountMinor: amountMinor,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EntryPayersTable, EntryPayer>(table),
                  BaseReferences<_$AppDatabase, $EntryPayersTable, EntryPayer>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EntryPayersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntryPayersTable,
      EntryPayer,
      $$EntryPayersTableFilterComposer,
      $$EntryPayersTableOrderingComposer,
      $$EntryPayersTableAnnotationComposer,
      $$EntryPayersTableCreateCompanionBuilder,
      $$EntryPayersTableUpdateCompanionBuilder,
      (
        EntryPayer,
        BaseReferences<_$AppDatabase, $EntryPayersTable, EntryPayer>,
      ),
      EntryPayer,
      PrefetchHooks Function()
    >;
typedef $$RecurringRulesTableCreateCompanionBuilder =
    RecurringRulesCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String id,
      Value<String> name,
      required String kind,
      required int amountMinor,
      Value<String> currency,
      Value<String?> categoryId,
      Value<String?> accountId,
      Value<String?> toAccountId,
      Value<String?> payee,
      Value<String?> projectId,
      Value<String> note,
      required String frequency,
      Value<int> interval,
      Value<int?> dayOfMonth,
      Value<int?> weekday,
      required DateTime startDate,
      Value<DateTime?> endDate,
      Value<int?> maxCount,
      Value<int> postedCount,
      Value<int> skippedCount,
      Value<DateTime?> nextDue,
      Value<bool> autoPost,
      Value<String> remindDaysBefore,
      Value<bool> isSubscription,
      Value<String?> groupId,
      Value<String?> groupSplit,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$RecurringRulesTableUpdateCompanionBuilder =
    RecurringRulesCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> id,
      Value<String> name,
      Value<String> kind,
      Value<int> amountMinor,
      Value<String> currency,
      Value<String?> categoryId,
      Value<String?> accountId,
      Value<String?> toAccountId,
      Value<String?> payee,
      Value<String?> projectId,
      Value<String> note,
      Value<String> frequency,
      Value<int> interval,
      Value<int?> dayOfMonth,
      Value<int?> weekday,
      Value<DateTime> startDate,
      Value<DateTime?> endDate,
      Value<int?> maxCount,
      Value<int> postedCount,
      Value<int> skippedCount,
      Value<DateTime?> nextDue,
      Value<bool> autoPost,
      Value<String> remindDaysBefore,
      Value<bool> isSubscription,
      Value<String?> groupId,
      Value<String?> groupSplit,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$RecurringRulesTableFilterComposer
    extends Composer<_$AppDatabase, $RecurringRulesTable> {
  $$RecurringRulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payee => $composableBuilder(
    column: $table.payee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get interval => $composableBuilder(
    column: $table.interval,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxCount => $composableBuilder(
    column: $table.maxCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get postedCount => $composableBuilder(
    column: $table.postedCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get skippedCount => $composableBuilder(
    column: $table.skippedCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextDue => $composableBuilder(
    column: $table.nextDue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoPost => $composableBuilder(
    column: $table.autoPost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remindDaysBefore => $composableBuilder(
    column: $table.remindDaysBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSubscription => $composableBuilder(
    column: $table.isSubscription,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupSplit => $composableBuilder(
    column: $table.groupSplit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecurringRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecurringRulesTable> {
  $$RecurringRulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payee => $composableBuilder(
    column: $table.payee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get interval => $composableBuilder(
    column: $table.interval,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxCount => $composableBuilder(
    column: $table.maxCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get postedCount => $composableBuilder(
    column: $table.postedCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get skippedCount => $composableBuilder(
    column: $table.skippedCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextDue => $composableBuilder(
    column: $table.nextDue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoPost => $composableBuilder(
    column: $table.autoPost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remindDaysBefore => $composableBuilder(
    column: $table.remindDaysBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSubscription => $composableBuilder(
    column: $table.isSubscription,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupSplit => $composableBuilder(
    column: $table.groupSplit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecurringRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecurringRulesTable> {
  $$RecurringRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payee =>
      $composableBuilder(column: $table.payee, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<int> get interval =>
      $composableBuilder(column: $table.interval, builder: (column) => column);

  GeneratedColumn<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => column,
  );

  GeneratedColumn<int> get weekday =>
      $composableBuilder(column: $table.weekday, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<int> get maxCount =>
      $composableBuilder(column: $table.maxCount, builder: (column) => column);

  GeneratedColumn<int> get postedCount => $composableBuilder(
    column: $table.postedCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get skippedCount => $composableBuilder(
    column: $table.skippedCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextDue =>
      $composableBuilder(column: $table.nextDue, builder: (column) => column);

  GeneratedColumn<bool> get autoPost =>
      $composableBuilder(column: $table.autoPost, builder: (column) => column);

  GeneratedColumn<String> get remindDaysBefore => $composableBuilder(
    column: $table.remindDaysBefore,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSubscription => $composableBuilder(
    column: $table.isSubscription,
    builder: (column) => column,
  );

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get groupSplit => $composableBuilder(
    column: $table.groupSplit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$RecurringRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecurringRulesTable,
          RecurringRule,
          $$RecurringRulesTableFilterComposer,
          $$RecurringRulesTableOrderingComposer,
          $$RecurringRulesTableAnnotationComposer,
          $$RecurringRulesTableCreateCompanionBuilder,
          $$RecurringRulesTableUpdateCompanionBuilder,
          (
            RecurringRule,
            BaseReferences<_$AppDatabase, $RecurringRulesTable, RecurringRule>,
          ),
          RecurringRule,
          PrefetchHooks Function()
        > {
  $$RecurringRulesTableTableManager(
    _$AppDatabase db,
    $RecurringRulesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurringRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurringRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurringRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<String?> toAccountId = const Value.absent(),
                Value<String?> payee = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> frequency = const Value.absent(),
                Value<int> interval = const Value.absent(),
                Value<int?> dayOfMonth = const Value.absent(),
                Value<int?> weekday = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                Value<int?> maxCount = const Value.absent(),
                Value<int> postedCount = const Value.absent(),
                Value<int> skippedCount = const Value.absent(),
                Value<DateTime?> nextDue = const Value.absent(),
                Value<bool> autoPost = const Value.absent(),
                Value<String> remindDaysBefore = const Value.absent(),
                Value<bool> isSubscription = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<String?> groupSplit = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecurringRulesCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                name: name,
                kind: kind,
                amountMinor: amountMinor,
                currency: currency,
                categoryId: categoryId,
                accountId: accountId,
                toAccountId: toAccountId,
                payee: payee,
                projectId: projectId,
                note: note,
                frequency: frequency,
                interval: interval,
                dayOfMonth: dayOfMonth,
                weekday: weekday,
                startDate: startDate,
                endDate: endDate,
                maxCount: maxCount,
                postedCount: postedCount,
                skippedCount: skippedCount,
                nextDue: nextDue,
                autoPost: autoPost,
                remindDaysBefore: remindDaysBefore,
                isSubscription: isSubscription,
                groupId: groupId,
                groupSplit: groupSplit,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String id,
                Value<String> name = const Value.absent(),
                required String kind,
                required int amountMinor,
                Value<String> currency = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<String?> toAccountId = const Value.absent(),
                Value<String?> payee = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<String> note = const Value.absent(),
                required String frequency,
                Value<int> interval = const Value.absent(),
                Value<int?> dayOfMonth = const Value.absent(),
                Value<int?> weekday = const Value.absent(),
                required DateTime startDate,
                Value<DateTime?> endDate = const Value.absent(),
                Value<int?> maxCount = const Value.absent(),
                Value<int> postedCount = const Value.absent(),
                Value<int> skippedCount = const Value.absent(),
                Value<DateTime?> nextDue = const Value.absent(),
                Value<bool> autoPost = const Value.absent(),
                Value<String> remindDaysBefore = const Value.absent(),
                Value<bool> isSubscription = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<String?> groupSplit = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecurringRulesCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                name: name,
                kind: kind,
                amountMinor: amountMinor,
                currency: currency,
                categoryId: categoryId,
                accountId: accountId,
                toAccountId: toAccountId,
                payee: payee,
                projectId: projectId,
                note: note,
                frequency: frequency,
                interval: interval,
                dayOfMonth: dayOfMonth,
                weekday: weekday,
                startDate: startDate,
                endDate: endDate,
                maxCount: maxCount,
                postedCount: postedCount,
                skippedCount: skippedCount,
                nextDue: nextDue,
                autoPost: autoPost,
                remindDaysBefore: remindDaysBefore,
                isSubscription: isSubscription,
                groupId: groupId,
                groupSplit: groupSplit,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecurringRulesTable, RecurringRule>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $RecurringRulesTable,
                    RecurringRule
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecurringRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecurringRulesTable,
      RecurringRule,
      $$RecurringRulesTableFilterComposer,
      $$RecurringRulesTableOrderingComposer,
      $$RecurringRulesTableAnnotationComposer,
      $$RecurringRulesTableCreateCompanionBuilder,
      $$RecurringRulesTableUpdateCompanionBuilder,
      (
        RecurringRule,
        BaseReferences<_$AppDatabase, $RecurringRulesTable, RecurringRule>,
      ),
      RecurringRule,
      PrefetchHooks Function()
    >;
typedef $$GroupActivitiesTableCreateCompanionBuilder =
    GroupActivitiesCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String id,
      required String groupId,
      required String action,
      required String subjectKind,
      required String subjectId,
      Value<String?> actorMemberId,
      required DateTime occurredAt,
      Value<String?> beforeJson,
      Value<String?> afterJson,
      Value<int> rowid,
    });
typedef $$GroupActivitiesTableUpdateCompanionBuilder =
    GroupActivitiesCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> id,
      Value<String> groupId,
      Value<String> action,
      Value<String> subjectKind,
      Value<String> subjectId,
      Value<String?> actorMemberId,
      Value<DateTime> occurredAt,
      Value<String?> beforeJson,
      Value<String?> afterJson,
      Value<int> rowid,
    });

class $$GroupActivitiesTableFilterComposer
    extends Composer<_$AppDatabase, $GroupActivitiesTable> {
  $$GroupActivitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subjectKind => $composableBuilder(
    column: $table.subjectKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorMemberId => $composableBuilder(
    column: $table.actorMemberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get beforeJson => $composableBuilder(
    column: $table.beforeJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get afterJson => $composableBuilder(
    column: $table.afterJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GroupActivitiesTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupActivitiesTable> {
  $$GroupActivitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjectKind => $composableBuilder(
    column: $table.subjectKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorMemberId => $composableBuilder(
    column: $table.actorMemberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get beforeJson => $composableBuilder(
    column: $table.beforeJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get afterJson => $composableBuilder(
    column: $table.afterJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GroupActivitiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupActivitiesTable> {
  $$GroupActivitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get subjectKind => $composableBuilder(
    column: $table.subjectKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subjectId =>
      $composableBuilder(column: $table.subjectId, builder: (column) => column);

  GeneratedColumn<String> get actorMemberId => $composableBuilder(
    column: $table.actorMemberId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get beforeJson => $composableBuilder(
    column: $table.beforeJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get afterJson =>
      $composableBuilder(column: $table.afterJson, builder: (column) => column);
}

class $$GroupActivitiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GroupActivitiesTable,
          GroupActivity,
          $$GroupActivitiesTableFilterComposer,
          $$GroupActivitiesTableOrderingComposer,
          $$GroupActivitiesTableAnnotationComposer,
          $$GroupActivitiesTableCreateCompanionBuilder,
          $$GroupActivitiesTableUpdateCompanionBuilder,
          (
            GroupActivity,
            BaseReferences<_$AppDatabase, $GroupActivitiesTable, GroupActivity>,
          ),
          GroupActivity,
          PrefetchHooks Function()
        > {
  $$GroupActivitiesTableTableManager(
    _$AppDatabase db,
    $GroupActivitiesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupActivitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupActivitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupActivitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> subjectKind = const Value.absent(),
                Value<String> subjectId = const Value.absent(),
                Value<String?> actorMemberId = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<String?> beforeJson = const Value.absent(),
                Value<String?> afterJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupActivitiesCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                groupId: groupId,
                action: action,
                subjectKind: subjectKind,
                subjectId: subjectId,
                actorMemberId: actorMemberId,
                occurredAt: occurredAt,
                beforeJson: beforeJson,
                afterJson: afterJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String id,
                required String groupId,
                required String action,
                required String subjectKind,
                required String subjectId,
                Value<String?> actorMemberId = const Value.absent(),
                required DateTime occurredAt,
                Value<String?> beforeJson = const Value.absent(),
                Value<String?> afterJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupActivitiesCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                groupId: groupId,
                action: action,
                subjectKind: subjectKind,
                subjectId: subjectId,
                actorMemberId: actorMemberId,
                occurredAt: occurredAt,
                beforeJson: beforeJson,
                afterJson: afterJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GroupActivitiesTable, GroupActivity>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $GroupActivitiesTable,
                    GroupActivity
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GroupActivitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GroupActivitiesTable,
      GroupActivity,
      $$GroupActivitiesTableFilterComposer,
      $$GroupActivitiesTableOrderingComposer,
      $$GroupActivitiesTableAnnotationComposer,
      $$GroupActivitiesTableCreateCompanionBuilder,
      $$GroupActivitiesTableUpdateCompanionBuilder,
      (
        GroupActivity,
        BaseReferences<_$AppDatabase, $GroupActivitiesTable, GroupActivity>,
      ),
      GroupActivity,
      PrefetchHooks Function()
    >;
typedef $$ItemAssignmentsTableCreateCompanionBuilder =
    ItemAssignmentsCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String id,
      required String entryItemId,
      required String memberId,
      Value<int> rowid,
    });
typedef $$ItemAssignmentsTableUpdateCompanionBuilder =
    ItemAssignmentsCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> id,
      Value<String> entryItemId,
      Value<String> memberId,
      Value<int> rowid,
    });

class $$ItemAssignmentsTableFilterComposer
    extends Composer<_$AppDatabase, $ItemAssignmentsTable> {
  $$ItemAssignmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entryItemId => $composableBuilder(
    column: $table.entryItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ItemAssignmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemAssignmentsTable> {
  $$ItemAssignmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entryItemId => $composableBuilder(
    column: $table.entryItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ItemAssignmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemAssignmentsTable> {
  $$ItemAssignmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entryItemId => $composableBuilder(
    column: $table.entryItemId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);
}

class $$ItemAssignmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemAssignmentsTable,
          ItemAssignment,
          $$ItemAssignmentsTableFilterComposer,
          $$ItemAssignmentsTableOrderingComposer,
          $$ItemAssignmentsTableAnnotationComposer,
          $$ItemAssignmentsTableCreateCompanionBuilder,
          $$ItemAssignmentsTableUpdateCompanionBuilder,
          (
            ItemAssignment,
            BaseReferences<
              _$AppDatabase,
              $ItemAssignmentsTable,
              ItemAssignment
            >,
          ),
          ItemAssignment,
          PrefetchHooks Function()
        > {
  $$ItemAssignmentsTableTableManager(
    _$AppDatabase db,
    $ItemAssignmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemAssignmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemAssignmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemAssignmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> entryItemId = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemAssignmentsCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                entryItemId: entryItemId,
                memberId: memberId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String id,
                required String entryItemId,
                required String memberId,
                Value<int> rowid = const Value.absent(),
              }) => ItemAssignmentsCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                entryItemId: entryItemId,
                memberId: memberId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ItemAssignmentsTable, ItemAssignment>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ItemAssignmentsTable,
                    ItemAssignment
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ItemAssignmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemAssignmentsTable,
      ItemAssignment,
      $$ItemAssignmentsTableFilterComposer,
      $$ItemAssignmentsTableOrderingComposer,
      $$ItemAssignmentsTableAnnotationComposer,
      $$ItemAssignmentsTableCreateCompanionBuilder,
      $$ItemAssignmentsTableUpdateCompanionBuilder,
      (
        ItemAssignment,
        BaseReferences<_$AppDatabase, $ItemAssignmentsTable, ItemAssignment>,
      ),
      ItemAssignment,
      PrefetchHooks Function()
    >;
typedef $$PayeeCategoriesTableCreateCompanionBuilder =
    PayeeCategoriesCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String id,
      required String payee,
      required String categoryId,
      Value<int> rowid,
    });
typedef $$PayeeCategoriesTableUpdateCompanionBuilder =
    PayeeCategoriesCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> id,
      Value<String> payee,
      Value<String> categoryId,
      Value<int> rowid,
    });

class $$PayeeCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $PayeeCategoriesTable> {
  $$PayeeCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payee => $composableBuilder(
    column: $table.payee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PayeeCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $PayeeCategoriesTable> {
  $$PayeeCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payee => $composableBuilder(
    column: $table.payee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PayeeCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PayeeCategoriesTable> {
  $$PayeeCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payee =>
      $composableBuilder(column: $table.payee, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );
}

class $$PayeeCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PayeeCategoriesTable,
          PayeeCategory,
          $$PayeeCategoriesTableFilterComposer,
          $$PayeeCategoriesTableOrderingComposer,
          $$PayeeCategoriesTableAnnotationComposer,
          $$PayeeCategoriesTableCreateCompanionBuilder,
          $$PayeeCategoriesTableUpdateCompanionBuilder,
          (
            PayeeCategory,
            BaseReferences<_$AppDatabase, $PayeeCategoriesTable, PayeeCategory>,
          ),
          PayeeCategory,
          PrefetchHooks Function()
        > {
  $$PayeeCategoriesTableTableManager(
    _$AppDatabase db,
    $PayeeCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PayeeCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PayeeCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PayeeCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> payee = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PayeeCategoriesCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                payee: payee,
                categoryId: categoryId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String id,
                required String payee,
                required String categoryId,
                Value<int> rowid = const Value.absent(),
              }) => PayeeCategoriesCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                payee: payee,
                categoryId: categoryId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PayeeCategoriesTable, PayeeCategory>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PayeeCategoriesTable,
                    PayeeCategory
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PayeeCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PayeeCategoriesTable,
      PayeeCategory,
      $$PayeeCategoriesTableFilterComposer,
      $$PayeeCategoriesTableOrderingComposer,
      $$PayeeCategoriesTableAnnotationComposer,
      $$PayeeCategoriesTableCreateCompanionBuilder,
      $$PayeeCategoriesTableUpdateCompanionBuilder,
      (
        PayeeCategory,
        BaseReferences<_$AppDatabase, $PayeeCategoriesTable, PayeeCategory>,
      ),
      PayeeCategory,
      PrefetchHooks Function()
    >;
typedef $$PeopleTableCreateCompanionBuilder = PeopleCompanion Function({
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required String id,
  required String name,
  required String email,
  Value<int> rowid,
});
typedef $$PeopleTableUpdateCompanionBuilder = PeopleCompanion Function({
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> id,
  Value<String> name,
  Value<String> email,
  Value<int> rowid,
});

class $$PeopleTableFilterComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PeopleTableOrderingComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PeopleTableAnnotationComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);
}

class $$PeopleTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PeopleTable,
          Person,
          $$PeopleTableFilterComposer,
          $$PeopleTableOrderingComposer,
          $$PeopleTableAnnotationComposer,
          $$PeopleTableCreateCompanionBuilder,
          $$PeopleTableUpdateCompanionBuilder,
          (Person, BaseReferences<_$AppDatabase, $PeopleTable, Person>),
          Person,
          PrefetchHooks Function()
        > {
  $$PeopleTableTableManager(_$AppDatabase db, $PeopleTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeopleTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeopleTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeopleTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PeopleCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                name: name,
                email: email,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String id,
                required String name,
                required String email,
                Value<int> rowid = const Value.absent(),
              }) => PeopleCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                name: name,
                email: email,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PeopleTable, Person>(table),
                  BaseReferences<_$AppDatabase, $PeopleTable, Person>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PeopleTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PeopleTable,
      Person,
      $$PeopleTableFilterComposer,
      $$PeopleTableOrderingComposer,
      $$PeopleTableAnnotationComposer,
      $$PeopleTableCreateCompanionBuilder,
      $$PeopleTableUpdateCompanionBuilder,
      (Person, BaseReferences<_$AppDatabase, $PeopleTable, Person>),
      Person,
      PrefetchHooks Function()
    >;
typedef $$QuickEntriesTableCreateCompanionBuilder =
    QuickEntriesCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String id,
      required String label,
      Value<String> kind,
      Value<int?> amountMinor,
      Value<String?> categoryId,
      Value<String?> accountId,
      Value<String?> payee,
      Value<String> note,
      Value<String> tags,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$QuickEntriesTableUpdateCompanionBuilder =
    QuickEntriesCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> id,
      Value<String> label,
      Value<String> kind,
      Value<int?> amountMinor,
      Value<String?> categoryId,
      Value<String?> accountId,
      Value<String?> payee,
      Value<String> note,
      Value<String> tags,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$QuickEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $QuickEntriesTable> {
  $$QuickEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payee => $composableBuilder(
    column: $table.payee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuickEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $QuickEntriesTable> {
  $$QuickEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payee => $composableBuilder(
    column: $table.payee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuickEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuickEntriesTable> {
  $$QuickEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get payee =>
      $composableBuilder(column: $table.payee, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$QuickEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuickEntriesTable,
          QuickEntry,
          $$QuickEntriesTableFilterComposer,
          $$QuickEntriesTableOrderingComposer,
          $$QuickEntriesTableAnnotationComposer,
          $$QuickEntriesTableCreateCompanionBuilder,
          $$QuickEntriesTableUpdateCompanionBuilder,
          (
            QuickEntry,
            BaseReferences<_$AppDatabase, $QuickEntriesTable, QuickEntry>,
          ),
          QuickEntry,
          PrefetchHooks Function()
        > {
  $$QuickEntriesTableTableManager(_$AppDatabase db, $QuickEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuickEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuickEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuickEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int?> amountMinor = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<String?> payee = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuickEntriesCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                label: label,
                kind: kind,
                amountMinor: amountMinor,
                categoryId: categoryId,
                accountId: accountId,
                payee: payee,
                note: note,
                tags: tags,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String id,
                required String label,
                Value<String> kind = const Value.absent(),
                Value<int?> amountMinor = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<String?> payee = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuickEntriesCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                label: label,
                kind: kind,
                amountMinor: amountMinor,
                categoryId: categoryId,
                accountId: accountId,
                payee: payee,
                note: note,
                tags: tags,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QuickEntriesTable, QuickEntry>(table),
                  BaseReferences<_$AppDatabase, $QuickEntriesTable, QuickEntry>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuickEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuickEntriesTable,
      QuickEntry,
      $$QuickEntriesTableFilterComposer,
      $$QuickEntriesTableOrderingComposer,
      $$QuickEntriesTableAnnotationComposer,
      $$QuickEntriesTableCreateCompanionBuilder,
      $$QuickEntriesTableUpdateCompanionBuilder,
      (
        QuickEntry,
        BaseReferences<_$AppDatabase, $QuickEntriesTable, QuickEntry>,
      ),
      QuickEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$EntriesTableTableManager get entries =>
      $$EntriesTableTableManager(_db, _db.entries);
  $$EntryItemsTableTableManager get entryItems =>
      $$EntryItemsTableTableManager(_db, _db.entryItems);
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db, _db.groups);
  $$MembersTableTableManager get members =>
      $$MembersTableTableManager(_db, _db.members);
  $$SplitsTableTableManager get splits =>
      $$SplitsTableTableManager(_db, _db.splits);
  $$SettlementsTableTableManager get settlements =>
      $$SettlementsTableTableManager(_db, _db.settlements);
  $$BudgetsTableTableManager get budgets =>
      $$BudgetsTableTableManager(_db, _db.budgets);
  $$SmsLogTableTableManager get smsLog =>
      $$SmsLogTableTableManager(_db, _db.smsLog);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
  $$ProjectFieldsTableTableManager get projectFields =>
      $$ProjectFieldsTableTableManager(_db, _db.projectFields);
  $$EntryFieldValuesTableTableManager get entryFieldValues =>
      $$EntryFieldValuesTableTableManager(_db, _db.entryFieldValues);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
  $$EntryPayersTableTableManager get entryPayers =>
      $$EntryPayersTableTableManager(_db, _db.entryPayers);
  $$RecurringRulesTableTableManager get recurringRules =>
      $$RecurringRulesTableTableManager(_db, _db.recurringRules);
  $$GroupActivitiesTableTableManager get groupActivities =>
      $$GroupActivitiesTableTableManager(_db, _db.groupActivities);
  $$ItemAssignmentsTableTableManager get itemAssignments =>
      $$ItemAssignmentsTableTableManager(_db, _db.itemAssignments);
  $$PayeeCategoriesTableTableManager get payeeCategories =>
      $$PayeeCategoriesTableTableManager(_db, _db.payeeCategories);
  $$PeopleTableTableManager get people =>
      $$PeopleTableTableManager(_db, _db.people);
  $$QuickEntriesTableTableManager get quickEntries =>
      $$QuickEntriesTableTableManager(_db, _db.quickEntries);
}
