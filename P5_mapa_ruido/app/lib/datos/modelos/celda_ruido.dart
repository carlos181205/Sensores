class CeldaRuido {
  final double celdaLat;
  final double celdaLon;
  final double promedioDb;
  final double maximoDb;
  final int muestras;

  const CeldaRuido({
    required this.celdaLat,
    required this.celdaLon,
    required this.promedioDb,
    required this.maximoDb,
    required this.muestras,
  });

  factory CeldaRuido.fromJson(Map<String, dynamic> json) {
    return CeldaRuido(
      celdaLat: (json['celdaLat'] as num).toDouble(),
      celdaLon: (json['celdaLon'] as num).toDouble(),
      promedioDb: (json['promedioDb'] as num).toDouble(),
      maximoDb: (json['maximoDb'] as num).toDouble(),
      muestras: (json['muestras'] as num).toInt(),
    );
  }
}
