
import 'package:flutter_test/flutter_test.dart';
import 'package:eventos_g62_5/models/evento.dart';
import 'package:eventos_g62_5/utils/evento_validator.dart';

void main() {
  group('Validaciones de eventos G62-5', () {
    final inicio = DateTime.now().add(
      const Duration(days: 3),
    );

    final fin = inicio.add(
      const Duration(hours: 2),
    );

    test('Acepta un evento válido', () {
      final evento = Evento(
        nombre: 'Conferencia tecnológica',
        capacidad: 30,
        inicio: inicio,
        fin: fin,
      );

      expect(EventoValidator.validar(evento), isNull);
    });

    test('Rechaza capacidad superior a 50', () {
      final evento = Evento(
        nombre: 'Conferencia',
        capacidad: 60,
        inicio: inicio,
        fin: fin,
      );

      expect(
        EventoValidator.validar(evento),
        contains('capacidad'),
      );
    });

    test('Rechaza capacidad igual a cero', () {
      final evento = Evento(
        nombre: 'Conferencia',
        capacidad: 0,
        inicio: inicio,
        fin: fin,
      );

      expect(
        EventoValidator.validar(evento),
        isNotNull,
      );
    });

    test('Rechaza nombre vacío', () {
      final evento = Evento(
        nombre: '',
        capacidad: 20,
        inicio: inicio,
        fin: fin,
      );

      expect(
        EventoValidator.validar(evento),
        isNotNull,
      );
    });

    test('Rechaza una fecha pasada', () {
      final pasado = DateTime.now().subtract(
        const Duration(days: 2),
      );

      final evento = Evento(
        nombre: 'Evento pasado',
        capacidad: 20,
        inicio: pasado,
        fin: pasado.add(const Duration(hours: 2)),
      );

      expect(
        EventoValidator.validar(evento),
        isNotNull,
      );
    });

    test('Rechaza finalización anterior al inicio', () {
      final evento = Evento(
        nombre: 'Conferencia',
        capacidad: 20,
        inicio: inicio,
        fin: inicio.subtract(
          const Duration(hours: 1),
        ),
      );

      expect(
        EventoValidator.validar(evento),
        isNotNull,
      );
    });
  });
}
