class Visita {
  const Visita({
    required this.id,
    required this.identificador,
    required this.azimutObjetivo,
    required this.iniciaEn,
    this.terminaEn,
  });

  final int id;
  final String identificador;
  final double azimutObjetivo;
  final DateTime iniciaEn;
  final DateTime? terminaEn;
}
