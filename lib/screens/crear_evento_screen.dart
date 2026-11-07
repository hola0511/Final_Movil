
import 'package:flutter/material.dart';
import '../models/evento.dart';
import '../utils/evento_validator.dart';

class CrearEventoScreen extends StatefulWidget {
  const CrearEventoScreen({super.key});

  @override
  State<CrearEventoScreen> createState() =>
      _CrearEventoScreenState();
}

class _CrearEventoScreenState extends State<CrearEventoScreen> {
  final nombreController = TextEditingController();
  final capacidadController = TextEditingController();

  DateTime? inicio;
  DateTime? fin;

  @override
  void dispose() {
    nombreController.dispose();
    capacidadController.dispose();
    super.dispose();
  }

  Future<void> seleccionarFecha(bool esInicio) async {
    final ahora = DateTime.now();
    final primerDia = DateTime(
      ahora.year,
      ahora.month,
      ahora.day,
    );

    final fecha = await showDatePicker(
      context: context,
      initialDate: primerDia,
      firstDate: primerDia,
      lastDate: DateTime(2100),
    );

    if (fecha == null || !mounted) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(ahora),
    );

    if (hora == null || !mounted) return;

    final seleccion = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      hora.hour,
      hora.minute,
    );

    setState(() {
      if (esInicio) {
        inicio = seleccion;
      } else {
        fin = seleccion;
      }
    });
  }

  String formatoFecha(DateTime? fecha) {
    if (fecha == null) return 'Seleccionar fecha y hora';

    String dosDigitos(int valor) =>
        valor.toString().padLeft(2, '0');

    return '${dosDigitos(fecha.day)}/'
        '${dosDigitos(fecha.month)}/'
        '${fecha.year} '
        '${dosDigitos(fecha.hour)}:'
        '${dosDigitos(fecha.minute)}';
  }

  void mostrarMensaje(String mensaje, bool exito) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: exito ? Colors.green : Colors.red,
      ),
    );
  }

  void validarFormulario() {
    final capacidad =
        int.tryParse(capacidadController.text.trim());

    if (capacidad == null) {
      mostrarMensaje('Ingresa una capacidad válida', false);
      return;
    }

    if (inicio == null || fin == null) {
      mostrarMensaje('Selecciona ambas fechas', false);
      return;
    }

    final evento = Evento(
      nombre: nombreController.text,
      capacidad: capacidad,
      inicio: inicio!,
      fin: fin!,
    );

    final error = EventoValidator.validar(evento);

    if (error != null) {
      mostrarMensaje(error, false);
      return;
    }

    mostrarMensaje(
      'Evento validado correctamente',
      true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear evento'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Registrar evento',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Completa los datos y valida el evento.',
          ),
          const SizedBox(height: 25),

          TextField(
            controller: nombreController,
            decoration: const InputDecoration(
              labelText: 'Nombre del evento',
              prefixIcon: Icon(Icons.event),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: capacidadController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Capacidad (1 a 50)',
              prefixIcon: Icon(Icons.people),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Fecha de inicio'),
              subtitle: Text(formatoFecha(inicio)),
              onTap: () => seleccionarFecha(true),
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.event_available),
              title: const Text('Fecha de finalización'),
              subtitle: Text(formatoFecha(fin)),
              onTap: () => seleccionarFecha(false),
            ),
          ),

          const SizedBox(height: 30),

          ElevatedButton.icon(
            onPressed: validarFormulario,
            icon: const Icon(Icons.check_circle),
            label: const Text('Validar evento'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
