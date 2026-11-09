import '../models/evento.dart';

class EventoValidator {
  static String? validar(Evento evento) {
    if (evento.nombre.trim().isEmpty) {
      return 'El nombre del evento es obligatorio';
    }

    if (evento.capacidad < 1 || evento.capacidad > 50) {
      return 'La capacidad debe estar entre 1 y 50';
    }

    if (!evento.inicio.isAfter(DateTime.now())) {
      return 'El evento debe iniciar en una fecha futura';
    }

    if (!evento.fin.isAfter(evento.inicio)) {
      return 'La fecha de fin debe ser posterior al inicio';
    }

    return null;
  }
}
