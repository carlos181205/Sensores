import 'package:dio/dio.dart';

import '../../core/configuracion.dart';
import '../modelos/muestra_ruido.dart';

class MuestrasApi {
  MuestrasApi({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ConfiguracionP5.apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              sendTimeout: const Duration(seconds: 10),
              headers: {'Content-Type': 'application/json'},
            ),
          );

  final Dio _dio;

  Future<int> enviarLote(List<MuestraRuido> muestras) async {
    if (muestras.length != 20) {
      throw Exception('El lote debe contener exactamente 20 muestras.');
    }

    final respuesta = await _dio.post(
      '/muestras',
      data: {'muestras': muestras.map((muestra) => muestra.toJson()).toList()},
    );

    final datos = respuesta.data;

    if (datos is! Map) {
      throw Exception('Respuesta inválida del servidor.');
    }

    if (datos['ok'] != true) {
      throw Exception(datos['mensaje'] ?? 'No se pudo guardar el lote.');
    }

    final cantidad = datos['cantidad'];
    if (cantidad is! num) {
      throw Exception('Respuesta inválida del servidor.');
    }

    return cantidad.toInt();
  }
}
