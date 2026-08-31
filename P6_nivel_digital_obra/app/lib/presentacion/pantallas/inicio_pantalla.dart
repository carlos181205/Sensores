import 'package:flutter/material.dart';

import 'nueva_visita_pantalla.dart';

class InicioPantalla extends StatelessWidget {
  const InicioPantalla({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Nivel digital de obra')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.architecture_outlined, size: 82),
                const SizedBox(height: 20),
                Text('Inspección de mástiles', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                const Text('Mide inclinación, rumbo y ubicación usando hardware real; captura evidencia anotada y genera el reporte de la visita.', textAlign: TextAlign.center),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const NuevaVisitaPantalla())),
                  icon: const Icon(Icons.add_business),
                  label: const Text('Nueva visita'),
                ),
              ],
            ),
          ),
        ),
      );
}
