import 'package:notely/models/homework.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class HomeworkDatabase {
  static final HomeworkDatabase instance = HomeworkDatabase._init();

  static Database? _database;

  HomeworkDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final String dbPath = await getDatabasesPath();
    final String path = join(dbPath, 'notely.db');

    return await openDatabase(path,
        version: 2, onCreate: _createDb, onUpgrade: onUpgrade);
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE homework(
        id TEXT NOT NULL PRIMARY KEY,
        lesson_name TEXT NOT NULL,
        title TEXT NOT NULL,
        details TEXT NOT NULL,
        due_date TEXT NOT NULL,
        is_done INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion == 1) {}
  }

  Future<Homework> create(Homework homework) async {
    final db = await instance.database;
    final id = await db.insert('homework', homework.toMap());
    return homework.copyWith(id: id.toString());
  }

  Future<List<Homework>> readAll() async {
    final db = await instance.database;
    final orderBy = 'due_date ASC';
    final result = await db.query('homework', orderBy: orderBy);
    return result.map((map) => Homework.fromMap(map)).toList();
  }

  Future<Homework> readHomework(String id) async {
    final db = await instance.database;
    final result = await db.query('homework', where: 'id = ?', whereArgs: [id]);
    return Homework.fromMap(result.first);
  }

  Future<void> update(Homework homework) async {
    final db = await instance.database;
    await db.update('homework', homework.toMap(),
        where: 'id = ?', whereArgs: [homework.id]);
  }

  Future<void> delete(String id) async {
    final db = await instance.database;
    await db.delete('homework', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAll() async {
    final db = await instance.database;
    await db.delete('homework');
  }
}
