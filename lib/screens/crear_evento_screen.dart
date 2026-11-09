import 'package:flutter/material.dart';

import '../models/evento.dart';
import '../models/catalogo.dart';
import '../repositories/evento_repository.dart';
import '../repositories/catalogo_repository.dart';
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
  final catalogoRepository = CatalogoRepository();

  DateTime? inicio;
  DateTime? fin;

  Categoria? categoriaSeleccionada;
  Recinto? recintoSeleccionado;

  Catalogo? catalogo;
  String? errorCatalogo;

  bool cargandoCatalogo = true;
  bool guardando = false;

  @override
  void initState() {
    super.initState();
    cargarCatalogo();
  }

  @override
  void dispose() {
    nombreController.dispose();
    capacidadController.dispose();
    catalogoRepository.dispose();
    super.dispose();
  }

  Future<void> cargarCatalogo() async {
    setState(() {
      cargandoCatalogo = true;
      errorCatalogo = null;
    });

    try {
      final resultado = await catalogoRepository.obtenerCatalogo();

      if (!mounted) return;

      setState(() {
        catalogo = resultado;
        cargandoCatalogo = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorCatalogo = e.toString();
        cargandoCatalogo = false;
      });
    }
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

    if (capacidad == null ||
        inicio == null ||
        fin == null ||
        categoriaSeleccionada == null ||
        recintoSeleccionado == null) {
      mostrarMensaje(
        'Completa todos los campos y selecciona categoría y recinto',
      );
      return;
    }

    final evento = Evento(
      nombre: nombreController.text.trim(),
      capacidad: capacidad,
      inicio: inicio!,
      fin: fin!,
      categoriaId: categoriaSeleccionada!.id,
      recintoId: recintoSeleccionado!.id,
    );

    final error = EventoValidator.validar(
      evento,
      capacidadRecinto: recintoSeleccionado!.capacidadReferencia,
    );

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

          const SizedBox(height: 24),

          const Text(
            'Categoría del evento',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          if (cargandoCatalogo)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (errorCatalogo != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text(errorCatalogo!),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: guardando ? null : cargarCatalogo,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          else if (catalogo == null || catalogo!.categorias.isEmpty)
            const Text('No hay categorías disponibles.')
          else
            DropdownButtonFormField<String>(
              initialValue: categoriaSeleccionada?.id,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
                labelText: 'Seleccionar categoría',
              ),
              items: catalogo!.categorias.map((categoria) {
                return DropdownMenuItem<String>(
                  value: categoria.id,
                  child: Text(categoria.nombre),
                );
              }).toList(),
              onChanged: guardando
                  ? null
                  : (id) {
                      setState(() {
                        categoriaSeleccionada = catalogo!.categorias.firstWhere(
                          (categoria) => categoria.id == id,
                        );
                      });
                    },
            ),

          const SizedBox(height: 20),

          const Text(
            'Recinto del evento',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          if (!cargandoCatalogo &&
              errorCatalogo == null &&
              catalogo != null &&
              catalogo!.recintos.isEmpty)
            const Text('No hay recintos disponibles.')
          else if (!cargandoCatalogo &&
              errorCatalogo == null &&
              catalogo != null)
            DropdownButtonFormField<String>(
              initialValue: recintoSeleccionado?.id,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
                labelText: 'Seleccionar recinto',
              ),
              items: catalogo!.recintos.map((recinto) {
                return DropdownMenuItem<String>(
                  value: recinto.id,
                  child: Text(recinto.nombre),
                );
              }).toList(),
              onChanged: guardando
                  ? null
                  : (id) {
                      setState(() {
                        recintoSeleccionado = catalogo!.recintos.firstWhere(
                          (recinto) => recinto.id == id,
                        );
                      });
                    },
            ),

          if (recintoSeleccionado != null) ...[
            const SizedBox(height: 8),
            Text(
              'Ubicación: ${recintoSeleccionado!.ubicacion}',
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              'Capacidad de referencia: '
              '${recintoSeleccionado!.capacidadReferencia} personas',
              style: const TextStyle(color: Colors.grey),
            ),
          ],

          const SizedBox(height: 24),

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
            onPressed: guardando || cargandoCatalogo || errorCatalogo != null
                ? null
                : guardarEvento,
            icon: const Icon(Icons.save),
            label: Text(guardando ? 'Guardando...' : 'Guardar borrador'),
          ),
        ],
      ),
    );
  }
}
