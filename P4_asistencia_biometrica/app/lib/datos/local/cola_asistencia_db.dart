import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class ColaAsistenciaDb {
  static final ColaAsistenciaDb _instance = ColaAsistenciaDb._internal();

  factory ColaAsistenciaDb() => _instance;

  ColaAsistenciaDb._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'cola_asistencia_p4.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE marcacion_offline (
            id TEXT PRIMARY KEY,
            tipo TEXT NOT NULL,
            latitud REAL NOT NULL,
            longitud REAL NOT NULL,
            precision_m REAL NOT NULL,
            timestamp TEXT NOT NULL,
            usuario_id INTEGER NOT NULL,
            sede_id INTEGER NOT NULL,
            sincronizada INTEGER NOT NULL DEFAULT 0,
            creada_en TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> guardarMarcacionOffline({
    required String id,
    required String tipo,
    required double latitud,
    required double longitud,
    required double precisionM,
    required String timestamp,
    required int usuarioId,
    required int sedeId,
  }) async {
    final db = await database;
    await db.insert(
      'marcacion_offline',
      {
        'id': id,
        'tipo': tipo,
        'latitud': latitud,
        'longitud': longitud,
        'precision_m': precisionM,
        'timestamp': timestamp,
        'usuario_id': usuarioId,
        'sede_id': sedeId,
        'sincronizada': 0,
        'creada_en': DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> obtenerPendientes() async {
    final db = await database;
    final rows = await db.query(
      'marcacion_offline',
      where: 'sincronizada = 0',
      orderBy: 'creada_en ASC',
    );
    return rows;
  }

  Future<void> marcarComoSincronizada(String id) async {
    final db = await database;
    await db.update(
      'marcacion_offline',
      {'sincronizada': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> eliminarSincronizadas() async {
    final db = await database;
    await db.delete(
      'marcacion_offline',
      where: 'sincronizada = 1',
    );
  }

  Future<void> limpiarTodo() async {
    final db = await database;
    await db.delete('marcacion_offline');
  }

  Stream<List<Map<String, dynamic>>> streamPendientes() {
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();
    Future.microtask(() async {
      final db = await database;
      final sub = db.query(
        'marcacion_offline',
        where: 'sincronizada = 0',
        orderBy: 'creada_en ASC',
      );
      final rows = await sub;
      controller.add(rows);
    });
    return controller.stream;
  }
}
