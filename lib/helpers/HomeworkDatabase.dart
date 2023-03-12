/*class HomeworkDatabase {
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
    final String path = join(dbPath, 'homework.db');

    return await openDatabase(path, version: 1, onCreate: _createDb);
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE lessons(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        time TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE homework(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lesson_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        due_date TEXT NOT NULL,
        FOREIGN KEY (lesson_id) REFERENCES lessons(id)
      )
    ''');
  }

  Future<Homework> create(Homework homework) async {
    final db = await instance.database;
    final id = await db.insert('homework', homework.toMap());
    return homework.copy(id: id);
  }

  Future<List<Homework>> readAll() async {
    final db = await instance.database;
    final orderBy = 'due_date ASC';
    final result = await db.query('homework', orderBy: orderBy);
    return result.map(Homework.fromMap).toList();
  }

  Future<void> update(Homework homework) async {
    final db = await instance.database;
    await db.update('homework', homework.toMap(),
        where: 'id = ?', whereArgs: [homework.id]);
  }

  Future<void> delete(int id) async {
    final db = await instance.database;
    await db.delete('homework', where: 'id = ?', whereArgs: [id]);
  }
}
*/