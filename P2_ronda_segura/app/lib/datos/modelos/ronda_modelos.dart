class PuntoControl {
  PuntoControl({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.latitud,
    required this.longitud,
    required this.radioM,
    required this.orden,
  });

  final int id;
  final String codigo;
  final String nombre;
  final double latitud;
  final double longitud;
  final int radioM;
  final int orden;

  factory PuntoControl.fromMap(Map<String, dynamic> map) {
    return PuntoControl(
      id: map['id'] as int,
      codigo: map['codigo'] as String,
      nombre: map['nombre'] as String,
      latitud: (map['latitud'] as num).toDouble(),
      longitud: (map['longitud'] as num).toDouble(),
      radioM: (map['radio_m'] as num?)?.toInt() ?? 40,
      orden: (map['orden'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'latitud': latitud,
      'longitud': longitud,
      'radio_m': radioM,
      'orden': orden,
    };
  }
}

class MarcacionLocal {
  MarcacionLocal({
    required this.id,
    required this.rondaId,
    required this.codigo,
    required this.latitud,
    required this.longitud,
    required this.precisionM,
    required this.escaneadaEn,
    this.enviado = 0,
    this.aceptada = false,
    this.motivoRechazo,
  });

  final int? id;
  final String rondaId;
  final String codigo;
  final double latitud;
  final double longitud;
  final double precisionM;
  final DateTime escaneadaEn;
  final int enviado;
  final bool aceptada;
  final String? motivoRechazo;

  Map<String, dynamic> toMap() {
    return {
      'ronda_id': rondaId,
      'codigo': codigo,
      'latitud': latitud,
      'longitud': longitud,
      'precision_m': precisionM,
      'escaneada_en': escaneadaEn.toIso8601String(),
      'enviado': enviado,
      'aceptada': aceptada ? 1 : 0,
      'motivo_rechazo': motivoRechazo,
    };
  }

  factory MarcacionLocal.fromMap(Map<String, dynamic> map) {
    return MarcacionLocal(
      id: map['id'] as int?,
      rondaId: map['ronda_id'] as String,
      codigo: map['codigo'] as String,
      latitud: (map['latitud'] as num).toDouble(),
      longitud: (map['longitud'] as num).toDouble(),
      precisionM: (map['precision_m'] as num).toDouble(),
      escaneadaEn: DateTime.parse(map['escaneada_en'] as String),
      enviado: map['enviado'] as int? ?? 0,
      aceptada: (map['aceptada'] as int?) == 1,
      motivoRechazo: map['motivo_rechazo'] as String?,
    );
  }
}
