import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/proveedor_medicion.dart';

class ResultadoPantalla extends ConsumerWidget {
  const ResultadoPantalla({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(proveedorMedicion);
    final snapshot = estado.snapshot;
    return Scaffold(
      appBar: AppBar(title: const Text('Resultado')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(snapshot?.cumple == true ? Icons.check_circle : Icons.cancel, color: snapshot?.cumple == true ? Colors.green : Colors.red, size: 72),
            const SizedBox(height: 16),
            Text(snapshot?.cumple == true ? 'CUMPLE' : 'NO CUMPLE', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 10),
            const Text('La medición fue registrada en el servidor.'),
            if (estado.error != null) Text(estado.error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: () => ref.read(proveedorMedicion.notifier).descargarYCompartirReporte(), icon: const Icon(Icons.picture_as_pdf), label: const Text('Generar y compartir PDF')),
          ]),
        ),
      ),
    );
  }
}
