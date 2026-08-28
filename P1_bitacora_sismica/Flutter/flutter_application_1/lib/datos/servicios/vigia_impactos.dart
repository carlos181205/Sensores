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
    required this.descripcion,
    required this.createdAt,
  });

  final String dispositivoId;
  final String claveCliente;
  final double intensidad;
  final double latitud;
  final double longitud;
  final String descripcion;
  final DateTime createdAt;
}

class VigiaImpactos {
  VigiaImpactos({
    required this.dispositivoId,
    this.umbral = 15.0,
  });

  final String dispositivoId;
  final double umbral;

  final DbHelper _dbHelper = DbHelper.instance;
  final StreamController<ImpactoRegistrado> _streamController = StreamController.broadcast();
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  bool _monitoreando = false;
  DateTime? _ultimoImpacto;

  Stream<ImpactoRegistrado> get eventos => _streamController.stream;
  bool get monitoreando => _monitoreando;

  Future<void> iniciar() async {
    if (_monitoreando) return;

    await _pedirPermisosUbicacion();
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      final gravedad = math.sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      if (gravedad < umbral) return;

      final ahora = DateTime.now();
      if (_ultimoImpacto != null && ahora.difference(_ultimoImpacto!).inMilliseconds < 1500) {
        return;
      }

      _ultimoImpacto = ahora;
      _procesarImpacto(gravedad);
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
    try {
      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      final claveCliente = DateTime.now().microsecondsSinceEpoch.toString();
      final evento = ImpactoRegistrado(
        dispositivoId: dispositivoId,
        claveCliente: claveCliente,
        intensidad: intensidad,
        latitud: posicion.latitude,
        longitud: posicion.longitude,
        descripcion: 'Impacto sísmico detectado',
        createdAt: DateTime.now(),
      );

      final pendiente = ColaImpacto(
        id: null,
        dispositivoId: evento.dispositivoId,
        claveCliente: evento.claveCliente,
        intensidad: evento.intensidad,
        latitud: evento.latitud,
        longitud: evento.longitud,
        descripcion: evento.descripcion,
        createdAt: evento.createdAt,
        enviado: 0,
      );

      await _dbHelper.insertarEventoPendiente(pendiente);
      _streamController.add(evento);

      HapticFeedback.mediumImpact();
    } catch (_) {
      final claveCliente = DateTime.now().microsecondsSinceEpoch.toString();
      final evento = ImpactoRegistrado(
        dispositivoId: dispositivoId,
        claveCliente: claveCliente,
        intensidad: intensidad,
        latitud: 0,
        longitud: 0,
        descripcion: 'Impacto sin ubicación disponible',
        createdAt: DateTime.now(),
      );

      final pendiente = ColaImpacto(
        id: null,
        dispositivoId: evento.dispositivoId,
        claveCliente: evento.claveCliente,
        intensidad: evento.intensidad,
        latitud: evento.latitud,
        longitud: evento.longitud,
        descripcion: evento.descripcion,
        createdAt: evento.createdAt,
        enviado: 0,
      );

      await _dbHelper.insertarEventoPendiente(pendiente);
      _streamController.add(evento);
      HapticFeedback.mediumImpact();
    }
  }

  void dispose() {
    _accelerometerSubscription?.cancel();
    _streamController.close();
  }
}
