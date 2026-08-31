class FalloApp implements Exception {
  const FalloApp(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}
