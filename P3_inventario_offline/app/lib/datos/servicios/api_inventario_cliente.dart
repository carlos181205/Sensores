import 'dart:io';
import 'package:dio/dio.dart';

class ApiInventarioCliente {
  ApiInventarioCliente({String? baseUrl})
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ?? const String.fromEnvironment(
              'BACKEND_URL',
              defaultValue: 'http://10.0.2.2:3002/api',
            ),
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            sendTimeout: const Duration(seconds: 10),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

  final Dio _dio;

  Dio get dio => _dio;

  Future<Response<dynamic>> post(String path, Map<String, dynamic> data) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw _mapError(e);
    } on SocketException {
      throw Exception('Sin conexión a la red');
    }
  }

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _mapError(e);
    } on SocketException {
      throw Exception('Sin conexión a la red');
    }
  }

  Exception _mapError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('Tiempo de espera agotado al conectar con el servidor');
    }

    if (e.type == DioExceptionType.connectionError) {
      return Exception('No se pudo conectar con el backend');
    }

    if (e.response != null) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('mensaje')) {
        return Exception(data['mensaje']);
      }
      return Exception('Error del servidor: HTTP ${e.response?.statusCode}');
    }

    return Exception('Error inesperado de red');
  }
}
