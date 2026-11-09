
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const String _keyTemaOscuro = 'tema_oscuro';

  // Estado global del tema
  static final ValueNotifier<bool> temaOscuro =
      ValueNotifier<bool>(false);

  // Cargar preferencias guardadas
  static Future<void> cargarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();

    temaOscuro.value = prefs.getBool(_keyTemaOscuro) ?? false;
  }

  // Cambiar y guardar el tema
  static Future<void> cambiarTema(bool oscuro) async {
    temaOscuro.value = oscuro;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTemaOscuro, oscuro);
  }

  // Limpiar preferencias
  static Future<void> limpiarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_keyTemaOscuro);

    temaOscuro.value = false;
  }
}
