class MedicionSnapshot {
  const MedicionSnapshot({
    required this.inclinacionX,
    required this.inclinacionY,
    required this.azimut,
    required this.azimutObjetivo,
    required this.desviacionAzimut,
    required this.latitud,
    required this.longitud,
    required this.cumple,
    required this.medidoEn,
  });

  final double inclinacionX;
  final double inclinacionY;
  final double azimut;
  final double azimutObjetivo;
  final double desviacionAzimut;
  final double? latitud;
  final double? longitud;
  final bool cumple;
  final DateTime medidoEn;

  Map<String, String> toMultipartFields() => {
        'inclinacionX': inclinacionX.toString(),
        'inclinacionY': inclinacionY.toString(),
        'azimut': azimut.toString(),
        'azimutObjetivo': azimutObjetivo.toString(),
        'desviacionAzimut': desviacionAzimut.toString(),
        'latitud': latitud?.toString() ?? '',
        'longitud': longitud?.toString() ?? '',
        'cumple': cumple.toString(),
        'medidoEn': medidoEn.toUtc().toIso8601String(),
      };
}
