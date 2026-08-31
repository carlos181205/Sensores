class ConfiguracionApp {
  const ConfiguracionApp._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.2:3000',
  );

  static const double pesoFiltroComplementario = 0.98;

  static const double maxInclinacionPermitida = 1.5;

  static const double maxDesviacionAzimutPermitida = 5.0;

  static const int maxFotoBytes = 4 * 1024 * 1024;
}