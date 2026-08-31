import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/configuracion.dart';
import '../../datos/modelos/celda_ruido.dart';
import '../providers/mapa_ruido_provider.dart';

class MapaRuidoPage extends ConsumerWidget {
  const MapaRuidoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapa = ref.watch(mapaRuidoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('P5 - Mapa de ruido')),
      body: mapa.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            _ErrorMapa(onRetry: () => ref.invalidate(mapaRuidoProvider)),
        data: (celdas) {
          if (celdas.isEmpty) {
            return const _EstadoMapa(
              icon: Icons.map_outlined,
              mensaje: 'No hay celdas con al menos 5 muestras.',
            );
          }
          return _MapaConDatos(celdas: celdas);
        },
      ),
    );
  }
}

class _MapaConDatos extends StatelessWidget {
  const _MapaConDatos({required this.celdas});

  final List<CeldaRuido> celdas;

  @override
  Widget build(BuildContext context) {
    final centro = LatLng(celdas.first.celdaLat, celdas.first.celdaLon);

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(initialCenter: centro, initialZoom: 13),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              maxZoom: 17,
              userAgentPackageName: 'com.example.app',
            ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'Map data: © OpenStreetMap contributors, SRTM | '
                  'Map style: © OpenTopoMap (CC-BY-SA)',
                ),
              ],
            ),
            MarkerLayer(
              markers: celdas
                  .map((celda) => _crearMarcador(context, celda))
                  .toList(growable: false),
            ),
          ],
        ),
        Positioned(
          left: 12,
          right: 12,
          top: 12,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                'Celdas agregadas: ${celdas.length} · '
                'Bajo ≤ ${ConfiguracionP5.ruidoBajoMax.toInt()} · '
                'Moderado ≤ ${ConfiguracionP5.ruidoModeradoMax.toInt()} · '
                'Alto ≤ ${ConfiguracionP5.ruidoAltoMax.toInt()} · '
                'Muy alto > ${ConfiguracionP5.ruidoAltoMax.toInt()}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Marker _crearMarcador(BuildContext context, CeldaRuido celda) {
    final color = _colorNivel(celda.promedioDb);
    return Marker(
      point: LatLng(celda.celdaLat, celda.celdaLon),
      width: 54,
      height: 54,
      child: GestureDetector(
        onTap: () => _mostrarDetalle(context, celda),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.82),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            celda.promedioDb.toStringAsFixed(0),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarDetalle(BuildContext context, CeldaRuido celda) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Celda de ruido',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text('Centro: ${celda.celdaLat}, ${celda.celdaLon}'),
              Text('Promedio relativo: ${celda.promedioDb.toStringAsFixed(1)}'),
              Text('Máximo relativo: ${celda.maximoDb.toStringAsFixed(1)}'),
              Text('Muestras: ${celda.muestras}'),
              const SizedBox(height: 8),
              const Text(
                'La escala es relativa; no representa dB SPL calibrados.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _colorNivel(double nivel) {
    if (nivel <= ConfiguracionP5.ruidoBajoMax) return Colors.green;
    if (nivel <= ConfiguracionP5.ruidoModeradoMax) return Colors.amber.shade800;
    if (nivel <= ConfiguracionP5.ruidoAltoMax) return Colors.orange;
    return Colors.red;
  }
}

class _ErrorMapa extends StatelessWidget {
  const _ErrorMapa({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _EstadoMapa(
      icon: Icons.cloud_off,
      mensaje: 'No se pudo conectar con el servidor.',
      accion: OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Reintentar'),
      ),
    );
  }
}

class _EstadoMapa extends StatelessWidget {
  const _EstadoMapa({required this.icon, required this.mensaje, this.accion});

  final IconData icon;
  final String mensaje;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64),
            const SizedBox(height: 16),
            Text(mensaje, textAlign: TextAlign.center),
            if (accion != null) ...[const SizedBox(height: 16), accion!],
          ],
        ),
      ),
    );
  }
}
