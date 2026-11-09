import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/evento.dart';
import '../models/inscripcion.dart';

class AccesoInscritosScreen extends StatefulWidget {
  final Evento evento;

  const AccesoInscritosScreen({super.key, required this.evento});

  @override
  State<AccesoInscritosScreen> createState() => _AccesoInscritosScreenState();
}

class _AccesoInscritosScreenState extends State<AccesoInscritosScreen> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final busquedaController = TextEditingController();

  late final Stream<QuerySnapshot<Map<String, dynamic>>> eventoStream;

  late final Stream<QuerySnapshot<Map<String, dynamic>>> inscripcionesStream;

  String filtro = '';
  String? procesandoId;

  @override
  void initState() {
    super.initState();

    eventoStream = db
        .collection('eventos')
        .where(FieldPath.documentId, isEqualTo: widget.evento.id)
        .snapshots();

    inscripcionesStream = db
        .collection('inscripciones')
        .where('eventoId', isEqualTo: widget.evento.id)
        .snapshots();
  }

  @override
  void dispose() {
    busquedaController.dispose();
    super.dispose();
  }

  void mensaje(String texto, {bool exito = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: exito ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> registrarIngreso(Inscripcion inscripcion) async {
    if (procesandoId != null) return;

    setState(() => procesandoId = inscripcion.id);

    try {
      final eventoRef = db.collection('eventos').doc(inscripcion.eventoId);

      final inscripcionRef = db.collection('inscripciones').doc(inscripcion.id);

      await db.runTransaction((tx) async {
        final eventoSnap = await tx.get(eventoRef);
        final inscripcionSnap = await tx.get(inscripcionRef);

        if (!eventoSnap.exists || !inscripcionSnap.exists) {
          throw StateError('El evento o la inscripción no existe');
        }

        final evento = eventoSnap.data()!;
        final datos = inscripcionSnap.data()!;

        if (datos['eventoId'] != inscripcion.eventoId) {
          throw StateError('Inscripción incorrecta');
        }

        if (datos['estado'] != 'CONFIRMADA') {
          throw StateError('Solo se permite ingreso de confirmados');
        }

        final estadoEvento = evento['estado'] as String;

        if (estadoEvento != 'ABIERTO' &&
            estadoEvento != 'INSCRIPCIONES_CERRADAS') {
          throw StateError('El evento no admite ingresos');
        }

        final inicio = (evento['inicio'] as Timestamp).toDate();
        final fin = (evento['fin'] as Timestamp).toDate();
        final ahora = DateTime.now();

        if (ahora.isBefore(inicio) || !ahora.isBefore(fin)) {
          throw StateError('El ingreso está fuera del horario del evento');
        }

        tx.update(inscripcionRef, {
          'estado': 'INGRESO_REGISTRADO',
          'fechaIngreso': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;

      mensaje('Ingreso registrado correctamente', exito: true);
    } catch (error) {
      if (!mounted) return;
      mensaje('No se pudo registrar: $error');
    } finally {
      if (mounted) {
        setState(() => procesandoId = null);
      }
    }
  }

  Future<void> marcarAusencia(Inscripcion inscripcion) async {
    if (procesandoId != null) return;

    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Marcar ausencia'),
        content: const Text(
          '¿Confirmas que el participante no asistió? '
          'Esta acción no se podrá revertir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Marcar ausente'),
          ),
        ],
      ),
    );

    if (confirmacion != true || !mounted) return;

    setState(() => procesandoId = inscripcion.id);

    try {
      final eventoRef = db.collection('eventos').doc(inscripcion.eventoId);

      final inscripcionRef = db.collection('inscripciones').doc(inscripcion.id);

      await db.runTransaction((tx) async {
        final eventoSnap = await tx.get(eventoRef);
        final inscripcionSnap = await tx.get(inscripcionRef);

        if (!eventoSnap.exists || !inscripcionSnap.exists) {
          throw StateError('Registro no encontrado');
        }

        final evento = eventoSnap.data()!;
        final datos = inscripcionSnap.data()!;

        if (datos['eventoId'] != inscripcion.eventoId ||
            datos['estado'] != 'CONFIRMADA') {
          throw StateError(
            'Solo pueden marcarse ausentes '
            'las inscripciones confirmadas',
          );
        }

        final fin = (evento['fin'] as Timestamp).toDate();

        if (evento['estado'] != 'FINALIZADO' || DateTime.now().isBefore(fin)) {
          throw StateError('El evento debe haber finalizado');
        }

        tx.update(inscripcionRef, {
          'estado': 'AUSENTE',
          'fechaAusencia': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;

      mensaje('Ausencia registrada correctamente', exito: true);
    } catch (error) {
      if (!mounted) return;

      mensaje('No se pudo marcar ausencia: $error');
    } finally {
      if (mounted) {
        setState(() => procesandoId = null);
      }
    }
  }

  Color colorEstado(String estado) {
    switch (estado) {
      case 'CONFIRMADA':
        return Colors.green;
      case 'INGRESO_REGISTRADO':
        return Colors.blue;
      case 'AUSENTE':
        return Colors.orange;
      case 'CANCELADA':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de acceso')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: eventoStream,
        builder: (context, eventoSnapshot) {
          if (eventoSnapshot.hasError) {
            return Center(
              child: Text(
                'Error al consultar el evento: '
                '${eventoSnapshot.error}',
              ),
            );
          }

          if (!eventoSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (eventoSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text('El evento no existe'));
          }

          final datosEvento = eventoSnapshot.data!.docs.first.data();

          final estadoEvento = datosEvento['estado'] as String;

          final inicio = (datosEvento['inicio'] as Timestamp).toDate();

          final fin = (datosEvento['fin'] as Timestamp).toDate();

          final ahora = DateTime.now();

          final puedeRegistrar =
              (estadoEvento == 'ABIERTO' ||
                  estadoEvento == 'INSCRIPCIONES_CERRADAS') &&
              !ahora.isBefore(inicio) &&
              ahora.isBefore(fin);

          final puedeMarcarAusentes =
              estadoEvento == 'FINALIZADO' && !ahora.isBefore(fin);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.evento.nombre,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Estado: $estadoEvento'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: busquedaController,
                      decoration: const InputDecoration(
                        labelText: 'Buscar por ID del participante',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (valor) {
                        setState(() {
                          filtro = valor.trim().toLowerCase();
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: inscripcionesStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error al consultar inscritos: '
                          '${snapshot.error}',
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final inscripciones = snapshot.data!.docs
                        .map(Inscripcion.desdeFirestore)
                        .where((inscripcion) {
                          return inscripcion.participanteUid
                                  .toLowerCase()
                                  .contains(filtro) ||
                              inscripcion.id.toLowerCase().contains(filtro);
                        })
                        .toList();

                    if (inscripciones.isEmpty) {
                      return const Center(
                        child: Text('No se encontraron inscripciones'),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: inscripciones.length,
                      itemBuilder: (context, index) {
                        final inscripcion = inscripciones[index];

                        final confirmada = inscripcion.estado == 'CONFIRMADA';

                        final procesando = procesandoId == inscripcion.id;

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Participante',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                SelectableText(inscripcion.participanteUid),
                                const SizedBox(height: 10),
                                Chip(
                                  label: Text(inscripcion.estado),
                                  backgroundColor: colorEstado(
                                    inscripcion.estado,
                                  ).withValues(alpha: 0.15),
                                ),
                                if (confirmada && puedeRegistrar) ...[
                                  const SizedBox(height: 10),
                                  ElevatedButton.icon(
                                    onPressed: procesandoId == null
                                        ? () => registrarIngreso(inscripcion)
                                        : null,
                                    icon: const Icon(Icons.login),
                                    label: Text(
                                      procesando
                                          ? 'Procesando...'
                                          : 'Registrar ingreso',
                                    ),
                                  ),
                                ],
                                if (confirmada && puedeMarcarAusentes) ...[
                                  const SizedBox(height: 10),
                                  OutlinedButton.icon(
                                    onPressed: procesandoId == null
                                        ? () => marcarAusencia(inscripcion)
                                        : null,
                                    icon: const Icon(Icons.person_off),
                                    label: Text(
                                      procesando
                                          ? 'Procesando...'
                                          : 'Marcar ausencia',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
