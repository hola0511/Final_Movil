import 'package:flutter/material.dart';

import '../models/evento.dart';
import '../repositories/evento_repository.dart';
import '../utils/evento_validator.dart';

class CrearEventoScreen extends StatefulWidget {
  const CrearEventoScreen({super.key});

  @override
  State<CrearEventoScreen> createState() => _CrearEventoScreenState();
}

class _CrearEventoScreenState extends State<CrearEventoScreen> {
  final nombreController = TextEditingController();
  final capacidadController = TextEditingController();

  final repository = EventoRepository();

  DateTime? inicio;
  DateTime? fin;
  bool guardando = false;

  @override
  void dispose() {
    nombreController.dispose();
    capacidadController.dispose();
    super.dispose();
  }

  Future<void> seleccionarFecha(bool esInicio) async {
    final ahora = DateTime.now();

    final fecha = await showDatePicker(
      context: context,
      initialDate: ahora,
      firstDate: DateTime(ahora.year, ahora.month, ahora.day),
      lastDate: DateTime(2100),
    );

    if (fecha == null || !mounted) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(ahora),
    );

    if (hora == null || !mounted) return;

    setState(() {
      final resultado = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        hora.hour,
        hora.minute,
      );

      if (esInicio) {
        inicio = resultado;
      } else {
        fin = resultado;
      }
    });
  }

  String formatoFecha(DateTime? fecha) {
    if (fecha == null) {
      return 'Seleccionar fecha y hora';
    }

    String dos(int valor) => valor.toString().padLeft(2, '0');

    return '${dos(fecha.day)}/${dos(fecha.month)}/'
        '${fecha.year} ${dos(fecha.hour)}:'
        '${dos(fecha.minute)}';
  }

  void mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> guardarEvento() async {
    if (guardando) return;

    final capacidad = int.tryParse(capacidadController.text.trim());

    if (capacidad == null || inicio == null || fin == null) {
      mostrarMensaje('Completa todos los campos');
      return;
    }

    final evento = Evento(
      nombre: nombreController.text.trim(),
      capacidad: capacidad,
      inicio: inicio!,
      fin: fin!,
    );

    final error = EventoValidator.validar(evento);

    if (error != null) {
      mostrarMensaje(error);
      return;
    }

    setState(() => guardando = true);

    try {
      await repository.crearEvento(evento);

      if (!mounted) return;

      mostrarMensaje('Evento guardado como borrador');

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      mostrarMensaje('No se pudo guardar: $e');
    } finally {
      if (mounted) {
        setState(() => guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear evento')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Nuevo evento',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Los eventos se guardan inicialmente '
            'como borradores.',
          ),
          const SizedBox(height: 24),

          TextField(
            controller: nombreController,
            enabled: !guardando,
            decoration: const InputDecoration(
              labelText: 'Nombre del evento',
              prefixIcon: Icon(Icons.event),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: capacidadController,
            enabled: !guardando,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Capacidad (1 a 50)',
              prefixIcon: Icon(Icons.people),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Fecha de inicio'),
              subtitle: Text(formatoFecha(inicio)),
              onTap: guardando ? null : () => seleccionarFecha(true),
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Fecha de finalización'),
              subtitle: Text(formatoFecha(fin)),
              onTap: guardando ? null : () => seleccionarFecha(false),
            ),
          ),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: guardando ? null : guardarEvento,
            icon: const Icon(Icons.save),
            label: Text(guardando ? 'Guardando...' : 'Guardar borrador'),
          ),
        ],
      ),
    );
  }
}
