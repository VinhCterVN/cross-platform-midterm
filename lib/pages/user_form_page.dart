import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
        password: _pass.text,
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Sửa người dùng' : 'Thêm người dùng'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _form,
              child: Column(
                children: [
                  Avatar(_hinhanh, radius: 56),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: () => _pick(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Chọn ảnh'),
                      ),
                      if (!kIsWeb)
                        TextButton.icon(
                          onPressed: () => _pick(ImageSource.camera),
                          icon: const Icon(Icons.photo_camera),
                          label: const Text('Chụp ảnh'),
                        ),
                    ],
                  ),
                  TextFormField(
                    controller: _hoten,
                    decoration: const InputDecoration(labelText: 'Họ tên'),
                    validator: validateName,
                  ),
                  TextFormField(
                    controller: _email,
                    readOnly: _isEdit,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: validateEmail,
                  ),
                  if (!_isEdit)
                    TextFormField(
                      controller: _pass,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Mật khẩu'),
                      validator: validatePassword,
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Đang lưu...' : 'Lưu'),
                    ),
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
