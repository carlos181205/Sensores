import 'dart:async';
import '../local/db_helper_ronda.dart';
import 'api_ronda_cliente.dart';

class SincronizadorRonda {
  SincronizadorRonda({ApiRondaCliente? apiCliente}) : _apiCliente = apiCliente ?? ApiRondaCliente();

  final ApiRondaCliente _apiCliente;
  final DbHelperRonda _dbHelper = DbHelperRonda.instance;

  Future<int> sincronizarPendientes() async {
    final pendientes = await _dbHelper.obtenerPendientes();
    if (pendientes.isEmpty) return 0;

    int procesados = 0;

    for (final m in pendientes) {
      try {
        final payload = {
          'rondaId': m.rondaId,
          'codigo': m.codigo,
          'latitud': m.latitud,
          'longitud': m.longitud,
          'precisionM': m.precisionM,
          'escaneadaEn': m.escaneadaEn.toIso8601String(),
        };

        final response = await _apiCliente.post('/rondas/${m.rondaId}/marcaciones', payload);
        final aceptada = (response.data['ok'] as bool?) ?? false;
        final motivo = response.data['marcacion']?['motivo_rechazo'] as String?;

        if (m.id != null) {
          await _dbHelper.marcarEnviado(m.id!, aceptada, motivo);
        }
        procesados++;
      } catch (e) {
        // Si fue rechazada por geocerca (HTTP 422), dio lanza exception pero el server devuelve json
        final msg = e.toString();
        if (m.id != null && msg.contains('Fuera de rango')) {
          await _dbHelper.marcarEnviado(m.id!, false, msg);
          procesados++;
        }
      }
    }

    return procesados;
  }
}
