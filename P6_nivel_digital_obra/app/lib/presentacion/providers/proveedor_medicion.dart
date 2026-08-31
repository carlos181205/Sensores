import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constantes/configuracion.dart';
import '../../datos/fuentes/fuente_api_visitas.dart';
import '../../datos/repositorios/repositorio_visitas_api.dart';
import '../../dominio/entidades/medicion_snapshot.dart';
import '../../dominio/entidades/visita.dart';
import '../../dominio/repositorios/repositorio_visitas.dart';

enum FaseMedicion { inicializando, lista, fotoTomada, enviando, enviada, error }

class EstadoMedicion {
  const EstadoMedicion({
    this.fase = FaseMedicion.inicializando,
    this.visita,
    this.snapshot,
    this.fotoAnotadaPath,
    this.error,
  });

  final FaseMedicion fase;
  final Visita? visita;
  final MedicionSnapshot? snapshot;
  final String? fotoAnotadaPath;
  final String? error;

  EstadoMedicion copyWith({
    FaseMedicion? fase,
    Visita? visita,
    MedicionSnapshot? snapshot,
    String? fotoAnotadaPath,
    String? error,
  }) =>
      EstadoMedicion(
        fase: fase ?? this.fase,
        visita: visita ?? this.visita,
        snapshot: snapshot ?? this.snapshot,
        fotoAnotadaPath: fotoAnotadaPath ?? this.fotoAnotadaPath,
        error: error,
      );
}

final proveedorRepositorioVisitas = Provider<RepositorioVisitas>((ref) {
  final dio = Dio(BaseOptions(baseUrl: ConfiguracionApp.apiBaseUrl));
  return RepositorioVisitasApi(FuenteApiVisitas(dio));
});

class ControladorMedicion extends Notifier<EstadoMedicion> {
  @override
  EstadoMedicion build() => const EstadoMedicion();

  void seleccionarVisita(Visita visita) {
    state = EstadoMedicion(fase: FaseMedicion.lista, visita: visita);
  }

  void guardarFoto({required MedicionSnapshot snapshot, required String fotoAnotadaPath}) {
    state = state.copyWith(
      fase: FaseMedicion.fotoTomada,
      snapshot: snapshot,
      fotoAnotadaPath: fotoAnotadaPath,
    );
  }

  Future<void> enviar() async {
    final visita = state.visita;
    final snapshot = state.snapshot;
    final foto = state.fotoAnotadaPath;
    if (visita == null || snapshot == null || foto == null) {
      state = state.copyWith(fase: FaseMedicion.error, error: 'No hay una captura para enviar.');
      return;
    }
    state = state.copyWith(fase: FaseMedicion.enviando);
    try {
      await ref.read(proveedorRepositorioVisitas).enviarMedicion(
            visitaId: visita.id,
            snapshot: snapshot,
            fotoAnotadaPath: foto,
          );
      state = state.copyWith(fase: FaseMedicion.enviada);
    } catch (error) {
      state = state.copyWith(fase: FaseMedicion.error, error: error.toString());
    }
  }

  Future<void> descargarYCompartirReporte() async {
    final visita = state.visita;
    if (visita == null) return;
    try {
      final bytes = await ref.read(proveedorRepositorioVisitas).descargarReporte(visita.id);
      final directorio = await getTemporaryDirectory();
      final archivo = File('${directorio.path}/reporte_visita_${visita.id}.pdf');
      await archivo.writeAsBytes(bytes);
      await SharePlus.instance.share(ShareParams(files: [XFile(archivo.path)]));
    } catch (error) {
      state = state.copyWith(fase: FaseMedicion.error, error: error.toString());
    }
  }
}

final proveedorMedicion = NotifierProvider<ControladorMedicion, EstadoMedicion>(
  ControladorMedicion.new,
);
