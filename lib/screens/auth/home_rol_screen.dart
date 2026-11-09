import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../lista_eventos_screen.dart';

class HomeRolScreen extends StatelessWidget {
  final String nombre;
  final String rol;

  const HomeRolScreen({super.key, required this.nombre, required this.rol});

  @override
  Widget build(BuildContext context) {
    final esOrganizador = rol == 'organizador';
    final esParticipante = rol == 'participante';

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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bienvenido, $nombre',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),
            Text('Rol: $rol'),
            const SizedBox(height: 30),

            if (esOrganizador || esParticipante)
              ElevatedButton.icon(
                icon: const Icon(Icons.event),
                label: Text(
                  esOrganizador
                      ? 'Administrar mis eventos'
                      : 'Consultar eventos',
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ListaEventosScreen(esOrganizador: esOrganizador),
                    ),
                  );
                },
              ),

            if (rol == 'auxiliar_acceso')
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'El control de asistencia se '
                    'implementará en la siguiente etapa.',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
