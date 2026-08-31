import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../core/constantes/configuracion.dart';
import '../../dominio/servicios/calculadora_azimut.dart';
import '../../dominio/servicios/calculadora_inclinacion.dart';
import '../../dominio/servicios/filtro_complementario.dart';

class EstadoSensores {
  const EstadoSensores({
    this.inicializando = true,
    this.error,
    this.advertenciaUbicacion,
    this.acelerometroActivo = false,
    this.giroscopioActivo = false,
    this.magnetometroActivo = false,
    this.inclinacionX = 0,
    this.inclinacionY = 0,
    this.azimut = 0,
    this.latitud,
    this.longitud,
  });

  final bool inicializando;
  final String? error;
  final String? advertenciaUbicacion;
  final bool acelerometroActivo;
  final bool giroscopioActivo;
  final bool magnetometroActivo;
  final double inclinacionX;
  final double inclinacionY;
  final double azimut;
  final double? latitud;
  final double? longitud;

  bool get listo =>
      !inicializando &&
      error == null &&
      acelerometroActivo &&
      giroscopioActivo &&
      magnetometroActivo;

  EstadoSensores copyWith({
    bool? inicializando,
    String? error,
    String? advertenciaUbicacion,
    bool limpiarError = false,
    double? inclinacionX,
    double? inclinacionY,
    double? azimut,
    double? latitud,
    double? longitud,
    bool? acelerometroActivo,
    bool? giroscopioActivo,
    bool? magnetometroActivo,
  }) =>
      EstadoSensores(
        inicializando: inicializando ?? this.inicializando,
        error: limpiarError ? null : error ?? this.error,
        advertenciaUbicacion: advertenciaUbicacion ?? this.advertenciaUbicacion,
        acelerometroActivo: acelerometroActivo ?? this.acelerometroActivo,
        giroscopioActivo: giroscopioActivo ?? this.giroscopioActivo,
        magnetometroActivo: magnetometroActivo ?? this.magnetometroActivo,
        inclinacionX: inclinacionX ?? this.inclinacionX,
        inclinacionY: inclinacionY ?? this.inclinacionY,
        azimut: azimut ?? this.azimut,
        latitud: latitud ?? this.latitud,
        longitud: longitud ?? this.longitud,
      );
}

class ControladorSensores extends Notifier<EstadoSensores> {
  final _calculadoraInclinacion = const CalculadoraInclinacion();
  final _calculadoraAzimut = const CalculadoraAzimut();
  final _filtroX = FiltroComplementario(
    peso: ConfiguracionApp.pesoFiltroComplementario,
  );
  final _filtroY = FiltroComplementario(
    peso: ConfiguracionApp.pesoFiltroComplementario,
  );
  StreamSubscription<AccelerometerEvent>? _acelerometro;
  StreamSubscription<GyroscopeEvent>? _giroscopio;
  StreamSubscription<MagnetometerEvent>? _magnetometro;
  StreamSubscription<Position>? _ubicacion;
  GyroscopeEvent? _ultimoGiroscopio;
  DateTime? _ultimoAcelerometro;

  @override
  EstadoSensores build() {
    ref.onDispose(_liberar);
    return const EstadoSensores();
  }

  Future<void> iniciar() async {
    if (!state.inicializando) return;
    try {
      try {
        await _iniciarUbicacion();
      } catch (error) {
        state = state.copyWith(advertenciaUbicacion: error.toString());
      }
      _giroscopio = gyroscopeEventStream().listen(
        (evento) {
          _ultimoGiroscopio = evento;
          state = state.copyWith(giroscopioActivo: true);
        },
        onError: (_, _) => _fallar('El giroscopio no está disponible.'),
      );
      _acelerometro = accelerometerEventStream().listen(_procesarAcelerometro,
          onError: (_, _) => _fallar('El acelerómetro no está disponible.'));
      _magnetometro = magnetometerEventStream().listen(
        (evento) => state = state.copyWith(
          inicializando: false,
          azimut: _calculadoraAzimut.desdeMagnetometro(x: evento.x, y: evento.y),
          magnetometroActivo: true,
        ), onError: (_, _) => _fallar('El magnetómetro no está disponible.'));
    } catch (_) {
      _fallar('No fue posible iniciar los sensores requeridos.');
    }
  }

  Future<void> _iniciarUbicacion() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('El GPS está desactivado.');
    }
    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.deniedForever) {
      throw StateError('El permiso de ubicación fue denegado permanentemente.');
    }
    if (permiso == LocationPermission.denied) {
      throw StateError('No se concedió permiso para la ubicación.');
    }
    _ubicacion = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((posicion) {
      state = state.copyWith(latitud: posicion.latitude, longitud: posicion.longitude);
    }, onError: (_, _) {
      state = state.copyWith(advertenciaUbicacion: 'No se pudo obtener la ubicación.');
    });
  }

  void _procesarAcelerometro(AccelerometerEvent evento) {
    final ahora = DateTime.now();
    final anterior = _ultimoAcelerometro;
    _ultimoAcelerometro = ahora;
    final inclinacion = _calculadoraInclinacion.desdeAcelerometro(
      x: evento.x,
      y: evento.y,
      z: evento.z,
    );
    final dt = anterior == null
        ? 0.0
        : ahora.difference(anterior).inMicroseconds / Duration.microsecondsPerSecond;
    final gyro = _ultimoGiroscopio;
    final x = _filtroX.actualizar(
      anguloAcelerometro: inclinacion.x,
      velocidadAngular: gyro?.y ?? 0,
      deltaSegundos: dt.clamp(0, 1),
    );
    final y = _filtroY.actualizar(
      anguloAcelerometro: inclinacion.y,
      velocidadAngular: gyro?.x ?? 0,
      deltaSegundos: dt.clamp(0, 1),
    );
    state = state.copyWith(
      inicializando: false,
      inclinacionX: x,
      inclinacionY: y,
      acelerometroActivo: true,
    );
  }

  void _fallar(String mensaje) => state = state.copyWith(inicializando: false, error: mensaje);

  void _liberar() {
    _acelerometro?.cancel();
    _giroscopio?.cancel();
    _magnetometro?.cancel();
    _ubicacion?.cancel();
  }
}

final proveedorSensores = NotifierProvider.autoDispose<ControladorSensores, EstadoSensores>(
  ControladorSensores.new,
);
