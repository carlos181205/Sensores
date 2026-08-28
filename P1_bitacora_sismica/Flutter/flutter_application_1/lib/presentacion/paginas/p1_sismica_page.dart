import 'dart:async';

import 'package:flutter/material.dart';

import '../../datos/local/db_helper.dart';
import '../../datos/servicios/api_cliente.dart';
import '../../datos/servicios/sincronizador_impactos.dart';
import '../../datos/servicios/vigia_impactos.dart';

class P1SismicaPage extends StatefulWidget {
  const P1SismicaPage({super.key});

  @override
  State<P1SismicaPage> createState() => _P1SismicaPageState();
}

class _P1SismicaPageState extends State<P1SismicaPage> {
  final DbHelper _dbHelper = DbHelper.instance;
  final SincronizadorImpactos _sincronizador = SincronizadorImpactos();
  final ApiCliente _apiCliente = ApiCliente();
  final String _dispositivoId = 'celular_ceet_01';
  VigiaImpactos? _vigia;

  bool _monitoreando = false;
  bool _hayConexion = false;
  List<Map<String, dynamic>> _eventos = [];
  int _pendientes = 0;
  Timer? _timerSincronizacion;
  bool _sincronizando = false;

  @override
  void initState() {
    super.initState();
    _cargarEstado();
    _timerSincronizacion = Timer.periodic(const Duration(seconds: 5), (_) {
      _verificarYsincronizar();
    });
  }

  Future<void> _cargarEstado() async {
    await _comprobarConexion();
    await _cargarEventos();
    await _cargarPendientes();
  }

  Future<void> _comprobarConexion() async {
    try {
      await _apiCliente.get('/salud');
      if (!mounted) return;
      setState(() => _hayConexion = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _hayConexion = false);
    }
  }

  Future<void> _verificarYsincronizar() async {
    if (_sincronizando) return;
    _sincronizando = true;
    try {
      final conexionAnterior = _hayConexion;
      await _comprobarConexion();
      if (_hayConexion && (!conexionAnterior || _pendientes > 0)) {
        await _sincronizador.sincronizarPendientes();
        await _cargarEventos();
        await _cargarPendientes();
      }
    } finally {
      _sincronizando = false;
    }
  }

  Future<void> _cargarPendientes() async {
    final total = await _dbHelper.contarPendientes();
    if (!mounted) return;
    setState(() {
      _pendientes = total;
    });
  }

  Future<void> _cargarEventos() async {
    if (_hayConexion) {
      try {
        final response = await _apiCliente.get('/eventos', queryParameters: {'limite': 20});
        final eventos = (response.data['eventos'] as List?) ?? const [];
        if (!mounted) return;
        setState(() {
          _eventos = eventos.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        });
        return;
      } catch (_) {
        // fallback local
      }
    }

    final locales = await _dbHelper.obtenerPendientes();
    if (!mounted) return;
    setState(() {
      _eventos = locales.map((e) => {
        'dispositivo_id': e.dispositivoId,
        'clave_cliente': e.claveCliente,
        'intensidad': e.intensidad,
        'latitud': e.latitud,
        'longitud': e.longitud,
        'descripcion': e.descripcion,
        'fecha_evento': e.createdAt.toIso8601String(),
      }).toList();
    });
  }

  Future<void> _toggleMonitoreo(bool value) async {
    if (!value) {
      await _vigia?.detener();
      if (!mounted) return;
      setState(() {
        _monitoreando = false;
      });
      await _comprobarConexion();
      await _sincronizador.verificarYEnviarSiHayRed();
      await _cargarEventos();
      await _cargarPendientes();
      return;
    }

    _vigia = VigiaImpactos(dispositivoId: _dispositivoId);
    await _vigia!.iniciar();

    _vigia!.eventos.listen((evento) async {
      final registro = ColaImpacto(
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

      await _dbHelper.insertarEventoPendiente(registro);
      await _cargarPendientes();
      await _cargarEventos();
    });

    if (!mounted) return;
    setState(() {
      _monitoreando = true;
    });
  }

  Future<void> _sincronizarAhora() async {
    await _verificarYsincronizar();
    if (!_hayConexion) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sin conexión. Los eventos quedarán pendientes en SQLite.')),
      );
      return;
    }

    final total = await _sincronizador.sincronizarPendientes();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(total > 0 ? 'Se sincronizaron $total eventos' : 'No hay eventos pendientes'),
      ),
    );
    await _cargarEventos();
    await _cargarPendientes();
  }

  @override
  void dispose() {
    _timerSincronizacion?.cancel();
    _vigia?.detener();
    super.dispose();
  }

  String _severidad(double intensidad) {
    if (intensidad <= 18) return 'leve';
    if (intensidad <= 35) return 'moderado';
    return 'fuerte';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('P1 · Bitácora sísmica CEET'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  avatar: Icon(
                    _hayConexion ? Icons.wifi : Icons.wifi_off,
                    color: _hayConexion ? Colors.green : Colors.red,
                  ),
                  label: Text(_hayConexion ? 'En línea' : 'Sin conexión'),
                ),
                const SizedBox(width: 12),
                Chip(
                  avatar: const Icon(Icons.pending_actions, color: Colors.blue),
                  label: Text('Pendientes: $_pendientes'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Escuchar acelerómetro'),
              subtitle: Text(_monitoreando ? 'Monitoreo activo' : 'Monitoreo detenido'),
              value: _monitoreando,
              onChanged: _toggleMonitoreo,
            ),
            const SizedBox(height: 8),
            Center(
              child: OutlinedButton.icon(
                onPressed: _sincronizarAhora,
                icon: const Icon(Icons.sync),
                label: const Text('Sincronizar cola'),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Historial de eventos',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _eventos.isEmpty
                  ? const Center(
                      child: Text('No hay eventos registrados.'),
                    )
                  : ListView.builder(
                      itemCount: _eventos.length,
                      itemBuilder: (context, index) {
                        final item = _eventos[index];
                        final intensidad = (item['intensidad'] as num?)?.toDouble() ?? 0.0;
                        final fecha = DateTime.tryParse(item['fecha_evento']?.toString() ?? '') ?? DateTime.now();

                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                            title: Text('Intensidad: ${intensidad.toStringAsFixed(1)} m/s²'),
                            subtitle: Text(
                              'Severidad: ${_severidad(intensidad)}\n'
                              'Lat: ${(item['latitud'] as num?)?.toStringAsFixed(4) ?? '0.0000'} · '
                              'Lng: ${(item['longitud'] as num?)?.toStringAsFixed(4) ?? '0.0000'}\n'
                              '${item['descripcion'] ?? 'Impacto registrado'}\n'
                              '${fecha.toLocal().toString()}',
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
