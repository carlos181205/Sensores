import '../../dominio/entidades/visita.dart';

class VisitaModelo extends Visita {
  const VisitaModelo({
    required super.id,
    required super.identificador,
    required super.azimutObjetivo,
    required super.iniciaEn,
    super.terminaEn,
  });

  factory VisitaModelo.fromJson(Map<String, dynamic> json) {
    return VisitaModelo(
      id: int.parse(json['id'].toString()),
      identificador: json['identificador'] as String,
      azimutObjetivo: (json['azimutObjetivo'] as num).toDouble(),
      iniciaEn: DateTime.parse(json['iniciaEn'] as String),
      terminaEn: json['terminaEn'] == null
          ? null
          : DateTime.parse(json['terminaEn'] as String),
    );
  }
}