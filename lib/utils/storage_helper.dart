import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class StorageHelper {
  static const String _userKey = 'user';
  static const String _todosKey = 'todos';
  static final StorageHelper _instance = StorageHelper._internal();

  factory StorageHelper() => _instance;

  StorageHelper._internal();

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // 用户相关操作
  Future<Map<String, dynamic>?> getUser(
      String username, String password) async {
    final prefs = await _prefs;
    final userJson = prefs.getString(_userKey);
    debugPrint('Stored users: $userJson');

    if (userJson == null) return null;

    final users =
        List<Map<String, dynamic>>.from(jsonDecode(userJson) as List<dynamic>);
    debugPrint('Parsed users: $users');
    debugPrint('Looking for user: $username with password: $password');

    final user = users.firstWhere(
      (user) => user['username'] == username && user['password'] == password,
      orElse: () => {},
    );

    debugPrint('Found user: $user');
    return user.isNotEmpty ? user : null;
  }

  Future<bool> insertUser(Map<String, dynamic> user) async {
    final prefs = await _prefs;
    final userJson = prefs.getString(_userKey);
    List<Map<String, dynamic>> users = [];

    if (userJson != null) {
      users = List<Map<String, dynamic>>.from(
          jsonDecode(userJson) as List<dynamic>);
      // 检查用户名是否已存在
      if (users.any((u) => u['username'] == user['username'])) {
        return false;
      }
    }

    user['id'] = DateTime.now().millisecondsSinceEpoch;
    users.add(user);

    final success = await prefs.setString(_userKey, jsonEncode(users));
    debugPrint('User registration ${success ? 'successful' : 'failed'}: $user');
    debugPrint('All users after registration: ${jsonEncode(users)}');
    return success;
  }

  Future<bool> updateUser(Map<String, dynamic> user) async {
    final prefs = await _prefs;
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return false;

    List<Map<String, dynamic>> users =
        List<Map<String, dynamic>>.from(jsonDecode(userJson) as List<dynamic>);

    final index = users.indexWhere((u) => u['id'] == user['id']);
    if (index == -1) return false;

    users[index] = user;
    final success = await prefs.setString(_userKey, jsonEncode(users));
    debugPrint('User update ${success ? 'successful' : 'failed'}: $user');
    return success;
  }

  // 待办事项相关操作
  Future<List<Map<String, dynamic>>> getTodos(int userId) async {
    final prefs = await _prefs;
    final todosJson = prefs.getString('${_todosKey}_$userId');
    if (todosJson == null) return [];

    return List<Map<String, dynamic>>.from(
        jsonDecode(todosJson) as List<dynamic>);
  }

  Future<bool> insertTodo(Map<String, dynamic> todo) async {
    final prefs = await _prefs;
    final userId = todo['user_id'] as int;
    final todosJson = prefs.getString('${_todosKey}_$userId');
    List<Map<String, dynamic>> todos = [];

    if (todosJson != null) {
      todos = List<Map<String, dynamic>>.from(
          jsonDecode(todosJson) as List<dynamic>);
    }

    todo['id'] = DateTime.now().millisecondsSinceEpoch;
    todos.add(todo);

    return prefs.setString('${_todosKey}_$userId', jsonEncode(todos));
  }

  Future<bool> updateTodo(Map<String, dynamic> todo) async {
    final prefs = await _prefs;
    final userId = todo['user_id'] as int;
    final todosJson = prefs.getString('${_todosKey}_$userId');
    if (todosJson == null) return false;

    List<Map<String, dynamic>> todos =
        List<Map<String, dynamic>>.from(jsonDecode(todosJson) as List<dynamic>);

    final index = todos.indexWhere((t) => t['id'] == todo['id']);
    if (index == -1) return false;

    todos[index] = todo;
    return prefs.setString('${_todosKey}_$userId', jsonEncode(todos));
  }

  Future<bool> deleteTodo(int userId, int todoId) async {
    final prefs = await _prefs;
    final todosJson = prefs.getString('${_todosKey}_$userId');
    if (todosJson == null) return false;

    List<Map<String, dynamic>> todos =
        List<Map<String, dynamic>>.from(jsonDecode(todosJson) as List<dynamic>);

    todos.removeWhere((todo) => todo['id'] == todoId);
    return prefs.setString('${_todosKey}_$userId', jsonEncode(todos));
  }

  // 统计信息
  Future<Map<String, dynamic>> getTodoStats(int userId) async {
    final todos = await getTodos(userId);
    final completed = todos.where((todo) => todo['completed'] == 1).length;
    final pending = todos.where((todo) => todo['completed'] == 0).length;

    return {
      'completed': completed,
      'pending': pending,
    };
  }
}
