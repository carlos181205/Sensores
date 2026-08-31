import 'dart:async';

import 'package:flutter/material.dart';

import '../../datos/modelos/estado_medicion.dart';
import '../../datos/modelos/lote_muestras.dart';
import '../../datos/modelos/muestra_ruido.dart';
import '../../dominio/servicios/medicion_ruido_service.dart';
import 'mapa_ruido_page.dart';

class PruebaMicrofonoPage extends StatefulWidget {
  const PruebaMicrofonoPage({super.key});

  @override
  State<PruebaMicrofonoPage> createState() => _PruebaMicrofonoPageState();
}

class _PruebaMicrofonoPageState extends State<PruebaMicrofonoPage> {
  final MedicionRuidoService _medicionService = MedicionRuidoService();

  StreamSubscription<MuestraRuido>? _muestraSubscription;
  StreamSubscription<EstadoMedicion>? _estadoSubscription;

  MuestraRuido? _muestra;

  int _cantidadMuestras = 0;

  bool _activo = false;

  String? _error;

  String _estadoTexto = 'Listo para iniciar.';

  int? _bateria;

  @override
  void initState() {
    super.initState();

    _muestraSubscription = _medicionService.muestras.listen((muestra) {
      if (!mounted) {
        return;
      }

      setState(() {
        _muestra = muestra;
        _cantidadMuestras = _medicionService.cantidadMuestras;
      });
    });

    _estadoSubscription = _medicionService.estados.listen((estado) {
      if (!mounted) return;
      setState(() {
        _estadoTexto = estado.mensaje;
        _bateria = estado.bateriaPercent;
        _cantidadMuestras = _medicionService.cantidadMuestras;
        _activo = _medicionService.activo;
      });
    });
  }

  Future<void> _iniciar() async {
    setState(() {
      _error = null;
    });

    try {
      await _medicionService.iniciar();

      if (!mounted) {
        return;
      }

      setState(() {
        _activo = true;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = e.toString();
        _activo = false;
      });
    }
  }

  Future<void> _detener() async {
    try {
      await _medicionService.detener();

      if (!mounted) {
        return;
      }

      setState(() {
        _activo = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _muestraSubscription?.cancel();
    _estadoSubscription?.cancel();
    _medicionService.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('P5 - Mapa de ruido')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 30),

              const Icon(Icons.graphic_eq, size: 80),

              const SizedBox(height: 24),

              Text(
                'Nivel de ruido',
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 12),

              Text(
                _muestra == null ? '--' : _muestra!.nivelDb.toStringAsFixed(1),
                style: Theme.of(context).textTheme.displaySmall,
              ),

              const Text('Nivel relativo'),

              const SizedBox(height: 24),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Muestras del lote',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        '$_cantidadMuestras / '
                        '${LoteMuestras.capacidad}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.battery_std),
                  title: Text(
                    _bateria == null ? 'Batería: --' : 'Batería: $_bateria%',
                  ),
                  subtitle: Text(_estadoTexto),
                ),
              ),

              if (_muestra != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Datos de la medición',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),

                        const SizedBox(height: 12),

                        Text(
                          'Latitud: '
                          '${_muestra!.latitud.toStringAsFixed(6)}',
                        ),

                        Text(
                          'Longitud: '
                          '${_muestra!.longitud.toStringAsFixed(6)}',
                        ),

                        Text(
                          'Precisión: '
                          '${_muestra!.precisionM.toStringAsFixed(1)} m',
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Medido: '
                          '${_muestra!.medidoEn}',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: 20),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MapaRuidoPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Ver mapa'),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _activo ? _detener : _iniciar,
                  icon: Icon(_activo ? Icons.stop : Icons.play_arrow),
                  label: Text(
                    _activo ? 'Detener medición' : 'Iniciar medición',
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
