import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:tugas_akhir_tpm_123210060/Model/User.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('liga1.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';

    await db.execute('''
    CREATE TABLE users ( 
      id $idType, 
      username $textType,
      password $textType,
      id_favorite_team $textType,
      favorite_team $textType,
      favorite_team_logo $textType
    )
    ''');
  }

  Future<void> create(User user) async {
    final db = await instance.database;
    await db.insert('users', user.toMap());
  }

  Future<User?> readUserByUsername(String username) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      columns: ['id', 'username', 'password', 'id_favorite_team', 'favorite_team', 'favorite_team_logo'],
      where: 'username = ?',
      whereArgs: [username],
    );

    if (maps.isNotEmpty) {
      return User(
        id: maps.first['id'] as int?,
        username: maps.first['username'] as String,
        password: maps.first['password'] as String,
        id_favorite_team: maps.first['id_favorite_team'] as String,
        favorite_team: maps.first['favorite_team'] as String,
        favorite_team_logo: maps.first['favorite_team_logo'] as String,
      );
    } else {
      return null;
    }
  }

  Future<void> update(User user) async {
    final db = await instance.database;
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}