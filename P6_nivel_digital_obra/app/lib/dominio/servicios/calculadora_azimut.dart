import 'dart:math' as math;

class CalculadoraAzimut {
  const CalculadoraAzimut();

  double normalizar(double grados) {
    if (!grados.isFinite) {
      throw ArgumentError('El azimut debe ser finito.');
    }
    final normalizado = grados % 360;
    return normalizado < 0 ? normalizado + 360 : normalizado;
  }

  /// Positivo: giro horario desde el objetivo hasta el rumbo actual.
  double desviacionCircular(double actual, double objetivo) {
    final diferencia = (normalizar(actual) - normalizar(objetivo) + 540) % 360 - 180;
    return diferencia == -180 ? 180 : diferencia;
  }

  double desdeMagnetometro({required double x, required double y}) {
    if (![x, y].every((valor) => valor.isFinite)) {
      throw ArgumentError('Las lecturas del magnetómetro deben ser finitas.');
    }
    return normalizar(-math.atan2(y, x) * 180 / math.pi);
  }
}
