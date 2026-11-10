import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../user_repo.dart';
import 'avatar.dart';
import 'login_page.dart';
import 'user_form_page.dart';

/// Nền tảng Web: quản lý hồ sơ người dùng
/// (thêm, hiển thị, sửa, xóa, tìm kiếm, xuất JSON).
class AdminPage extends StatefulWidget {
  const AdminPage({super.key, required this.currentId});

  final String currentId;

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  String _query = '';

  void _toast(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _logout() async {
    await logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  void _openForm([String? id, Map<String, dynamic>? data]) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => UserFormPage(id: id, data: data),
        ),
      );

  Future<void> _delete(String id, String email) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Xóa hồ sơ'),
        content: Text(
          'Xóa hồ sơ $email? Tài khoản Authentication vẫn còn và có thể đăng nhập, tạo lại hồ sơ. Muốn khóa/xóa tài khoản, dùng Firebase Console.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await deleteUser(id);
      if (mounted) _toast('Đã xóa hồ sơ; tài khoản Auth vẫn còn');
    } catch (e) {
      if (mounted) _toast(errorMessage(e));
    }
  }

  Future<void> _exportJson() async {
    try {
      final json = await exportUsersJson();
      await Clipboard.setData(ClipboardData(text: json));
      if (mounted) _toast('Đã sao chép JSON. Dán vào file .json để nộp');
    } catch (e) {
      if (mounted) _toast(errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý hồ sơ người dùng'),
        actions: [
          IconButton(
            tooltip: 'Xuất JSON',
            onPressed: _exportJson,
            icon: const Icon(Icons.download),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('Thêm người dùng'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Tìm theo họ tên hoặc email',
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder(
                stream: users.snapshots(),
                builder: (context, snap) {
                  if (snap.hasError) return Text(errorMessage(snap.error!));
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snap.data!.docs
                      .where(
                        (d) => '${d['hoten']} ${d['email']}'
                            .toLowerCase()
                            .contains(_query),
                      )
                      .toList();
                  if (docs.isEmpty) {
                    return const Center(child: Text('Không có người dùng'));
                  }
                  return SingleChildScrollView(
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Hình ảnh')),
                          DataColumn(label: Text('Họ tên')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Mật khẩu')),
                          DataColumn(label: Text('Thao tác')),
                        ],
                        rows: [
                          for (final d in docs)
                            DataRow(
                              cells: [
                                DataCell(Avatar(d['hinhanh'], radius: 20)),
                                DataCell(Text(d['hoten'])),
                                DataCell(Text(d['email'])),
                                DataCell(
                                  Tooltip(
                                    message: passwordMarker,
                                    child: const Text('••••••••'),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        tooltip: 'Sửa',
                                        icon: const Icon(Icons.edit),
                                        onPressed: () =>
                                            _openForm(d.id, d.data()),
                                      ),
                                      IconButton(
                                        tooltip: 'Xóa hồ sơ',
                                        icon: const Icon(Icons.delete),
                                        onPressed: d.id == widget.currentId
                                            ? null
                                            : () => _delete(d.id, d['email']),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
