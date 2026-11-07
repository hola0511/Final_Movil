
import 'package:flutter/material.dart';
import '../models/evento.dart';
import 'crear_evento_screen.dart';

class ListadoEventosScreen extends StatelessWidget {
  ListadoEventosScreen({super.key});

  // Lista de eventos de ejemplo
  final List<Evento> eventos = [
    Evento(
      nombre: 'Conferencia de tecnologia',
      capacidad: 30,
      inicio: DateTime(2026, 11, 14, 9, 0),
      fin: DateTime(2026, 11, 14, 12, 0),
    ),
    Evento(
      nombre: 'Feria de emprendimiento',
      capacidad: 45,
      inicio: DateTime(2026, 11, 18, 10, 0),
      fin: DateTime(2026, 11, 18, 15, 0),
    ),
    Evento(
      nombre: 'Taller de programacion',
      capacidad: 20,
      inicio: DateTime(2026, 11, 21, 14, 0),
      fin: DateTime(2026, 11, 21, 17, 0),
    ),
    Evento(
      nombre: 'Encuentro academico',
      capacidad: 50,
      inicio: DateTime(2026, 11, 25, 8, 0),
      fin: DateTime(2026, 11, 25, 12, 0),
    ),
  ];

  String formatoFecha(DateTime fecha) {
    String dosDigitos(int numero) {
      return numero.toString().padLeft(2, '0');
    }

    return '${dosDigitos(fecha.day)}/'
        '${dosDigitos(fecha.month)}/'
        '${fecha.year} '
        '${dosDigitos(fecha.hour)}:'
        '${dosDigitos(fecha.minute)}';
  }

  Widget construirTarjeta(Evento evento) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.indigo,
                  child: Icon(
                    Icons.event,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    evento.nombre,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 25),
            Row(
              children: [
                const Icon(
                  Icons.people,
                  color: Colors.indigo,
                ),
                const SizedBox(width: 10),
                Text(
                  'Capacidad: ${evento.capacidad} personas',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Colors.indigo,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Inicio: ${formatoFecha(evento.inicio)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.event_available,
                  color: Colors.indigo,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Finalizacion: ${formatoFecha(evento.fin)}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listado de eventos'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Eventos registrados',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Se encontraron ${eventos.length} eventos.',
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 20),
          ...eventos.map(construirTarjeta),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Crear evento'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CrearEventoScreen(),
            ),
          );
        },
      ),
    );
  }
}
