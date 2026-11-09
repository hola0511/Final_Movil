import 'package:flutter/material.dart';

import '../models/evento.dart';
import '../repositories/evento_repository.dart';
import '../repositories/inscripcion_repository.dart';
import 'crear_evento_screen.dart';
import 'mis_inscripciones_screen.dart';

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
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<bool> confirmarAccion(String titulo, String descripcion) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(descripcion),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    return resultado == true;
  }

  Future<void> ejecutar(
    Evento evento,
    Future<void> Function() operacion,
    String mensajeExito,
  ) async {
    if (procesandoId != null) return;

    setState(() => procesandoId = evento.id);

    try {
      await operacion();

      if (!mounted) return;

      mostrarMensaje(mensajeExito, exito: true);
    } catch (error) {
      if (!mounted) return;

      mostrarMensaje('No se pudo completar la operación: $error');
    } finally {
      if (mounted) {
        setState(() => procesandoId = null);
      }
    }
  }

  Future<void> publicar(Evento evento) async {
    await ejecutar(
      evento,
      () => eventoRepository.publicarEvento(evento.id),
      'Evento publicado correctamente',
    );
  }

  Future<void> cerrarInscripciones(Evento evento) async {
    final confirmar = await confirmarAccion(
      'Cerrar inscripciones',
      '¿Quieres cerrar las inscripciones de este evento?',
    );

    if (!confirmar || !mounted) return;

    await ejecutar(
      evento,
      () => eventoRepository.cerrarInscripciones(evento.id),
      'Inscripciones cerradas',
    );
  }

  Future<void> finalizarEvento(Evento evento) async {
    final confirmar = await confirmarAccion(
      'Finalizar evento',
      '¿Quieres marcar este evento como finalizado?',
    );

    if (!confirmar || !mounted) return;

    await ejecutar(
      evento,
      () => eventoRepository.finalizarEvento(evento.id),
      'Evento finalizado',
    );
  }

  Future<void> inscribirse(Evento evento) async {
    final confirmar = await confirmarAccion(
      'Solicitar inscripción',
      'La solicitud se guardará primero en el '
          'dispositivo. El cupo solo estará reservado '
          'cuando Firestore confirme la inscripción.',
    );

    if (!confirmar || !mounted) return;

    await ejecutar(
      evento,
      () => inscripcionRepository.confirmarInscripcion(evento.id),
      'Solicitud registrada. Consulta Mis inscripciones '
      'para verificar si fue confirmada.',
    );
  }

  Widget tarjetaEvento(Evento evento) {
    final disponibles = evento.capacidad - evento.confirmados;

    final sinCupos = disponibles <= 0;
    final procesando = procesandoId == evento.id;
    final ahora = DateTime.now();

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
            Text('Inicio: ${fechaTexto(evento.inicio)}'),
            Text('Fin: ${fechaTexto(evento.fin)}'),
            const SizedBox(height: 12),
            Text('Capacidad: ${evento.capacidad}'),
            Text('Confirmados: ${evento.confirmados}'),
            Text(
              'Cupos disponibles: $disponibles',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: sinCupos ? Colors.red : Colors.green,
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
                  label: Text(procesando ? 'Procesando...' : 'Publicar evento'),
                ),
              ),
            ],

            if (widget.esOrganizador && evento.estado == 'ABIERTO') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: procesandoId == null
                      ? () => cerrarInscripciones(evento)
                      : null,
                  icon: const Icon(Icons.lock),
                  label: Text(
                    procesando ? 'Procesando...' : 'Cerrar inscripciones',
                  ),
                ),
              ),
            ],

            if (widget.esOrganizador &&
                evento.estado == 'INSCRIPCIONES_CERRADAS') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: procesandoId == null && !ahora.isBefore(evento.fin)
                      ? () => finalizarEvento(evento)
                      : null,
                  icon: const Icon(Icons.task_alt),
                  label: Text(
                    ahora.isBefore(evento.fin)
                        ? 'Esperando fin del evento'
                        : procesando
                        ? 'Procesando...'
                        : 'Finalizar evento',
                  ),
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
                          ahora.isBefore(evento.inicio)
                      ? () => inscribirse(evento)
                      : null,
                  icon: const Icon(Icons.how_to_reg),
                  label: Text(
                    procesando
                        ? 'Guardando solicitud...'
                        : sinCupos
                        ? 'Sin cupos'
                        : ahora.isBefore(evento.inicio)
                        ? 'Solicitar inscripción'
                        : 'Evento iniciado',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MisInscripcionesScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.assignment),
                label: const Text('Ver mis solicitudes y sincronización'),
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
              child: Text(
                'Error al consultar eventos: '
                '${snapshot.error}',
                textAlign: TextAlign.center,
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
            itemBuilder: (context, index) => tarjetaEvento(eventos[index]),
          );
        },
      ),
    );
  }
}
