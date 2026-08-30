import 'package:dio/dio.dart';
import '../../datos/local/almacen_seguro.dart';

class InterceptorAuth extends QueuedInterceptor {
  InterceptorAuth(this.almacen, this.dioLimpio);

  final AlmacenSeguro almacen;
  final Dio dioLimpio; // Instancia de Dio sin interceptor para evitar recursión infinita

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await almacen.obtenerAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Si el error no es 401 Unauthorized, continuar con el flujo normal de errores
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final refreshToken = await almacen.obtenerRefreshToken();
    if (refreshToken == null) {
      return handler.next(err);
    }

    try {
      // Intentar renovación transparente con el endpoint de refresh token
      final response = await dioLimpio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final nuevosTokens = response.data['tokens'];
      final nuevoAccess = nuevosTokens['accessToken'] as String;
      final nuevoRefresh = nuevosTokens['refreshToken'] as String;

      // Guardar el nuevo par de tokens (Rotación)
      await almacen.guardarTokens(accessToken: nuevoAccess, refreshToken: nuevoRefresh);

      // Reintentar la petición original con el nuevo access token
      final reqOriginal = err.requestOptions;
      reqOriginal.headers['Authorization'] = 'Bearer $nuevoAccess';

      final respuestaReintento = await dioLimpio.fetch(reqOriginal);
      return handler.resolve(respuestaReintento);
    } catch (_) {
      // Si la renovación falla (refresh token expirado o revocado), limpiar credenciales
      await almacen.borrarTodo();
      return handler.next(err);
    }
  }
}
