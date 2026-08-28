import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class ColaImpacto {
  ColaImpacto({
    required this.id,
    required this.dispositivoId,
    required this.claveCliente,
    required this.intensidad,
    required this.latitud,
    required this.longitud,
    required this.descripcion,
    required this.createdAt,
    required this.enviado,
  });

  final int? id;
  final String dispositivoId;
  final String claveCliente;
  final double intensidad;
  final double latitud;
  final double longitud;
  final String descripcion;
  final DateTime createdAt;
  final int enviado;

  Map<String, dynamic> toMap() {
    return {
      'dispositivo_id': dispositivoId,
      'clave_cliente': claveCliente,
      'intensidad': intensidad,
      'latitud': latitud,
      'longitud': longitud,
      'descripcion': descripcion,
      'created_at': createdAt.toIso8601String(),
      'enviado': enviado,
    };
  }

  factory ColaImpacto.fromMap(Map<String, dynamic> map) {
    return ColaImpacto(
      id: map['id'] as int?,
      dispositivoId: map['dispositivo_id'] as String,
      claveCliente: map['clave_cliente'] as String,
      intensidad: (map['intensidad'] as num).toDouble(),
      latitud: (map['latitud'] as num).toDouble(),
      longitud: (map['longitud'] as num).toDouble(),
      descripcion: map['descripcion'] as String? ?? 'Impacto',
      createdAt: DateTime.parse(map['created_at'] as String),
      enviado: map['enviado'] as int? ?? 0,
    );
  }
}

class DbHelper {
  static final DbHelper instance = DbHelper._internal();
  DbHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bitacora_ceet.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cola_impactos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dispositivo_id TEXT NOT NULL,
        clave_cliente TEXT NOT NULL,
        intensidad REAL NOT NULL,
        latitud REAL,
        longitud REAL,
        descripcion TEXT,
        created_at TEXT NOT NULL,
        enviado INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<int> insertarEventoPendiente(ColaImpacto evento) async {
    final db = await database;
    return db.insert('cola_impactos', evento.toMap());
  }

  Future<List<ColaImpacto>> obtenerPendientes() async {
    final db = await database;
    final maps = await db.query(
      'cola_impactos',
      where: 'enviado = ?',
      whereArgs: [0],
      orderBy: 'created_at DESC',
    );
    return maps.map((e) => ColaImpacto.fromMap(e)).toList();
  }

  Future<int> marcarComoEnviado(int id) async {
    final db = await database;
    return db.update(
      'cola_impactos',
      {'enviado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> eliminarEnviados() async {
    final db = await database;
    return db.delete(
      'cola_impactos',
      where: 'enviado = ?',
      whereArgs: [1],
    );
  }

  Future<int> contarPendientes() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as total FROM cola_impactos WHERE enviado = 0');
    return result.isNotEmpty ? (result.first['total'] as int?) ?? 0 : 0;
  }

  Future<void> limpiarTodo() async {
    final db = await database;
    await db.delete('cola_impactos');
  }
}
