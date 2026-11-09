import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../database/app_database.dart';
import '../models/inscripcion.dart';

class InscripcionRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AppDatabase _local = AppDatabase.instance;

  // Impide sincronizaciones simultáneas
  // del mismo usuario dentro de esta aplicación.
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

  // LOCAL-FIRST:
  // La operación termina después de guardar
  // en SQLite, sin esperar a Firestore.
  Future<void> confirmarInscripcion(String eventoId) async {
    final uid = _uid;

    final id = _idInscripcion(eventoId, uid);

    await _local.guardarSolicitud(id: id, eventoId: eventoId, usuarioUid: uid);

    // No bloqueamos la interfaz esperando la red.
    // Los errores se registran en SQLite.
    unawaited(_sincronizarSinPropagar());
  }

  Future<void> _sincronizarSinPropagar() async {
    try {
      await sincronizarPendientes();
    } catch (_) {
      // Una futura apertura de Mis inscripciones
      // podrá reintentar las solicitudes pendientes.
    }
  }

  Future<void> sincronizarPendientes() async {
    final uid = _uid;

    if (!_sincronizando.add(uid)) {
      return;
    }

    try {
      final pendientes = await _local.pendientes(uid);

      for (final solicitud in pendientes) {
        if (_auth.currentUser?.uid != uid) {
          break;
        }

        // Releemos el registro para comprobar
        // que sigue pendiente y sin cambios.
        final actual = await _local.obtener(solicitud.id);

        if (actual == null ||
            actual.usuarioUid != uid ||
            actual.estadoSync != 'PENDIENTE') {
          continue;
        }

        await _sincronizarUno(actual, uid);
      }
    } finally {
      _sincronizando.remove(uid);
    }
  }

  Future<void> _sincronizarUno(SolicitudesLocale solicitud, String uid) async {
    try {
      // Retorna el estado real de Firestore.
      // Puede ser una inscripción previamente
      // confirmada, o un estado posterior.
      final estadoRemoto = await _confirmarRemotamente(solicitud.eventoId, uid);

      if (_auth.currentUser?.uid != uid) {
        return;
      }

      await _local.actualizarResultado(
        id: solicitud.id,
        versionEsperada: solicitud.versionLocal,
        estadoNegocio: estadoRemoto,
        estadoSync: 'SINCRONIZADO',
      );
    } on StateError catch (error) {
      if (_auth.currentUser?.uid != uid) {
        return;
      }

      await _local.registrarConflicto(
        id: solicitud.id,
        versionEsperada: solicitud.versionLocal,
        motivo: error.message.toString(),
      );
    } on FirebaseException catch (error) {
      if (_auth.currentUser?.uid != uid) {
        return;
      }

      // Estos errores pueden corresponder
      // a problemas temporales.
      if (error.code == 'unavailable' ||
          error.code == 'deadline-exceeded' ||
          error.code == 'network-request-failed' ||
          error.code == 'aborted') {
        await _local.actualizarResultado(
          id: solicitud.id,
          versionEsperada: solicitud.versionLocal,
          estadoNegocio: 'SOLICITADA',
          estadoSync: 'PENDIENTE',
          error:
              'Error temporal: ${error.code}. '
              'Reintenta cuando tengas conexión.',
        );
        return;
      }

      // Las reglas rechazaron la operación
      // o Firestore reportó otra condición.
      // Conservamos el motivo para diagnóstico.
      if (error.code == 'permission-denied' ||
          error.code == 'failed-precondition' ||
          error.code == 'not-found') {
        await _local.registrarConflicto(
          id: solicitud.id,
          versionEsperada: solicitud.versionLocal,
          motivo:
              'Firestore rechazó la operación: '
              '${error.code}. Revisa permisos y datos.',
        );
        return;
      }

      await _local.actualizarResultado(
        id: solicitud.id,
        versionEsperada: solicitud.versionLocal,
        estadoNegocio: 'SOLICITADA',
        estadoSync: 'PENDIENTE',
        error:
            'No fue posible completar el envío: '
            '${error.code}',
      );
    } catch (_) {
      if (_auth.currentUser?.uid != uid) {
        return;
      }

      await _local.actualizarResultado(
        id: solicitud.id,
        versionEsperada: solicitud.versionLocal,
        estadoNegocio: 'SOLICITADA',
        estadoSync: 'PENDIENTE',
        error:
            'No fue posible sincronizar. '
            'Puedes reintentar.',
      );
    }
  }

  Future<String> _confirmarRemotamente(String eventoId, String uid) async {
    final eventoRef = _db.collection('eventos').doc(eventoId);

    final inscripcionRef = _db
        .collection('inscripciones')
        .doc(_idInscripcion(eventoId, uid));

    return _db.runTransaction<String>((tx) async {
      // Todas las lecturas se hacen antes
      // de cualquier escritura.
      final eventoSnap = await tx.get(eventoRef);

      final inscripcionSnap = await tx.get(inscripcionRef);

      if (inscripcionSnap.exists) {
        final existente = inscripcionSnap.data()!;

        if (existente['eventoId'] != eventoId ||
            existente['participanteUid'] != uid) {
          throw StateError(
            'El registro remoto no coincide '
            'con la solicitud local.',
          );
        }

        final estado = existente['estado'] as String;

        // Si un envío anterior tuvo éxito,
        // solo recuperamos su estado.
        // No se aumenta el contador nuevamente.
        if (estado == 'CONFIRMADA' ||
            estado == 'INGRESO_REGISTRADO' ||
            estado == 'AUSENTE' ||
            estado == 'CANCELADA') {
          return estado;
        }

        throw StateError(
          'Existe una inscripción remota '
          'con estado no reconocido: $estado',
        );
      }

      if (!eventoSnap.exists) {
        throw StateError('El evento ya no existe');
      }

      final evento = eventoSnap.data()!;

      final estado = evento['estado'] as String;
      final capacidad = evento['capacidad'] as int;
      final confirmados = evento['confirmados'] as int;

      final inicio = (evento['inicio'] as Timestamp).toDate();

      if (estado != 'ABIERTO') {
        throw StateError('Las inscripciones ya no están abiertas');
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

      return 'CONFIRMADA';
    });
  }

  Future<void> cancelarInscripcion(String eventoId) async {
    final uid = _uid;

    final id = _idInscripcion(eventoId, uid);

    final local = await _local.obtener(id);

    if (local != null &&
        local.usuarioUid == uid &&
        local.estadoSync == 'PENDIENTE') {
      throw StateError(
        'La solicitud todavía está pendiente. '
        'Sincronízala antes de cancelar.',
      );
    }

    final eventoRef = _db.collection('eventos').doc(eventoId);

    final inscripcionRef = _db.collection('inscripciones').doc(id);

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

    // Se actualiza SQLite únicamente
    // después de confirmar la transacción.
    await _local.registrarCancelacion(id: id, uid: uid);
  }

  Stream<List<Inscripcion>> misInscripciones() {
    final uid = _uid;

    return _db
        .collection('inscripciones')
        .where('participanteUid', isEqualTo: uid)
        .snapshots()
        .asyncMap((snapshot) async {
          final inscripciones = snapshot.docs
              .map(Inscripcion.desdeFirestore)
              .toList();

          // No utilizamos datos de caché como
          // autoridad para actualizar SQLite.
          if (!snapshot.metadata.isFromCache && _auth.currentUser?.uid == uid) {
            for (final inscripcion in inscripciones) {
              await _local.reflejarEstadoRemoto(
                id: inscripcion.id,
                uid: uid,
                estado: inscripcion.estado,
              );
            }
          }

          return inscripciones;
        });
  }
}
