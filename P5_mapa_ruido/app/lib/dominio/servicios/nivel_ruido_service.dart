class NivelRuidoService {
  /// Convierte el valor técnico dBFS del micrófono a una escala relativa.
  ///
  /// El resultado no es dB SPL calibrado: cada dispositivo tiene un
  /// micrófono y una ganancia diferentes.
  double convertir(double dbfs) {
    final nivel = 100 + dbfs;

    if (nivel < 0) {
      return 0;
    }

    if (nivel > 100) {
      return 100;
    }

    return nivel;
  }
}
