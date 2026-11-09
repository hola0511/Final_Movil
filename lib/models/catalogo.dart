class Categoria {
  final String id;
  final String nombre;
  final String descripcion;

  const Categoria({
    required this.id,
    required this.nombre,
    required this.descripcion,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final nombre = json['nombre'];
    final descripcion = json['descripcion'];

    if (id is! String ||
        nombre is! String ||
        descripcion is! String ||
        id.trim().isEmpty ||
        nombre.trim().isEmpty) {
      throw const FormatException('Categoría con datos inválidos');
    }

    return Categoria(id: id, nombre: nombre, descripcion: descripcion);
  }
}

class Recinto {
  final String id;
  final String nombre;
  final String ubicacion;
  final int capacidadReferencia;

  const Recinto({
    required this.id,
    required this.nombre,
    required this.ubicacion,
    required this.capacidadReferencia,
  });

  factory Recinto.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final nombre = json['nombre'];
    final ubicacion = json['ubicacion'];
    final capacidad = json['capacidadReferencia'];

    if (id is! String ||
        nombre is! String ||
        ubicacion is! String ||
        capacidad is! int ||
        id.trim().isEmpty ||
        nombre.trim().isEmpty ||
        capacidad < 1) {
      throw const FormatException('Recinto con datos inválidos');
    }

    return Recinto(
      id: id,
      nombre: nombre,
      ubicacion: ubicacion,
      capacidadReferencia: capacidad,
    );
  }
}

class Catalogo {
  final List<Categoria> categorias;
  final List<Recinto> recintos;

  const Catalogo({required this.categorias, required this.recintos});

  factory Catalogo.fromJson(Map<String, dynamic> json) {
    final categoriasJson = json['categorias'];
    final recintosJson = json['recintos'];

    if (categoriasJson is! List || recintosJson is! List) {
      throw const FormatException(
        'El JSON debe contener categorías y recintos',
      );
    }

    return Catalogo(
      categorias: categoriasJson.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Formato de categoría incorrecto');
        }

        return Categoria.fromJson(item);
      }).toList(),
      recintos: recintosJson.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Formato de recinto incorrecto');
        }

        return Recinto.fromJson(item);
      }).toList(),
    );
  }

  bool get estaVacio => categorias.isEmpty && recintos.isEmpty;
}
