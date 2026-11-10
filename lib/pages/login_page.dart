import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../academic_theme.dart';
import '../user_repo.dart';
import 'admin_page.dart';
import 'profile_page.dart';
import 'user_form_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _open(String id) async {
    if (kIsWeb && !await isAdmin()) {
      await logout();
      if (mounted) _toast('Web chỉ dành cho quản trị viên');
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => kIsWeb ? AdminPage(currentId: id) : ProfilePage(id: id),
      ),
    );
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _login() async {
    if (_loading || !_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final id = await login(_email.text, _pass.text);
      if (!mounted) return;
      if (id != null) await _open(id);
    } catch (e) {
      if (mounted) _toast(errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    final id = await Navigator.of(context)
        .push<String>(MaterialPageRoute(builder: (_) => const UserFormPage()));
    if (id != null && mounted) _open(id);
  }

  Widget _formPanel() => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CỔNG THÔNG TIN',
            style: TextStyle(
              color: academicBrass,
              letterSpacing: 2,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Text('Chào mừng\ntrở lại.', style: academicHeading(44)),
          const SizedBox(height: 14),
          Text(
            kIsWeb
                ? 'Đăng nhập để quản lý và kết nối những hồ sơ trong cộng đồng học đường.'
                : 'Không gian của bạn. Hồ sơ của bạn.\nĐăng nhập để xem và cập nhật thông tin.',
            style: const TextStyle(color: academicSlate, height: 1.7),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _email,
            enabled: !_loading,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Địa chỉ email',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: validateEmail,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _pass,
            enabled: !_loading,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: _showPassword ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
                onPressed: _loading
                    ? null
                    : () => setState(() => _showPassword = !_showPassword),
                icon: Icon(
                  _showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
            obscureText: !_showPassword,
            validator: validatePassword,
            onFieldSubmitted: (_) => _login(),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _loading ? null : _login,
              icon: _loading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward, size: 18),
              label: Text(_loading ? 'Đang đăng nhập…' : 'Đăng nhập'),
            ),
          ),
          const SizedBox(height: 20),
          if (!kIsWeb)
            Center(
              child: TextButton(
                onPressed: _loading ? null : _register,
                child: const Text('Chưa có tài khoản? Đăng ký'),
              ),
            )
          else
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 17,
                  color: academicSlate,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Phiên bản web dành cho quản trị viên.',
                    style: TextStyle(fontSize: 12, color: academicSlate),
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: wide
                  ? IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Container(
                              color: academicNavy,
                              padding: const EdgeInsets.all(56),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const AcademicBrand(light: true),
                                  const SizedBox(height: 90),
                                  const Icon(
                                    Icons.account_balance_outlined,
                                    size: 110,
                                    color: Color(0xFFBEA17A),
                                  ),
                                  const SizedBox(height: 36),
                                  Text(
                                    'Mỗi hồ sơ,\nmột kết nối.',
                                    style: academicHeading(
                                      52,
                                      color: academicIvory,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    'Một không gian gọn gàng để lưu giữ thông tin,\nnuôi dưỡng sự kết nối trong cộng đồng.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      height: 1.8,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 72),
                                  const Divider(color: Colors.white24),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'THÔNG TIN RÕ RÀNG. KẾT NỐI DỄ DÀNG.',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 10,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 6,
                            child: Padding(
                              padding: const EdgeInsets.all(56),
                              child: Center(child: _formPanel()),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AcademicBrand(),
                          const SizedBox(height: 48),
                          Center(child: _formPanel()),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),
          );
        },
      ),
    ),
  );
}
