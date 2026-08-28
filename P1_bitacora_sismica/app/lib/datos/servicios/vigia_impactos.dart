import 'dart:async';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/services.dart';

import '../local/db_helper.dart';

class ImpactoRegistrado {
  ImpactoRegistrado({
    required this.dispositivoId,
    required this.claveCliente,
    required this.intensidad,
    required this.latitud,
    required this.longitud,
    required this.precisionM,
    required this.descripcion,
    required this.createdAt,
  });

  final String dispositivoId;
  final String claveCliente;
  final double intensidad;
  final double latitud;
  final double longitud;
  final double precisionM;
  final String descripcion;
  final DateTime createdAt;
}

class VigiaImpactos {
  static const double umbralDefault = 15.0;
  static const Duration reposoDefault = Duration(milliseconds: 900);

  VigiaImpactos({
    required this.dispositivoId,
    this.umbral = umbralDefault,
    this.reposo = reposoDefault,
  });

  final String dispositivoId;
  final double umbral;
  final Duration reposo;

  final DbHelper _dbHelper = DbHelper.instance;
  final StreamController<ImpactoRegistrado> _streamController = StreamController.broadcast();
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  bool _monitoreando = false;
  DateTime? _ultimoImpacto;

  Stream<ImpactoRegistrado> get eventos => _streamController.stream;
  bool get monitoreando => _monitoreando;

  Future<void> iniciar() async {
    if (_monitoreando) return;

    await _pedirPermisosUbicacion();
    _accelerometerSubscription = userAccelerometerEventStream().listen((event) {
      final magnitud = math.sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      if (magnitud < umbral) return;

      final ahora = DateTime.now();
      if (_ultimoImpacto != null && ahora.difference(_ultimoImpacto!) < reposo) {
        return;
      }

      _ultimoImpacto = ahora;
      _procesarImpacto(magnitud);
    });

    _monitoreando = true;
  }

  Future<void> detener() async {
    await _accelerometerSubscription?.cancel();
    _monitoreando = false;
  }

  Future<void> _pedirPermisosUbicacion() async {
    final permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      final nuevoPermiso = await Geolocator.requestPermission();
      if (nuevoPermiso == LocationPermission.denied) {
        throw Exception('Permiso de ubicación denegado');
      }
    }
  }

  Future<void> _procesarImpacto(double intensidad) async {
    double lat = 0.0;
    double lng = 0.0;
    double accuracy = 0.0;
    String desc = 'Impacto sísmico detectado';

    try {
      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      lat = posicion.latitude;
      lng = posicion.longitude;
      accuracy = posicion.accuracy;
    } catch (_) {
      desc = 'Impacto sin ubicación disponible';
    }

    final claveCliente = DateTime.now().microsecondsSinceEpoch.toString();
    final evento = ImpactoRegistrado(
      dispositivoId: dispositivoId,
      claveCliente: claveCliente,
      intensidad: intensidad,
      latitud: lat,
      longitud: lng,
      precisionM: accuracy,
      descripcion: desc,
      createdAt: DateTime.now(),
    );

    final pendiente = ColaImpacto(
      id: null,
      dispositivoId: evento.dispositivoId,
      claveCliente: evento.claveCliente,
      intensidad: evento.intensidad,
      latitud: evento.latitud,
      longitud: evento.longitud,
      precisionM: evento.precisionM,
      descripcion: evento.descripcion,
      createdAt: evento.createdAt,
      enviado: 0,
    );

    await _dbHelper.insertarEventoPendiente(pendiente);
    _streamController.add(evento);

    // Retroalimentación háptica diferenciada por severidad
    if (intensidad > 35.0) {
      HapticFeedback.heavyImpact();
    } else if (intensidad > 18.0) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void dispose() {
    _accelerometerSubscription?.cancel();
    _streamController.close();
  }
}
