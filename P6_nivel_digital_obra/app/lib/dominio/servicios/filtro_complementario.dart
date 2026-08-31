class FiltroComplementario {
  FiltroComplementario({this.peso = 0.98})
      : assert(peso >= 0 && peso <= 1, 'El peso debe estar entre 0 y 1.');

  final double peso;
  double? _angulo;

  double actualizar({
    required double anguloAcelerometro,
    required double velocidadAngular,
    required double deltaSegundos,
  }) {
    if (![anguloAcelerometro, velocidadAngular, deltaSegundos]
        .every((valor) => valor.isFinite)) {
      throw ArgumentError('Los datos del filtro deben ser finitos.');
    }
    if (deltaSegundos < 0 || deltaSegundos > 1) {
      throw ArgumentError('El delta de tiempo debe estar entre 0 y 1 segundo.');
    }
    final previo = _angulo;
    if (previo == null) {
      _angulo = anguloAcelerometro;
      return _angulo!;
    }
    final integrado = previo + velocidadAngular * deltaSegundos;
    _angulo = peso * integrado + (1 - peso) * anguloAcelerometro;
    return _angulo!;
  }

  void reiniciar() => _angulo = null;

  double? get anguloActual => _angulo;
}
