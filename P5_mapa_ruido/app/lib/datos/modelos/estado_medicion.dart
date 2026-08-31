enum EstadoCaptura { detenido, capturando, enviando, error, bateriaBaja }

class EstadoMedicion {
  final EstadoCaptura estado;
  final int? bateriaPercent;
  final String mensaje;

  const EstadoMedicion({
    required this.estado,
    required this.mensaje,
    this.bateriaPercent,
  });
}
