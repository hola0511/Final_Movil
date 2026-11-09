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
  final InscripcionRepository repository = InscripcionRepository();

  late final Stream<List<SolicitudesLocale>> localStream;
  late final Stream<List<Inscripcion>> remotoStream;

  bool sincronizando = false;
  String? cancelandoId;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    localStream = repository.observarSolicitudesLocales();

    remotoStream = repository.misInscripciones();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        sincronizar(mostrarMensaje: false);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      sincronizar(mostrarMensaje: false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void mostrarAviso(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> sincronizar({bool mostrarMensaje = true}) async {
    if (!mounted || sincronizando) return;

    setState(() {
      sincronizando = true;
    });

    try {
      await repository.sincronizarPendientes();

      if (!mounted) return;

      if (mostrarMensaje) {
        mostrarAviso(
          'Revisión de sincronización terminada. '
          'Consulta el estado de cada solicitud.',
        );
      }
    } catch (error) {
      if (!mounted) return;

      mostrarAviso('No se pudo ejecutar la sincronización: $error');
    } finally {
      if (mounted) {
        setState(() {
          sincronizando = false;
        });
      }
    }
  }

  Future<void> cancelar(Inscripcion inscripcion) async {
    if (cancelandoId != null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar inscripción'),
        content: const Text(
          '¿Deseas cancelar esta inscripción? '
          'El cupo se liberará si todavía estás '
          'dentro del plazo permitido.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() {
      cancelandoId = inscripcion.id;
    });

    try {
      await repository.cancelarInscripcion(inscripcion.eventoId);

      if (!mounted) return;

      mostrarAviso('Inscripción cancelada correctamente');
    } catch (error) {
      if (!mounted) return;

      mostrarAviso('No se pudo cancelar: $error');
    } finally {
      if (mounted) {
        setState(() {
          cancelandoId = null;
        });
      }
    }
  }

  Color colorEstadoSync(String estado) {
    switch (estado) {
      case 'SINCRONIZADO':
        return Colors.green;
      case 'CONFLICTO':
        return Colors.red;
      case 'PENDIENTE':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget solicitudLocal(SolicitudesLocale solicitud) {
    final pendiente = solicitud.estadoSync == 'PENDIENTE';

    final conflicto = solicitud.estadoSync == 'CONFLICTO';

    final sincronizado = solicitud.estadoSync == 'SINCRONIZADO';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
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

            Text('Estado: ${solicitud.estadoNegocio}'),

            const SizedBox(height: 8),

            Chip(
              label: Text(solicitud.estadoSync),
              backgroundColor: colorEstadoSync(solicitud.estadoSync)
                  .withValues(alpha: 0.15),
            ),

            if (pendiente) ...[
              const SizedBox(height: 10),
              const Text(
                'Pendiente de confirmación. '
                'Todavía no tienes un cupo reservado.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],

            if (sincronizado) ...[
              const SizedBox(height: 10),
              const Text(
                'Esta solicitud fue procesada '
                'por Firestore.',
              ),
            ],

            if (conflicto) ...[
              const SizedBox(height: 10),
              const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Solicitud rechazada',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'El registro permanecerá guardado '
                'para que puedas consultar el motivo.',
              ),
            ],

            if (solicitud.ultimoError != null) ...[
              const SizedBox(height: 10),
              Text(
                'Detalle: ${solicitud.ultimoError}',
                style: TextStyle(color: conflicto ? Colors.red : null),
              ),
            ],

            const SizedBox(height: 10),

            Text(
              'Versión local: '
              '${solicitud.versionLocal}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget inscripcionRemota(Inscripcion inscripcion) {
    final puedeCancelar = inscripcion.estado == 'CONFIRMADA';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inscripción en Firestore',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            SelectableText('Evento: ${inscripcion.eventoId}'),

            const SizedBox(height: 8),

            Text('Estado: ${inscripcion.estado}'),

            if (puedeCancelar) ...[
              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed: cancelandoId == null
                    ? () => cancelar(inscripcion)
                    : null,
                icon: const Icon(Icons.cancel_outlined),
                label: Text(
                  cancelandoId == inscripcion.id
                      ? 'Cancelando...'
                      : 'Cancelar inscripción',
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
        title: const Text('Mis inscripciones'),
        actions: [
          IconButton(
            tooltip: 'Sincronizar pendientes',
            onPressed: sincronizando ? null : () => sincronizar(),
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

          const Text(
            'Las solicitudes se guardan primero '
            'en SQLite y después se envían '
            'a Firebase.',
          ),

          const SizedBox(height: 16),

          if (sincronizando) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 12),
          ],

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

              final solicitudes = snapshot.data!;

              if (solicitudes.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No tienes solicitudes locales.'),
                  ),
                );
              }

              return Column(children: solicitudes.map(solicitudLocal).toList());
            },
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: sincronizando ? null : () => sincronizar(),
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
            'Aquí aparece el estado registrado '
            'en Firebase Firestore.',
          ),

          const SizedBox(height: 16),

          StreamBuilder<List<Inscripcion>>(
            stream: remotoStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text(
                  'No se pudo consultar Firestore. '
                  'Los datos locales siguen disponibles.',
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final inscripciones = snapshot.data!;

              if (inscripciones.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No hay inscripciones remotas.'),
                  ),
                );
              }

              return Column(
                children: inscripciones.map(inscripcionRemota).toList(),
              );
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
