import '../models/catalogo.dart';
import '../services/catalogo_http_service.dart';

class CatalogoRepository {
  final CatalogoHttpService _service;

  CatalogoRepository({CatalogoHttpService? service})
    : _service = service ?? CatalogoHttpService();

  Future<Catalogo> obtenerCatalogo() {
    return _service.obtenerCatalogo();
  }

  void dispose() {
    _service.cerrar();
  }
}
