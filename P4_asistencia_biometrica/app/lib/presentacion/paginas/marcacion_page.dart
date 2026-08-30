import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../datos/local/cola_asistencia_db.dart';
import '../../datos/modelos/asistencia_modelos.dart';
import '../../datos/servicios/api_asistencia_cliente.dart';
import '../../datos/servicios/servicio_ubicacion.dart';
import '../../datos/servicios/sincronizador_offline.dart';
import '../../datos/servicios/verificacion_biometrica.dart';
import 'historico_page.dart';
import 'login_page.dart';

class MarcacionPage extends StatefulWidget {
  const MarcacionPage({super.key, required this.usuario});

  final UsuarioModelo usuario;

  @override
  State<MarcacionPage> createState() => _MarcacionPageState();
}

class _MarcacionPageState extends State<MarcacionPage> {
  final ApiAsistenciaCliente _api = ApiAsistenciaCliente();
  final VerificacionBiometrica _biometria = VerificacionBiometrica();
  final ServicioUbicacion _servicioUbicacion = ServicioUbicacion();
  final ColaAsistenciaDb _cola = ColaAsistenciaDb();
  final SincronizadorOffline _sincronizador = SincronizadorOffline();

  bool _cargando = false;
  String? _mensajeResultado;
  bool? _exitoMarcacion;

  Future<void> _marcarAsistencia(String tipo) async {
    setState(() {
      _cargando = true;
      _mensajeResultado = null;
      _exitoMarcacion = null;
    });

    final verificado = await _biometria.verificarIdentidad(
      motivo: 'Confirma tu identidad para marcar $tipo de asistencia',
    );

    if (!verificado) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _exitoMarcacion = false;
        _mensajeResultado = 'La verificación biométrica no fue aprobada. Revisa tu bloqueo del dispositivo.';
      });
      return;
    }

    final permisoUbicacion = await _servicioUbicacion.solicitarPermisos();
    if (permisoUbicacion == LocationPermission.denied ||
        permisoUbicacion == LocationPermission.deniedForever ||
        permisoUbicacion == LocationPermission.unableToDetermine) {
      final mensajePermiso = await _servicioUbicacion.obtenerMensajePermiso(permiso: permisoUbicacion);
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _exitoMarcacion = false;
        _mensajeResultado = mensajePermiso;
      });
      return;
    }

    try {
      final pos = await _servicioUbicacion.obtenerPosicionActual();
      if (pos == null) {
        if (!mounted) return;
        setState(() {
          _cargando = false;
          _exitoMarcacion = false;
          _mensajeResultado = 'No fue posible obtener la ubicación GPS del dispositivo.';
        });
        return;
      }

      final timestamp = DateTime.now().toUtc().toIso8601String();
      final payload = {
        'tipo': tipo.toUpperCase(),
        'latitud': pos.latitude,
        'longitud': pos.longitude,
        'precisionM': pos.accuracy,
        'timestamp': timestamp,
      };

      final conectado = await _sincronizador.hayConexion();
      if (!conectado) {
        final id = '${widget.usuario.id}_${DateTime.now().microsecondsSinceEpoch}';
        await _cola.guardarMarcacionOffline(
          id: id,
          tipo: tipo.toUpperCase(),
          latitud: pos.latitude,
          longitud: pos.longitude,
          precisionM: pos.accuracy,
          timestamp: timestamp,
          usuarioId: widget.usuario.id,
          sedeId: widget.usuario.fichaId ?? 1,
        );

        if (!mounted) return;
        setState(() {
          _cargando = false;
          _exitoMarcacion = false;
          _mensajeResultado = 'Sin conexión. La marcación quedó guardada en cola local y se sincronizará al recuperar la red.';
        });
        return;
      }

      final res = await _api.post('/asistencia/marcacion', payload);
      final ok = (res.data['ok'] as bool?) ?? false;
      final msg = res.data['mensaje'] as String? ?? 'Marcación registrada';

      if (!mounted) return;
      setState(() {
        _cargando = false;
        _exitoMarcacion = ok;
        _mensajeResultado = msg;
      });
    } catch (e) {
      final mensaje = e.toString().replaceAll('Exception: ', '');
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _exitoMarcacion = false;
        _mensajeResultado = mensaje;
      });
    }
  }

  Future<void> _cerrarSesion() async {
    await _api.almacen.borrarTodo();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.usuario;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marcación de Asistencia'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Ver Histórico',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HistoricoPage(usuario: u)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: Colors.indigo.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.indigo,
                        child: Text(
                          u.nombre.substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u.nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('Doc: ${u.documento} · Rol: ${u.rol.toUpperCase()}'),
                            Text('Ficha ADSO: ${u.fichaId ?? 1}', style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Selecciona el tipo de marcación:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 100,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _cargando ? null : () => _marcarAsistencia('entrada'),
                        icon: const Icon(Icons.login, size: 32),
                        label: const Text('MARCAR\nENTRADA', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 100,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _cargando ? null : () => _marcarAsistencia('salida'),
                        icon: const Icon(Icons.logout, size: 32),
                        label: const Text('MARCAR\nSALIDA', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_cargando)
                const Center(child: CircularProgressIndicator())
              else if (_exitoMarcacion != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _exitoMarcacion! ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _exitoMarcacion! ? Colors.green : Colors.red),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _exitoMarcacion! ? Icons.check_circle : Icons.error,
                        color: _exitoMarcacion! ? Colors.green : Colors.red,
                        size: 36,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _mensajeResultado ?? '',
                          style: TextStyle(
                            color: _exitoMarcacion! ? Colors.green.shade900 : Colors.red.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
