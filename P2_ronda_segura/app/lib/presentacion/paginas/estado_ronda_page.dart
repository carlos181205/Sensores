import 'dart:async';
import 'package:flutter/material.dart';

import '../../datos/local/db_helper_ronda.dart';
import '../../datos/modelos/ronda_modelos.dart';
import '../../datos/servicios/api_ronda_cliente.dart';
import '../../datos/servicios/sincronizador_ronda.dart';
import 'escaner_ronda_page.dart';

class EstadoRondaPage extends StatefulWidget {
  const EstadoRondaPage({super.key});

  @override
  State<EstadoRondaPage> createState() => _EstadoRondaPageState();
}

class _EstadoRondaPageState extends State<EstadoRondaPage> {
  final ApiRondaCliente _api = ApiRondaCliente();
  final DbHelperRonda _dbHelper = DbHelperRonda.instance;
  final SincronizadorRonda _sincronizador = SincronizadorRonda();

  String? _rondaId;
  bool _cargando = true;
  bool _enLinea = false;
  int _pendientesOffline = 0;
  List<PuntoControl> _puntos = [];
  Set<int> _puntosVisitados = {};
  Timer? _timerSync;

  @override
  void initState() {
    super.initState();
    _iniciarOrecuperarRonda();
    _timerSync = Timer.periodic(const Duration(seconds: 6), (_) {
      _sincronizar();
    });
  }

  Future<void> _iniciarOrecuperarRonda() async {
    await _comprobarConexion();
    await _cargarCatalogoLocal();

    if (_enLinea) {
      try {
        final r = await _api.post('/rondas', {'usuarioId': 1});
        _rondaId = r.data['ronda']['id'] as String;
      } catch (_) {
        _rondaId = 'ronda_local_demo';
      }
    } else {
      _rondaId = 'ronda_local_demo';
    }

    await _actualizarEstado();
  }

  Future<void> _comprobarConexion() async {
    try {
      await _api.get('/salud');
      if (!mounted) return;
      setState(() => _enLinea = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _enLinea = false);
    }
  }

  Future<void> _cargarCatalogoLocal() async {
    if (_enLinea) {
      try {
        final res = await _api.get('/puntos');
        final lista = (res.data['puntos'] as List?) ?? [];
        final puntosServidor = lista.map((e) => PuntoControl.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        await _dbHelper.guardarPuntosCatalogo(puntosServidor);
      } catch (_) {}
    }

    final locales = await _dbHelper.obtenerPuntosCatalogo();
    if (!mounted) return;
    setState(() {
      _puntos = locales;
    });
  }

  Future<void> _sincronizar() async {
    await _comprobarConexion();
    if (_enLinea) {
      await _sincronizador.sincronizarPendientes();
      await _actualizarEstado();
    }
  }

  Future<void> _actualizarEstado() async {
    final pen = await _dbHelper.contarPendientes();
    if (_enLinea && _rondaId != null) {
      try {
        final res = await _api.get('/rondas/$_rondaId');
        final marcaciones = (res.data['marcaciones'] as List?) ?? [];
        final visitados = marcaciones
            .where((m) => m['aceptada'] == true)
            .map((m) => (m['punto_id'] ?? m['puntoId']) as int)
            .toSet();

        if (!mounted) return;
        setState(() {
          _puntosVisitados = visitados;
          _pendientesOffline = pen;
          _cargando = false;
        });
        return;
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _pendientesOffline = pen;
      _cargando = false;
    });
  }

  @override
  void dispose() {
    _timerSync?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visitadosCount = _puntosVisitados.length;
    final totalCount = _puntos.length;
    final porcentaje = totalCount > 0 ? (visitadosCount / totalCount) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('P2 · Ronda segura'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              await _sincronizar();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Estado actualizado')),
                );
              }
            },
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(
                        avatar: Icon(
                          _enLinea ? Icons.wifi : Icons.wifi_off,
                          color: _enLinea ? Colors.green : Colors.red,
                        ),
                        label: Text(_enLinea ? 'En línea' : 'Sin conexión'),
                      ),
                      const SizedBox(width: 12),
                      Chip(
                        avatar: const Icon(Icons.pending_actions, color: Colors.orange),
                        label: Text('Pendientes sync: $_pendientesOffline'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Avance de la Ronda',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: porcentaje,
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(5),
                            backgroundColor: Colors.grey.shade300,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Visitados: $visitadosCount / $totalCount'),
                              Text('Faltantes: ${totalCount - visitadosCount}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Puntos de Control',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      FilledButton.icon(
                        onPressed: _rondaId == null
                            ? null
                            : () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EscanerRondaPage(rondaId: _rondaId!),
                                  ),
                                );
                                await _actualizarEstado();
                              },
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Escanear QR'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _puntos.isEmpty
                        ? const Center(child: Text('No hay puntos de control en el catálogo.'))
                        : ListView.builder(
                            itemCount: _puntos.length,
                            itemBuilder: (context, index) {
                              final punto = _puntos[index];
                              final completado = _puntosVisitados.contains(punto.id);

                              return Card(
                                color: completado ? Colors.green.shade50 : null,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: completado ? Colors.green : Colors.grey,
                                    child: Text(
                                      '${punto.orden}',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(punto.nombre),
                                  subtitle: Text('Código QR: ${punto.codigo}\nTolerancia: ${punto.radioM} m'),
                                  trailing: Icon(
                                    completado ? Icons.check_circle : Icons.radio_button_unchecked,
                                    color: completado ? Colors.green : Colors.grey,
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
