import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'home_rol_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    return StreamBuilder<User?>(
      stream: auth.authStateChanges,
      builder: (context, sesion) {
        if (sesion.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (sesion.hasError) {
          return const Scaffold(
            body: Center(child: Text('Error al recuperar la sesión')),
          );
        }

        final usuario = sesion.data;

        if (usuario == null) {
          return const LoginScreen();
        }

        return StreamBuilder(
          stream: auth.perfilActual(usuario.uid),
          builder: (context, perfil) {
            if (perfil.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (perfil.hasError) {
              return const Scaffold(
                body: Center(child: Text('Error al consultar el perfil')),
              );
            }

            if (!perfil.hasData || !perfil.data!.exists) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Tu perfil no está disponible.'),
                      ElevatedButton(
                        onPressed: auth.cerrarSesion,
                        child: const Text('Cerrar sesión'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final datos = perfil.data!.data()!;
            final rol = datos['rol'] as String?;

            if (![
              'participante',
              'organizador',
              'auxiliar_acceso',
            ].contains(rol)) {
              return const Scaffold(
                body: Center(child: Text('Rol no autorizado')),
              );
            }

            return HomeRolScreen(
              nombre: datos['nombre'] as String? ?? 'Usuario',
              rol: rol!,
            );
          },
        );
      },
    );
  }
}
