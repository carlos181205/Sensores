import 'package:dio/dio.dart';

import '../../core/configuracion.dart';
import '../modelos/celda_ruido.dart';

class MapaRuidoApi {
  MapaRuidoApi({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ConfiguracionP5.apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );

  final Dio _dio;

  Future<List<CeldaRuido>> obtenerCeldas() async {
    final respuesta = await _dio.get('/mapa');
    final datos = respuesta.data;

    if (datos is! Map || datos['ok'] != true || datos['datos'] is! List) {
      throw const FormatException('Respuesta inválida del mapa.');
    }

    return (datos['datos'] as List)
        .map((dato) {
          if (dato is! Map) {
            throw const FormatException('Celda inválida en la respuesta.');
          }
          return CeldaRuido.fromJson(Map<String, dynamic>.from(dato));
        })
        .toList(growable: false);
  }
}
