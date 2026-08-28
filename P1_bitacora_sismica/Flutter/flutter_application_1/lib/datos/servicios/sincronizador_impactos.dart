import 'dart:async';

import 'api_cliente.dart';
import '../local/db_helper.dart';

class SincronizadorImpactos {
  SincronizadorImpactos({ApiCliente? apiCliente}) : _apiCliente = apiCliente ?? ApiCliente();

  final ApiCliente _apiCliente;
  final DbHelper _dbHelper = DbHelper.instance;
  final StreamController<int> _streamController = StreamController.broadcast();

  Stream<int> get pendientesStream => _streamController.stream;

  Future<int> sincronizarPendientes() async {
    final pendientes = await _dbHelper.obtenerPendientes();

    if (pendientes.isEmpty) {
      _streamController.add(0);
      return 0;
    }

    final payload = pendientes.map((item) {
      return {
        'dispositivo_id': item.dispositivoId,
        'clave_cliente': item.claveCliente,
        'intensidad': item.intensidad,
        'latitud': item.latitud,
        'longitud': item.longitud,
        'descripcion': item.descripcion,
        'fecha_evento': item.createdAt.toUtc().toIso8601String(),
      };
    }).toList();

    try {
      final response = await _apiCliente.post('/eventos/lote', {'eventos': payload});
      final total = (response.data['total'] as int?) ?? payload.length;

      for (final item in pendientes) {
        if (item.id != null) {
          await _dbHelper.marcarComoEnviado(item.id!);
        }
      }

      _streamController.add(total);
      return total;
    } catch (_) {
      _streamController.add(pendientes.length);
      return pendientes.length;
    }
  }

  Future<void> verificarYEnviarSiHayRed() async {
    try {
      await _apiCliente.get('/salud');
      await sincronizarPendientes();
    } catch (_) {
      return;
    }
  }

  void dispose() {
    _streamController.close();
  }
}
