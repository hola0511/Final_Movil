import 'package:flutter/material.dart';

import '../models/inscripcion.dart';
import '../repositories/inscripcion_repository.dart';

class MisInscripcionesScreen extends StatefulWidget {
  const MisInscripcionesScreen({super.key});

  @override
  State<MisInscripcionesScreen> createState() => _MisInscripcionesScreenState();
}

class _MisInscripcionesScreenState extends State<MisInscripcionesScreen> {
  final repository = InscripcionRepository();

  late final Stream<List<Inscripcion>> stream;

  String? procesandoId;

  @override
  void initState() {
    super.initState();
    stream = repository.misInscripciones();
  }

  Future<void> cancelar(Inscripcion inscripcion) async {
    if (procesandoId != null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar inscripción'),
        content: const Text(
          '¿Deseas cancelar esta inscripción? '
          'El cupo será liberado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar cancelación'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() {
      procesandoId = inscripcion.id;
    });

    try {
      await repository.cancelarInscripcion(inscripcion.eventoId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inscripción cancelada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('No se pudo cancelar: $error')));
    } finally {
      if (mounted) {
        setState(() {
          procesandoId = null;
        });
      }
    }
  }

  Color colorEstado(String estado) {
    switch (estado) {
      case 'CONFIRMADA':
        return Colors.green;
      case 'CANCELADA':
        return Colors.red;
      case 'INGRESO_REGISTRADO':
        return Colors.blue;
      case 'AUSENTE':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis inscripciones')),
      body: StreamBuilder<List<Inscripcion>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al consultar inscripciones: '
                '${snapshot.error}',
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final inscripciones = snapshot.data!;

          if (inscripciones.isEmpty) {
            return const Center(child: Text('Todavía no tienes inscripciones'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: inscripciones.length,
            itemBuilder: (context, index) {
              final inscripcion = inscripciones[index];

              final confirmada = inscripcion.estado == 'CONFIRMADA';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Inscripción al evento',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      SelectableText('Evento ID: ${inscripcion.eventoId}'),

                      const SizedBox(height: 10),

                      Chip(
                        label: Text(inscripcion.estado),
                        backgroundColor: colorEstado(inscripcion.estado)
                            .withValues(alpha: 0.15),
                      ),

                      if (confirmada) ...[
                        const SizedBox(height: 12),

                        ElevatedButton.icon(
                          onPressed: procesandoId == null
                              ? () => cancelar(inscripcion)
                              : null,
                          icon: const Icon(Icons.cancel),
                          label: procesandoId == inscripcion.id
                              ? const Text('Cancelando...')
                              : const Text('Cancelar inscripción'),
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
    );
  }
}
