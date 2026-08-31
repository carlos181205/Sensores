import 'dart:async';

import 'package:battery_plus/battery_plus.dart';

import '../../core/configuracion.dart';

class BateriaService {
  BateriaService({Battery? battery}) : _battery = battery ?? Battery();

  final Battery _battery;

  Future<int> obtenerNivel() => _battery.batteryLevel;

  /// Consulta periódicamente el nivel para detectar también cambios que no
  /// produzcan una transición de estado de carga.
  Stream<int> observarNiveles({
    Duration intervalo = ConfiguracionP5.batteryCheckInterval,
  }) async* {
    yield await obtenerNivel();
    yield* Stream.periodic(
      intervalo,
      (_) => obtenerNivel(),
    ).asyncMap((nivel) => nivel).distinct();
  }
}
