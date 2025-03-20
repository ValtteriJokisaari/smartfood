import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, "food.db");

    if (!await databaseExists(path)) {
      final dir = await getApplicationDocumentsDirectory();
      await Directory(dir.path).create(recursive: true);
      final asset = await rootBundle.load("assets/databases/food.db");
      await File(path).writeAsBytes(asset.buffer.asUint8List());
    }

    return await openDatabase(path);
  }

  Future<List<Map<String, dynamic>>> searchFoodCandidates(String query) async {
    final db = await database;

    final cleanedQuery = query
        .replaceAll(RegExp(r'[^\w\såäö]'), '')
        .replaceAll(RegExp(r'\b(l|g|ve|m)\b', caseSensitive: false), '')
        .trim();

    final terms = cleanedQuery.split(' ')
        .where((t) => t.length > 2)
        .toList();

    if (terms.isEmpty) return [];

    final patterns = terms.map((t) => '%${t.substring(0, t.length-1)}%').toList();

    return await db.query(
      'foods',
      where: List.generate(terms.length, (_) => 'foodname LIKE ?').join(' OR '),
      whereArgs: patterns,
      limit: 50,
    );
  }

  Future<double?> getEnergyValues(int foodId) async {
    final db = await database;
    final result = await db.query(
      'energy',
      where: 'foodid = ?',
      whereArgs: [foodId],
    );

    if (result.isEmpty) return null;

    final value = result.first['energy_kj'];
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    }
    return null;
  }
}