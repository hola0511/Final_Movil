import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/inscripcion.dart';
import '../repositories/inscripcion_repository.dart';

class MisInscripcionesScreen extends StatefulWidget {
  const MisInscripcionesScreen({super.key});

  @override
  State<MisInscripcionesScreen> createState() => _MisInscripcionesScreenState();
}

class _MisInscripcionesScreenState extends State<MisInscripcionesScreen>
    with WidgetsBindingObserver {
  final repository = InscripcionRepository();

  late final Stream<List<SolicitudesLocale>> localStream;
  late final Stream<List<Inscripcion>> remotoStream;

  bool sincronizando = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    localStream = repository.observarSolicitudesLocales();
    remotoStream = repository.misInscripciones();

    // Intenta enviar pendientes al abrir esta pantalla.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) sincronizar();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      sincronizar();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void mensaje(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> sincronizar() async {
    if (sincronizando || !mounted) return;

    setState(() => sincronizando = true);

    try {
      await repository.sincronizarPendientes();

      if (!mounted) return;

      mensaje(
        'Sincronización revisada. '
        'Comprueba el estado de cada solicitud.',
      );
    } catch (error) {
      mensaje('No se pudo sincronizar: $error');
    } finally {
      if (mounted) {
        setState(() => sincronizando = false);
      }
    }
  }

  Future<void> descartar(SolicitudesLocale solicitud) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descartar intento'),
        content: const Text(
          'Se eliminará el intento local rechazado. '
          'Esto no elimina una inscripción remota.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      await repository.descartarConflicto(solicitud.id);
      mensaje('Intento local descartado');
    } catch (error) {
      mensaje('Error al descartar: $error');
    }
  }

  Color colorSincronizacion(String estado) {
    switch (estado) {
      case 'SINCRONIZADO':
        return Colors.green;
      case 'CONFLICTO':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget construirLocales(List<SolicitudesLocale> solicitudes) {
    if (solicitudes.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No tienes solicitudes guardadas localmente.'),
        ),
      );
    }

    return Column(
      children: solicitudes.map((solicitud) {
        final pendiente = solicitud.estadoSync == 'PENDIENTE';

        final conflicto = solicitud.estadoSync == 'CONFLICTO';

        final sincronizado = solicitud.estadoSync == 'SINCRONIZADO';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Solicitud local',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SelectableText('Evento: ${solicitud.eventoId}'),
                const SizedBox(height: 8),
                Text(
                  'Estado de negocio al sincronizar: '
                  '${solicitud.estadoNegocio}',
                ),
                const SizedBox(height: 8),
                Chip(
                  label: Text(solicitud.estadoSync),
                  backgroundColor: colorSincronizacion(solicitud.estadoSync)
                      .withValues(alpha: 0.15),
                ),
                if (solicitud.ultimoError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Detalle: ${solicitud.ultimoError}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                if (pendiente) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Todavía no hay cupo confirmado.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
                if (conflicto) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'La solicitud fue rechazada '
                    'por una condición del negocio.',
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => descartar(solicitud),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Descartar intento'),
                  ),
                ],
                if (sincronizado) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Envío confirmado. Consulta el historial '
                    'remoto para conocer el estado actual.',
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> cancelarInscripcion(Inscripcion inscripcion) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar inscripción'),
        content: const Text(
          '¿Quieres cancelar esta inscripción? '
          'Solo se puede cancelar dentro del plazo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar inscripción'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      await repository.cancelarInscripcion(inscripcion.eventoId);

      mensaje('Inscripción cancelada');
    } catch (error) {
      mensaje('No se pudo cancelar: $error');
    }
  }

  Widget construirRemotas(List<Inscripcion> inscripciones) {
    if (inscripciones.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No hay inscripciones confirmadas en Firestore.'),
        ),
      );
    }

    return Column(
      children: inscripciones.map((inscripcion) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text('Evento: ${inscripcion.eventoId}'),
            subtitle: Text('Estado real: ${inscripcion.estado}'),
            trailing: inscripcion.estado == 'CONFIRMADA'
                ? IconButton(
                    tooltip: 'Cancelar inscripción',
                    icon: const Icon(Icons.cancel_outlined),
                    onPressed: () => cancelarInscripcion(inscripcion),
                  )
                : const Icon(Icons.history),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis inscripciones'),
        actions: [
          IconButton(
            tooltip: 'Sincronizar pendientes',
            onPressed: sincronizando ? null : sincronizar,
            icon: const Icon(Icons.sync),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Solicitudes locales',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Las solicitudes pendientes no reservan cupo.'),
          const SizedBox(height: 16),

          if (sincronizando) const LinearProgressIndicator(),

          StreamBuilder<List<SolicitudesLocale>>(
            stream: localStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(
                  'Error al consultar SQLite: '
                  '${snapshot.error}',
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return construirLocales(snapshot.data!);
            },
          ),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: sincronizando ? null : sincronizar,
            icon: const Icon(Icons.sync),
            label: Text(
              sincronizando ? 'Sincronizando...' : 'Sincronizar pendientes',
            ),
          ),

          const SizedBox(height: 32),

          const Text(
            'Historial remoto',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Aquí aparecen las inscripciones '
            'que Firestore conoce.',
          ),
          const SizedBox(height: 16),

          StreamBuilder<List<Inscripcion>>(
            stream: remotoStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text(
                  'No se pudo consultar Firestore. '
                  'Las solicitudes locales siguen disponibles.',
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return construirRemotas(snapshot.data!);
            },
          ),
        ],
      ),
    );
  }
}
