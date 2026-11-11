import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth_repo.dart';
import '../product_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.registering = false});
  final bool registering;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false, _showPassword = false;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _toast(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      if (widget.registering) {
        await register(_email.text, _password.text);
      } else {
        await login(_email.text, _password.text);
      }
    } catch (error) {
      if (mounted) _toast(errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    if (validateEmail(_email.text) != null) {
      _toast('Nhập email của bạn trước khi đặt lại mật khẩu.');
      return;
    }
    setState(() => _busy = true);
    try {
      await auth.sendPasswordResetEmail(email: _email.text.trim());
      if (mounted) {
        _toast('Nếu email đã đăng ký, bạn sẽ nhận được liên kết đặt lại mật khẩu.');
      }
    } catch (error) {
      if (mounted) _toast(errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _formPanel() => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 420),
    child: Form(
      key: _form,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.registering ? 'Bắt đầu kho hàng\ncủa bạn.' : 'Mọi sản phẩm.\nTrong tầm tay.',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 16),
            Text(
              widget.registering
                  ? 'Tạo tài khoản để thêm và quản lý sản phẩm trên mọi thiết bị.'
                  : 'Đăng nhập để quản lý sản phẩm, hình ảnh và số lượng trong kho.',
              style: const TextStyle(color: muted, fontSize: 16, height: 1.6),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _email,
              enabled: !_busy,
              validator: validateEmail,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _password,
              enabled: !_busy,
              obscureText: !_showPassword,
              validator: validatePassword,
              autofillHints: [widget.registering ? AutofillHints.newPassword : AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _showPassword ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                  icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                ),
              ),
            ),
            if (widget.registering) ...[
              const SizedBox(height: 18),
              TextFormField(
                enabled: !_busy,
                obscureText: !_showPassword,
                decoration: const InputDecoration(labelText: 'Nhập lại mật khẩu', prefixIcon: Icon(Icons.lock_reset)),
                validator: (value) => value != _password.text ? 'Mật khẩu nhập lại chưa khớp' : null,
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _submit,
                icon: _busy
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(widget.registering ? Icons.person_add_outlined : Icons.login),
                label: Text(
                  _busy
                      ? 'Đang xử lý…'
                      : widget.registering
                      ? 'Tạo tài khoản'
                      : 'Đăng nhập',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _busy ? null : () => context.go(widget.registering ? '/login' : '/register'),
                child: Text(widget.registering ? 'Đã có tài khoản? Đăng nhập' : 'Chưa có tài khoản? Đăng ký'),
              ),
            ),
            if (!widget.registering)
              Center(
                child: TextButton(onPressed: _busy ? null : _resetPassword, child: const Text('Quên mật khẩu?')),
              ),
          ],
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 960;
          final form = Padding(
            padding: EdgeInsets.all(wide ? 56 : 24),
            child: Center(child: _formPanel()),
          );
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: wide
                  ? IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              color: ink,
                              padding: const EdgeInsets.all(48),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const ProductBrand(light: true),
                                  const SizedBox(height: 80),
                                  const Icon(Icons.shelves, size: 120, color: Color(0xFF72D6C3)),
                                  const SizedBox(height: 36),
                                  const Text(
                                    'Một nơi cho\ntất cả hàng hóa.',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 46,
                                      height: 1.15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    'Ảnh rõ ràng. Giá minh bạch.\nLuôn nắm được số lượng trong kho.',
                                    style: TextStyle(color: Color(0xFFC0DAD7), height: 1.8, fontSize: 17),
                                  ),
                                  const SizedBox(height: 64),
                                  const Divider(color: Colors.white24),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Quản lý sản phẩm trên Web & Android',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(child: form),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(padding: EdgeInsets.fromLTRB(24, 24, 24, 8), child: ProductBrand()),
                        form,
                      ],
                    ),
            ),
          );
        },
      ),
    ),
  );
}
