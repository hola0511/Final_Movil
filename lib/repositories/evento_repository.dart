import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/evento.dart';
import '../utils/evento_validator.dart';

class EventoRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _eventos =>
      _db.collection('eventos');

  String get _uid {
    final usuario = _auth.currentUser;

    if (usuario == null) {
      throw Exception('Debes iniciar sesión');
    }

    return usuario.uid;
  }

  Future<String> crearEvento(Evento evento) async {
    final error = EventoValidator.validar(evento);

    if (error != null) {
      throw Exception(error);
    }

    final referencia = _eventos.doc();

    await referencia.set({
      ...evento.paraFirestore(),
      'organizadorUid': _uid,
      'estado': 'BORRADOR',
      'confirmados': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return referencia.id;
  }

  Stream<List<Evento>> obtenerMisEventos() {
    final uid = _uid;

    return _eventos
        .where('organizadorUid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Evento.desdeFirestore).toList());
  }

  Stream<List<Evento>> obtenerEventosPublicados() {
    return _eventos
        .where('estado', isEqualTo: 'ABIERTO')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Evento.desdeFirestore).toList());
  }

  Future<void> publicarEvento(String eventoId) async {
    final referencia = _eventos.doc(eventoId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(referencia);

      if (!snapshot.exists) {
        throw Exception('El evento no existe');
      }

      final evento = Evento.desdeFirestore(snapshot);

      if (evento.organizadorUid != _uid) {
        throw Exception('No eres el organizador');
      }

      if (evento.estado != 'BORRADOR') {
        throw Exception('Solo se publican borradores');
      }

      final error = EventoValidator.validar(evento);

      if (error != null) {
        throw Exception(error);
      }

      transaction.update(referencia, {
        'estado': 'ABIERTO',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
