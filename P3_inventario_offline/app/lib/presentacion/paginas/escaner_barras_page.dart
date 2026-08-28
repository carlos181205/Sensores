import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../datos/local/db_helper_inventario.dart';
import '../../datos/modelos/item_model.dart';

class EscanerBarrasPage extends StatefulWidget {
  const EscanerBarrasPage({super.key});

  @override
  State<EscanerBarrasPage> createState() => _EscanerBarrasPageState();
}

class _EscanerBarrasPageState extends State<EscanerBarrasPage> {
  final DbHelperInventario _dbHelper = DbHelperInventario.instance;
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  final ImagePicker _picker = ImagePicker();

  bool _procesando = false;

  Future<void> _procesarCodigo(String codigo) async {
    if (_procesando) return;
    setState(() => _procesando = true);

    final item = await _dbHelper.buscarPorCodigoBarras(codigo);

    if (item == null) {
      // RF-04: Código desconocido -> Vibración de error
      await HapticFeedback.vibrate();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Código de barras desconocido: $codigo'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _procesando = false);
      return;
    }

    // RF-04: Código válido -> Vibración háptica de éxito
    await HapticFeedback.selectionClick();

    if (!mounted) return;
    await _mostrarDialogoEdicion(item);
    setState(() => _procesando = false);
  }

  Future<void> _mostrarDialogoEdicion(ItemInventario item) async {
    int cantidad = item.cantidad;
    String estado = item.estado;
    String? fotoBase64 = item.fotoBase64;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(item.nombre),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Código: ${item.codigoBarras}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Cantidad conteo:'),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                if (cantidad > 0) setModalState(() => cantidad--);
                              },
                            ),
                            Text('$cantidad', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => setModalState(() => cantidad++),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Estado del equipo:'),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: estado,
                      items: const [
                        DropdownMenuItem(value: 'excelente', child: Text('Excelente')),
                        DropdownMenuItem(value: 'bueno', child: Text('Bueno')),
                        DropdownMenuItem(value: 'averiado', child: Text('Averiado (Requiere Foto)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => estado = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    if (estado == 'averiado') ...[
                      OutlinedButton.icon(
                        onPressed: () async {
                          final XFile? photo = await _picker.pickImage(
                            source: ImageSource.camera,
                            maxWidth: 600,
                            imageQuality: 50, // RF-03: Compresión para garantizar < 300 KB
                          );
                          if (photo != null) {
                            final bytes = await File(photo.path).readAsBytes();
                            final b64 = base64Encode(bytes);
                            setModalState(() => fotoBase64 = b64);
                          }
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: Text(fotoBase64 == null ? 'Tomar Foto de Avería' : 'Foto Tomada (Cambiar)'),
                      ),
                      if (fotoBase64 != null)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text('✓ Fotografía comprimida adjuntada', style: TextStyle(color: Colors.green, fontSize: 12)),
                        ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    await _dbHelper.actualizarConteoLocal(item.id, cantidad, estado, fotoBase64);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
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
        title: const Text('Escáner de Inventario (EAN-13 / Code-128)'),
      ),
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          final barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final code = barcodes.first.rawValue;
            if (code != null && code.isNotEmpty) {
              _procesarCodigo(code);
            }
          }
        },
      ),
    );
  }
}
