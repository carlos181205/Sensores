import 'package:geolocator/geolocator.dart';

import '../../core/configuracion.dart';

class UbicacionService {
  Future<bool> prepararPermisos() async {
    final servicioActivo = await Geolocator.isLocationServiceEnabled();

    if (!servicioActivo) {
      throw Exception('El servicio de ubicación está desactivado.');
    }

    LocationPermission permiso = await Geolocator.checkPermission();

    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }

    if (permiso == LocationPermission.denied) {
      throw Exception('El permiso de ubicación fue rechazado.');
    }

    if (permiso == LocationPermission.deniedForever) {
      throw Exception(
        'El permiso de ubicación fue rechazado permanentemente. '
        'Habilítalo en Ajustes > Permisos de la aplicación.',
      );
    }

    return true;
  }

  Future<Position> obtenerPosicion() async {
    await prepararPermisos();

    const configuracion = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: ConfiguracionP5.distanceFilterMeters,
      timeLimit: Duration(seconds: 10),
    );

    return Geolocator.getCurrentPosition(locationSettings: configuracion);
  }

  Stream<Position> observarPosiciones() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: ConfiguracionP5.distanceFilterMeters,
      ),
    );
  }
}
