import 'package:flutter/material.dart';

import '../models/evento.dart';
import '../repositories/evento_repository.dart';
import '../repositories/inscripcion_repository.dart';
import 'crear_evento_screen.dart';

class ListaEventosScreen extends StatefulWidget {
  final bool esOrganizador;

  const ListaEventosScreen({super.key, required this.esOrganizador});

  @override
  State<ListaEventosScreen> createState() => _ListaEventosScreenState();
}

class _ListaEventosScreenState extends State<ListaEventosScreen> {
  final eventoRepository = EventoRepository();
  final inscripcionRepository = InscripcionRepository();

  late final Stream<List<Evento>> eventosStream;

  String? procesandoId;

  @override
  void initState() {
    super.initState();

    eventosStream = widget.esOrganizador
        ? eventoRepository.obtenerMisEventos()
        : eventoRepository.obtenerEventosPublicados();
  }

  String fechaTexto(DateTime fecha) {
    String dos(int valor) => valor.toString().padLeft(2, '0');

    return '${dos(fecha.day)}/${dos(fecha.month)}/'
        '${fecha.year} '
        '${dos(fecha.hour)}:${dos(fecha.minute)}';
  }

  void mostrarMensaje(String mensaje, {bool exito = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: exito ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> publicar(Evento evento) async {
    if (procesandoId != null) return;

    setState(() => procesandoId = evento.id);

    try {
      await eventoRepository.publicarEvento(evento.id);

      if (!mounted) return;

      mostrarMensaje('Evento publicado correctamente', exito: true);
    } catch (error) {
      if (!mounted) return;

      mostrarMensaje('Error al publicar: $error');
    } finally {
      if (mounted) {
        setState(() => procesandoId = null);
      }
    }
  }

  Future<void> inscribirse(Evento evento) async {
    if (procesandoId != null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar inscripción'),
        content: Text('¿Quieres inscribirte en "${evento.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Inscribirme'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => procesandoId = evento.id);

    try {
      await inscripcionRepository.confirmarInscripcion(evento.id);

      if (!mounted) return;

      mostrarMensaje('Inscripción confirmada correctamente', exito: true);
    } catch (error) {
      if (!mounted) return;

      mostrarMensaje('No se pudo confirmar: $error');
    } finally {
      if (mounted) {
        setState(() => procesandoId = null);
      }
    }
  }

  Widget tarjetaEvento(Evento evento) {
    final disponibles = evento.capacidad - evento.confirmados;

    final sinCupos = disponibles <= 0;
    final procesando = procesandoId == evento.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              evento.nombre,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Inicio: ${fechaTexto(evento.inicio)}')),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(Icons.schedule, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Fin: ${fechaTexto(evento.fin)}')),
              ],
            ),

            const SizedBox(height: 12),

            Text('Capacidad: ${evento.capacidad}'),

            Text('Confirmados: ${evento.confirmados}'),

            Text(
              'Cupos disponibles: $disponibles',
              style: TextStyle(
                color: sinCupos ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Chip(label: Text(evento.estado)),

            if (widget.esOrganizador && evento.estado == 'BORRADOR') ...[
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: procesandoId == null
                      ? () => publicar(evento)
                      : null,
                  icon: const Icon(Icons.publish),
                  label: Text(procesando ? 'Publicando...' : 'Publicar evento'),
                ),
              ),
            ],

            if (!widget.esOrganizador && evento.estado == 'ABIERTO') ...[
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      procesandoId == null &&
                          !sinCupos &&
                          evento.inicio.isAfter(DateTime.now())
                      ? () => inscribirse(evento)
                      : null,
                  icon: const Icon(Icons.how_to_reg),
                  label: Text(
                    procesando
                        ? 'Confirmando...'
                        : sinCupos
                        ? 'Sin cupos'
                        : 'Inscribirme',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
              tooltip: 'Crear evento',
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
            return Center(
              child: Text(
                widget.esOrganizador
                    ? 'Todavía no has creado eventos'
                    : 'No hay eventos publicados',
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: eventos.length,
            itemBuilder: (context, index) {
              return tarjetaEvento(eventos[index]);
            },
          );
        },
      ),
    );
  }
}
