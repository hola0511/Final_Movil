import 'package:flutter/material.dart';

import '../models/catalogo.dart';
import '../repositories/catalogo_repository.dart';

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  final CatalogoRepository repository = CatalogoRepository();

  late Future<Catalogo> catalogoFuture;

  @override
  void initState() {
    super.initState();
    cargarCatalogo();
  }

  void cargarCatalogo() {
    catalogoFuture = repository.obtenerCatalogo();
  }

  void reintentar() {
    setState(() {
      cargarCatalogo();
    });
  }

  @override
  void dispose() {
    repository.dispose();
    super.dispose();
  }

  Widget construirError(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 70, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              'No se pudo cargar el catálogo',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('$error', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: reintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget construirVacio() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 70, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('El catálogo está vacío', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: reintentar,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  Widget tarjetaCategoria(Categoria categoria) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.category)),
        title: Text(
          categoria.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(categoria.descripcion),
      ),
    );
  }

  Widget tarjetaRecinto(Recinto recinto) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_city, size: 28, color: Colors.indigo),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    recinto.nombre,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('ID: ${recinto.id}'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Ubicación: ${recinto.ubicacion}')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.people_outline, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Capacidad de referencia: '
                  '${recinto.capacidadReferencia}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget construirCatalogo(Catalogo catalogo) {
    if (catalogo.estaVacio) {
      return construirVacio();
    }

    return RefreshIndicator(
      onRefresh: () async {
        reintentar();
        try {
          await catalogoFuture;
        } catch (_) {
          // El FutureBuilder muestra el error.
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Catálogo remoto',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Categorías y recintos consultados '
            'mediante HTTP/JSON.',
          ),
          const SizedBox(height: 12),
          const Text(
            'La capacidad de referencia no representa '
            'los cupos disponibles de un evento.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              const Icon(Icons.category),
              const SizedBox(width: 8),
              Text(
                'Categorías (${catalogo.categorias.length})',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          for (final categoria in catalogo.categorias)
            tarjetaCategoria(categoria),

          const SizedBox(height: 24),

          Row(
            children: [
              const Icon(Icons.location_city),
              const SizedBox(width: 8),
              Text(
                'Recintos (${catalogo.recintos.length})',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          for (final recinto in catalogo.recintos) tarjetaRecinto(recinto),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de eventos'),
        actions: [
          IconButton(
            tooltip: 'Actualizar catálogo',
            onPressed: reintentar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<Catalogo>(
        future: catalogoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Consultando catálogo HTTP...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return construirError(snapshot.error!);
          }

          if (!snapshot.hasData) {
            return construirVacio();
          }

          return construirCatalogo(snapshot.data!);
        },
      ),
    );
  }
}
