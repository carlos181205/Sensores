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
  StreamSubscription<ImpactoRegistrado>? _suscripcionEventos;

  String _filtroSeveridad = 'todos';
  DateTimeRange? _filtroFechas;

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
    final params = <String, dynamic>{'limite': 50};
    if (_filtroSeveridad != 'todos') {
      params['severidad'] = _filtroSeveridad;
    }
    if (_filtroFechas != null) {
      params['desde'] = _filtroFechas!.start.toIso8601String();
      params['hasta'] = _filtroFechas!.end.toIso8601String();
    }

    if (_hayConexion) {
      try {
        final response = await _apiCliente.get('/eventos', queryParameters: params);
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
      var filtrados = locales;
      if (_filtroSeveridad != 'todos') {
        filtrados = filtrados.where((e) => _severidad(e.intensidad) == _filtroSeveridad).toList();
      }
      _eventos = filtrados.map((e) => {
        'dispositivo_id': e.dispositivoId,
        'clave_cliente': e.claveCliente,
        'intensidad': e.intensidad,
        'latitud': e.latitud,
        'longitud': e.longitud,
        'precision_m': e.precisionM,
        'descripcion': e.descripcion,
        'fecha_evento': e.createdAt.toIso8601String(),
      }).toList();
    });
  }

  Future<void> _toggleMonitoreo(bool value) async {
    if (!value) {
      await _suscripcionEventos?.cancel();
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

    _suscripcionEventos = _vigia!.eventos.listen((evento) async {
      final registro = {
        'dispositivo_id': evento.dispositivoId,
        'clave_cliente': evento.claveCliente,
        'intensidad': evento.intensidad,
        'latitud': evento.latitud,
        'longitud': evento.longitud,
        'precision_m': evento.precisionM,
        'descripcion': evento.descripcion,
        'fecha_evento': evento.createdAt.toIso8601String(),
      };

      if (!mounted) return;
      setState(() {
        _eventos = [registro, ..._eventos];
      });
      await _cargarPendientes();
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
    _suscripcionEventos?.cancel();
    _vigia?.dispose();
    super.dispose();
  }

  String _severidad(double intensidad) {
    if (intensidad <= 18) return 'leve';
    if (intensidad <= 35) return 'moderado';
    return 'fuerte';
  }

  Color _colorSeveridad(String sev) {
    switch (sev) {
      case 'fuerte':
        return Colors.red;
      case 'moderado':
        return Colors.orange;
      default:
        return Colors.amber;
    }
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
              title: const Text('Escuchar acelerómetro (sin gravedad)'),
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Historial de eventos',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: _filtroSeveridad,
                  items: const [
                    DropdownMenuItem(value: 'todos', child: Text('Todas')),
                    DropdownMenuItem(value: 'leve', child: Text('Leve')),
                    DropdownMenuItem(value: 'moderado', child: Text('Moderado')),
                    DropdownMenuItem(value: 'fuerte', child: Text('Fuerte')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _filtroSeveridad = val);
                      _cargarEventos();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
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
                        final precision = (item['precision_m'] as num?)?.toDouble() ?? 0.0;
                        final fecha = DateTime.tryParse(item['fecha_evento']?.toString() ?? '') ?? DateTime.now();
                        final sev = _severidad(intensidad);

                        return Card(
                          child: ListTile(
                            leading: Icon(Icons.warning_amber_rounded, color: _colorSeveridad(sev)),
                            title: Text('Intensidad: ${intensidad.toStringAsFixed(1)} m/s²'),
                            subtitle: Text(
                              'Severidad: $sev · Precisión GPS: ${precision.toStringAsFixed(1)} m\n'
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
