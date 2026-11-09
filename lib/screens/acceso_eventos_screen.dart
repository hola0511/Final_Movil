import 'package:flutter/material.dart';

import '../models/evento.dart';
import '../repositories/evento_repository.dart';
import 'acceso_inscritos_screen.dart';

class AccesoEventosScreen extends StatefulWidget {
  const AccesoEventosScreen({super.key});

  @override
  State<AccesoEventosScreen> createState() => _AccesoEventosScreenState();
}

class _AccesoEventosScreenState extends State<AccesoEventosScreen> {
  final repository = EventoRepository();

  late final Stream<List<Evento>> eventosStream;

  @override
  void initState() {
    super.initState();
    eventosStream = repository.obtenerEventosAcceso();
  }

  String formatearFecha(DateTime fecha) {
    String dos(int numero) => numero.toString().padLeft(2, '0');

    return '${dos(fecha.day)}/${dos(fecha.month)}/'
        '${fecha.year} '
        '${dos(fecha.hour)}:${dos(fecha.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Control de acceso')),
      body: StreamBuilder<List<Evento>>(
        stream: eventosStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No se pudieron consultar los eventos: '
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final eventos = snapshot.data!;

          if (eventos.isEmpty) {
            return const Center(
              child: Text(
                'No hay eventos disponibles '
                'para control de acceso',
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: eventos.length,
            itemBuilder: (context, index) {
              final evento = eventos[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        evento.nombre,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Inicio: ${formatearFecha(evento.inicio)}'),
                      Text(
                        'Finalización: '
                        '${formatearFecha(evento.fin)}',
                      ),
                      Text('Confirmados: ${evento.confirmados}'),
                      const SizedBox(height: 8),
                      Chip(label: Text(evento.estado)),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AccesoInscritosScreen(evento: evento),
                              ),
                            );
                          },
                          icon: const Icon(Icons.fact_check),
                          label: const Text('Consultar inscritos'),
                        ),
                      ),
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
