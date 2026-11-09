// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SolicitudesLocalesTable extends SolicitudesLocales
    with TableInfo<$SolicitudesLocalesTable, SolicitudesLocale> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SolicitudesLocalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventoIdMeta = const VerificationMeta(
    'eventoId',
  );
  @override
  late final GeneratedColumn<String> eventoId = GeneratedColumn<String>(
    'evento_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usuarioUidMeta = const VerificationMeta(
    'usuarioUid',
  );
  @override
  late final GeneratedColumn<String> usuarioUid = GeneratedColumn<String>(
    'usuario_uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _estadoNegocioMeta = const VerificationMeta(
    'estadoNegocio',
  );
  @override
  late final GeneratedColumn<String> estadoNegocio = GeneratedColumn<String>(
    'estado_negocio',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _estadoSyncMeta = const VerificationMeta(
    'estadoSync',
  );
  @override
  late final GeneratedColumn<String> estadoSync = GeneratedColumn<String>(
    'estado_sync',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actualizadoEnMeta = const VerificationMeta(
    'actualizadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> actualizadoEn =
      GeneratedColumn<DateTime>(
        'actualizado_en',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _versionLocalMeta = const VerificationMeta(
    'versionLocal',
  );
  @override
  late final GeneratedColumn<int> versionLocal = GeneratedColumn<int>(
    'version_local',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ultimoErrorMeta = const VerificationMeta(
    'ultimoError',
  );
  @override
  late final GeneratedColumn<String> ultimoError = GeneratedColumn<String>(
    'ultimo_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    eventoId,
    usuarioUid,
    estadoNegocio,
    estadoSync,
    actualizadoEn,
    versionLocal,
    ultimoError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'solicitudes_locales';
  @override
  VerificationContext validateIntegrity(
    Insertable<SolicitudesLocale> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('evento_id')) {
      context.handle(
        _eventoIdMeta,
        eventoId.isAcceptableOrUnknown(data['evento_id']!, _eventoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventoIdMeta);
    }
    if (data.containsKey('usuario_uid')) {
      context.handle(
        _usuarioUidMeta,
        usuarioUid.isAcceptableOrUnknown(data['usuario_uid']!, _usuarioUidMeta),
      );
    } else if (isInserting) {
      context.missing(_usuarioUidMeta);
    }
    if (data.containsKey('estado_negocio')) {
      context.handle(
        _estadoNegocioMeta,
        estadoNegocio.isAcceptableOrUnknown(
          data['estado_negocio']!,
          _estadoNegocioMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_estadoNegocioMeta);
    }
    if (data.containsKey('estado_sync')) {
      context.handle(
        _estadoSyncMeta,
        estadoSync.isAcceptableOrUnknown(data['estado_sync']!, _estadoSyncMeta),
      );
    } else if (isInserting) {
      context.missing(_estadoSyncMeta);
    }
    if (data.containsKey('actualizado_en')) {
      context.handle(
        _actualizadoEnMeta,
        actualizadoEn.isAcceptableOrUnknown(
          data['actualizado_en']!,
          _actualizadoEnMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_actualizadoEnMeta);
    }
    if (data.containsKey('version_local')) {
      context.handle(
        _versionLocalMeta,
        versionLocal.isAcceptableOrUnknown(
          data['version_local']!,
          _versionLocalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_versionLocalMeta);
    }
    if (data.containsKey('ultimo_error')) {
      context.handle(
        _ultimoErrorMeta,
        ultimoError.isAcceptableOrUnknown(
          data['ultimo_error']!,
          _ultimoErrorMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SolicitudesLocale map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SolicitudesLocale(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      eventoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}evento_id'],
      )!,
      usuarioUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}usuario_uid'],
      )!,
      estadoNegocio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estado_negocio'],
      )!,
      estadoSync: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estado_sync'],
      )!,
      actualizadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}actualizado_en'],
      )!,
      versionLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version_local'],
      )!,
      ultimoError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ultimo_error'],
      ),
    );
  }

  @override
  $SolicitudesLocalesTable createAlias(String alias) {
    return $SolicitudesLocalesTable(attachedDatabase, alias);
  }
}

class SolicitudesLocale extends DataClass
    implements Insertable<SolicitudesLocale> {
  final String id;
  final String eventoId;
  final String usuarioUid;
  final String estadoNegocio;
  final String estadoSync;
  final DateTime actualizadoEn;
  final int versionLocal;
  final String? ultimoError;
  const SolicitudesLocale({
    required this.id,
    required this.eventoId,
    required this.usuarioUid,
    required this.estadoNegocio,
    required this.estadoSync,
    required this.actualizadoEn,
    required this.versionLocal,
    this.ultimoError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['evento_id'] = Variable<String>(eventoId);
    map['usuario_uid'] = Variable<String>(usuarioUid);
    map['estado_negocio'] = Variable<String>(estadoNegocio);
    map['estado_sync'] = Variable<String>(estadoSync);
    map['actualizado_en'] = Variable<DateTime>(actualizadoEn);
    map['version_local'] = Variable<int>(versionLocal);
    if (!nullToAbsent || ultimoError != null) {
      map['ultimo_error'] = Variable<String>(ultimoError);
    }
    return map;
  }

  SolicitudesLocalesCompanion toCompanion(bool nullToAbsent) {
    return SolicitudesLocalesCompanion(
      id: Value(id),
      eventoId: Value(eventoId),
      usuarioUid: Value(usuarioUid),
      estadoNegocio: Value(estadoNegocio),
      estadoSync: Value(estadoSync),
      actualizadoEn: Value(actualizadoEn),
      versionLocal: Value(versionLocal),
      ultimoError: ultimoError == null && nullToAbsent
          ? const Value.absent()
          : Value(ultimoError),
    );
  }

  factory SolicitudesLocale.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SolicitudesLocale(
      id: serializer.fromJson<String>(json['id']),
      eventoId: serializer.fromJson<String>(json['eventoId']),
      usuarioUid: serializer.fromJson<String>(json['usuarioUid']),
      estadoNegocio: serializer.fromJson<String>(json['estadoNegocio']),
      estadoSync: serializer.fromJson<String>(json['estadoSync']),
      actualizadoEn: serializer.fromJson<DateTime>(json['actualizadoEn']),
      versionLocal: serializer.fromJson<int>(json['versionLocal']),
      ultimoError: serializer.fromJson<String?>(json['ultimoError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'eventoId': serializer.toJson<String>(eventoId),
      'usuarioUid': serializer.toJson<String>(usuarioUid),
      'estadoNegocio': serializer.toJson<String>(estadoNegocio),
      'estadoSync': serializer.toJson<String>(estadoSync),
      'actualizadoEn': serializer.toJson<DateTime>(actualizadoEn),
      'versionLocal': serializer.toJson<int>(versionLocal),
      'ultimoError': serializer.toJson<String?>(ultimoError),
    };
  }

  SolicitudesLocale copyWith({
    String? id,
    String? eventoId,
    String? usuarioUid,
    String? estadoNegocio,
    String? estadoSync,
    DateTime? actualizadoEn,
    int? versionLocal,
    Value<String?> ultimoError = const Value.absent(),
  }) => SolicitudesLocale(
    id: id ?? this.id,
    eventoId: eventoId ?? this.eventoId,
    usuarioUid: usuarioUid ?? this.usuarioUid,
    estadoNegocio: estadoNegocio ?? this.estadoNegocio,
    estadoSync: estadoSync ?? this.estadoSync,
    actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    versionLocal: versionLocal ?? this.versionLocal,
    ultimoError: ultimoError.present ? ultimoError.value : this.ultimoError,
  );
  SolicitudesLocale copyWithCompanion(SolicitudesLocalesCompanion data) {
    return SolicitudesLocale(
      id: data.id.present ? data.id.value : this.id,
      eventoId: data.eventoId.present ? data.eventoId.value : this.eventoId,
      usuarioUid: data.usuarioUid.present
          ? data.usuarioUid.value
          : this.usuarioUid,
      estadoNegocio: data.estadoNegocio.present
          ? data.estadoNegocio.value
          : this.estadoNegocio,
      estadoSync: data.estadoSync.present
          ? data.estadoSync.value
          : this.estadoSync,
      actualizadoEn: data.actualizadoEn.present
          ? data.actualizadoEn.value
          : this.actualizadoEn,
      versionLocal: data.versionLocal.present
          ? data.versionLocal.value
          : this.versionLocal,
      ultimoError: data.ultimoError.present
          ? data.ultimoError.value
          : this.ultimoError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SolicitudesLocale(')
          ..write('id: $id, ')
          ..write('eventoId: $eventoId, ')
          ..write('usuarioUid: $usuarioUid, ')
          ..write('estadoNegocio: $estadoNegocio, ')
          ..write('estadoSync: $estadoSync, ')
          ..write('actualizadoEn: $actualizadoEn, ')
          ..write('versionLocal: $versionLocal, ')
          ..write('ultimoError: $ultimoError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    eventoId,
    usuarioUid,
    estadoNegocio,
    estadoSync,
    actualizadoEn,
    versionLocal,
    ultimoError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SolicitudesLocale &&
          other.id == this.id &&
          other.eventoId == this.eventoId &&
          other.usuarioUid == this.usuarioUid &&
          other.estadoNegocio == this.estadoNegocio &&
          other.estadoSync == this.estadoSync &&
          other.actualizadoEn == this.actualizadoEn &&
          other.versionLocal == this.versionLocal &&
          other.ultimoError == this.ultimoError);
}

class SolicitudesLocalesCompanion extends UpdateCompanion<SolicitudesLocale> {
  final Value<String> id;
  final Value<String> eventoId;
  final Value<String> usuarioUid;
  final Value<String> estadoNegocio;
  final Value<String> estadoSync;
  final Value<DateTime> actualizadoEn;
  final Value<int> versionLocal;
  final Value<String?> ultimoError;
  final Value<int> rowid;
  const SolicitudesLocalesCompanion({
    this.id = const Value.absent(),
    this.eventoId = const Value.absent(),
    this.usuarioUid = const Value.absent(),
    this.estadoNegocio = const Value.absent(),
    this.estadoSync = const Value.absent(),
    this.actualizadoEn = const Value.absent(),
    this.versionLocal = const Value.absent(),
    this.ultimoError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SolicitudesLocalesCompanion.insert({
    required String id,
    required String eventoId,
    required String usuarioUid,
    required String estadoNegocio,
    required String estadoSync,
    required DateTime actualizadoEn,
    required int versionLocal,
    this.ultimoError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       eventoId = Value(eventoId),
       usuarioUid = Value(usuarioUid),
       estadoNegocio = Value(estadoNegocio),
       estadoSync = Value(estadoSync),
       actualizadoEn = Value(actualizadoEn),
       versionLocal = Value(versionLocal);
  static Insertable<SolicitudesLocale> custom({
    Expression<String>? id,
    Expression<String>? eventoId,
    Expression<String>? usuarioUid,
    Expression<String>? estadoNegocio,
    Expression<String>? estadoSync,
    Expression<DateTime>? actualizadoEn,
    Expression<int>? versionLocal,
    Expression<String>? ultimoError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventoId != null) 'evento_id': eventoId,
      if (usuarioUid != null) 'usuario_uid': usuarioUid,
      if (estadoNegocio != null) 'estado_negocio': estadoNegocio,
      if (estadoSync != null) 'estado_sync': estadoSync,
      if (actualizadoEn != null) 'actualizado_en': actualizadoEn,
      if (versionLocal != null) 'version_local': versionLocal,
      if (ultimoError != null) 'ultimo_error': ultimoError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SolicitudesLocalesCompanion copyWith({
    Value<String>? id,
    Value<String>? eventoId,
    Value<String>? usuarioUid,
    Value<String>? estadoNegocio,
    Value<String>? estadoSync,
    Value<DateTime>? actualizadoEn,
    Value<int>? versionLocal,
    Value<String?>? ultimoError,
    Value<int>? rowid,
  }) {
    return SolicitudesLocalesCompanion(
      id: id ?? this.id,
      eventoId: eventoId ?? this.eventoId,
      usuarioUid: usuarioUid ?? this.usuarioUid,
      estadoNegocio: estadoNegocio ?? this.estadoNegocio,
      estadoSync: estadoSync ?? this.estadoSync,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
      versionLocal: versionLocal ?? this.versionLocal,
      ultimoError: ultimoError ?? this.ultimoError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (eventoId.present) {
      map['evento_id'] = Variable<String>(eventoId.value);
    }
    if (usuarioUid.present) {
      map['usuario_uid'] = Variable<String>(usuarioUid.value);
    }
    if (estadoNegocio.present) {
      map['estado_negocio'] = Variable<String>(estadoNegocio.value);
    }
    if (estadoSync.present) {
      map['estado_sync'] = Variable<String>(estadoSync.value);
    }
    if (actualizadoEn.present) {
      map['actualizado_en'] = Variable<DateTime>(actualizadoEn.value);
    }
    if (versionLocal.present) {
      map['version_local'] = Variable<int>(versionLocal.value);
    }
    if (ultimoError.present) {
      map['ultimo_error'] = Variable<String>(ultimoError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SolicitudesLocalesCompanion(')
          ..write('id: $id, ')
          ..write('eventoId: $eventoId, ')
          ..write('usuarioUid: $usuarioUid, ')
          ..write('estadoNegocio: $estadoNegocio, ')
          ..write('estadoSync: $estadoSync, ')
          ..write('actualizadoEn: $actualizadoEn, ')
          ..write('versionLocal: $versionLocal, ')
          ..write('ultimoError: $ultimoError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SolicitudesLocalesTable solicitudesLocales =
      $SolicitudesLocalesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [solicitudesLocales];
}

typedef $$SolicitudesLocalesTableCreateCompanionBuilder =
    SolicitudesLocalesCompanion Function({
      required String id,
      required String eventoId,
      required String usuarioUid,
      required String estadoNegocio,
      required String estadoSync,
      required DateTime actualizadoEn,
      required int versionLocal,
      Value<String?> ultimoError,
      Value<int> rowid,
    });
typedef $$SolicitudesLocalesTableUpdateCompanionBuilder =
    SolicitudesLocalesCompanion Function({
      Value<String> id,
      Value<String> eventoId,
      Value<String> usuarioUid,
      Value<String> estadoNegocio,
      Value<String> estadoSync,
      Value<DateTime> actualizadoEn,
      Value<int> versionLocal,
      Value<String?> ultimoError,
      Value<int> rowid,
    });

class $$SolicitudesLocalesTableFilterComposer
    extends Composer<_$AppDatabase, $SolicitudesLocalesTable> {
  $$SolicitudesLocalesTableFilterComposer({
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

  ColumnFilters<String> get eventoId => $composableBuilder(
    column: $table.eventoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get usuarioUid => $composableBuilder(
    column: $table.usuarioUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get estadoNegocio => $composableBuilder(
    column: $table.estadoNegocio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get estadoSync => $composableBuilder(
    column: $table.estadoSync,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get versionLocal => $composableBuilder(
    column: $table.versionLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ultimoError => $composableBuilder(
    column: $table.ultimoError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SolicitudesLocalesTableOrderingComposer
    extends Composer<_$AppDatabase, $SolicitudesLocalesTable> {
  $$SolicitudesLocalesTableOrderingComposer({
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

  ColumnOrderings<String> get eventoId => $composableBuilder(
    column: $table.eventoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get usuarioUid => $composableBuilder(
    column: $table.usuarioUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estadoNegocio => $composableBuilder(
    column: $table.estadoNegocio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estadoSync => $composableBuilder(
    column: $table.estadoSync,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get versionLocal => $composableBuilder(
    column: $table.versionLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ultimoError => $composableBuilder(
    column: $table.ultimoError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SolicitudesLocalesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SolicitudesLocalesTable> {
  $$SolicitudesLocalesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventoId =>
      $composableBuilder(column: $table.eventoId, builder: (column) => column);

  GeneratedColumn<String> get usuarioUid => $composableBuilder(
    column: $table.usuarioUid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get estadoNegocio => $composableBuilder(
    column: $table.estadoNegocio,
    builder: (column) => column,
  );

  GeneratedColumn<String> get estadoSync => $composableBuilder(
    column: $table.estadoSync,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => column,
  );

  GeneratedColumn<int> get versionLocal => $composableBuilder(
    column: $table.versionLocal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ultimoError => $composableBuilder(
    column: $table.ultimoError,
    builder: (column) => column,
  );
}

class $$SolicitudesLocalesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SolicitudesLocalesTable,
          SolicitudesLocale,
          $$SolicitudesLocalesTableFilterComposer,
          $$SolicitudesLocalesTableOrderingComposer,
          $$SolicitudesLocalesTableAnnotationComposer,
          $$SolicitudesLocalesTableCreateCompanionBuilder,
          $$SolicitudesLocalesTableUpdateCompanionBuilder,
          (
            SolicitudesLocale,
            BaseReferences<
              _$AppDatabase,
              $SolicitudesLocalesTable,
              SolicitudesLocale
            >,
          ),
          SolicitudesLocale,
          PrefetchHooks Function()
        > {
  $$SolicitudesLocalesTableTableManager(
    _$AppDatabase db,
    $SolicitudesLocalesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SolicitudesLocalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SolicitudesLocalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SolicitudesLocalesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> eventoId = const Value.absent(),
                Value<String> usuarioUid = const Value.absent(),
                Value<String> estadoNegocio = const Value.absent(),
                Value<String> estadoSync = const Value.absent(),
                Value<DateTime> actualizadoEn = const Value.absent(),
                Value<int> versionLocal = const Value.absent(),
                Value<String?> ultimoError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SolicitudesLocalesCompanion(
                id: id,
                eventoId: eventoId,
                usuarioUid: usuarioUid,
                estadoNegocio: estadoNegocio,
                estadoSync: estadoSync,
                actualizadoEn: actualizadoEn,
                versionLocal: versionLocal,
                ultimoError: ultimoError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String eventoId,
                required String usuarioUid,
                required String estadoNegocio,
                required String estadoSync,
                required DateTime actualizadoEn,
                required int versionLocal,
                Value<String?> ultimoError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SolicitudesLocalesCompanion.insert(
                id: id,
                eventoId: eventoId,
                usuarioUid: usuarioUid,
                estadoNegocio: estadoNegocio,
                estadoSync: estadoSync,
                actualizadoEn: actualizadoEn,
                versionLocal: versionLocal,
                ultimoError: ultimoError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SolicitudesLocalesTable, SolicitudesLocale>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $SolicitudesLocalesTable,
                    SolicitudesLocale
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SolicitudesLocalesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SolicitudesLocalesTable,
      SolicitudesLocale,
      $$SolicitudesLocalesTableFilterComposer,
      $$SolicitudesLocalesTableOrderingComposer,
      $$SolicitudesLocalesTableAnnotationComposer,
      $$SolicitudesLocalesTableCreateCompanionBuilder,
      $$SolicitudesLocalesTableUpdateCompanionBuilder,
      (
        SolicitudesLocale,
        BaseReferences<
          _$AppDatabase,
          $SolicitudesLocalesTable,
          SolicitudesLocale
        >,
      ),
      SolicitudesLocale,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SolicitudesLocalesTableTableManager get solicitudesLocales =>
      $$SolicitudesLocalesTableTableManager(_db, _db.solicitudesLocales);
}
