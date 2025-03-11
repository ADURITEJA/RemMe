import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'memories.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE memories(id INTEGER PRIMARY KEY, imagePath TEXT, transcribedText TEXT, createdAt TEXT)",
        );
      },
    );
  }

  Future<void> insertMemory(Map<String, dynamic> memory) async {
    final db = await database;
    await db.insert('memories', memory);
  }

  Future<List<Map<String, dynamic>>> getMemories() async {
    final db = await database;
    return await db.query('memories', orderBy: "id DESC");
  }
}
