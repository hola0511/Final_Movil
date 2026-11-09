import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class SolicitudesLocales extends Table {
  TextColumn get id => text()();

  TextColumn get eventoId => text()();

  TextColumn get usuarioUid => text()();

  TextColumn get estadoNegocio => text()();

  TextColumn get estadoSync => text()();

  DateTimeColumn get actualizadoEn => dateTime()();

  IntColumn get versionLocal => integer()();

  TextColumn get ultimoError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [SolicitudesLocales])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(driftDatabase(name: 'eventos_g62_5_local'));

  static final AppDatabase instance = AppDatabase._();

  @override
  int get schemaVersion => 1;

  Stream<List<SolicitudesLocale>> observarSolicitudes(String uid) {
    return (select(solicitudesLocales)
          ..where((t) => t.usuarioUid.equals(uid))
          ..orderBy([(t) => OrderingTerm.desc(t.actualizadoEn)]))
        .watch();
  }

  Future<List<SolicitudesLocale>> pendientes(String uid) {
    return (select(solicitudesLocales)..where(
          (t) => t.usuarioUid.equals(uid) & t.estadoSync.equals('PENDIENTE'),
        ))
        .get();
  }

  Future<SolicitudesLocale?> obtener(String id) {
    return (select(
      solicitudesLocales,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> guardarSolicitud({
    required String id,
    required String eventoId,
    required String usuarioUid,
  }) async {
    final existente = await obtener(id);

    if (existente != null) {
      throw StateError(
        'Ya existe una solicitud local '
        'para este evento',
      );
    }

    await into(solicitudesLocales).insert(
      SolicitudesLocalesCompanion.insert(
        id: id,
        eventoId: eventoId,
        usuarioUid: usuarioUid,
        estadoNegocio: 'SOLICITADA',
        estadoSync: 'PENDIENTE',
        actualizadoEn: DateTime.now(),
        versionLocal: 1,
        ultimoError: const Value(null),
      ),
    );
  }

  Future<void> actualizarResultado({
    required String id,
    required int versionEsperada,
    required String estadoNegocio,
    required String estadoSync,
    String? error,
  }) async {
    await (update(solicitudesLocales)..where(
          (t) => t.id.equals(id) & t.versionLocal.equals(versionEsperada),
        ))
        .write(
          SolicitudesLocalesCompanion(
            estadoNegocio: Value(estadoNegocio),
            estadoSync: Value(estadoSync),
            actualizadoEn: Value(DateTime.now()),
            ultimoError: Value(error),
          ),
        );
  }

  Future<void> eliminarIntentoFallido({
    required String id,
    required String uid,
  }) async {
    await (delete(solicitudesLocales)..where(
          (t) =>
              t.id.equals(id) &
              t.usuarioUid.equals(uid) &
              t.estadoSync.equals('CONFLICTO'),
        ))
        .go();
  }
}
