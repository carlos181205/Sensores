import 'dart:async';
import '../local/db_helper_inventario.dart';
import '../modelos/item_model.dart';
import 'api_inventario_cliente.dart';

class ResultadoSync {
  ResultadoSync({
    required this.aplicadosCount,
    required this.conflictos,
    required this.exitoso,
    this.errorMensaje,
  });

  final int aplicadosCount;
  final List<ConflictoVersion> conflictos;
  final bool exitoso;
  final String? errorMensaje;
}

class SincronizadorInventario {
  SincronizadorInventario({ApiInventarioCliente? apiCliente})
      : _apiCliente = apiCliente ?? ApiInventarioCliente();

  final ApiInventarioCliente _apiCliente;
  final DbHelperInventario _dbHelper = DbHelperInventario.instance;
  DateTime? _ultimaSync;

  Future<ResultadoSync> sincronizar() async {
    final sucios = await _dbHelper.obtenerModificadosSucios();

    final cambiosPayload = sucios.map((item) => {
      'id': item.id,
      'codigo_barras': item.codigoBarras,
      'nombre': item.nombre,
      'cantidad': item.cantidad,
      'estado': item.estado,
      'version': item.version,
      'foto_base64': item.fotoBase64,
      'modificado_en': item.modificadoEn.toUtc().toIso8601String(),
    }).toList();

    try {
      final res = await _apiCliente.post('/sync', {
        'ultimaSync': _ultimaSync?.toUtc().toIso8601String(),
        'cambiosLocales': cambiosPayload,
      });

      final data = res.data as Map<String, dynamic>;
      final aplicados = (data['aplicados'] as List?)?.cast<String>() ?? [];
      final conflictosRaw = (data['conflictos'] as List?) ?? [];
      final remotosRaw = (data['cambiosRemotos'] as List?) ?? [];
      final servidorEnStr = data['servidorEn'] as String?;

      if (servidorEnStr != null) {
        _ultimaSync = DateTime.parse(servidorEnStr);
      }

      // 1. Marcar como limpios los ítems que se aplicaron exitosamente en el servidor
      for (final item in sucios) {
        if (aplicados.contains(item.id)) {
          await _dbHelper.marcarComoLimpio(item.id, item.version + 1);
        }
      }

      // 2. Aplicar cambios remotos recibidos del servidor
      for (final r in remotosRaw) {
        final itemRemoto = ItemInventario.fromMap(Map<String, dynamic>.from(r as Map));
        await _dbHelper.actualizarItemDesdeServidor(itemRemoto);
      }

      final conflictos = conflictosRaw.map((c) => ConflictoVersion.fromMap(Map<String, dynamic>.from(c as Map))).toList();

      return ResultadoSync(
        aplicadosCount: aplicados.length,
        conflictos: conflictos,
        exitoso: true,
      );
    } catch (e) {
      return ResultadoSync(
        aplicadosCount: 0,
        conflictos: [],
        exitoso: false,
        errorMensaje: e.toString(),
      );
    }
  }

  Future<bool> resolverConflictoEnServidor(String id, String conservar, Map<String, dynamic> valorElegido) async {
    try {
      final res = await _apiCliente.post('/items/resolver-conflicto', {
        'id': id,
        'conservar': conservar,
        'valorElegido': valorElegido,
      });

      if (res.data['ok'] == true) {
        final itemRes = res.data['item'];
        if (itemRes != null) {
          final item = ItemInventario.fromMap(Map<String, dynamic>.from(itemRes as Map));
          await _dbHelper.actualizarItemDesdeServidor(item);
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
