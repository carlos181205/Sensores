import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AlmacenSeguro {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _kAccessToken = 'access_token';
  static const String _kRefreshToken = 'refresh_token';
  static const String _kUsuarioNombre = 'usuario_nombre';

  Future<void> guardarTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _kAccessToken, value: accessToken);
    await _storage.write(key: _kRefreshToken, value: refreshToken);
  }

  Future<String?> obtenerAccessToken() async {
    return await _storage.read(key: _kAccessToken);
  }

  Future<String?> obtenerRefreshToken() async {
    return await _storage.read(key: _kRefreshToken);
  }

  Future<void> guardarNombreUsuario(String nombre) async {
    await _storage.write(key: _kUsuarioNombre, value: nombre);
  }

  Future<String?> obtenerNombreUsuario() async {
    return await _storage.read(key: _kUsuarioNombre);
  }

  Future<void> borrarTodo() async {
    await _storage.deleteAll();
  }
}
