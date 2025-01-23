import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/user_provider.dart';
import '../utils/storage_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final StorageHelper _storage = StorageHelper();
  List<Map<String, dynamic>> _todos = [];

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isLoggedIn) {
      return;
    }

    final userId = userProvider.user?['id'];
    if (userId == null) return;

    try {
      final todos = await _storage.getTodos(userId);
      if (mounted) {
        setState(() {
          _todos = todos;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('加载失败，请重试')),
        );
      }
    }
  }

  Future<void> _addTodo() async {
    final userId =
        Provider.of<UserProvider>(context, listen: false).user?['id'];
    if (userId == null) return;

    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加待办事项'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '标题',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('添加'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await _storage.insertTodo({
          'title': result,
          'completed': 0,
          'user_id': userId,
          'created_at': DateTime.now().toIso8601String(),
        });
        _loadTodos(); // 重新加载待办事项列表
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('添加失败，请重试')),
        );
      }
    }
  }

  Future<void> _toggleTodo(Map<String, dynamic> todo) async {
    try {
      await _storage.updateTodo({
        ...todo,
        'completed': todo['completed'] == 1 ? 0 : 1,
      });
      _loadTodos(); // 重新加载待办事项列表
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('更新失败，请重试')),
      );
    }
  }

  Future<void> _deleteTodo(int id) async {
    final userId =
        Provider.of<UserProvider>(context, listen: false).user?['id'];
    if (userId == null) return;

    try {
      await _storage.deleteTodo(userId, id);
      _loadTodos(); // 重新加载待办事项列表
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('删除失败，请重试')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('待办事项'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTodos,
          ),
        ],
      ),
      body: _todos.isEmpty
          ? const Center(
              child: Text('暂无待办事项'),
            )
          : ListView.builder(
              itemCount: _todos.length,
              itemBuilder: (context, index) {
                final todo = _todos[index];
                return ListTile(
                  leading: Checkbox(
                    value: todo['completed'] == 1,
                    onChanged: (bool? value) {
                      _toggleTodo(todo);
                    },
                  ),
                  title: Text(
                    todo['title'],
                    style: TextStyle(
                      decoration: todo['completed'] == 1
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  subtitle: Text(
                    '创建于：${DateTime.parse(todo['created_at']).toLocal().toString().split('.')[0]}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteTodo(todo['id']),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTodo,
        child: const Icon(Icons.add),
      ),
    );
  }
}
