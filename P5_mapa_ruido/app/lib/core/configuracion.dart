class ConfiguracionP5 {
  const ConfiguracionP5._();

  // Cambiar esta URL por la IP del PC en la red local del dispositivo.
  static const String apiBaseUrl = 'http://192.168.1.2:3000/api';

  // El GPS solo actualiza la posición después de este desplazamiento.
  static const int distanceFilterMeters = 15;

  // Se descartan mediciones cuya precisión estimada supere este límite.
  static const double maxGpsAccuracyMeters = 40;

  // La captura se detiene por debajo de este porcentaje.
  static const int minBatteryPercent = 15;

  // Intervalo de sondeo para detectar cambios de nivel durante la captura.
  static const Duration batteryCheckInterval = Duration(seconds: 15);

  // Rangos relativos 0–100; no son límites ambientales oficiales.
  static const double ruidoBajoMax = 25;
  static const double ruidoModeradoMax = 50;
  static const double ruidoAltoMax = 75;
}
