import 'package:flutter/material.dart';

import '../models/evento.dart';
import '../repositories/evento_repository.dart';
import '../utils/evento_validator.dart';

class EditarEventoScreen extends StatefulWidget {
  final Evento evento;

  const EditarEventoScreen({super.key, required this.evento});

  @override
  State<EditarEventoScreen> createState() => _EditarEventoScreenState();
}

class _EditarEventoScreenState extends State<EditarEventoScreen> {
  final EventoRepository repository = EventoRepository();

  late final TextEditingController nombreController;
  late final TextEditingController capacidadController;

  late DateTime inicio;
  late DateTime fin;

  bool guardando = false;

  @override
  void initState() {
    super.initState();

    nombreController = TextEditingController(text: widget.evento.nombre);

    capacidadController = TextEditingController(
      text: widget.evento.capacidad.toString(),
    );

    inicio = widget.evento.inicio;
    fin = widget.evento.fin;
  }

  @override
  void dispose() {
    nombreController.dispose();
    capacidadController.dispose();
    super.dispose();
  }

  String formatoFecha(DateTime fecha) {
    String dos(int valor) => valor.toString().padLeft(2, '0');

    return '${dos(fecha.day)}/${dos(fecha.month)}/'
        '${fecha.year} '
        '${dos(fecha.hour)}:${dos(fecha.minute)}';
  }

  Future<void> seleccionarFecha(bool esInicio) async {
    final ahora = DateTime.now();
    final actual = esInicio ? inicio : fin;

    final hoy = DateTime(ahora.year, ahora.month, ahora.day);

    final fechaInicial = actual.isBefore(hoy) ? hoy : actual;

    final fecha = await showDatePicker(
      context: context,
      initialDate: fechaInicial,
      firstDate: hoy,
      lastDate: DateTime(2100),
    );

    if (fecha == null || !mounted) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(actual),
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

  void mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), duration: const Duration(seconds: 4)),
    );
  }

  Future<void> guardarCambios() async {
    if (guardando) return;

    final nombre = nombreController.text.trim();

    final capacidad = int.tryParse(capacidadController.text.trim());

    if (capacidad == null) {
      mostrarMensaje('Ingresa una capacidad numérica válida');
      return;
    }

    if (capacidad < widget.evento.confirmados) {
      mostrarMensaje(
        'No puedes reducir la capacidad por debajo '
        'de ${widget.evento.confirmados} confirmados',
      );
      return;
    }

    final actualizado = Evento(
      id: widget.evento.id,
      nombre: nombre,
      capacidad: capacidad,
      inicio: inicio,
      fin: fin,
      organizadorUid: widget.evento.organizadorUid,
      estado: widget.evento.estado,
      confirmados: widget.evento.confirmados,
      categoriaId: widget.evento.categoriaId,
      recintoId: widget.evento.recintoId,
    );

    final error = EventoValidator.validar(actualizado);

    if (error != null) {
      mostrarMensaje(error);
      return;
    }

    setState(() => guardando = true);

    try {
      await repository.editarEvento(
        eventoId: widget.evento.id,
        nombre: nombre,
        capacidad: capacidad,
        inicio: inicio,
        fin: fin,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      mostrarMensaje('No se pudo actualizar el evento: $error');
    } finally {
      if (mounted) {
        setState(() => guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar evento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Editando: ${widget.evento.nombre}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estado: ${widget.evento.estado}'),
                    const SizedBox(height: 8),
                    Text(
                      'Confirmados al abrir: '
                      '${widget.evento.confirmados}',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'La capacidad nueva no puede '
                      'ser menor que el número de '
                      'participantes confirmados.',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: nombreController,
              maxLength: 150,
              decoration: const InputDecoration(
                labelText: 'Nombre del evento',
                prefixIcon: Icon(Icons.event),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

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

            const Text(
              'Fecha y hora de inicio',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: guardando ? null : () => seleccionarFecha(true),
              icon: const Icon(Icons.calendar_month),
              label: Text(formatoFecha(inicio)),
            ),

            const SizedBox(height: 20),

            const Text(
              'Fecha y hora de finalización',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: guardando ? null : () => seleccionarFecha(false),
              icon: const Icon(Icons.schedule),
              label: Text(formatoFecha(fin)),
            ),

            const SizedBox(height: 24),

            const Text(
              'La categoría y el recinto actuales '
              'se conservarán. Esta versión permite '
              'editar nombre, fechas y capacidad.',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: guardando ? null : guardarCambios,
              icon: const Icon(Icons.save),
              label: Text(
                guardando ? 'Guardando cambios...' : 'Guardar cambios',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
