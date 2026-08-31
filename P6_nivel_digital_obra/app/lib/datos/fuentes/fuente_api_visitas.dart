import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/errores/fallo_app.dart';
import '../../dominio/entidades/medicion_snapshot.dart';
import '../modelos/visita_modelo.dart';

class FuenteApiVisitas {
  FuenteApiVisitas(this._dio);

  final Dio _dio;

  Future<VisitaModelo> crearVisita({
    required String identificador,
    required double azimutObjetivo,
  }) async {
    try {
      final respuesta = await _dio.post<Map<String, dynamic>>(
        '/api/visitas',
        data: {
          'identificador': identificador,
          'azimutObjetivo': azimutObjetivo,
        },
      );
      return VisitaModelo.fromJson(respuesta.data!['visita'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw FalloApp(_mensajeDio(error, 'No se pudo crear la visita.'));
    }
  }

  Future<List<VisitaModelo>> listarVisitas() async {
    try {
      final respuesta = await _dio.get<Map<String, dynamic>>('/api/visitas');
      final visitas = respuesta.data!['visitas'] as List<dynamic>;
      return visitas
          .map((json) => VisitaModelo.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw FalloApp(_mensajeDio(error, 'No se pudieron cargar las visitas.'));
    }
  }

  Future<void> enviarMedicion({
    required int visitaId,
    required MedicionSnapshot snapshot,
    required String fotoAnotadaPath,
  }) async {
    try {
      final datos = FormData.fromMap({
        ...snapshot.toMultipartFields(),
        'foto': await MultipartFile.fromFile(fotoAnotadaPath,
            filename: File(fotoAnotadaPath).uri.pathSegments.last),
      });
      await _dio.post<void>('/api/visitas/$visitaId/mediciones', data: datos);
    } on DioException catch (error) {
      throw FalloApp(_mensajeDio(error, 'No se pudo enviar la medición.'));
    }
  }

  Future<List<int>> descargarReporte(int visitaId) async {
    try {
      final respuesta = await _dio.get<List<int>>(
        '/api/visitas/$visitaId/reporte',
        options: Options(responseType: ResponseType.bytes),
      );
      return respuesta.data!;
    } on DioException catch (error) {
      throw FalloApp(_mensajeDio(error, 'No se pudo generar el reporte.'));
    }
  }

  String _mensajeDio(DioException error, String porDefecto) {
    final datos = error.response?.data;
    if (datos is Map<String, dynamic> && datos['error'] is String) {
      return datos['error'] as String;
    }
    return porDefecto;
  }
}
