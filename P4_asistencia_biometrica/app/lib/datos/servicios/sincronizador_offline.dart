import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../local/cola_asistencia_db.dart';
import 'api_asistencia_cliente.dart';

class SincronizadorOffline {
  SincronizadorOffline({ApiAsistenciaCliente? api}) : _api = api ?? ApiAsistenciaCliente();

  final ApiAsistenciaCliente _api;
  final ColaAsistenciaDb _db = ColaAsistenciaDb();

  Future<bool> hayConexion() async {
    final resultado = await Connectivity().checkConnectivity();
    return resultado != ConnectivityResult.none;
  }

  Future<void> sincronizarPendientes() async {
    final conectado = await hayConexion();
    if (!conectado) return;

    final pendientes = await _db.obtenerPendientes();
    if (pendientes.isEmpty) return;

    for (final item in pendientes) {
      try {
        final payload = {
          'tipo': item['tipo'],
          'latitud': item['latitud'],
          'longitud': item['longitud'],
          'precisionM': item['precision_m'],
          'timestamp': item['timestamp'],
        };

        await _api.post('/asistencia/marcacion', payload);
        await _db.marcarComoSincronizada(item['id'] as String);
      } on DioException {
        break;
      } catch (_) {
        break;
      }
    }
  }

  StreamSubscription<List<ConnectivityResult>> escucharConexion({
    required void Function() onCambiar,
  }) {
    return Connectivity().onConnectivityChanged.listen((_) {
      onCambiar();
    });
  }
}
