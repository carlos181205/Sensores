import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:record/record.dart';

import '../../core/configuracion.dart';
import '../../datos/modelos/estado_medicion.dart';
import '../../datos/modelos/lote_muestras.dart';
import '../../datos/modelos/muestra_ruido.dart';
import '../../datos/repositorios/muestras_repository.dart';
import 'bateria_service.dart';
import 'nivel_ruido_service.dart';
import 'ubicacion_service.dart';

class MedicionRuidoService {
  MedicionRuidoService({
    BateriaService? bateriaService,
    MuestrasRepository? muestrasRepository,
  }) : _bateriaService = bateriaService ?? BateriaService(),
       _muestrasRepository = muestrasRepository ?? MuestrasRepository();

  final AudioRecorder _recorder = AudioRecorder();
  final NivelRuidoService _nivelRuidoService = NivelRuidoService();
  final UbicacionService _ubicacionService = UbicacionService();
  final BateriaService _bateriaService;
  final MuestrasRepository _muestrasRepository;
  final LoteMuestras _lote = LoteMuestras();

  final StreamController<MuestraRuido> _muestrasController =
      StreamController<MuestraRuido>.broadcast();
  final StreamController<List<MuestraRuido>> _lotesController =
      StreamController<List<MuestraRuido>>.broadcast();
  final StreamController<EstadoMedicion> _estadoController =
      StreamController<EstadoMedicion>.broadcast();

  StreamSubscription<Position>? _posicionSubscription;
  StreamSubscription<Amplitude>? _amplitudSubscription;
  StreamSubscription<int>? _bateriaSubscription;
  Timer? _reintentoTimer;
  Position? _ultimaPosicion;
  bool _activo = false;
  bool _enviandoLote = false;
  bool _deteniendoPorBateria = false;
  bool _dispuesto = false;
  int? _nivelBateria;
  String _mensajeEstado = 'Listo para iniciar.';
  String? _rutaGrabacion;

  Stream<MuestraRuido> get muestras => _muestrasController.stream;
  Stream<List<MuestraRuido>> get lotesCompletos => _lotesController.stream;
  Stream<EstadoMedicion> get estados => _estadoController.stream;
  int get cantidadMuestras => _lote.cantidad;
  bool get estaCompleto => _lote.estaCompleto;
  bool get activo => _activo;
  int? get nivelBateria => _nivelBateria;
  String get mensajeEstado => _mensajeEstado;

  Future<void> iniciar() async {
    if (_activo) return;

    final nivelBateria = await _bateriaService.obtenerNivel();
    _nivelBateria = nivelBateria;
    if (nivelBateria < ConfiguracionP5.minBatteryPercent) {
      final mensaje =
          'Captura no iniciada: batería inferior al '
          '${ConfiguracionP5.minBatteryPercent} %.';
      _emitirEstado(
        EstadoMedicion(
          estado: EstadoCaptura.bateriaBaja,
          mensaje: mensaje,
          bateriaPercent: nivelBateria,
        ),
      );
      throw Exception(mensaje);
    }

    final tienePermiso = await _recorder.hasPermission();
    if (!tienePermiso) {
      const mensaje =
          'No se concedió permiso para el micrófono. Habilítalo en Ajustes.';
      _emitirEstado(
        const EstadoMedicion(estado: EstadoCaptura.detenido, mensaje: mensaje),
      );
      throw Exception(mensaje);
    }

    final posicionInicial = await _ubicacionService.obtenerPosicion();
    _ultimaPosicion = posicionInicial;
    _posicionSubscription = _ubicacionService.observarPosiciones().listen(
      (posicion) => _ultimaPosicion = posicion,
      onError: (Object error, StackTrace stackTrace) {
        developer.log(
          'Error observando GPS: $error',
          name: 'P5.MedicionRuido',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );

    final ruta = File(
      '${Directory.systemTemp.path}/p5_ruido_${DateTime.now().millisecondsSinceEpoch}.m4a',
    ).path;
    _rutaGrabacion = ruta;

    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: ruta,
      );
    } catch (_) {
      await _posicionSubscription?.cancel();
      _posicionSubscription = null;
      rethrow;
    }

    _amplitudSubscription = _recorder
        .onAmplitudeChanged(const Duration(seconds: 3))
        .listen((amplitud) {
          unawaited(_procesarAmplitud(amplitud));
        });

    _activo = true;
    _emitirEstado(
      EstadoMedicion(
        estado: EstadoCaptura.capturando,
        mensaje: 'Captura activa.',
        bateriaPercent: _nivelBateria,
      ),
    );

    _bateriaSubscription = _bateriaService.observarNiveles().listen(
      (nivel) {
        _nivelBateria = nivel;
        if (nivel < ConfiguracionP5.minBatteryPercent) {
          unawaited(_detenerPorBateria());
        } else {
          _emitirEstado(
            EstadoMedicion(
              estado: _enviandoLote
                  ? EstadoCaptura.enviando
                  : EstadoCaptura.capturando,
              mensaje: _mensajeEstado,
              bateriaPercent: nivel,
            ),
          );
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        developer.log(
          'No se pudo consultar la batería: $error',
          name: 'P5.MedicionRuido',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  }

  Future<void> _procesarAmplitud(Amplitude amplitud) async {
    if (!_activo || _dispuesto) return;

    final posicion = _ultimaPosicion;
    if (posicion == null) return;

    if (posicion.accuracy > ConfiguracionP5.maxGpsAccuracyMeters) {
      developer.log(
        'Muestra descartada por precisión GPS: '
        '${posicion.accuracy.toStringAsFixed(1)} m',
        name: 'P5.MedicionRuido',
      );
      return;
    }

    final nivelRelativo = _nivelRuidoService.convertir(amplitud.current);
    final muestra = MuestraRuido(
      nivelDb: nivelRelativo,
      latitud: posicion.latitude,
      longitud: posicion.longitude,
      precisionM: posicion.accuracy,
      medidoEn: DateTime.now().toUtc(),
    );

    _lote.agregar(muestra);
    _muestrasController.add(muestra);
    developer.log(
      'Muestra ${_lote.cantidad}/${LoteMuestras.capacidad} | '
      'Nivel: ${nivelRelativo.toStringAsFixed(2)} | '
      'GPS: ${posicion.latitude}, ${posicion.longitude}',
      name: 'P5.MedicionRuido',
    );

    if (_lote.estaCompleto && !_enviandoLote) {
      unawaited(_enviarLotePendiente());
    }
  }

  Future<void> _enviarLotePendiente() async {
    if (_enviandoLote || !_lote.estaCompleto || _dispuesto) return;

    _enviandoLote = true;
    final lotePendiente = _lote.muestras;
    _lotesController.add(lotePendiente);
    _emitirEstado(
      EstadoMedicion(
        estado: EstadoCaptura.enviando,
        mensaje: 'Enviando lote de ${lotePendiente.length} muestras...',
        bateriaPercent: _nivelBateria,
      ),
    );

    try {
      final cantidadEnviada = await _muestrasRepository.enviarLote(
        lotePendiente,
      );
      _lote.extraer();
      _reintentoTimer?.cancel();
      developer.log(
        'LOTE ENVIADO: $cantidadEnviada muestras guardadas en el servidor.',
        name: 'P5.MedicionRuido',
      );
      _emitirEstado(
        EstadoMedicion(
          estado: EstadoCaptura.capturando,
          mensaje: 'Lote enviado correctamente.',
          bateriaPercent: _nivelBateria,
        ),
      );
    } catch (error, stackTrace) {
      developer.log(
        'ERROR ENVIANDO LOTE: $error',
        name: 'P5.MedicionRuido',
        error: error,
        stackTrace: stackTrace,
      );
      const mensaje = 'No se pudo conectar con el servidor. Lote conservado.';
      _emitirEstado(
        EstadoMedicion(
          estado: EstadoCaptura.error,
          mensaje: mensaje,
          bateriaPercent: _nivelBateria,
        ),
      );
      _programarReintento();
    } finally {
      _enviandoLote = false;
    }
  }

  void _programarReintento() {
    _reintentoTimer?.cancel();
    _reintentoTimer = Timer(const Duration(seconds: 10), () {
      unawaited(_enviarLotePendiente());
    });
  }

  Future<void> _detenerPorBateria() async {
    if (_deteniendoPorBateria || !_activo) return;

    _deteniendoPorBateria = true;
    await detener();
    _emitirEstado(
      EstadoMedicion(
        estado: EstadoCaptura.bateriaBaja,
        mensaje:
            'Captura detenida: batería inferior al '
            '${ConfiguracionP5.minBatteryPercent} %.',
        bateriaPercent: _nivelBateria,
      ),
    );
    _deteniendoPorBateria = false;
  }

  Future<void> detener() async {
    if (!_activo && _amplitudSubscription == null) return;

    _activo = false;
    _reintentoTimer?.cancel();
    _reintentoTimer = null;
    await _amplitudSubscription?.cancel();
    _amplitudSubscription = null;
    await _posicionSubscription?.cancel();
    _posicionSubscription = null;
    await _bateriaSubscription?.cancel();
    _bateriaSubscription = null;
    await _recorder.stop();
    final rutaGrabacion = _rutaGrabacion;
    _rutaGrabacion = null;
    if (rutaGrabacion != null) {
      try {
        await File(rutaGrabacion).delete();
      } on FileSystemException catch (error, stackTrace) {
        developer.log(
          'No se pudo eliminar el audio temporal: $error',
          name: 'P5.MedicionRuido',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    _emitirEstado(
      EstadoMedicion(
        estado: EstadoCaptura.detenido,
        mensaje: 'Captura detenida.',
        bateriaPercent: _nivelBateria,
      ),
    );
  }

  void limpiarLote() => _lote.limpiar();

  void _emitirEstado(EstadoMedicion estado) {
    if (_dispuesto || _estadoController.isClosed) return;
    _mensajeEstado = estado.mensaje;
    _estadoController.add(estado);
  }

  void dispose() {
    if (_dispuesto) return;
    _dispuesto = true;
    _activo = false;
    _reintentoTimer?.cancel();
    unawaited(_amplitudSubscription?.cancel());
    unawaited(_posicionSubscription?.cancel());
    unawaited(_bateriaSubscription?.cancel());
    unawaited(_recorder.stop());
    _muestrasController.close();
    _lotesController.close();
    _estadoController.close();
    _recorder.dispose();
  }
}
