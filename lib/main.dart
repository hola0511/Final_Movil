import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'preferences/app_preferences.dart';
import 'screens/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Cargar el tema guardado.
  await AppPreferences.cargarPreferencias();

  // Crashlytics está orientado aquí a Android e iOS.
  final plataformaCompatible =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  if (plataformaCompatible) {
    // Habilitar recopilación para esta prueba.
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

    // Capturar errores del framework de Flutter.
    FlutterError.onError = (details) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };

    // Capturar errores no controlados fuera
    // del framework de Flutter.
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);

      return true;
    };
  }

  runApp(const EventosApp());
}

class EventosApp extends StatelessWidget {
  const EventosApp({super.key});

  Future<void> enviarErrorPrueba(BuildContext context) async {
    try {
      final crashlytics = FirebaseCrashlytics.instance;

      await crashlytics.setCustomKey('proyecto', 'G62-5');

      await crashlytics.setCustomKey('modulo', 'diagnostico');

      await crashlytics.log('Inicio de prueba controlada de Crashlytics');

      await crashlytics.recordError(
        StateError('G62-5: error de prueba no fatal'),
        StackTrace.current,
        reason: 'Verificar integración de Crashlytics',
        fatal: false,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error de prueba registrado localmente. '
            'Reinicia la aplicación y revisa '
            'Firebase Crashlytics.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo registrar el error: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppPreferences.temaOscuro,
      builder: (context, oscuro, child) {
        return MaterialApp(
          title: 'Eventos G62-5',

          debugShowCheckedModeBanner: false,

          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigo,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: Colors.grey.shade50,
            appBarTheme: const AppBarTheme(centerTitle: true),
          ),

          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigo,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
            ),
            cardTheme: const CardThemeData(color: Color(0xFF242424)),
          ),

          themeMode: oscuro ? ThemeMode.dark : ThemeMode.light,

          home: const AuthGate(),

          // El botón de diagnóstico únicamente
          // aparece en desarrollo sobre Android/iOS.
          builder: (context, child) {
            final mostrarDiagnostico =
                kDebugMode &&
                !kIsWeb &&
                (defaultTargetPlatform == TargetPlatform.android ||
                    defaultTargetPlatform == TargetPlatform.iOS);

            if (!mostrarDiagnostico) {
              return child ?? const SizedBox.shrink();
            }

            return Stack(
              children: [
                Positioned.fill(child: child ?? const SizedBox.shrink()),

                Positioned(
                  right: 12,
                  bottom: 16,
                  child: Builder(
                    builder: (context) {
                      return Material(
                        elevation: 4,
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(40),
                        child: IconButton(
                          tooltip: 'Probar Firebase Crashlytics',
                          icon: const Icon(Icons.bug_report_outlined),
                          onPressed: () {
                            enviarErrorPrueba(context);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
