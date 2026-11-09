import 'package:flutter/material.dart';

import '../models/evento.dart';
import '../repositories/evento_repository.dart';
import 'crear_evento_screen.dart';

class ListaEventosScreen extends StatefulWidget {
  final bool esOrganizador;

  const ListaEventosScreen({super.key, required this.esOrganizador});

  @override
  State<ListaEventosScreen> createState() => _ListaEventosScreenState();
}

class _ListaEventosScreenState extends State<ListaEventosScreen> {
  final repository = EventoRepository();

  late final Stream<List<Evento>> eventosStream;

  @override
  void initState() {
    super.initState();

    eventosStream = widget.esOrganizador
        ? repository.obtenerMisEventos()
        : repository.obtenerEventosPublicados();
  }

  Future<void> publicar(Evento evento) async {
    try {
      await repository.publicarEvento(evento.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento publicado correctamente')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String fechaTexto(DateTime fecha) {
    String dos(int valor) => valor.toString().padLeft(2, '0');

    return '${dos(fecha.day)}/${dos(fecha.month)}/'
        '${fecha.year} ${dos(fecha.hour)}:'
        '${dos(fecha.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.esOrganizador ? 'Mis eventos' : 'Eventos disponibles',
        ),
      ),

      floatingActionButton: widget.esOrganizador
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CrearEventoScreen()),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,

      body: StreamBuilder<List<Evento>>(
        stream: eventosStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error al consultar eventos: '
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
            return const Center(child: Text('No hay eventos disponibles'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: eventos.length,
            itemBuilder: (context, index) {
              final evento = eventos[index];

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        evento.nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text('Inicio: ${fechaTexto(evento.inicio)}'),
                      Text('Fin: ${fechaTexto(evento.fin)}'),

                      Text('Capacidad: ${evento.capacidad}'),

                      Text('Confirmados: ${evento.confirmados}'),

                      Text('Estado: ${evento.estado}'),

                      if (widget.esOrganizador &&
                          evento.estado == 'BORRADOR') ...[
                        const SizedBox(height: 12),

                        ElevatedButton(
                          onPressed: () => publicar(evento),
                          child: const Text('Publicar evento'),
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
