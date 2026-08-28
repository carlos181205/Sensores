import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../modelos/item_model.dart';

class DbHelperInventario {
  static final DbHelperInventario instance = DbHelperInventario._internal();
  DbHelperInventario._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'inventario_ceet.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE item (
        id TEXT PRIMARY KEY,
        codigo_barras TEXT NOT NULL,
        nombre TEXT NOT NULL,
        cantidad INTEGER NOT NULL,
        estado TEXT NOT NULL,
        version INTEGER NOT NULL DEFAULT 1,
        sucio INTEGER NOT NULL DEFAULT 0,
        foto_base64 TEXT,
        modificado_en TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_item_codigo ON item(codigo_barras);');
    await db.execute('CREATE INDEX idx_item_sucio ON item(sucio);');
  }

  Future<void> guardarCatalogoInicial(List<ItemInventario> items) async {
    final db = await database;
    final batch = db.batch();
    for (final item in items) {
      batch.insert(
        'item',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<ItemInventario>> obtenerTodos() async {
    final db = await database;
    final maps = await db.query('item', orderBy: 'nombre ASC');
    return maps.map((e) => ItemInventario.fromMap(e)).toList();
  }

  Future<ItemInventario?> buscarPorCodigoBarras(String codigo) async {
    final db = await database;
    final maps = await db.query(
      'item',
      where: 'codigo_barras = ?',
      whereArgs: [codigo],
    );
    if (maps.isEmpty) return null;
    return ItemInventario.fromMap(maps.first);
  }

  Future<int> actualizarConteoLocal(String id, int nuevaCantidad, String nuevoEstado, String? fotoBase64) async {
    final db = await database;
    final res = await db.query('item', where: 'id = ?', whereArgs: [id]);
    if (res.isEmpty) return 0;

    final actual = ItemInventario.fromMap(res.first);
    final actualizado = actual.copyWith(
      cantidad: nuevaCantidad,
      estado: nuevoEstado,
      fotoBase64: fotoBase64 ?? actual.fotoBase64,
      sucio: 1, // Marca como sucio (pendiente de sincronizar)
      modificadoEn: DateTime.now(),
    );

    return db.update(
      'item',
      actualizado.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ItemInventario>> obtenerModificadosSucios() async {
    final db = await database;
    final maps = await db.query(
      'item',
      where: 'sucio = ?',
      whereArgs: [1],
    );
    return maps.map((e) => ItemInventario.fromMap(e)).toList();
  }

  Future<void> marcarComoLimpio(String id, int nuevaVersion) async {
    final db = await database;
    await db.update(
      'item',
      {
        'sucio': 0,
        'version': nuevaVersion,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> actualizarItemDesdeServidor(ItemInventario item) async {
    final db = await database;
    await db.insert(
      'item',
      item.copyWith(sucio: 0).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> contarPendientesSucios() async {
    final db = await database;
    final res = await db.rawQuery('SELECT COUNT(*) as total FROM item WHERE sucio = 1');
    return res.isNotEmpty ? (res.first['total'] as int?) ?? 0 : 0;
  }
}
