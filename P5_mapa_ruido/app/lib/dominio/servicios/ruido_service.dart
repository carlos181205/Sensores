import 'dart:async';

import 'package:record/record.dart';

class RuidoService {
  final AudioRecorder _grabador = AudioRecorder();

  Future<bool> solicitarPermiso() async {
    return _grabador.hasPermission();
  }

  Future<void> iniciar() async {
    final tienePermiso = await solicitarPermiso();

    if (!tienePermiso) {
      throw Exception('No se concedió permiso para usar el micrófono.');
    }

    await _grabador.start(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: '',
    );
  }

  Future<void> detener() async {
    await _grabador.stop();
  }

  void liberar() {
    _grabador.dispose();
  }
}
