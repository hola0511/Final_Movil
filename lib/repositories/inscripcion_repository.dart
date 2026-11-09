import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/inscripcion.dart';

class InscripcionRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  Future<void> confirmarInscripcion(String eventoId) async {
    final uid = _uid;

    final eventoRef = _db.collection('eventos').doc(eventoId);

    final inscripcionRef = _db
        .collection('inscripciones')
        .doc(_idInscripcion(eventoId, uid));

    await _db.runTransaction((tx) async {
      final eventoSnap = await tx.get(eventoRef);
      final inscripcionSnap = await tx.get(inscripcionRef);

      if (!eventoSnap.exists) {
        throw StateError('El evento no existe');
      }

      if (inscripcionSnap.exists) {
        throw StateError(
          'Ya tienes una inscripción registrada '
          'para este evento',
        );
      }

      final evento = eventoSnap.data()!;

      final estado = evento['estado'] as String;
      final capacidad = evento['capacidad'] as int;
      final confirmados = evento['confirmados'] as int;
      final inicio = (evento['inicio'] as Timestamp).toDate();

      if (estado != 'ABIERTO') {
        throw StateError('Las inscripciones no están abiertas');
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
        throw StateError('Solo puedes cancelar inscripciones confirmadas');
      }

      if (evento['estado'] == 'FINALIZADO') {
        throw StateError('El evento ya finalizó');
      }

      final inicio = (evento['inicio'] as Timestamp).toDate();

      final limite = inicio.subtract(const Duration(hours: 1));

      if (DateTime.now().isAfter(limite)) {
        throw StateError('Solo puedes cancelar hasta una hora antes');
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
}
