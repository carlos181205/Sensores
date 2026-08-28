import 'dart:async';
import 'package:flutter/material.dart';

import '../../datos/local/db_helper_inventario.dart';
import '../../datos/modelos/item_model.dart';
import '../../datos/servicios/api_inventario_cliente.dart';
import '../../datos/servicios/sincronizador_inventario.dart';
import 'escaner_barras_page.dart';
import 'resolucion_conflictos_page.dart';

class InventarioHomePage extends StatefulWidget {
  const InventarioHomePage({super.key});

  @override
  State<InventarioHomePage> createState() => _InventarioHomePageState();
}

class _InventarioHomePageState extends State<InventarioHomePage> {
  final ApiInventarioCliente _api = ApiInventarioCliente();
  final DbHelperInventario _dbHelper = DbHelperInventario.instance;
  final SincronizadorInventario _sincronizador = SincronizadorInventario();

  bool _enLinea = false;
  int _pendientesSucios = 0;
  List<ItemInventario> _items = [];
  bool _cargando = true;
  Timer? _timerSync;

  @override
  void initState() {
    super.initState();
    _cargarEstado();
    _timerSync = Timer.periodic(const Duration(seconds: 8), (_) {
      _comprobarConexion();
    });
  }

  Future<void> _cargarEstado() async {
    await _comprobarConexion();
    await _cargarItemsLocales();
  }

  Future<void> _comprobarConexion() async {
    try {
      await _api.get('/salud');
      if (!mounted) return;
      setState(() => _enLinea = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _enLinea = false);
    }
  }

  Future<void> _descargarCatalogoServidor() async {
    if (!_enLinea) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sin red para descargar el catálogo')),
      );
      return;
    }

    setState(() => _cargando = true);
    try {
      final res = await _api.get('/items');
      final lista = (res.data['items'] as List?) ?? [];
      final itemsServidor = lista.map((e) => ItemInventario.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      await _dbHelper.guardarCatalogoInicial(itemsServidor);
      await _cargarItemsLocales();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catálogo descargado correctamente a SQLite local')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al descargar catálogo: $e')),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _cargarItemsLocales() async {
    final items = await _dbHelper.obtenerTodos();
    final sucios = await _dbHelper.contarPendientesSucios();

    if (!mounted) return;
    setState(() {
      _items = items;
      _pendientesSucios = sucios;
      _cargando = false;
    });
  }

  Future<void> _sincronizarDelta() async {
    await _comprobarConexion();
    if (!_enLinea) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sin conexión. Sincronización pospuesta.')),
      );
      return;
    }

    setState(() => _cargando = true);
    final resultado = await _sincronizador.sincronizar();
    await _cargarItemsLocales();

    if (!mounted) return;

    if (!resultado.exitoso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error en sincronización: ${resultado.errorMensaje}')),
      );
      setState(() => _cargando = false);
      return;
    }

    if (resultado.conflictos.isNotEmpty) {
      // RF-06: Presentar conflictos al usuario
      final resuelto = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResolucionConflictosPage(conflictos: resultado.conflictos),
        ),
      );
      if (resuelto == true) {
        await _cargarItemsLocales();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sincronización exitosa: ${resultado.aplicadosCount} ítems actualizados')),
      );
    }

    setState(() => _cargando = false);
  }

  @override
  void dispose() {
    _timerSync?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('P3 · Inventario CEET sin conexión'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Descargar catálogo antes de bajar a sótano',
            onPressed: _descargarCatalogoServidor,
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sincronizar cambios (Delta)',
            onPressed: _sincronizarDelta,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(
                        avatar: Icon(
                          _enLinea ? Icons.wifi : Icons.wifi_off,
                          color: _enLinea ? Colors.green : Colors.red,
                        ),
                        label: Text(_enLinea ? 'En línea' : 'Modo Avión / Offline'),
                      ),
                      const SizedBox(width: 12),
                      Chip(
                        avatar: const Icon(Icons.edit_note, color: Colors.orange),
                        label: Text('Sucios local: $_pendientesSucios'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _descargarCatalogoServidor,
                        icon: const Icon(Icons.cloud_download),
                        label: const Text('Descargar Catálogo'),
                      ),
                      FilledButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EscanerBarrasPage(),
                            ),
                          );
                          await _cargarItemsLocales();
                        },
                        icon: const Icon(Icons.barcode_reader),
                        label: const Text('Escanear Código'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Catálogo Local (SQLite)',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _items.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('No hay ítems en la base de datos SQLite local.'),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: _descargarCatalogoServidor,
                                  child: const Text('Descargar datos de prueba del servidor'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              final esSucio = item.sucio == 1;

                              return Card(
                                color: esSucio ? Colors.amber.shade50 : null,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: esSucio ? Colors.amber.shade700 : Colors.indigo,
                                    child: Text(
                                      '${item.cantidad}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(item.nombre),
                                  subtitle: Text(
                                    'Código: ${item.codigoBarras} · Estado: ${item.estado}\n'
                                    'Versión: ${item.version} ${esSucio ? "· ⚠️ Pendiente subir" : ""}',
                                  ),
                                  trailing: item.fotoBase64 != null
                                      ? const Icon(Icons.photo, color: Colors.purple)
                                      : null,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
