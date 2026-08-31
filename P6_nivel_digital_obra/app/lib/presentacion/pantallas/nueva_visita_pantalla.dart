import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errores/fallo_app.dart';
import '../providers/proveedor_medicion.dart';
import 'medicion_pantalla.dart';

class NuevaVisitaPantalla extends ConsumerStatefulWidget {
  const NuevaVisitaPantalla({super.key});

  @override
  ConsumerState<NuevaVisitaPantalla> createState() => _NuevaVisitaPantallaState();
}

class _NuevaVisitaPantallaState extends ConsumerState<NuevaVisitaPantalla> {
  final _formulario = GlobalKey<FormState>();
  final _identificador = TextEditingController();
  final _azimut = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _identificador.dispose();
    _azimut.dispose();
    super.dispose();
  }

  Future<void> _continuar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      final visita = await ref.read(proveedorRepositorioVisitas).crearVisita(
            identificador: _identificador.text.trim(),
            azimutObjetivo: double.parse(_azimut.text),
          );
      ref.read(proveedorMedicion.notifier).seleccionarVisita(visita);
      if (mounted) await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MedicionPantalla(visita: visita)));
    } on FalloApp catch (error) {
      _mostrar(error.mensaje);
    } catch (_) {
      _mostrar('No se pudo crear la visita.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _mostrar(String mensaje) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Nueva visita')),
        body: Form(
          key: _formulario,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                TextFormField(controller: _identificador, decoration: const InputDecoration(labelText: 'Identificador de visita'), validator: (valor) => valor == null || valor.trim().isEmpty ? 'Ingrese un identificador.' : null),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _azimut,
                  decoration: const InputDecoration(labelText: 'Azimut objetivo (0 a <360°)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (valor) {
                    final numero = double.tryParse(valor ?? '');
                    return numero == null || numero < 0 || numero >= 360 ? 'El azimut objetivo debe estar entre 0 y menor que 360.' : null;
                  },
                ),
                const Spacer(),
                FilledButton(onPressed: _enviando ? null : _continuar, child: Text(_enviando ? 'Creando visita…' : 'Iniciar medición')),
              ],
            ),
          ),
        ),
      );
}
