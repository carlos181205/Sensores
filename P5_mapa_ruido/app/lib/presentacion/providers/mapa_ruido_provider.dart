import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../datos/fuentes/mapa_ruido_api.dart';
import '../../datos/repositorios/mapa_ruido_repository.dart';
import '../../datos/modelos/celda_ruido.dart';

final mapaRuidoRepositoryProvider = Provider<MapaRuidoRepository>((ref) {
  return MapaRuidoRepository(api: MapaRuidoApi());
});

final mapaRuidoProvider = FutureProvider.autoDispose<List<CeldaRuido>>((ref) {
  return ref.watch(mapaRuidoRepositoryProvider).obtenerCeldas();
});
