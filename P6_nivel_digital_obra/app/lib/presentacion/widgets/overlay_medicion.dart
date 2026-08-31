import 'package:flutter/material.dart';

import '../../dominio/entidades/medicion_snapshot.dart';

class OverlayMedicion extends StatelessWidget {
  const OverlayMedicion({super.key, required this.snapshot});

  final MedicionSnapshot snapshot;

  @override
  Widget build(BuildContext context) => Semantics(
        label: snapshot.cumple ? 'CUMPLE' : 'NO CUMPLE',
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            color: Colors.black.withValues(alpha: 0.72),
            padding: const EdgeInsets.all(14),
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.white, fontSize: 15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('X: ${snapshot.inclinacionX.toStringAsFixed(1)}°   Y: ${snapshot.inclinacionY.toStringAsFixed(1)}°'),
                  Text('Azimut: ${snapshot.azimut.toStringAsFixed(1)}°   Objetivo: ${snapshot.azimutObjetivo.toStringAsFixed(1)}°'),
                  Text('Desviación: ${snapshot.desviacionAzimut.toStringAsFixed(1)}°'),
                  Text('GPS: ${snapshot.latitud?.toStringAsFixed(6) ?? 'sin dato'}, ${snapshot.longitud?.toStringAsFixed(6) ?? 'sin dato'}'),
                  const SizedBox(height: 4),
                  Text(snapshot.cumple ? 'ESTADO: CUMPLE' : 'ESTADO: NO CUMPLE', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      );
}
