import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../auth_repo.dart';
import '../product_repo.dart';
import '../product_theme.dart';
import 'product_image.dart';

class ProductForm extends StatefulWidget {
  const ProductForm({super.key, this.product});
  final Product? product;
  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _price, _quantity;
  late String _image;
  bool _busy = false, _picking = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _price = TextEditingController(text: p?.price.toString() ?? '');
    _quantity = TextEditingController(text: p?.quantity.toString() ?? '');
    _image = p?.image ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _quantity.dispose();
    super.dispose();
  }

  double? get _parsedPrice => double.tryParse(_price.text.trim().replaceAll(',', '.'));
  Future<void> _pick(ImageSource source) async {
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final file = await ImagePicker().pickImage(source: source, maxWidth: 960, maxHeight: 960, imageQuality: 75);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final message = validateImage(bytes);
      if (message != null) throw FormatException(message);
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 64);
      try {
        final frame = await codec.getNextFrame();
        frame.image.dispose();
      } finally {
        codec.dispose();
      }
      if (mounted) setState(() => _image = base64Encode(bytes));
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is FormatException
              ? error.message
              : 'Không đọc được ảnh. Chọn ảnh PNG/JPEG khác hoặc cấp quyền thư viện/camera.',
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    if (_busy || _picking || !_form.currentState!.validate()) return;
    if (_image.isEmpty) {
      setState(() => _error = 'Vui lòng đính kèm hình ảnh đại diện sản phẩm.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await saveProduct(
        original: widget.product,
        name: _name.text,
        price: _parsedPrice!,
        quantity: int.parse(_quantity.text.trim()),
        image: _image,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy && !_picking,
    child: Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: line, width: 1),
      ),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: sageWash,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: line),
                      ),
                      child: Icon(
                        widget.product == null ? Icons.post_add_outlined : Icons.edit_note_outlined,
                        size: 20,
                        color: academicGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product == null ? 'Ghi Danh Sản Phẩm' : 'Hiệu Đính Dữ Liệu',
                            style: GoogleFonts.newsreader(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'TIÊU CHUẨN LƯU TRỮ VẬT TƯ',
                            style: GoogleFonts.jetBrainsMono(fontSize: 9, letterSpacing: 1, color: muted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Đóng',
                      onPressed: _busy || _picking ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.product == null
                      ? 'Lập thẻ danh mục mới để quản lý định mức tồn kho và định giá tài sản.'
                      : 'Cập nhật lại các thông số lưu kho, định giá và hình ảnh thực tế.',
                  style: GoogleFonts.inter(color: muted, fontSize: 12.5),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: canvas,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: line),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: ProductImage(image: _image, size: 120, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _busy || _picking ? null : () => _pick(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined, size: 16),
                        label: Text(_picking ? 'Đang đọc…' : 'Chọn ảnh tư liệu'),
                      ),
                      if (!kIsWeb)
                        OutlinedButton.icon(
                          onPressed: _busy || _picking ? null : () => _pick(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined, size: 16),
                          label: const Text('Chụp ảnh'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Định dạng PNG / JPEG, tối đa 200 KiB',
                    style: GoogleFonts.jetBrainsMono(color: muted, fontSize: 10.5),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  enabled: !_busy,
                  maxLength: 120,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Tên định danh sản phẩm'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập tên sản phẩm' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _price,
                  enabled: !_busy,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Đơn giá định mức (VNĐ)',
                    helperText: 'Ví dụ: 150000; không dùng dấu chấm phân tách.',
                  ),
                  validator: (_) =>
                      _parsedPrice == null ||
                          !_parsedPrice!.isFinite ||
                          _parsedPrice! < 0 ||
                          _parsedPrice! > 1000000000000
                      ? 'Giá trị phải trong khoảng 0 đến 1.000.000.000.000 VNĐ'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _quantity,
                  enabled: !_busy,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Số lượng vật tư tồn kho'),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    return n == null || n < 0 || n > 1000000000 ? 'Nhập số nguyên hợp lệ (0 đến 1.000.000.000)' : null;
                  },
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(_error!, style: GoogleFonts.inter(color: academicCrimson, fontSize: 12.5)),
                  ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _busy || _picking ? null : _save,
                    icon: _busy
                        ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check, size: 18),
                    label: Text(_busy ? 'Đang cập nhật…' : 'Lưu sản phẩm'),
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
