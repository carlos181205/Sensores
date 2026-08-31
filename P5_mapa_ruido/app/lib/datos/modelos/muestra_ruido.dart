class MuestraRuido {
  final double nivelDb;
  final double latitud;
  final double longitud;
  final double precisionM;
  final DateTime medidoEn;

  const MuestraRuido({
    required this.nivelDb,
    required this.latitud,
    required this.longitud,
    required this.precisionM,
    required this.medidoEn,
  });

  Map<String, dynamic> toJson() {
    return {
      'nivelDb': nivelDb,
      'latitud': latitud,
      'longitud': longitud,
      'precisionM': precisionM,
      'medidoEn': medidoEn.toUtc().toIso8601String(),
    };
  }

  factory MuestraRuido.fromJson(Map<String, dynamic> json) {
    return MuestraRuido(
      nivelDb: (json['nivelDb'] as num).toDouble(),
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
      precisionM: (json['precisionM'] as num).toDouble(),
      medidoEn: DateTime.parse(json['medidoEn'] as String),
    );
  }
}
