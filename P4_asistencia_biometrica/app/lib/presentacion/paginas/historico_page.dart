import 'package:flutter/material.dart';
import '../../datos/modelos/asistencia_modelos.dart';
import '../../datos/servicios/api_asistencia_cliente.dart';

class HistoricoPage extends StatefulWidget {
  const HistoricoPage({super.key, required this.usuario});

  final UsuarioModelo usuario;

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  final ApiAsistenciaCliente _api = ApiAsistenciaCliente();
  List<MarcacionModelo> _marcaciones = [];
  bool _cargando = true;
  String? _errorMsg;
  bool _verConsolidado = false;

  @override
  void initState() {
    super.initState();
    _cargarMarcaciones();
  }

  Future<void> _cargarMarcaciones() async {
    setState(() {
      _cargando = true;
      _errorMsg = null;
    });

    try {
      if (_verConsolidado) {
        // Intentar consultar el consolidado de la ficha (Requiere rol 'instructor' en el servidor)
        final res = await _api.get('/fichas/${widget.usuario.fichaId ?? 1}/consolidado');
        final lista = (res.data['consolidado'] as List?) ?? [];
        final items = lista.map((e) => MarcacionModelo.fromMap(Map<String, dynamic>.from(e as Map))).toList();

        if (!mounted) return;
        setState(() {
          _marcaciones = items;
          _cargando = false;
        });
      } else {
        // Consultar mis marcaciones propias (Aprendiz o Instructor)
        final res = await _api.get('/marcaciones/mias');
        final lista = (res.data['marcaciones'] as List?) ?? [];
        final items = lista.map((e) => MarcacionModelo.fromMap(Map<String, dynamic>.from(e as Map))).toList();

        if (!mounted) return;
        setState(() {
          _marcaciones = items;
          _cargando = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _errorMsg = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final esInstructor = widget.usuario.rol == 'instructor';

    return Scaffold(
      appBar: AppBar(
        title: Text(_verConsolidado ? 'Consolidado Ficha (Instructor)' : 'Mis Marcaciones'),
      ),
      body: Column(
        children: [
          if (esInstructor) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Mis Marcaciones')),
                  ButtonSegment(value: true, label: Text('Consolidado Ficha')),
                ],
                selected: {_verConsolidado},
                onSelectionChanged: (val) {
                  setState(() {
                    _verConsolidado = val.first;
                  });
                  _cargarMarcaciones();
                },
              ),
            ),
          ],
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _errorMsg != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.block, size: 64, color: Colors.red),
                              const SizedBox(height: 12),
                              Text(
                                _errorMsg!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _marcaciones.isEmpty
                        ? const Center(child: Text('No hay marcaciones registradas.'))
                        : ListView.builder(
                            itemCount: _marcaciones.length,
                            itemBuilder: (context, index) {
                              final m = _marcaciones[index];
                              final esEntrada = m.tipo == 'entrada';

                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: esEntrada ? Colors.green : Colors.red,
                                    child: Icon(esEntrada ? Icons.login : Icons.logout, color: Colors.white),
                                  ),
                                  title: Text(
                                    '${m.tipo.toUpperCase()} - ${m.usuarioNombre ?? widget.usuario.nombre}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    'Fecha: ${m.registradaEn.toLocal().toString().substring(0, 19)}\n'
                                    'Distancia: ${m.distanciaM} m · Perímetro OK: ${m.dentroPerimetro ? "Sí" : "No"}',
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
