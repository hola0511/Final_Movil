import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/catalogo.dart';

class CatalogoHttpException implements Exception {
  final String mensaje;

  const CatalogoHttpException(this.mensaje);

  @override
  String toString() => mensaje;
}

class CatalogoHttpService {
  static const String urlCatalogo =
      'https://raw.githubusercontent.com/'
      'hola0511/eventos_g62_5/main/'
      'catalogo/catalogo.json';

  final http.Client _cliente;

  CatalogoHttpService({http.Client? cliente})
    : _cliente = cliente ?? http.Client();

  Future<Catalogo> obtenerCatalogo() async {
    try {
      final uri = Uri.parse(urlCatalogo);

      final respuesta = await _cliente
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));

      if (respuesta.statusCode < 200 || respuesta.statusCode >= 300) {
        throw CatalogoHttpException(
          'El servidor respondió con el código '
          '${respuesta.statusCode}.',
        );
      }

      dynamic datos;

      try {
        datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
      } on FormatException {
        throw const CatalogoHttpException(
          'El servidor devolvió un JSON inválido.',
        );
      }

      if (datos is! Map<String, dynamic>) {
        throw const CatalogoHttpException(
          'La estructura del catálogo no es válida.',
        );
      }

      try {
        return Catalogo.fromJson(datos);
      } on FormatException catch (error) {
        throw CatalogoHttpException(
          'Error en los datos del catálogo: '
          '${error.message}',
        );
      }
    } on TimeoutException {
      throw const CatalogoHttpException(
        'La solicitud tardó demasiado. '
        'Comprueba tu conexión e inténtalo nuevamente.',
      );
    } on SocketException {
      throw const CatalogoHttpException('No hay conexión con el servidor.');
    } on http.ClientException {
      throw const CatalogoHttpException(
        'No fue posible completar la solicitud HTTP.',
      );
    } on CatalogoHttpException {
      rethrow;
    } catch (_) {
      throw const CatalogoHttpException(
        'Ocurrió un error inesperado '
        'al consultar el catálogo.',
      );
    }
  }

  void cerrar() {
    _cliente.close();
  }
}
