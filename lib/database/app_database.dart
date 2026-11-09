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

  // Devuelve exclusivamente los registros
  // del usuario autenticado.
  Stream<List<SolicitudesLocale>> observarSolicitudes(String uid) {
    return (select(solicitudesLocales)
          ..where((t) => t.usuarioUid.equals(uid))
          ..orderBy([(t) => OrderingTerm.desc(t.actualizadoEn)]))
        .watch();
  }

  Future<SolicitudesLocale?> obtener(String id) {
    return (select(
      solicitudesLocales,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  // Se ejecuta como una transacción local para
  // impedir que dos pulsaciones simultáneas
  // creen la misma solicitud.
  Future<void> guardarSolicitud({
    required String id,
    required String eventoId,
    required String usuarioUid,
  }) async {
    await transaction(() async {
      final existente = await obtener(id);

      if (existente != null) {
        if (existente.usuarioUid != usuarioUid) {
          throw StateError('La solicitud pertenece a otra cuenta');
        }

        if (existente.estadoSync == 'PENDIENTE') {
          // La solicitud ya existe.
          // Se reutiliza para sincronizar.
          return;
        }

        if (existente.estadoSync == 'CONFLICTO') {
          throw StateError(
            'Esta solicitud tiene un conflicto. '
            'Consulta Mis inscripciones.',
          );
        }

        throw StateError(
          'Ya existe una solicitud procesada '
          'para este evento.',
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
    });
  }

  Future<List<SolicitudesLocale>> pendientes(String uid) {
    return (select(solicitudesLocales)
          ..where(
            (t) => t.usuarioUid.equals(uid) & t.estadoSync.equals('PENDIENTE'),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.actualizadoEn)]))
        .get();
  }

  // Actualiza únicamente la versión exacta
  // con la que comenzó la sincronización.
  // Así una respuesta antigua no sobrescribe
  // una modificación local más reciente.
  Future<bool> actualizarResultado({
    required String id,
    required int versionEsperada,
    required String estadoNegocio,
    required String estadoSync,
    String? error,
  }) async {
    final actualizados =
        await (update(solicitudesLocales)..where(
              (t) => t.id.equals(id) & t.versionLocal.equals(versionEsperada),
            ))
            .write(
              SolicitudesLocalesCompanion(
                estadoNegocio: Value(estadoNegocio),
                estadoSync: Value(estadoSync),
                actualizadoEn: Value(DateTime.now()),
                versionLocal: Value(versionEsperada + 1),
                ultimoError: Value(error),
              ),
            );

    return actualizados == 1;
  }

  // Cuando Firestore confirma una cancelación,
  // actualizamos el estado local si existe.
  Future<void> registrarCancelacion({
    required String id,
    required String uid,
  }) async {
    await (update(solicitudesLocales)..where(
          (t) =>
              t.id.equals(id) &
              t.usuarioUid.equals(uid) &
              t.estadoSync.equals('SINCRONIZADO'),
        ))
        .write(
          SolicitudesLocalesCompanion(
            estadoNegocio: const Value('CANCELADA'),
            actualizadoEn: Value(DateTime.now()),
            ultimoError: const Value(null),
          ),
        );
  }

  // Refleja otros estados remotos solamente
  // sobre solicitudes que ya están sincronizadas.
  // Nunca reemplaza una solicitud pendiente.
  Future<void> reflejarEstadoRemoto({
    required String id,
    required String uid,
    required String estado,
  }) async {
    final registro = await obtener(id);

    if (registro == null ||
        registro.usuarioUid != uid ||
        registro.estadoSync != 'SINCRONIZADO' ||
        registro.estadoNegocio == estado) {
      return;
    }

    await (update(solicitudesLocales)..where(
          (t) =>
              t.id.equals(id) &
              t.usuarioUid.equals(uid) &
              t.estadoSync.equals('SINCRONIZADO'),
        ))
        .write(
          SolicitudesLocalesCompanion(
            estadoNegocio: Value(estado),
            actualizadoEn: Value(DateTime.now()),
          ),
        );
  }

  // Se conserva la solicitud rechazada.
  // No se elimina el conflicto automáticamente.
  Future<void> registrarConflicto({
    required String id,
    required int versionEsperada,
    required String motivo,
  }) async {
    await actualizarResultado(
      id: id,
      versionEsperada: versionEsperada,
      estadoNegocio: 'SOLICITADA',
      estadoSync: 'CONFLICTO',
      error: motivo,
    );
  }
}
