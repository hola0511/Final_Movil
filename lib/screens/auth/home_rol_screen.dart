import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../acceso_eventos_screen.dart';
import '../lista_eventos_screen.dart';
import '../mis_inscripciones_screen.dart';

class HomeRolScreen extends StatelessWidget {
  final String nombre;
  final String rol;

  const HomeRolScreen({super.key, required this.nombre, required this.rol});

  @override
  Widget build(BuildContext context) {
    final esOrganizador = rol == 'organizador';
    final esParticipante = rol == 'participante';
    final esAuxiliar = rol == 'auxiliar_acceso';

    String titulo;
    IconData icono;

    if (esOrganizador) {
      titulo = 'Panel del organizador';
      icono = Icons.event;
    } else if (esAuxiliar) {
      titulo = 'Control de acceso';
      icono = Icons.verified_user;
    } else {
      titulo = 'Panel del participante';
      icono = Icons.people;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos G62-5'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().cerrarSesion();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Icon(icono, size: 72, color: Colors.indigo),
            const SizedBox(height: 20),
            Text(
              'Bienvenido, $nombre',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 35),

            if (esOrganizador) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.event_note),
                label: const Text('Administrar mis eventos'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ListaEventosScreen(esOrganizador: true),
                    ),
                  );
                },
              ),
            ],

            if (esParticipante) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.event),
                label: const Text('Consultar eventos'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ListaEventosScreen(esOrganizador: false),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                icon: const Icon(Icons.assignment),
                label: const Text('Mis inscripciones'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MisInscripcionesScreen(),
                    ),
                  );
                },
              ),
            ],

            if (esAuxiliar) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.fact_check),
                label: const Text('Control de acceso'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AccesoEventosScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Aquí podrás consultar inscritos, '
                    'registrar ingresos durante el evento '
                    'y marcar ausencias después de finalizar.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
