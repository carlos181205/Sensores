import 'package:flutter/material.dart';

import 'mapa_ruido_page.dart';
import 'prueba_microfono_page.dart';

class InicioPage extends StatelessWidget {
  const InicioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('P5 - Mapa de ruido')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.map, size: 88),
                const SizedBox(height: 20),
                Text(
                  'Mapa colaborativo de ruido',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Captura niveles relativos con micrófono y GPS, o consulta las celdas agregadas.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PruebaMicrofonoPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Iniciar medición'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
