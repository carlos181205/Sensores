import '../entidades/medicion_snapshot.dart';
import '../entidades/visita.dart';

abstract class RepositorioVisitas {
  Future<Visita> crearVisita({
    required String identificador,
    required double azimutObjetivo,
  });

  Future<List<Visita>> listarVisitas();
  Future<void> enviarMedicion({
    required int visitaId,
    required MedicionSnapshot snapshot,
    required String fotoAnotadaPath,
  });

  Future<List<int>> descargarReporte(int visitaId);
}
