import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../academic_theme.dart';
import '../user_repo.dart';
import 'avatar.dart';
import 'login_page.dart';
import 'user_form_page.dart';

/// Nền tảng Web: quản lý hồ sơ từ luồng dữ liệu Firestore.
class AdminPage extends StatefulWidget {
  const AdminPage({super.key, required this.currentId});
  final String currentId;

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  String _query = '';
  bool _exporting = false;

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
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final json = await exportUsersJson();
      await Clipboard.setData(ClipboardData(text: json));
      if (mounted)
        _toast(
          'Đã sao chép JSON. Dữ liệu có hash mật khẩu — chỉ lưu và chia sẻ ở nơi an toàn.',
        );
    } catch (e) {
      if (mounted) _toast(errorMessage(e));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Widget _sidebar() => Container(
    width: 252,
    color: academicNavy,
    child: ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      children: [
        const AcademicBrand(light: true),
        const SizedBox(height: 52),
        const Text(
          'KHÔNG GIAN QUẢN TRỊ',
          style: TextStyle(
            color: Colors.white60,
            letterSpacing: 1.5,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white24),
          ),
          child: const Row(
            children: [
              Icon(Icons.people_outline, color: Color(0xFFCFB48F), size: 21),
              SizedBox(width: 12),
              Text(
                'Danh bạ hồ sơ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 64),
        const Divider(color: Colors.white24),
        const SizedBox(height: 20),
        const Text(
          'Thông tin cá nhân cần được\nquản lý và chia sẻ có trách nhiệm.',
          style: TextStyle(color: Colors.white60, height: 1.7, fontSize: 12),
        ),
        const SizedBox(height: 20),
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: academicIvory),
          onPressed: _logout,
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Đăng xuất'),
        ),
      ],
    ),
  );

  Widget _profileCard(String id, Map<String, dynamic> data) {
    final own = id == widget.currentId;
    final hash = data['matkhau'] as String?;
    return AcademicPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Avatar(data['hinhanh'], radius: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['hoten'] ?? '', style: academicHeading(23)),
                    const SizedBox(height: 4),
                    SelectableText(
                      data['email'] ?? '',
                      style: const TextStyle(
                        color: academicSlate,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (own) ...[
            const SizedBox(height: 14),
            const Text(
              'TÀI KHOẢN CỦA BẠN',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1,
                color: academicBrass,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 22),
          const Divider(),
          const SizedBox(height: 18),
          const Row(
            children: [
              Icon(Icons.key_outlined, size: 16, color: academicSlate),
              SizedBox(width: 7),
              Text(
                'Mật khẩu băm',
                style: TextStyle(
                  color: academicSlate,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            hash == null || hash == passwordMarker
                ? 'Chưa có hash — đăng nhập lại để cập nhật'
                : hash,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              height: 1.7,
              color: academicNavy,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _openForm(id, data),
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: const Text('Chỉnh sửa'),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: own ? null : () => _delete(id, data['email']),
                icon: const Icon(Icons.delete_outline, size: 17),
                label: const Text('Xóa hồ sơ'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, viewport) {
      final desktop = viewport.maxWidth >= 1100;
      return Scaffold(
        appBar: desktop
            ? null
            : AppBar(
                title: const Text('Danh bạ hồ sơ'),
                actions: [
                  IconButton(
                    tooltip: 'Đăng xuất',
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                  ),
                ],
              ),
        body: SafeArea(
          child: Row(
            children: [
              if (desktop) _sidebar(),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, area) {
                    final padding = area.maxWidth >= 700 ? 40.0 : 20.0;
                    return ListView(
                      padding: EdgeInsets.all(padding),
                      children: [
                        const Text(
                          'QUẢN LÝ CỘNG ĐỒNG',
                          style: TextStyle(
                            color: academicBrass,
                            letterSpacing: 1.8,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Danh bạ hồ sơ',
                          style: academicHeading(desktop ? 42 : 34),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Lưu giữ thông tin. Kết nối từng thành viên.',
                          style: TextStyle(color: academicSlate, fontSize: 15),
                        ),
                        const SizedBox(height: 26),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            FilledButton.icon(
                              onPressed: _openForm,
                              icon: const Icon(Icons.add, size: 19),
                              label: const Text('Thêm người dùng'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _exporting ? null : _exportJson,
                              icon: const Icon(
                                Icons.file_download_outlined,
                                size: 19,
                              ),
                              label: Text(
                                _exporting ? 'Đang xuất…' : 'Xuất JSON',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        TextField(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            labelText: 'Tìm theo họ tên hoặc email',
                          ),
                          onChanged: (v) =>
                              setState(() => _query = v.trim().toLowerCase()),
                        ),
                        const SizedBox(height: 24),
                        StreamBuilder(
                          stream: users.snapshots(),
                          builder: (context, snap) {
                            if (snap.hasError)
                              return AcademicPanel(
                                child: Text(errorMessage(snap.error!)),
                              );
                            if (!snap.hasData)
                              return const Padding(
                                padding: EdgeInsets.all(48),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            final docs = snap.data!.docs
                                .where(
                                  (d) =>
                                      '${d.data()['hoten']} ${d.data()['email']}'
                                          .toLowerCase()
                                          .contains(_query),
                                )
                                .toList();
                            final available = area.maxWidth - padding * 2;
                            final columns = available >= 1000
                                ? 3
                                : available >= 640
                                ? 2
                                : 1;
                            final cardWidth =
                                (available - (columns - 1) * 18) / columns;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${docs.length} hồ sơ${_query.isEmpty ? '' : ' phù hợp'}  /  ${snap.data!.docs.length} tổng cộng',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: academicSlate,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                if (docs.isEmpty)
                                  AcademicPanel(
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: Column(
                                        children: [
                                          const Icon(
                                            Icons.person_search_outlined,
                                            color: academicBrass,
                                            size: 38,
                                          ),
                                          const SizedBox(height: 14),
                                          Text(
                                            'Chưa tìm thấy hồ sơ',
                                            style: academicHeading(24),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Thử từ khóa khác hoặc thêm một người dùng mới.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: academicSlate,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  Wrap(
                                    spacing: 18,
                                    runSpacing: 18,
                                    children: [
                                      for (final d in docs)
                                        SizedBox(
                                          width: cardWidth,
                                          child: _profileCard(d.id, d.data()),
                                        ),
                                    ],
                                  ),
                                const SizedBox(height: 28),
                                const Text(
                                  'Lưu ý: JSON chứa thông tin cá nhân và hash mật khẩu. Không chia sẻ công khai.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: academicSlate,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
