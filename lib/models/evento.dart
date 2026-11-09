import 'package:cloud_firestore/cloud_firestore.dart';

class Evento {
  final String id;
  final String nombre;
  final int capacidad;
  final DateTime inicio;
  final DateTime fin;
  final String organizadorUid;
  final String estado;
  final int confirmados;

  const Evento({
    this.id = '',
    required this.nombre,
    required this.capacidad,
    required this.inicio,
    required this.fin,
    this.organizadorUid = '',
    this.estado = 'BORRADOR',
    this.confirmados = 0,
  });

  factory Evento.desdeFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final datos = doc.data()!;

    return Evento(
      id: doc.id,
      nombre: datos['nombre'] as String,
      capacidad: datos['capacidad'] as int,
      inicio: (datos['inicio'] as Timestamp).toDate(),
      fin: (datos['fin'] as Timestamp).toDate(),
      organizadorUid: datos['organizadorUid'] as String,
      estado: datos['estado'] as String,
      confirmados: datos['confirmados'] as int,
    );
  }

  Map<String, dynamic> paraFirestore() {
    return {
      'nombre': nombre.trim(),
      'capacidad': capacidad,
      'inicio': Timestamp.fromDate(inicio),
      'fin': Timestamp.fromDate(fin),
      'organizadorUid': organizadorUid,
      'estado': estado,
      'confirmados': confirmados,
    };
  }
}
