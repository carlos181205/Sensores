import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/proveedor_medicion.dart';
import 'resultado_pantalla.dart';

class RevisionFotografiaPantalla extends ConsumerWidget {
  const RevisionFotografiaPantalla({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(proveedorMedicion);
    final foto = estado.fotoAnotadaPath;
    if (foto == null) return const Scaffold(body: Center(child: Text('No hay fotografía para revisar.')));
    return Scaffold(
      appBar: AppBar(title: const Text('Revisión de fotografía')),
      body: Column(
        children: [
          Expanded(child: InteractiveViewer(child: Image.file(File(foto), fit: BoxFit.contain))),
          if (estado.error != null) Padding(padding: const EdgeInsets.all(8), child: Text(estado.error!, style: const TextStyle(color: Colors.red))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: estado.fase == FaseMedicion.enviando ? null : () async {
                await ref.read(proveedorMedicion.notifier).enviar();
                if (context.mounted && ref.read(proveedorMedicion).fase == FaseMedicion.enviada) {
                  await Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const ResultadoPantalla()));
                }
              },
              icon: const Icon(Icons.cloud_upload),
              label: Text(estado.fase == FaseMedicion.enviando ? 'Enviando…' : 'Enviar medición'),
            ),
          ),
        ],
      ),
    );
  }
}
