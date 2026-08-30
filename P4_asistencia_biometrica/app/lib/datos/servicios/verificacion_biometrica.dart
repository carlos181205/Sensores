import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class VerificacionBiometrica {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> esBiometriaDisponible() async {
    try {
      final puedeCheckear = await _auth.canCheckBiometrics;
      final soportado = await _auth.isDeviceSupported();
      return puedeCheckear && soportado;
    } catch (_) {
      return false;
    }
  }

  Future<bool> verificarIdentidad({String motivo = 'Confirma tu identidad para marcar asistencia'}) async {
    final disponible = await esBiometriaDisponible();
    if (!disponible) {
      // RF-05: Si no hay biometría, permite el flujo alternativo mediante PIN/Patrón del sistema
      return await _pedirRespaldoPinDelSistema(motivo);
    }

    try {
      return await _auth.authenticate(
        localizedReason: motivo,
        options: const AuthenticationOptions(
          biometricOnly: false, // RF-05: Permite PIN del equipo como respaldo
          stickyAuth: true,    // Sobrevive al paso a segundo plano
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      if (e.code == 'NotEnrolled') {
        return await _pedirRespaldoPinDelSistema(motivo);
      }
      return false;
    }
  }

  Future<bool> _pedirRespaldoPinDelSistema(String motivo) async {
    try {
      return await _auth.authenticate(
        localizedReason: '$motivo (Utilizando PIN / Patrón de respaldo)',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
