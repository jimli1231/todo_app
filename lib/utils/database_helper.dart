import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'todo_app.db');
      debugPrint('Initializing database at path: $path');

      // 如果数据库存在，先删除它（仅用于开发阶段）
      await deleteDatabase(path);

      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
        onOpen: (db) async {
          debugPrint('Database opened successfully');
          // 验证表是否创建成功
          var tables = await db.query('sqlite_master', columns: ['name']);
          debugPrint(
              'Created tables: ${tables.map((e) => e['name']).toList()}');
        },
      );
    } catch (e) {
      debugPrint('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      debugPrint('Creating database tables...');

      // 创建用户表
      await db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT UNIQUE,
          password TEXT,
          email TEXT
        )
      ''');
      debugPrint('Users table created successfully');

      // 创建待办事项表
      await db.execute('''
        CREATE TABLE todos(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          completed INTEGER,
          user_id INTEGER,
          created_at TEXT,
          FOREIGN KEY (user_id) REFERENCES users (id)
        )
      ''');
      debugPrint('Todos table created successfully');
    } catch (e) {
      debugPrint('Error creating tables: $e');
      rethrow;
    }
  }

  // 用户相关操作
  Future<int> insertUser(Map<String, dynamic> user) async {
    try {
      Database db = await database;
      debugPrint('Inserting user: ${user['username']}');
      return await db.insert('users', user);
    } catch (e) {
      debugPrint('Error inserting user: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUser(
      String username, String password) async {
    try {
      Database db = await database;
      debugPrint('Querying user: $username');
      List<Map<String, dynamic>> results = await db.query(
        'users',
        where: 'username = ? AND password = ?',
        whereArgs: [username, password],
      );
      debugPrint('Query results: ${results.length} users found');
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      debugPrint('Error getting user: $e');
      rethrow;
    }
  }

  // 待办事项相关操作
  Future<int> insertTodo(Map<String, dynamic> todo) async {
    try {
      Database db = await database;
      return await db.insert('todos', todo);
    } catch (e) {
      debugPrint('Error inserting todo: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTodos(int userId) async {
    try {
      Database db = await database;
      return await db.query(
        'todos',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
    } catch (e) {
      debugPrint('Error getting todos: $e');
      rethrow;
    }
  }

  Future<int> updateTodo(Map<String, dynamic> todo) async {
    try {
      Database db = await database;
      return await db.update(
        'todos',
        todo,
        where: 'id = ?',
        whereArgs: [todo['id']],
      );
    } catch (e) {
      debugPrint('Error updating todo: $e');
      rethrow;
    }
  }

  Future<int> deleteTodo(int id) async {
    try {
      Database db = await database;
      return await db.delete(
        'todos',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error deleting todo: $e');
      rethrow;
    }
  }

  // 获取统计信息
  Future<Map<String, dynamic>> getTodoStats(int userId) async {
    try {
      Database db = await database;
      var results = await Future.wait([
        db.rawQuery(
          'SELECT COUNT(*) as count FROM todos WHERE user_id = ? AND completed = 1',
          [userId],
        ),
        db.rawQuery(
          'SELECT COUNT(*) as count FROM todos WHERE user_id = ? AND completed = 0',
          [userId],
        ),
      ]);

      return {
        'completed': results[0].first['count'] as int,
        'pending': results[1].first['count'] as int,
      };
    } catch (e) {
      debugPrint('Error getting todo stats: $e');
      rethrow;
    }
  }
}
