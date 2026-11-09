
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final nombre = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final auth = AuthService();

  bool esRegistro = false;
  bool cargando = false;

  @override
  void dispose() {
    nombre.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  String mensajeError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'El correo no es válido';
        case 'email-already-in-use':
          return 'El correo ya está registrado';
        case 'weak-password':
          return 'La contraseña es demasiado débil';
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          return 'Correo o contraseña incorrectos';
        case 'network-request-failed':
          return 'No se pudo establecer conexión';
        case 'too-many-requests':
          return 'Demasiados intentos. Intenta más tarde';
      }
    }

    return 'No se pudo completar la operación: $error';
  }

  Future<void> enviar() async {
    if (cargando) return;

    final correo = email.text.trim();
    final clave = password.text;

    if (esRegistro && nombre.text.trim().isEmpty) {
      mostrarMensaje('Ingresa tu nombre');
      return;
    }

    if (correo.isEmpty || clave.isEmpty) {
      mostrarMensaje('Completa el correo y la contraseña');
      return;
    }

    setState(() => cargando = true);

    try {
      if (esRegistro) {
        await auth.registrar(
          nombre: nombre.text,
          email: correo,
          password: clave,
        );
      } else {
        await auth.iniciarSesion(
          email: correo,
          password: clave,
        );
      }
    } catch (error) {
      if (mounted) mostrarMensaje(mensajeError(error));
    } finally {
      if (mounted) {
        setState(() => cargando = false);
      }
    }
  }

  void mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos G62-5'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.event_available,
                  size: 70,
                  color: Colors.indigo,
                ),
                const SizedBox(height: 20),
                Text(
                  esRegistro
                      ? 'Crear cuenta'
                      : 'Iniciar sesión',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 25),
                if (esRegistro) ...[
                  TextField(
                    controller: nombre,
                    enabled: !cargando,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
                TextField(
                  controller: email,
                  enabled: !cargando,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: password,
                  enabled: !cargando,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: cargando ? null : enviar,
                  child: cargando
                      ? const CircularProgressIndicator()
                      : Text(
                          esRegistro
                              ? 'Registrarme'
                              : 'Ingresar',
                        ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: cargando
                      ? null
                      : () => setState(() {
                            esRegistro = !esRegistro;
                          }),
                  child: Text(
                    esRegistro
                        ? 'Ya tengo cuenta'
                        : 'Crear una cuenta',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
