import '../fuentes/muestras_api.dart';
import '../modelos/muestra_ruido.dart';

class MuestrasRepository {
  MuestrasRepository({MuestrasApi? api}) : _api = api ?? MuestrasApi();

  final MuestrasApi _api;

  Future<int> enviarLote(List<MuestraRuido> muestras) {
    return _api.enviarLote(muestras);
  }
}
