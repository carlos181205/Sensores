import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../datos/local/db_helper_ronda.dart';
import '../../datos/modelos/ronda_modelos.dart';
import '../../datos/servicios/api_ronda_cliente.dart';

class EscanerRondaPage extends StatefulWidget {
  const EscanerRondaPage({super.key, required this.rondaId});

  final String rondaId;

  @override
  State<EscanerRondaPage> createState() => _EscanerRondaPageState();
}

class _EscanerRondaPageState extends State<EscanerRondaPage> {
  final ApiRondaCliente _api = ApiRondaCliente();
  final DbHelperRonda _dbHelper = DbHelperRonda.instance;
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _procesando = false;
  String? _mensajeResultado;
  bool? _ultimoResultadoExitoso;

  Future<void> _procesarCodigoScaneado(String codigo) async {
    if (_procesando) return;
    setState(() {
      _procesando = true;
      _mensajeResultado = null;
      _ultimoResultadoExitoso = null;
    });

    try {
      // RF-02: Tomar posición en el instante del escaneo
      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Descartar lecturas de GPS con precisión mayor a 30 m (Criterio bloqueante)
      if (posicion.accuracy > 30.0) {
        await HapticFeedback.vibrate();
        if (!mounted) return;
        setState(() {
          _ultimoResultadoExitoso = false;
          _mensajeResultado = 'Señal GPS insuficiente (${posicion.accuracy.toStringAsFixed(1)} m). Sal al exterior.';
          _procesando = false;
        });
        return;
      }

      final escaneadaEn = DateTime.now();

      // Intentar enviar al backend para validación de geocerca en el servidor
      try {
        final res = await _api.post('/rondas/${widget.rondaId}/marcaciones', {
          'codigo': codigo,
          'latitud': posicion.latitude,
          'longitud': posicion.longitude,
          'precisionM': posicion.accuracy,
          'escaneadaEn': escaneadaEn.toIso8601String(),
        });

        final aceptada = (res.data['ok'] as bool?) ?? false;
        final motivo = res.data['marcacion']?['motivo_rechazo'] as String?;

        if (aceptada) {
          await HapticFeedback.mediumImpact();
        } else {
          await HapticFeedback.vibrate();
        }

        if (!mounted) return;
        setState(() {
          _ultimoResultadoExitoso = aceptada;
          _mensajeResultado = aceptada
              ? 'Punto $codigo registrado correctamente'
              : (motivo ?? 'Rechazado por fuera de rango');
          _procesando = false;
        });
      } catch (e) {
        // RF-05: Sin red -> Guardar en SQLite local conservando coordenadas y hora originales
        final marcacionLocal = MarcacionLocal(
          id: null,
          rondaId: widget.rondaId,
          codigo: codigo,
          latitud: posicion.latitude,
          longitud: posicion.longitude,
          precisionM: posicion.accuracy,
          escaneadaEn: escaneadaEn,
          enviado: 0,
        );

        await _dbHelper.insertarMarcacionOffline(marcacionLocal);
        await HapticFeedback.selectionClick();

        if (!mounted) return;
        setState(() {
          _ultimoResultadoExitoso = true;
          _mensajeResultado = 'Marcación guardada localmente (Sin conexión)';
          _procesando = false;
        });
      }
    } catch (e) {
      await HapticFeedback.vibrate();
      if (!mounted) return;
      setState(() {
        _ultimoResultadoExitoso = false;
        _mensajeResultado = 'Error al obtener ubicación GPS';
        _procesando = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escáner QR · Ronda Segura'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                final barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final code = barcodes.first.rawValue;
                  if (code != null && code.isNotEmpty) {
                    _procesarCodigoScaneado(code);
                  }
                }
              },
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              color: _ultimoResultadoExitoso == null
                  ? Colors.grey.shade100
                  : (_ultimoResultadoExitoso! ? Colors.green.shade100 : Colors.red.shade100),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_procesando)
                    const CircularProgressIndicator()
                  else if (_ultimoResultadoExitoso != null) ...[
                    Icon(
                      _ultimoResultadoExitoso! ? Icons.check_circle : Icons.cancel,
                      size: 48,
                      color: _ultimoResultadoExitoso! ? Colors.green : Colors.red,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _mensajeResultado ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _ultimoResultadoExitoso! ? Colors.green.shade900 : Colors.red.shade900,
                      ),
                    ),
                  ] else
                    const Text(
                      'Apunta la cámara al código QR del punto de control',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
