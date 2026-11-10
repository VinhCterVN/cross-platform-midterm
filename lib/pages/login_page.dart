import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
        // Web: quản lý hồ sơ; Android: trang cá nhân của người dùng.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _form,
              child: Column(
                children: [
                  Text(
                    kIsWeb ? 'Quản lý hồ sơ người dùng' : 'Đăng nhập',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: validateEmail,
                  ),
                  TextFormField(
                    controller: _pass,
                    decoration: const InputDecoration(labelText: 'Mật khẩu'),
                    obscureText: true,
                    validator: validatePassword,
                    onFieldSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _login,
                      child: Text(_loading ? 'Đang đăng nhập...' : 'Đăng nhập'),
                    ),
                  ),
                  if (!kIsWeb)
                    TextButton(
                      onPressed: _loading ? null : _register,
                      child: const Text('Chưa có tài khoản? Đăng ký'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
