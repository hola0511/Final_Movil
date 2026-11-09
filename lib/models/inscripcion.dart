import 'package:cloud_firestore/cloud_firestore.dart';

class Inscripcion {
  final String id;
  final String eventoId;
  final String participanteUid;
  final String estado;
  final DateTime? fechaConfirmacion;
  final DateTime? fechaCancelacion;

  const Inscripcion({
    required this.id,
    required this.eventoId,
    required this.participanteUid,
    required this.estado,
    this.fechaConfirmacion,
    this.fechaCancelacion,
  });

  factory Inscripcion.desdeFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final datos = doc.data()!;

    return Inscripcion(
      id: doc.id,
      eventoId: datos['eventoId'] as String,
      participanteUid: datos['participanteUid'] as String,
      estado: datos['estado'] as String,
      fechaConfirmacion: (datos['fechaConfirmacion'] as Timestamp?)?.toDate(),
      fechaCancelacion: (datos['fechaCancelacion'] as Timestamp?)?.toDate(),
    );
  }
}
