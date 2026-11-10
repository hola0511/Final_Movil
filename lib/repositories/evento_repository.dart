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
      throw StateError('Debes iniciar sesión');
    }

    return usuario.uid;
  }

  Future<String> crearEvento(Evento evento) async {
    final error = EventoValidator.validar(evento);

    if (error != null) {
      throw StateError(error);
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
    return _eventos.where('organizadorUid', isEqualTo: _uid).snapshots().map((
      snapshot,
    ) {
      final eventos = snapshot.docs.map(Evento.desdeFirestore).toList();

      eventos.sort((a, b) => a.inicio.compareTo(b.inicio));

      return eventos;
    });
  }

  Stream<List<Evento>> obtenerEventosPublicados() {
    return _eventos.where('estado', isEqualTo: 'ABIERTO').snapshots().map((
      snapshot,
    ) {
      final eventos = snapshot.docs.map(Evento.desdeFirestore).toList();

      eventos.sort((a, b) => a.inicio.compareTo(b.inicio));

      return eventos;
    });
  }

  Stream<List<Evento>> obtenerEventosAcceso() {
    return _eventos
        .where(
          'estado',
          whereIn: ['ABIERTO', 'INSCRIPCIONES_CERRADAS', 'FINALIZADO'],
        )
        .snapshots()
        .map((snapshot) {
          final eventos = snapshot.docs.map(Evento.desdeFirestore).toList();

          eventos.sort((a, b) => b.inicio.compareTo(a.inicio));

          return eventos;
        });
  }

  Future<void> publicarEvento(String eventoId) async {
    final referencia = _eventos.doc(eventoId);
    final uid = _uid;

    await _db.runTransaction((tx) async {
      final snapshot = await tx.get(referencia);

      if (!snapshot.exists) {
        throw StateError('El evento no existe');
      }

      final evento = Evento.desdeFirestore(snapshot);

      if (evento.organizadorUid != uid) {
        throw StateError('No eres el organizador');
      }

      if (evento.estado != 'BORRADOR') {
        throw StateError('Solo se pueden publicar borradores');
      }

      final error = EventoValidator.validar(evento);

      if (error != null) {
        throw StateError(error);
      }

      tx.update(referencia, {
        'estado': 'ABIERTO',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> editarEvento({
    required String eventoId,
    required String nombre,
    required int capacidad,
    required DateTime inicio,
    required DateTime fin,
  }) async {
    final uid = _uid;
    final referencia = _eventos.doc(eventoId);

    await _db.runTransaction((tx) async {
      final snapshot = await tx.get(referencia);

      if (!snapshot.exists) {
        throw StateError('El evento no existe');
      }

      final actual = Evento.desdeFirestore(snapshot);

      if (actual.organizadorUid != uid) {
        throw StateError('Solo el organizador propietario puede editar');
      }

      if (actual.estado != 'BORRADOR' && actual.estado != 'ABIERTO') {
        throw StateError(
          'No se puede editar un evento cerrado '
          'o finalizado',
        );
      }

      final ahora = DateTime.now();

      if (!actual.inicio.isAfter(ahora)) {
        throw StateError('No se pueden editar eventos iniciados');
      }

      if (capacidad < actual.confirmados) {
        throw StateError(
          'La capacidad no puede ser inferior a '
          'los ${actual.confirmados} participantes '
          'confirmados',
        );
      }

      final actualizado = Evento(
        id: actual.id,
        nombre: nombre.trim(),
        capacidad: capacidad,
        inicio: inicio,
        fin: fin,
        organizadorUid: actual.organizadorUid,
        estado: actual.estado,
        confirmados: actual.confirmados,
        categoriaId: actual.categoriaId,
        recintoId: actual.recintoId,
      );

      final error = EventoValidator.validar(actualizado);

      if (error != null) {
        throw StateError(error);
      }

      // La transacción trabaja con el contador
      // más reciente de Firestore.
      // No se cambia confirmados ni el estado.
      tx.update(referencia, {
        'nombre': actualizado.nombre,
        'capacidad': actualizado.capacidad,
        'inicio': Timestamp.fromDate(actualizado.inicio),
        'fin': Timestamp.fromDate(actualizado.fin),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> cerrarInscripciones(String eventoId) async {
    final referencia = _eventos.doc(eventoId);
    final uid = _uid;

    await _db.runTransaction((tx) async {
      final snapshot = await tx.get(referencia);

      if (!snapshot.exists) {
        throw StateError('El evento no existe');
      }

      final evento = Evento.desdeFirestore(snapshot);

      if (evento.organizadorUid != uid) {
        throw StateError('Solo el organizador puede cerrar inscripciones');
      }

      if (evento.estado != 'ABIERTO') {
        throw StateError('Solo se pueden cerrar eventos abiertos');
      }

      tx.update(referencia, {
        'estado': 'INSCRIPCIONES_CERRADAS',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> finalizarEvento(String eventoId) async {
    final referencia = _eventos.doc(eventoId);
    final uid = _uid;

    await _db.runTransaction((tx) async {
      final snapshot = await tx.get(referencia);

      if (!snapshot.exists) {
        throw StateError('El evento no existe');
      }

      final evento = Evento.desdeFirestore(snapshot);

      if (evento.organizadorUid != uid) {
        throw StateError('Solo el organizador puede finalizar el evento');
      }

      if (evento.estado != 'INSCRIPCIONES_CERRADAS') {
        throw StateError('Primero debes cerrar las inscripciones');
      }

      if (DateTime.now().isBefore(evento.fin)) {
        throw StateError('El evento todavía no ha terminado');
      }

      tx.update(referencia, {
        'estado': 'FINALIZADO',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
