import '../../dominio/entidades/medicion_snapshot.dart';
import '../../dominio/entidades/visita.dart';
import '../../dominio/repositorios/repositorio_visitas.dart';
import '../fuentes/fuente_api_visitas.dart';

class RepositorioVisitasApi implements RepositorioVisitas {
  RepositorioVisitasApi(this._fuente);

  final FuenteApiVisitas _fuente;

  @override
  Future<Visita> crearVisita({
    required String identificador,
    required double azimutObjetivo,
  }) =>
      _fuente.crearVisita(
        identificador: identificador,
        azimutObjetivo: azimutObjetivo,
      );

  @override
  Future<List<Visita>> listarVisitas() => _fuente.listarVisitas();

  @override
  Future<void> enviarMedicion({
    required int visitaId,
    required MedicionSnapshot snapshot,
    required String fotoAnotadaPath,
  }) =>
      _fuente.enviarMedicion(
        visitaId: visitaId,
        snapshot: snapshot,
        fotoAnotadaPath: fotoAnotadaPath,
      );

  @override
  Future<List<int>> descargarReporte(int visitaId) => _fuente.descargarReporte(visitaId);
}
