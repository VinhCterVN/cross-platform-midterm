import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../auth_repo.dart';
import '../gemini_service.dart';
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
  final _repeatPassword = TextEditingController();
  bool _busy = false, _showPassword = false, _aiGeneratingPassword = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _repeatPassword.dispose();
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

  Future<void> _suggestAiPassword() async {
    setState(() => _aiGeneratingPassword = true);
    try {
      final suggestion = await GeminiService.suggestStrongPassword(
        userEmail: _email.text.trim(),
      );
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: line, width: 1),
          ),
          backgroundColor: Colors.white,
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: sageWash,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: line),
                ),
                child: const Icon(Icons.shield_outlined, size: 20, color: academicGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gợi Ý Mật Khẩu An Toàn',
                      style: GoogleFonts.newsreader(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'TIÊU CHUẨN MẬT MÃ HỌC THUẬT',
                      style: GoogleFonts.jetBrainsMono(fontSize: 9, letterSpacing: 1.2, color: muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: canvas,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: line),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          suggestion.password,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: academicGreen,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Sao chép',
                        icon: const Icon(Icons.copy, size: 18, color: muted),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: suggestion.password));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã sao chép mật khẩu vào bộ nhớ tạm.')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AcademicBadge(
                      label: suggestion.strength,
                      icon: Icons.verified_user_outlined,
                      backgroundColor: sageWash,
                      textColor: academicGreen,
                    ),
                    AcademicBadge(
                      label: suggestion.entropy,
                      icon: Icons.data_usage_outlined,
                      backgroundColor: const Color(0xFFF2F5F2),
                      textColor: muted,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  suggestion.explanation,
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: muted),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton.icon(
              onPressed: () {
                _password.text = suggestion.password;
                if (widget.registering) {
                  _repeatPassword.text = suggestion.password;
                }
                setState(() => _showPassword = true);
                Navigator.of(ctx).pop();
                _toast('Đã áp dụng mật khẩu mạnh vào biểu mẫu.');
              },
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Áp dụng mật khẩu'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) _toast('Lỗi tạo mật khẩu: $e');
    } finally {
      if (mounted) setState(() => _aiGeneratingPassword = false);
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: sageWash,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: line),
              ),
              child: Text(
                widget.registering ? 'KHỞI TẠO TÀI KHOẢN' : 'XÁC THỰC DANH TÍNH',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: academicGreen,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.registering ? 'Bắt đầu không gian kho học thuật' : 'Quản lý vật tư chuẩn xác & tinh giản',
              style: GoogleFonts.newsreader(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: ink,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.registering
                  ? 'Tạo tài khoản học giả để quản lý danh mục và xuất nhập tồn.'
                  : 'Đăng nhập hệ thống để quản lý danh mục và phân tích kho vật tư.',
              style: GoogleFonts.inter(color: muted, fontSize: 13, height: 1.45),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _email,
              enabled: !_busy,
              validator: validateEmail,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Địa chỉ Email',
                prefixIcon: Icon(Icons.alternate_email, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              enabled: !_busy,
              obscureText: !_showPassword,
              validator: validatePassword,
              autofillHints: [widget.registering ? AutofillHints.newPassword : AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  tooltip: _showPassword ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                  icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                ),
              ),
            ),
            if (widget.registering) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _repeatPassword,
                enabled: !_busy,
                obscureText: !_showPassword,
                decoration: const InputDecoration(
                  labelText: 'Nhập lại mật khẩu',
                  prefixIcon: Icon(Icons.lock_reset, size: 20),
                ),
                validator: (value) => value != _password.text ? 'Mật khẩu nhập lại chưa khớp' : null,
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _busy || _aiGeneratingPassword ? null : _suggestAiPassword,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: Colors.white,
                ),
                icon: _aiGeneratingPassword
                    ? const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome, size: 15, color: academicGold),
                label: Text(
                  _aiGeneratingPassword ? 'Gemini đang tạo…' : 'Gợi ý mật khẩu mạnh (Gemini AI)',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: ink),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _submit,
                icon: _busy
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(widget.registering ? Icons.person_add_outlined : Icons.login, size: 20),
                label: Text(
                  _busy
                      ? 'Đang xác thực…'
                      : widget.registering
                      ? 'Tạo tài khoản'
                      : 'Đăng nhập vào hệ thống',
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: _busy ? null : () => context.go(widget.registering ? '/login' : '/register'),
                child: Text(
                  widget.registering ? 'Đã có tài khoản? Đăng nhập' : 'Chưa có tài khoản? Khởi tạo ngay',
                ),
              ),
            ),
            if (!widget.registering)
              Center(
                child: TextButton(
                  onPressed: _busy ? null : _resetPassword,
                  child: const Text('Quên mật khẩu? Đặt lại qua email'),
                ),
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
            padding: EdgeInsets.all(wide ? 56 : 18),
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
                              color: academicGreen,
                              padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 64),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const ProductBrand(light: true),
                                  const SizedBox(height: 60),
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white24, width: 0.8),
                                    ),
                                    child: const Icon(Icons.account_balance, size: 64, color: Color(0xFFC8E6D3)),
                                  ),
                                  const SizedBox(height: 36),
                                  Text(
                                    'Lưu trữ vật tư.\nChuẩn mực học thuật.',
                                    style: GoogleFonts.newsreader(
                                      color: Colors.white,
                                      fontSize: 42,
                                      height: 1.18,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Định danh chính xác. Quản lý minh bạch.\nKiểm soát danh mục và cảnh báo tồn kho thời gian thực với trợ lý AI.',
                                    style: GoogleFonts.inter(color: const Color(0xFFD3E7D9), height: 1.7, fontSize: 15),
                                  ),
                                  const SizedBox(height: 32),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      AcademicBadge(
                                        label: 'GEMINI AI INSIGHTS',
                                        icon: Icons.auto_awesome,
                                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                                        textColor: Colors.white,
                                        borderColor: Colors.white24,
                                      ),
                                      AcademicBadge(
                                        label: 'ACADEMIC MINIMALISM',
                                        icon: Icons.border_all,
                                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                                        textColor: Colors.white,
                                        borderColor: Colors.white24,
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  const Divider(color: Colors.white24),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Hệ thống quản lý sản phẩm trên Web & Android',
                                    style: GoogleFonts.jetBrainsMono(fontSize: 11, color: Colors.white60),
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
                        const Padding(
                          padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
                          child: ProductBrand(),
                        ),
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
