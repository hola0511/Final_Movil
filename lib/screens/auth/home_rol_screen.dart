
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class HomeRolScreen extends StatelessWidget {
  final String nombre;
  final String rol;

  const HomeRolScreen({
    super.key,
    required this.nombre,
    required this.rol,
  });

  @override
  Widget build(BuildContext context) {
    String titulo;
    IconData icono;

    switch (rol) {
      case 'organizador':
        titulo = 'Panel del organizador';
        icono = Icons.event;
        break;
      case 'auxiliar_acceso':
        titulo = 'Control de acceso';
        icono = Icons.verified_user;
        break;
      default:
        titulo = 'Panel del participante';
        icono = Icons.people;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
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
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icono,
              size: 70,
              color: Colors.indigo,
            ),
            const SizedBox(height: 20),
            Text(
              'Bienvenido, $nombre',
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 12),
            Text('Tu rol es: $rol'),
            const SizedBox(height: 20),
            const Text(
              'Autenticación configurada correctamente',
            ),
          ],
        ),
      ),
    );
  }
}
