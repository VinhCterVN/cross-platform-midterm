import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
      // Đọc thực tế ảnh, không chỉ kiểm tra đuôi file hoặc MIME do người dùng cung cấp.
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
      setState(() => _error = 'Chọn ảnh sản phẩm trước khi lưu.');
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
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.product == null ? 'Thêm sản phẩm' : 'Sửa sản phẩm',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Đóng',
                      onPressed: _busy || _picking ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.product == null
                      ? 'Sản phẩm mới được lưu vào kho hàng của bạn.'
                      : 'Cập nhật thông tin và hình ảnh sản phẩm.',
                  style: const TextStyle(color: muted),
                ),
                const SizedBox(height: 24),
                Center(
                  child: ProductImage(image: _image, size: 180, fit: BoxFit.contain),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _busy || _picking ? null : () => _pick(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(_picking ? 'Đang đọc ảnh…' : 'Chọn ảnh'),
                      ),
                      if (!kIsWeb)
                        OutlinedButton.icon(
                          onPressed: _busy || _picking ? null : () => _pick(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Chụp ảnh'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text('PNG / JPEG, tối đa 200 KiB', style: TextStyle(color: muted, fontSize: 12)),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _name,
                  enabled: !_busy,
                  maxLength: 120,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Tên sản phẩm'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Nhập tên sản phẩm' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _price,
                  enabled: !_busy,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Giá sản phẩm (VNĐ)',
                    helperText: 'Ví dụ: 125000 hoặc 125000,50; không dùng dấu phân cách hàng nghìn.',
                  ),
                  validator: (_) =>
                      _parsedPrice == null ||
                          !_parsedPrice!.isFinite ||
                          _parsedPrice! < 0 ||
                          _parsedPrice! > 1000000000000
                      ? 'Giá từ 0 đến 1.000.000.000.000 VNĐ'
                      : null,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _quantity,
                  enabled: !_busy,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Số lượng'),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    return n == null || n < 0 || n > 1000000000 ? 'Nhập số nguyên từ 0 đến 1.000.000.000' : null;
                  },
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _busy || _picking ? null : _save,
                    icon: _busy
                        ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check),
                    label: Text(_busy ? 'Đang lưu…' : 'Lưu sản phẩm'),
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
