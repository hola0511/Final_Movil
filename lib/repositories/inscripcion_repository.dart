import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../database/app_database.dart';
import '../models/inscripcion.dart';

class InscripcionRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AppDatabase _local = AppDatabase.instance;

  static final Set<String> _sincronizando = {};

  String get _uid {
    final usuario = _auth.currentUser;

    if (usuario == null) {
      throw StateError('Debes iniciar sesión');
    }

    return usuario.uid;
  }

  String _idInscripcion(String eventoId, String uid) {
    return '${eventoId}_$uid';
  }

  Stream<List<SolicitudesLocale>> observarSolicitudesLocales() {
    return _local.observarSolicitudes(_uid);
  }

  Future<void> confirmarInscripcion(String eventoId) async {
    final uid = _uid;
    final id = _idInscripcion(eventoId, uid);

    // Se registra localmente antes de intentar Firestore.
    await _local.guardarSolicitud(id: id, eventoId: eventoId, usuarioUid: uid);

    // Se intenta sincronizar. Si no hay Internet,
    // la solicitud permanece guardada en SQLite.
    await sincronizarPendientes();
  }

  Future<void> sincronizarPendientes() async {
    final uid = _uid;

    // Impide ejecutar dos sincronizaciones al mismo
    // tiempo para el mismo usuario.
    if (!_sincronizando.add(uid)) return;

    try {
      final registros = await _local.pendientes(uid);

      for (final registro in registros) {
        // Si se cambió de cuenta, no enviar datos
        // del usuario anterior.
        if (_auth.currentUser?.uid != uid) {
          break;
        }

        await _sincronizarUno(registro, uid);
      }
    } finally {
      _sincronizando.remove(uid);
    }
  }

  Future<void> _sincronizarUno(SolicitudesLocale registro, String uid) async {
    try {
      await _confirmarRemotamente(registro.eventoId, uid);

      if (_auth.currentUser?.uid != uid) return;

      await _local.actualizarResultado(
        id: registro.id,
        versionEsperada: registro.versionLocal,
        estadoNegocio: 'CONFIRMADA',
        estadoSync: 'SINCRONIZADO',
      );
    } on FirebaseException catch (error) {
      if (_auth.currentUser?.uid != uid) return;

      if (error.code == 'unavailable' ||
          error.code == 'deadline-exceeded' ||
          error.code == 'network-request-failed' ||
          error.code == 'aborted') {
        await _local.actualizarResultado(
          id: registro.id,
          versionEsperada: registro.versionLocal,
          estadoNegocio: 'SOLICITADA',
          estadoSync: 'PENDIENTE',
          error:
              'No se pudo conectar con Firestore. '
              'Puedes reintentar.',
        );
      } else if (error.code == 'permission-denied' ||
          error.code == 'failed-precondition' ||
          error.code == 'not-found') {
        await _local.actualizarResultado(
          id: registro.id,
          versionEsperada: registro.versionLocal,
          estadoNegocio: 'SOLICITADA',
          estadoSync: 'CONFLICTO',
          error: 'Operación rechazada: ${error.code}',
        );
      } else {
        await _local.actualizarResultado(
          id: registro.id,
          versionEsperada: registro.versionLocal,
          estadoNegocio: 'SOLICITADA',
          estadoSync: 'PENDIENTE',
          error: 'Error temporal: ${error.code}',
        );
      }
    } on StateError catch (error) {
      if (_auth.currentUser?.uid != uid) return;

      await _local.actualizarResultado(
        id: registro.id,
        versionEsperada: registro.versionLocal,
        estadoNegocio: 'SOLICITADA',
        estadoSync: 'CONFLICTO',
        error: error.message.toString(),
      );
    } catch (_) {
      if (_auth.currentUser?.uid != uid) return;

      await _local.actualizarResultado(
        id: registro.id,
        versionEsperada: registro.versionLocal,
        estadoNegocio: 'SOLICITADA',
        estadoSync: 'PENDIENTE',
        error:
            'No se completó el envío. '
            'Comprueba la conexión y reintenta.',
      );
    }
  }

  Future<void> _confirmarRemotamente(String eventoId, String uid) async {
    final eventoRef = _db.collection('eventos').doc(eventoId);

    final inscripcionRef = _db
        .collection('inscripciones')
        .doc(_idInscripcion(eventoId, uid));

    await _db.runTransaction((tx) async {
      // Todas las lecturas van antes de escribir.
      final eventoSnap = await tx.get(eventoRef);
      final inscripcionSnap = await tx.get(inscripcionRef);

      if (!eventoSnap.exists) {
        throw StateError('El evento ya no existe');
      }

      // Idempotencia:
      // Si una confirmación anterior tuvo éxito,
      // no incrementamos el contador otra vez.
      if (inscripcionSnap.exists) {
        final datos = inscripcionSnap.data()!;

        if (datos['eventoId'] == eventoId &&
            datos['participanteUid'] == uid &&
            datos['estado'] == 'CONFIRMADA') {
          return;
        }

        throw StateError(
          'Ya existe un registro para este evento. '
          'No se puede crear una nueva inscripción.',
        );
      }

      final evento = eventoSnap.data()!;

      final estado = evento['estado'] as String;
      final capacidad = evento['capacidad'] as int;
      final confirmados = evento['confirmados'] as int;
      final inicio = (evento['inicio'] as Timestamp).toDate();

      if (estado != 'ABIERTO') {
        throw StateError('Las inscripciones están cerradas');
      }

      if (!inicio.isAfter(DateTime.now())) {
        throw StateError('El evento ya comenzó');
      }

      if (confirmados >= capacidad) {
        throw StateError('No quedan cupos disponibles');
      }

      tx.set(inscripcionRef, {
        'eventoId': eventoId,
        'participanteUid': uid,
        'estado': 'CONFIRMADA',
        'fechaConfirmacion': FieldValue.serverTimestamp(),
        'fechaCancelacion': null,
      });

      tx.update(eventoRef, {
        'confirmados': confirmados + 1,
        'ultimaOperacionUid': uid,
        'ultimaOperacionTipo': 'CONFIRMAR',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> cancelarInscripcion(String eventoId) async {
    final uid = _uid;

    final eventoRef = _db.collection('eventos').doc(eventoId);

    final inscripcionRef = _db
        .collection('inscripciones')
        .doc(_idInscripcion(eventoId, uid));

    await _db.runTransaction((tx) async {
      final eventoSnap = await tx.get(eventoRef);
      final inscripcionSnap = await tx.get(inscripcionRef);

      if (!eventoSnap.exists || !inscripcionSnap.exists) {
        throw StateError('Inscripción no encontrada');
      }

      final evento = eventoSnap.data()!;
      final inscripcion = inscripcionSnap.data()!;

      if (inscripcion['participanteUid'] != uid) {
        throw StateError('La inscripción no te pertenece');
      }

      if (inscripcion['estado'] != 'CONFIRMADA') {
        throw StateError(
          'Solo puedes cancelar '
          'inscripciones confirmadas',
        );
      }

      if (evento['estado'] == 'FINALIZADO') {
        throw StateError('El evento ya finalizó');
      }

      final inicio = (evento['inicio'] as Timestamp).toDate();

      final limite = inicio.subtract(const Duration(hours: 1));

      if (DateTime.now().isAfter(limite)) {
        throw StateError(
          'Solo puedes cancelar hasta '
          'una hora antes del evento',
        );
      }

      final confirmados = evento['confirmados'] as int;

      if (confirmados <= 0) {
        throw StateError('Contador de cupos inconsistente');
      }

      tx.update(inscripcionRef, {
        'estado': 'CANCELADA',
        'fechaCancelacion': FieldValue.serverTimestamp(),
      });

      tx.update(eventoRef, {
        'confirmados': confirmados - 1,
        'ultimaOperacionUid': uid,
        'ultimaOperacionTipo': 'CANCELAR',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<List<Inscripcion>> misInscripciones() {
    final uid = _uid;

    return _db
        .collection('inscripciones')
        .where('participanteUid', isEqualTo: uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(Inscripcion.desdeFirestore).toList(),
        );
  }

  Future<void> descartarConflicto(String id) async {
    await _local.eliminarIntentoFallido(id: id, uid: _uid);
  }
}
