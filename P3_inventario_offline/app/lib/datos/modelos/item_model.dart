class ItemInventario {
  ItemInventario({
    required this.id,
    required this.codigoBarras,
    required this.nombre,
    required this.cantidad,
    required this.estado,
    required this.version,
    required this.modificadoEn,
    this.sucio = 0,
    this.fotoBase64,
  });

  final String id;
  final String codigoBarras;
  final String nombre;
  final int cantidad;
  final String estado; // 'excelente', 'bueno', 'averiado'
  final int version;
  final DateTime modificadoEn;
  final int sucio; // 1 = Modificado localmente y pendiente de sincronizar
  final String? fotoBase64;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigo_barras': codigoBarras,
      'nombre': nombre,
      'cantidad': cantidad,
      'estado': estado,
      'version': version,
      'sucio': sucio,
      'foto_base64': fotoBase64,
      'modificado_en': modificadoEn.toIso8601String(),
    };
  }

  factory ItemInventario.fromMap(Map<String, dynamic> map) {
    return ItemInventario(
      id: map['id'] as String,
      codigoBarras: (map['codigo_barras'] ?? map['codigoBarras']) as String,
      nombre: map['nombre'] as String,
      cantidad: (map['cantidad'] as num).toInt(),
      estado: map['estado'] as String? ?? 'bueno',
      version: (map['version'] as num?)?.toInt() ?? 1,
      sucio: (map['sucio'] as num?)?.toInt() ?? 0,
      fotoBase64: (map['foto_base64'] ?? map['fotoBase64']) as String?,
      modificadoEn: DateTime.parse((map['modificado_en'] ?? map['modificadoEn'] ?? DateTime.now().toIso8601String()) as String),
    );
  }

  ItemInventario copyWith({
    int? cantidad,
    String? estado,
    int? version,
    int? sucio,
    String? fotoBase64,
    DateTime? modificadoEn,
  }) {
    return ItemInventario(
      id: id,
      codigoBarras: codigoBarras,
      nombre: nombre,
      cantidad: cantidad ?? this.cantidad,
      estado: estado ?? this.estado,
      version: version ?? this.version,
      sucio: sucio ?? this.sucio,
      fotoBase64: fotoBase64 ?? this.fotoBase64,
      modificadoEn: modificadoEn ?? this.modificadoEn,
    );
  }
}

class ConflictoVersion {
  ConflictoVersion({
    required this.id,
    required this.versionServidor,
    required this.versionCliente,
    required this.valorServidor,
    required this.valorCliente,
  });

  final String id;
  final int versionServidor;
  final int versionCliente;
  final Map<String, dynamic> valorServidor;
  final Map<String, dynamic> valorCliente;

  factory ConflictoVersion.fromMap(Map<String, dynamic> map) {
    return ConflictoVersion(
      id: map['id'] as String,
      versionServidor: (map['versionServidor'] as num).toInt(),
      versionCliente: (map['versionCliente'] as num).toInt(),
      valorServidor: Map<String, dynamic>.from(map['valorServidor'] as Map),
      valorCliente: Map<String, dynamic>.from(map['valorCliente'] as Map),
    );
  }
}
