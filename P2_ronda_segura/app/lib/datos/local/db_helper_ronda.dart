import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../modelos/ronda_modelos.dart';

class DbHelperRonda {
  static final DbHelperRonda instance = DbHelperRonda._internal();
  DbHelperRonda._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ronda_segura.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE punto_control (
        id INTEGER PRIMARY KEY,
        codigo TEXT UNIQUE NOT NULL,
        nombre TEXT NOT NULL,
        latitud REAL NOT NULL,
        longitud REAL NOT NULL,
        radio_m INTEGER NOT NULL DEFAULT 40,
        orden INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cola_marcaciones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ronda_id TEXT NOT NULL,
        codigo TEXT NOT NULL,
        latitud REAL NOT NULL,
        longitud REAL NOT NULL,
        precision_m REAL NOT NULL,
        escaneada_en TEXT NOT NULL,
        enviado INTEGER NOT NULL DEFAULT 0,
        aceptada INTEGER NOT NULL DEFAULT 0,
        motivo_rechazo TEXT
      )
    ''');
  }

  Future<void> guardarPuntosCatalogo(List<PuntoControl> puntos) async {
    final db = await database;
    final batch = db.batch();
    for (final p in puntos) {
      batch.insert('punto_control', p.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<PuntoControl>> obtenerPuntosCatalogo() async {
    final db = await database;
    final maps = await db.query('punto_control', orderBy: 'orden ASC');
    return maps.map((e) => PuntoControl.fromMap(e)).toList();
  }

  Future<int> insertarMarcacionOffline(MarcacionLocal marcacion) async {
    final db = await database;
    return db.insert('cola_marcaciones', marcacion.toMap());
  }

  Future<List<MarcacionLocal>> obtenerPendientes() async {
    final db = await database;
    final maps = await db.query(
      'cola_marcaciones',
      where: 'enviado = ?',
      whereArgs: [0],
      orderBy: 'escaneada_en ASC',
    );
    return maps.map((e) => MarcacionLocal.fromMap(e)).toList();
  }

  Future<int> marcarEnviado(int id, bool aceptada, String? motivoRechazo) async {
    final db = await database;
    return db.update(
      'cola_marcaciones',
      {
        'enviado': 1,
        'aceptada': aceptada ? 1 : 0,
        'motivo_rechazo': motivoRechazo,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> contarPendientes() async {
    final db = await database;
    final res = await db.rawQuery('SELECT COUNT(*) as total FROM cola_marcaciones WHERE enviado = 0');
    return res.isNotEmpty ? (res.first['total'] as int?) ?? 0 : 0;
  }
}
