import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constantes/configuracion.dart';
import '../../datos/servicios/anotador_fotografia.dart';
import '../../dominio/entidades/medicion_snapshot.dart';
import '../../dominio/entidades/visita.dart';
import '../../dominio/servicios/calculadora_azimut.dart';
import '../../dominio/servicios/regla_cumplimiento.dart';
import '../providers/proveedor_camara.dart';
import '../providers/proveedor_medicion.dart';
import '../providers/proveedor_sensores.dart';
import '../widgets/overlay_medicion.dart';
import 'revision_fotografia_pantalla.dart';

class MedicionPantalla extends ConsumerStatefulWidget {
  const MedicionPantalla({super.key, required this.visita});

  final Visita visita;

  @override
  ConsumerState<MedicionPantalla> createState() => _MedicionPantallaState();
}

class _MedicionPantallaState extends ConsumerState<MedicionPantalla> {
  final _regla = const ReglaCumplimiento();
  final _azimut = const CalculadoraAzimut();
  bool _capturando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(proveedorSensores.notifier).iniciar();
      ref.read(proveedorCamara.notifier).iniciar();
    });
  }

  MedicionSnapshot _snapshot(EstadoSensores sensores) {
    final desviacion = _azimut.desviacionCircular(sensores.azimut, widget.visita.azimutObjetivo);
    return MedicionSnapshot(
      inclinacionX: sensores.inclinacionX,
      inclinacionY: sensores.inclinacionY,
      azimut: sensores.azimut,
      azimutObjetivo: widget.visita.azimutObjetivo,
      desviacionAzimut: desviacion,
      latitud: sensores.latitud,
      longitud: sensores.longitud,
      cumple: _regla.evaluar(inclinacionX: sensores.inclinacionX, inclinacionY: sensores.inclinacionY, azimut: sensores.azimut, azimutObjetivo: widget.visita.azimutObjetivo),
      medidoEn: DateTime.now(),
    );
  }

  Future<void> _capturar(EstadoSensores sensores) async {
    if (!sensores.listo) {
      _mostrar(sensores.error ?? 'Los sensores todavía se están inicializando.');
      return;
    }
    setState(() => _capturando = true);
    try {
      final snapshot = _snapshot(sensores);
      final original = await ref.read(proveedorCamara.notifier).tomarFotografia();
      if (await File(original.path).length() > ConfiguracionApp.maxFotoBytes) {
        _mostrar('La fotografía supera el límite de 4 MB. Ajuste la resolución e intente de nuevo.');
        return;
      }
      final anotada = await const AnotadorFotografia().anotar(rutaOriginal: original.path, identificadorVisita: widget.visita.identificador, snapshot: snapshot);
      ref.read(proveedorMedicion.notifier).guardarFoto(snapshot: snapshot, fotoAnotadaPath: anotada.path);
      if (mounted) await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RevisionFotografiaPantalla()));
    } catch (_) {
      _mostrar('No se pudo capturar o anotar la fotografía.');
    } finally {
      if (mounted) setState(() => _capturando = false);
    }
  }

  void _mostrar(String mensaje) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));

  @override
  Widget build(BuildContext context) {
    final sensores = ref.watch(proveedorSensores);
    final camara = ref.watch(proveedorCamara);
    final snapshot = _snapshot(sensores);
    return Scaffold(
      appBar: AppBar(title: Text('Medición · ${widget.visita.identificador}')),
      body: Column(
        children: [
          Expanded(
            child: camara.lista
                ? Stack(fit: StackFit.expand, children: [CameraPreview(camara.controlador!), OverlayMedicion(snapshot: snapshot)])
                : Center(child: camara.cargando ? const CircularProgressIndicator() : Text(camara.error ?? 'Inicializando cámara…')),
          ),
          if (sensores.error != null) Padding(padding: const EdgeInsets.all(12), child: Text(sensores.error!, style: const TextStyle(color: Colors.red))),
          if (sensores.advertenciaUbicacion != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(sensores.advertenciaUbicacion!, style: const TextStyle(color: Colors.orange))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: !camara.lista || _capturando ? null : () => _capturar(sensores),
              icon: const Icon(Icons.camera_alt),
              label: Text(_capturando ? 'Procesando…' : 'Tomar fotografía anotada'),
            ),
          ),
        ],
      ),
    );
  }
}
