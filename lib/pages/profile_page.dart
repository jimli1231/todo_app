import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/user_provider.dart';
import '../utils/storage_helper.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _storage = StorageHelper();

  Future<void> _updateAvatar() async {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.user;
    if (user == null) return;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('更新头像'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: '输入头像文本（如：JL）',
            border: OutlineInputBorder(),
          ),
          maxLength: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(
                context,
                (context.findAncestorWidgetOfExactType<TextField>()
                        as TextField)
                    .controller
                    ?.text),
            child: const Text('更新'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final success = await _storage.updateUser({
        ...user,
        'avatar': result,
      });

      if (success) {
        if (!mounted) return;
        userProvider.setUser({
          ...user,
          'avatar': result,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('头像更新成功')),
        );
      }
    }
  }

  void _logout() {
    context.read<UserProvider>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _updateAvatar,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      user['avatar'] as String? ??
                          user['username']?.substring(0, 1).toUpperCase() ??
                          '用户',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['username'] ?? '',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '用户ID: ${user['id']}',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('设置'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 导航到设置页面
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('历史记录'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 导航到历史记录页面
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('帮助与反馈'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 导航到帮助页面
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('退出登录'),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
