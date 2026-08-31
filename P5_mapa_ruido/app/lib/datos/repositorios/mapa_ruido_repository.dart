import '../fuentes/mapa_ruido_api.dart';
import '../modelos/celda_ruido.dart';

class MapaRuidoRepository {
  MapaRuidoRepository({MapaRuidoApi? api}) : _api = api ?? MapaRuidoApi();

  final MapaRuidoApi _api;

  Future<List<CeldaRuido>> obtenerCeldas() => _api.obtenerCeldas();
}
