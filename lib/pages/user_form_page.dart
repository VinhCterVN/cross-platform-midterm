import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../academic_theme.dart';
import '../user_repo.dart';
import 'avatar.dart';

/// Form thêm / sửa người dùng. Truyền [id] + [data] để sửa; pop về id đã lưu.
class UserFormPage extends StatefulWidget {
  const UserFormPage({super.key, this.id, this.data});

  final String? id;
  final Map<String, dynamic>? data;

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.data?['email']);
  late final _hoten = TextEditingController(text: widget.data?['hoten']);
  final _pass = TextEditingController();
  late String _hinhanh = widget.data?['hinhanh'] ?? '';
  bool _saving = false;
  bool _picking = false;

  bool get _isEdit => widget.id != null;
  bool get _needsPassword => !_isEdit || widget.data?['matkhau'] == null;
  bool get _busy => _saving || _picking;

  @override
  void dispose() {
    _email.dispose();
    _hoten.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _pick(ImageSource source) async {
    if (_picking || _saving) return;
    setState(() => _picking = true);
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 70,
      );
      if (file == null) return;
      if (await file.length() > maxPhotoBytes) {
        if (mounted) _toast('Ảnh phải có dung lượng không quá 200 KiB');
        return;
      }
      final bytes = await file.readAsBytes();
      final error = validatePhotoBytes(bytes);
      if (error != null) {
        if (mounted) _toast(error);
        return;
      }
      final codec = await ui.instantiateImageCodec(bytes);
      codec.dispose();
      if (mounted) setState(() => _hinhanh = base64Encode(bytes));
    } catch (_) {
      if (mounted) _toast('Không thể đọc ảnh. Hãy chọn ảnh PNG/JPEG khác');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    if (_saving || _picking || !_form.currentState!.validate()) return;
    if (_hinhanh.isEmpty) return _toast('Vui lòng chọn hình ảnh');
    setState(() => _saving = true);
    try {
      final id = await saveUser(
        id: widget.id,
        email: _email.text,
        hoten: _hoten.text,
        hinhanh: _hinhanh,
        password: _needsPassword ? _pass.text : null,
      );
      if (mounted) Navigator.of(context).pop(id);
    } catch (e) {
      if (mounted) _toast(errorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = !_isEdit
        ? 'Tạo hồ sơ mới'
        : _needsPassword
        ? 'Hoàn thiện hồ sơ'
        : 'Chỉnh sửa hồ sơ';
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'THÔNG TIN THÀNH VIÊN',
                        style: TextStyle(
                          color: academicBrass,
                          letterSpacing: 1.5,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(title, style: academicHeading(34)),
                      const SizedBox(height: 12),
                      Text(
                        _isEdit
                            ? 'Giữ thông tin của bạn luôn đầy đủ và dễ nhận diện.'
                            : 'Bắt đầu với thông tin cơ bản và một ảnh đại diện.',
                        style: const TextStyle(color: academicSlate),
                      ),
                      const SizedBox(height: 28),
                      AcademicPanel(
                        child: SizedBox(
                          width: double.infinity,
                          child: Column(
                            children: [
                              const Text(
                                '01  /  ẢNH ĐẠI DIỆN',
                                style: TextStyle(
                                  color: academicSlate,
                                  letterSpacing: 1.2,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 22),
                              Avatar(_hinhanh, radius: 52),
                              const SizedBox(height: 18),
                              Text(
                                _picking
                                    ? 'Đang xử lý ảnh…'
                                    : _hinhanh.isEmpty
                                    ? 'Chọn ảnh đại diện của bạn'
                                    : 'Ảnh đại diện đã được chọn',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'PNG hoặc JPEG · Không quá 200 KiB',
                                style: TextStyle(
                                  color: academicSlate,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 12,
                                runSpacing: 10,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _busy
                                        ? null
                                        : () => _pick(ImageSource.gallery),
                                    icon: const Icon(
                                      Icons.photo_library_outlined,
                                      size: 19,
                                    ),
                                    label: const Text('Chọn từ thư viện'),
                                  ),
                                  if (!kIsWeb)
                                    OutlinedButton.icon(
                                      onPressed: _busy
                                          ? null
                                          : () => _pick(ImageSource.camera),
                                      icon: const Icon(
                                        Icons.photo_camera_outlined,
                                        size: 19,
                                      ),
                                      label: const Text('Chụp ảnh'),
                                    ),
                                ],
                              ),
                              if (_picking) ...[
                                const SizedBox(height: 18),
                                const LinearProgressIndicator(),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      AcademicPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '02  /  THÔNG TIN CƠ BẢN',
                              style: TextStyle(
                                color: academicSlate,
                                letterSpacing: 1.2,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 26),
                            TextFormField(
                              controller: _hoten,
                              enabled: !_busy,
                              decoration: const InputDecoration(
                                labelText: 'Họ và tên',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              validator: validateName,
                            ),
                            const SizedBox(height: 22),
                            TextFormField(
                              controller: _email,
                              enabled: !_busy,
                              readOnly: _isEdit,
                              decoration: InputDecoration(
                                labelText: 'Địa chỉ email',
                                prefixIcon: const Icon(Icons.mail_outline),
                                suffixIcon: _isEdit
                                    ? const Icon(Icons.lock_outline, size: 18)
                                    : null,
                              ),
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: _needsPassword
                                  ? TextInputAction.next
                                  : TextInputAction.done,
                              validator: validateEmail,
                            ),
                            if (_isEdit) ...[
                              const SizedBox(height: 10),
                              const Text(
                                'Email được liên kết với tài khoản và không thể chỉnh sửa tại đây.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: academicSlate,
                                ),
                              ),
                            ],
                            if (_needsPassword) ...[
                              const SizedBox(height: 22),
                              TextFormField(
                                controller: _pass,
                                enabled: !_busy,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: _isEdit
                                      ? 'Xác nhận mật khẩu hiện tại'
                                      : 'Mật khẩu',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                ),
                                validator: validatePassword,
                                onFieldSubmitted: (_) => _save(),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _isEdit
                                    ? 'Xác nhận tài khoản để hoàn thiện và lưu hồ sơ.'
                                    : 'Mật khẩu được bảo vệ bằng cơ chế băm, không lưu dạng rõ.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: academicSlate,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _busy ? null : _save,
                          icon: _saving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check, size: 19),
                          label: Text(
                            _saving ? 'Đang lưu hồ sơ…' : 'Lưu hồ sơ',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: _busy
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Hủy và quay lại'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
