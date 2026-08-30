import 'package:geolocator/geolocator.dart';

class ServicioUbicacion {
  Future<bool> servicioHabilitado() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<LocationPermission> solicitarPermisos() async {
    final servicioActivo = await Geolocator.isLocationServiceEnabled();
    if (!servicioActivo) {
      return Future.value(LocationPermission.deniedForever);
    }

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    return permiso;
  }

  Future<bool> permisoConcedido() async {
    final permiso = await solicitarPermisos();
    return permiso == LocationPermission.always ||
        permiso == LocationPermission.whileInUse;
  }

  Future<String> obtenerMensajePermiso({required LocationPermission permiso}) async {
    switch (permiso) {
      case LocationPermission.denied:
        return 'Se requieren permisos de ubicación para validar la geocerca.';
      case LocationPermission.deniedForever:
        return 'El permiso de ubicación quedó denegado permanentemente. Actívalo en Ajustes.';
      case LocationPermission.unableToDetermine:
        return 'No fue posible determinar el permiso de ubicación del dispositivo.';
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return 'Permiso de ubicación habilitado.';
    }
  }

  Future<Position?> obtenerPosicionActual() async {
    final permiso = await solicitarPermisos();

    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.deniedForever ||
        permiso == LocationPermission.unableToDetermine) {
      return null;
    }

    final servicioActivo = await Geolocator.isLocationServiceEnabled();
    if (!servicioActivo) {
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }
}
