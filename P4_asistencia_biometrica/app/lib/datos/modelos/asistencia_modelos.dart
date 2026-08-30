class UsuarioModelo {
  UsuarioModelo({
    required this.id,
    required this.documento,
    required this.nombre,
    required this.rol,
    this.fichaId,
  });

  final int id;
  final String documento;
  final String nombre;
  final String rol; // 'aprendiz' | 'instructor'
  final int? fichaId;

  factory UsuarioModelo.fromMap(Map<String, dynamic> map) {
    return UsuarioModelo(
      id: (map['id'] as num).toInt(),
      documento: map['documento'] as String,
      nombre: map['nombre'] as String,
      rol: map['rol'] as String? ?? 'aprendiz',
      fichaId: (map['fichaId'] ?? map['ficha_id']) as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'documento': documento,
      'nombre': nombre,
      'rol': rol,
      'fichaId': fichaId,
    };
  }
}

class MarcacionModelo {
  MarcacionModelo({
    required this.id,
    required this.tipo,
    required this.latitud,
    required this.longitud,
    required this.precisionM,
    required this.distanciaM,
    required this.dentroPerimetro,
    required this.dentroHorario,
    required this.registradaEn,
    this.usuarioNombre,
    this.documento,
  });

  final String id;
  final String tipo; // 'entrada' | 'salida'
  final double latitud;
  final double longitud;
  final double precisionM;
  final double distanciaM;
  final bool dentroPerimetro;
  final bool dentroHorario;
  final DateTime registradaEn;
  final String? usuarioNombre;
  final String? documento;

  factory MarcacionModelo.fromMap(Map<String, dynamic> map) {
    return MarcacionModelo(
      id: map['id'] as String,
      tipo: map['tipo'] as String,
      latitud: (map['latitud'] as num).toDouble(),
      longitud: (map['longitud'] as num).toDouble(),
      precisionM: (map['precision_m'] ?? map['precisionM'] ?? 0.0) as double,
      distanciaM: (map['distancia_m'] ?? map['distanciaM'] ?? 0.0) as double,
      dentroPerimetro: (map['dentro_perimetro'] ?? map['dentroPerimetro']) == true,
      dentroHorario: (map['dentro_horario'] ?? map['dentroHorario']) == true,
      registradaEn: DateTime.parse((map['registrada_en'] ?? map['registradaEn']) as String),
      usuarioNombre: (map['usuario_nombre'] ?? map['usuarioNombre']) as String?,
      documento: map['documento'] as String?,
    );
  }
}
