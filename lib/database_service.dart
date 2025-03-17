import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:string_similarity/string_similarity.dart';

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

    // Check if database exists
    if (!await databaseExists(path)) {
      // Copy from assets
      final dir = await getApplicationDocumentsDirectory();
      await Directory(dir.path).create(recursive: true);

      final asset = await rootBundle.load("assets/databases/food.db");
      final bytes = asset.buffer.asUint8List();

      await File(path).writeAsBytes(bytes);
    }

    return await openDatabase(path);
  }

  Future<List<Map<String, dynamic>>> searchSimilarFoods(String query) async {
    final db = await database;
    final allFoods = await db.query('foods');

    return allFoods.map((food) {
      final similarity = StringSimilarity.compareTwoStrings(
          query.toLowerCase(),
          (food['foodname'] as String).toLowerCase()
      );
      return {...food, 'similarity': similarity};
    }).toList()
      ..sort((a, b) => (b['similarity'] as double).compareTo(a['similarity'] as double));
  }

  Future<double?> getEnergyValues(int foodId) async {
    final db = await database;
    final result = await db.query(
      'energy',
      where: 'foodid = ?',
      whereArgs: [foodId],
    );
    return result.isNotEmpty ? result.first['energy_kj'] as double? : null;
  }
}