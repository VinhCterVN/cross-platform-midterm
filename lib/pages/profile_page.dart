import 'package:flutter/material.dart';

import '../academic_theme.dart';
import '../user_repo.dart';
import 'avatar.dart';
import 'login_page.dart';
import 'user_form_page.dart';

/// Người dùng xem và cập nhật thông tin, hình ảnh của mình.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.id});
  final String id;

  Widget _detail(
    IconData icon,
    String label,
    String value, {
    bool hash = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: academicBrass, size: 21),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: academicSlate, fontSize: 12),
              ),
              const SizedBox(height: 8),
              SelectableText(
                value,
                style: TextStyle(
                  fontSize: hash ? 12 : 16,
                  fontFamily: hash ? 'monospace' : null,
                  height: 1.7,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Hồ sơ của tôi'),
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
    body: SafeArea(
      child: StreamBuilder(
        stream: users.doc(id).snapshots(),
        builder: (context, snap) {
          if (snap.hasError)
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(errorMessage(snap.error!)),
              ),
            );
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final data = snap.data!.data();
          if (data == null) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: AcademicPanel(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.badge_outlined,
                          size: 48,
                          color: academicBrass,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Bắt đầu từ hồ sơ của bạn',
                          style: academicHeading(28),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Thêm họ tên và ảnh đại diện để hoàn thiện thông tin. Xác nhận mật khẩu hiện tại để lưu hồ sơ.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: academicSlate),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
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
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          final hash = data['matkhau'] as String?;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: academicNavy,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.school_outlined,
                              color: Color(0xFFCFB48F),
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'KHÔNG GIAN CÁ NHÂN',
                                style: TextStyle(
                                  color: Colors.white70,
                                  letterSpacing: 1.5,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFCFB48F)),
                          ),
                          child: Avatar(data['hinhanh'], radius: 52),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          data['hoten'] ?? '',
                          textAlign: TextAlign.center,
                          style: academicHeading(32, color: academicIvory),
                        ),
                        const SizedBox(height: 10),
                        SelectableText(
                          data['email'] ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text('Thông tin hồ sơ', style: academicHeading(26)),
                  const SizedBox(height: 8),
                  const Text(
                    'Thông tin được cập nhật từ tài khoản của bạn.',
                    style: TextStyle(color: academicSlate, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  AcademicPanel(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 4,
                    ),
                    child: Column(
                      children: [
                        _detail(
                          Icons.person_outline,
                          'Họ và tên',
                          data['hoten'] ?? '',
                        ),
                        const Divider(),
                        _detail(
                          Icons.mail_outline,
                          'Địa chỉ email',
                          data['email'] ?? '',
                        ),
                        const Divider(),
                        _detail(
                          Icons.key_outlined,
                          'Mật khẩu băm',
                          hash == null || hash == passwordMarker
                              ? 'Chưa có hash — đăng nhập lại để cập nhật'
                              : hash,
                          hash: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => UserFormPage(id: id, data: data),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 19),
                    label: const Text('Cập nhật hồ sơ'),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bạn có thể thay đổi họ tên và ảnh đại diện. Email được giữ nguyên theo tài khoản đăng nhập.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: academicSlate),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}
