import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EstadoCamara {
  const EstadoCamara({this.controlador, this.cargando = false, this.error});

  final CameraController? controlador;
  final bool cargando;
  final String? error;

  bool get lista => controlador?.value.isInitialized ?? false;
}

class ControladorCamara extends Notifier<EstadoCamara> {
  @override
  EstadoCamara build() {
    ref.onDispose(() => state.controlador?.dispose());
    return const EstadoCamara();
  }

  Future<void> iniciar() async {
    if (state.lista || state.cargando) return;
    state = const EstadoCamara(cargando: true);
    try {
      final disponibles = await availableCameras();
      if (disponibles.isEmpty) throw StateError('No hay cámara disponible.');
      final camara = disponibles.firstWhere(
        (valor) => valor.lensDirection == CameraLensDirection.back,
        orElse: () => disponibles.first,
      );
      final controlador = CameraController(camara, ResolutionPreset.high, enableAudio: false);
      await controlador.initialize();
      state = EstadoCamara(controlador: controlador);
    } on CameraException catch (_) {
      state = const EstadoCamara(error: 'No se concedió permiso para la cámara.');
    } catch (_) {
      state = const EstadoCamara(error: 'No se pudo inicializar la cámara.');
    }
  }

  Future<XFile> tomarFotografia() async {
    final controlador = state.controlador;
    if (controlador == null || !controlador.value.isInitialized) {
      throw StateError('La cámara no está lista.');
    }
    return controlador.takePicture();
  }
}

final proveedorCamara = NotifierProvider.autoDispose<ControladorCamara, EstadoCamara>(
  ControladorCamara.new,
);
