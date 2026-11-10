import 'package:flutter/material.dart';

import '../user_repo.dart';
import 'avatar.dart';
import 'login_page.dart';
import 'user_form_page.dart';

/// Nền tảng Android: người dùng xem và cập nhật thông tin, hình ảnh của mình.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: () async {
              await logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: users.doc(id).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text(errorMessage(snap.error!)));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!.data();
          if (data == null) {
            return Center(
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => UserFormPage(
                      id: id,
                      data: {
                        'email': auth.currentUser?.email ?? '',
                        'hoten': '',
                        'hinhanh': '',
                      },
                    ),
                  ),
                ),
                child: const Text('Hoàn thiện hồ sơ'),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(child: Avatar(data['hinhanh'], radius: 64)),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.badge),
                title: const Text('Họ tên'),
                subtitle: Text(data['hoten']),
              ),
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email'),
                subtitle: Text(data['email']),
              ),
              const ListTile(
                leading: Icon(Icons.lock),
                title: Text('Mật khẩu'),
                subtitle: Text('••••••••'),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => UserFormPage(id: id, data: data),
                  ),
                ),
                icon: const Icon(Icons.edit),
                label: const Text('Cập nhật thông tin / hình ảnh'),
              ),
            ],
          );
        },
      ),
    );
  }
}
