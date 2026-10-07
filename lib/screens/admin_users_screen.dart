import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/auth_api.dart';
import '../core/api_exceptions.dart';
import '../models/app_user.dart';
import '../state/auth_notifier.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<AppUser>? _users;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthNotifier>();
    try {
      final api = AuthApi();
      final token = auth.accessToken;
      if (token == null) throw const UnauthorizedException();
      final users = await api.listUsers(token);
      setState(() => _users = users);
    } catch (e) {
      setState(() => _error = describeError(e is ApiException ? e : e));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Пользователи'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView.separated(
                  itemCount: _users!.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final u = _users![index];
                    return ListTile(
                      leading: CircleAvatar(child: Text(u.username[0].toUpperCase())),
                      title: Text(u.displayName),
                      subtitle: Text('@${u.username}'),
                      trailing: Chip(label: Text(u.role.label)),
                    );
                  },
                ),
    );
  }
}
