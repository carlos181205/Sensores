import 'dart:math' as math;

class Inclinacion {
  const Inclinacion({required this.x, required this.y});

  final double x;
  final double y;
}

class CalculadoraInclinacion {
  const CalculadoraInclinacion();

  Inclinacion desdeAcelerometro({
    required double x,
    required double y,
    required double z,
  }) {
    if (![x, y, z].every((valor) => valor.isFinite)) {
      throw ArgumentError('Las lecturas del acelerómetro deben ser finitas.');
    }
    final inclinacionX = math.atan2(y, math.sqrt(x * x + z * z)) * 180 / math.pi;
    final inclinacionY = math.atan2(-x, math.sqrt(y * y + z * z)) * 180 / math.pi;
    return Inclinacion(x: inclinacionX, y: inclinacionY);
  }
}
