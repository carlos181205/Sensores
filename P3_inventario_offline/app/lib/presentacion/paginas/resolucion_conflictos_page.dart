import 'package:flutter/material.dart';
import '../../datos/modelos/item_model.dart';
import '../../datos/servicios/sincronizador_inventario.dart';

class ResolucionConflictosPage extends StatefulWidget {
  const ResolucionConflictosPage({
    super.key,
    required this.conflictos,
  });

  final List<ConflictoVersion> conflictos;

  @override
  State<ResolucionConflictosPage> createState() => _ResolucionConflictosPageState();
}

class _ResolucionConflictosPageState extends State<ResolucionConflictosPage> {
  final SincronizadorInventario _sincronizador = SincronizadorInventario();
  late List<ConflictoVersion> _listaConflictos;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _listaConflictos = List.from(widget.conflictos);
  }

  Future<void> _resolver(ConflictoVersion conflicto, String opcion) async {
    setState(() => _procesando = true);

    final valorElegido = opcion == 'servidor' ? conflicto.valorServidor : conflicto.valorCliente;
    final exito = await _sincronizador.resolverConflictoEnServidor(conflicto.id, opcion, valorElegido);

    if (!mounted) return;

    if (exito) {
      setState(() {
        _listaConflictos.removeWhere((c) => c.id == conflicto.id);
        _procesando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conflicto resuelto conservando versión $opcion')),
      );

      if (_listaConflictos.isEmpty) {
        Navigator.pop(context, true);
      }
    } else {
      setState(() => _procesando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al comunicar resolución con el servidor'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resolución de Conflictos de Versión'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: _listaConflictos.isEmpty
          ? const Center(child: Text('No hay conflictos pendientes por resolver.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _listaConflictos.length,
              itemBuilder: (context, index) {
                final c = _listaConflictos[index];
                final valServidor = c.valorServidor;
                final valCliente = c.valorCliente;

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Conflicto en ítem ${c.id}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('☁️ SERVIDOR (Versión ${c.versionServidor})', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                              Text('Cantidad: ${valServidor['cantidad']}'),
                              Text('Estado: ${valServidor['estado']}'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('📱 CLIENTE LOCAL (Versión ${c.versionCliente})', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade900)),
                              Text('Cantidad: ${valCliente['cantidad']}'),
                              Text('Estado: ${valCliente['estado']}'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _procesando ? null : () => _resolver(c, 'servidor'),
                                child: const Text('Conservar Servidor'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: _procesando ? null : () => _resolver(c, 'cliente'),
                                child: const Text('Conservar Cliente'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
