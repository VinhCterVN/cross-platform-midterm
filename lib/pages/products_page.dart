import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_state.dart';
import '../auth_repo.dart';
import '../export_download.dart';
import '../gemini_service.dart';
import '../product_repo.dart';
import '../product_theme.dart';
import 'product_form.dart';
import 'product_image.dart';

class ProductsPage extends ConsumerWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider).asData?.value;
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: academicGreen, strokeWidth: 2),
        ),
      );
    }
    return ref.watch(managerAccessProvider).when(
          loading: () => const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: academicGreen, strokeWidth: 2),
            ),
          ),
          error: (error, _) => Scaffold(
            appBar: AppBar(title: const Text('Kho hàng')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(errorMessage(error), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => ref.invalidate(managerAccessProvider),
                      child: const Text('Thử lại'),
                    ),
                    TextButton(
                      onPressed: () async {
                        try {
                          await logout();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(errorMessage(e))),
                            );
                          }
                        }
                      },
                      child: const Text('Đăng xuất'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          data: (manager) => _Catalog(
            key: ValueKey('${user.uid}:$manager'),
            uid: user.uid,
            manager: manager,
            refreshRole: () => ref.invalidate(managerAccessProvider),
          ),
        );
  }
}

class _Catalog extends StatefulWidget {
  const _Catalog({
    super.key,
    required this.uid,
    required this.manager,
    required this.refreshRole,
  });

  final String uid;
  final bool manager;
  final VoidCallback refreshRole;

  @override
  State<_Catalog> createState() => _CatalogState();
}

class _CatalogState extends State<_Catalog> {
  final _searchController = TextEditingController();
  late final String _uid;
  late bool _allOwners;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _stream;
  bool _groupOwners = true, _exporting = false, _signingOut = false;
  String _search = '', _sort = 'name', _stock = 'all';
  String? _owner;

  // Trạng thái AI Avatar & Huy hiệu học thuật
  String _avatarSvg = '';
  bool _generatingAvatar = false;
  String _academicDiscipline = 'Khoa học & Quản trị';

  @override
  void initState() {
    super.initState();
    _uid = widget.uid;
    _allOwners = widget.manager;
    _refreshStream();
    _initAvatar();
  }

  void _initAvatar() {
    final email = auth.currentUser?.email ?? _uid;
    _avatarSvg = GeminiService.generateLocalAcademicSvg(
      initials: GeminiService.generateAvatarSvg(email: email).toString().isEmpty ? 'K' : '',
      email: email,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshStream() => _stream = productQuery(uid: _uid, allOwners: _allOwners).snapshots();
  void _toast(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  void _scope(bool all) {
    if (_allOwners == all) return;
    setState(() {
      _allOwners = all;
      _owner = null;
      _refreshStream();
    });
  }

  Future<void> _logout() async {
    setState(() => _signingOut = true);
    try {
      await logout();
    } catch (e) {
      if (mounted) _toast(errorMessage(e));
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  Future<void> _edit([Product? product]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProductForm(product: product),
    );
    if (saved == true && mounted) {
      _toast(product == null ? 'Đã nhập sản phẩm vào kho.' : 'Đã cập nhật dữ liệu sản phẩm.');
    }
  }

  Future<void> _delete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: line),
        ),
        title: Text(
          'Xóa sản phẩm khỏi kho?',
          style: GoogleFonts.newsreader(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Mặt hàng “${product.name}” sẽ bị xóa vĩnh viễn khỏi danh mục lưu trữ. Thao tác này không thể hoàn tác.',
          style: GoogleFonts.inter(fontSize: 13.5, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Giữ lại'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: academicCrimson),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await deleteProduct(product);
      if (mounted) _toast('Đã xóa sản phẩm khỏi kho.');
    } catch (e) {
      if (mounted) _toast(errorMessage(e));
    }
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final json = await exportProducts(uid: _uid, allOwners: _allOwners);
      if (!mounted) return;
      if (downloadJson(json, 'co_so_du_lieu_kho_hang.json')) {
        _toast('Đã xuất JSON cơ sở dữ liệu kho hàng.');
      } else {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: line)),
            title: Text('Xuất Cơ Sở Dữ Liệu', style: GoogleFonts.newsreader(fontSize: 18, fontWeight: FontWeight.w700)),
            content: SizedBox(
              width: 580,
              child: SingleChildScrollView(
                child: SelectableText(
                  json,
                  style: GoogleFonts.jetBrainsMono(fontSize: 12),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
              FilledButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: json));
                  if (context.mounted) Navigator.pop(context);
                  if (mounted) _toast('Đã sao chép JSON vào bộ nhớ tạm.');
                },
                child: const Text('Sao chép JSON'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) _toast(errorMessage(e));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // 1. TÍNH NĂNG GEMINI AI: Tóm tắt & Đánh giá tồn kho học thuật
  Future<void> _showAiStockSummary(List<Product> products) async {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return FutureBuilder<String>(
              future: GeminiService.summarizeStock(products),
              builder: (context, snapshot) {
                final isLoading = snapshot.connectionState == ConnectionState.waiting;
                final report = snapshot.data ?? '';

                return AlertDialog(
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
                        child: const Icon(Icons.analytics_outlined, size: 22, color: academicGreen),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Báo Cáo Tồn Kho Học Thuật',
                              style: GoogleFonts.newsreader(fontSize: 19, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'PHÂN TÍCH CHUỖI CUNG ỨNG • GEMINI AI',
                              style: GoogleFonts.jetBrainsMono(fontSize: 9.5, letterSpacing: 1.2, color: muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  content: SizedBox(
                    width: 650,
                    child: isLoading
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(color: academicGreen, strokeWidth: 2.5),
                                const SizedBox(height: 20),
                                Text(
                                  'Gemini AI đang tổng hợp và phân tích dữ liệu kho...',
                                  style: GoogleFonts.inter(fontSize: 13.5, color: muted),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: canvas,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: line),
                              ),
                              child: SelectableText(
                                report,
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  height: 1.6,
                                  color: ink,
                                ),
                              ),
                            ),
                          ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Đóng'),
                    ),
                    if (!isLoading && report.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: report));
                          _toast('Đã sao chép báo cáo học thuật.');
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Sao chép báo cáo'),
                      ),
                    if (!isLoading)
                      FilledButton.icon(
                        onPressed: () => setDialogState(() {}),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Phân tích lại'),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // 2. TÍNH NĂNG GEMINI AI: Tạo huy hiệu & ảnh đại diện học thuật cá nhân hóa
  Future<void> _showAvatarDialog() async {
    final email = auth.currentUser?.email ?? _uid;
    final apiKeyController = TextEditingController(text: GeminiService.apiKey);

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
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
                    child: const Icon(Icons.military_tech_outlined, size: 22, color: academicGold),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Huy Hiệu Học Giả Cá Nhân',
                          style: GoogleFonts.newsreader(fontSize: 19, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'ACADEMIC EMBLEM • VECTOR SVG BY GEMINI',
                          style: GoogleFonts.jetBrainsMono(fontSize: 9.5, letterSpacing: 1.2, color: muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: canvas,
                            shape: BoxShape.circle,
                            border: Border.all(color: line, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _generatingAvatar
                                ? const Center(
                                    child: CircularProgressIndicator(color: academicGreen, strokeWidth: 2),
                                  )
                                : _avatarSvg.isNotEmpty
                                    ? SvgPicture.string(_avatarSvg, fit: BoxFit.contain)
                                    : const Icon(Icons.person, size: 80, color: muted),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        email,
                        style: GoogleFonts.newsreader(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      AcademicBadge(
                        label: widget.manager ? 'HỌC GIẢ QUẢN TRỊ' : 'NGHIÊN CỨU VIÊN KHO VẬT TƯ',
                        icon: Icons.school_outlined,
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        initialValue: _academicDiscipline,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Chuyên ngành học thuật của bạn'),
                        items: const [
                          DropdownMenuItem(value: 'Khoa học & Quản trị', child: Text('Khoa học & Quản trị')),
                          DropdownMenuItem(value: 'Logistics & Chuỗi cung ứng', child: Text('Logistics & Chuỗi cung ứng')),
                          DropdownMenuItem(value: 'Kinh tế & Tài chính', child: Text('Kinh tế & Tài chính')),
                          DropdownMenuItem(value: 'Công nghệ thông tin & Mật mã', child: Text('Công nghệ thông tin & Mật mã')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => _academicDiscipline = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _generatingAvatar
                              ? null
                              : () async {
                                  setDialogState(() => _generatingAvatar = true);
                                  setState(() => _generatingAvatar = true);
                                  try {
                                    final newSvg = await GeminiService.generateAvatarSvg(
                                      email: email,
                                      discipline: _academicDiscipline,
                                    );
                                    setState(() => _avatarSvg = newSvg);
                                    setDialogState(() => _avatarSvg = newSvg);
                                    _toast('Đã tạo huy hiệu học thuật mới với Gemini AI.');
                                  } catch (e) {
                                    _toast('Lỗi tạo huy hiệu: $e');
                                  } finally {
                                    setDialogState(() => _generatingAvatar = false);
                                    setState(() => _generatingAvatar = false);
                                  }
                                },
                          icon: const Icon(Icons.auto_awesome, size: 18),
                          label: Text(
                            _generatingAvatar ? 'Gemini đang phác thảo SVG…' : 'Tạo lại huy hiệu với Gemini AI',
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text(
                          'Cấu hình khóa Gemini API Key',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: muted),
                        ),
                        subtitle: Text(
                          GeminiService.hasApiKey ? 'Đang hoạt động (khóa hợp lệ)' : 'Chưa nhập khóa cá nhân',
                          style: TextStyle(
                            fontSize: 11,
                            color: GeminiService.hasApiKey ? academicGreen : academicCrimson,
                          ),
                        ),
                        children: [
                          const SizedBox(height: 8),
                          TextField(
                            controller: apiKeyController,
                            decoration: InputDecoration(
                              labelText: 'Gemini API Key',
                              hintText: 'AIzaSy...',
                              suffixIcon: IconButton(
                                tooltip: 'Lưu khóa API',
                                icon: const Icon(Icons.check, color: academicGreen),
                                onPressed: () {
                                  GeminiService.setRuntimeApiKey(apiKeyController.text);
                                  setDialogState(() {});
                                  _toast('Đã cập nhật Gemini API Key tạm thời.');
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Khóa mặc định được nạp từ GEMINI_API_KEY trong tệp .env (--dart-define-from-file=.env). Bạn cũng có thể dán khóa Google AI Studio vào đây.',
                            style: GoogleFonts.inter(fontSize: 11, color: muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Đóng'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _details(Product product) => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: line),
          ),
          title: Text(
            product.name,
            style: GoogleFonts.newsreader(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: canvas,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: line),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: ProductImage(image: product.image, size: 220, fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(money(product.price), style: GoogleFonts.newsreader(fontSize: 24, fontWeight: FontWeight.w800, color: academicGreen)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('Tồn kho:', style: GoogleFonts.inter(color: muted, fontSize: 13.5)),
                      const SizedBox(width: 8),
                      _stockBadge(product.quantity),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 14),
                  Text('CHỦ SỞ HỮU (UID)', style: GoogleFonts.jetBrainsMono(fontSize: 10, letterSpacing: 1, color: muted)),
                  const SizedBox(height: 4),
                  SelectableText(product.ownerId, style: GoogleFonts.jetBrainsMono(fontSize: 12.5)),
                  const SizedBox(height: 12),
                  Text('MÃ SẢN PHẨM (ID)', style: GoogleFonts.jetBrainsMono(fontSize: 10, letterSpacing: 1, color: muted)),
                  const SizedBox(height: 4),
                  SelectableText(product.id, style: GoogleFonts.jetBrainsMono(fontSize: 12.5)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _edit(product);
              },
              child: const Text('Sửa sản phẩm'),
            ),
          ],
        ),
      );

  List<Product> _filter(List<Product> products) {
    final query = _search.trim().toLowerCase();
    final ownerExists = products.any((product) => product.ownerId == _owner);
    final result = products
        .where(
          (p) =>
              (query.isEmpty || '${p.name} ${p.id} ${p.ownerId}'.toLowerCase().contains(query)) &&
              (_owner == null || !ownerExists || p.ownerId == _owner) &&
              (_stock == 'all' || (_stock == 'out' ? p.quantity == 0 : p.quantity > 0 && p.quantity <= 5)),
        )
        .toList();
    result.sort((a, b) {
      final comparison = switch (_sort) {
        'price-up' => a.price.compareTo(b.price),
        'price-down' => b.price.compareTo(a.price),
        'quantity' => a.quantity.compareTo(b.quantity),
        'owner' => a.ownerId.compareTo(b.ownerId),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return comparison != 0 ? comparison : '${a.ownerId}/${a.id}'.compareTo('${b.ownerId}/${b.id}');
    });
    return result;
  }

  Widget _stat(String title, String value, IconData icon, {bool isMobile = false}) {
    if (isMobile) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: line),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 13, color: academicGreen),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        color: muted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: GoogleFonts.newsreader(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      width: 230,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: line),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: sageWash,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 15, color: academicGreen),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: muted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.newsreader(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _stockBadge(int quantity) {
    if (quantity == 0) {
      return const AcademicBadge(
        label: 'Hết hàng',
        icon: Icons.cancel_outlined,
        backgroundColor: Color(0xFFFDE8E8),
        textColor: academicCrimson,
        borderColor: Color(0xFFF3C0C0),
      );
    }
    if (quantity <= 5) {
      return AcademicBadge(
        label: 'Sắp hết · $quantity',
        icon: Icons.warning_amber_outlined,
        backgroundColor: const Color(0xFFFEF3D6),
        textColor: academicAmber,
        borderColor: const Color(0xFFE8D49E),
      );
    }
    return AcademicBadge(
      label: '$quantity trong kho',
      icon: Icons.check_circle_outline,
      backgroundColor: sageWash,
      textColor: academicGreen,
      borderColor: line,
    );
  }

  Widget _actions(Product product, {bool compact = false}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Chi tiết sản phẩm',
            onPressed: () => _details(product),
            icon: Icon(Icons.visibility_outlined, size: compact ? 17 : 19, color: muted),
            padding: compact ? const EdgeInsets.all(4) : const EdgeInsets.all(8),
            constraints: compact ? const BoxConstraints() : const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          IconButton(
            tooltip: 'Chỉnh sửa',
            onPressed: () => _edit(product),
            icon: Icon(Icons.edit_outlined, size: compact ? 17 : 19, color: muted),
            padding: compact ? const EdgeInsets.all(4) : const EdgeInsets.all(8),
            constraints: compact ? const BoxConstraints() : const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          IconButton(
            tooltip: 'Xóa',
            onPressed: () => _delete(product),
            icon: Icon(Icons.delete_outline, size: compact ? 17 : 19, color: academicCrimson),
            padding: compact ? const EdgeInsets.all(4) : const EdgeInsets.all(8),
            constraints: compact ? const BoxConstraints() : const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ],
      );

  Widget _products(List<Product> products, bool wide) {
    if (wide) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: line),
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: const WidgetStatePropertyAll(Color(0xFFF4F7F4)),
            dataRowMinHeight: 84,
            dataRowMaxHeight: 84,
            columnSpacing: 28,
            columns: [
              const DataColumn(label: Text('Sản phẩm & Danh mục')),
              const DataColumn(label: Text('Đơn giá (VND)'), numeric: true),
              const DataColumn(label: Text('Tồn kho')),
              if (_allOwners && !_groupOwners) const DataColumn(label: Text('Chủ sở hữu')),
              const DataColumn(label: Text('Thao tác')),
            ],
            rows: products
                .map(
                  (p) => DataRow(
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: line),
                              ),
                              child: ProductImage(image: p.image, size: 54),
                            ),
                            const SizedBox(width: 14),
                            SizedBox(
                              width: 220,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    p.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13.5),
                                  ),
                                  Text(
                                    'ID: ${p.id}',
                                    style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: muted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _details(p),
                      ),
                      DataCell(
                        Text(
                          money(p.price),
                          style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w600, fontSize: 13.5),
                        ),
                      ),
                      DataCell(_stockBadge(p.quantity)),
                      if (_allOwners && !_groupOwners)
                        DataCell(
                          SizedBox(
                            width: 140,
                            child: Tooltip(
                              message: p.ownerId,
                              child: Text(
                                p.ownerId,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.jetBrainsMono(fontSize: 11, color: muted),
                              ),
                            ),
                          ),
                        ),
                      DataCell(_actions(p)),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      );
    }

    // Giao diện Mobile / Android App tinh gọn
    return Column(
      children: products
          .map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: line),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => _details(p),
                      borderRadius: BorderRadius.circular(6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: line),
                            ),
                            child: ProductImage(image: p.image, size: 52),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13.5),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  money(p.price),
                                  style: GoogleFonts.jetBrainsMono(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                    color: academicGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _stockBadge(p.quantity),
                        if (_allOwners && !_groupOwners) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              p.ownerId,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.jetBrainsMono(color: muted, fontSize: 10),
                            ),
                          ),
                        ] else
                          const Spacer(),
                        _actions(p, compact: true),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _body(List<Product> products, bool wide) {
    final visible = _filter(products);
    final owners = products.map((p) => p.ownerId).toSet().toList()..sort();
    final grouped = <String, List<Product>>{};
    for (final p in visible) {
      (grouped[p.ownerId] ??= []).add(p);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!wide)
          Row(
            children: [
              _stat('Sản phẩm', '${visible.length}', Icons.inventory_2_outlined, isMobile: true),
              const SizedBox(width: 6),
              _stat('Lưu kho', '${visible.fold<int>(0, (t, p) => t + p.quantity)}', Icons.shelves, isMobile: true),
              const SizedBox(width: 6),
              _stat(
                'Tổng giá trị',
                money(visible.fold<double>(0, (t, p) => t + p.price * p.quantity)),
                Icons.account_balance_wallet_outlined,
                isMobile: true,
              ),
            ],
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _stat('Sản phẩm hiển thị', '${visible.length}', Icons.inventory_2_outlined),
              _stat('Tổng số lượng lưu kho', '${visible.fold<int>(0, (total, p) => total + p.quantity)}', Icons.shelves),
              _stat(
                'Tổng giá trị tồn kho',
                money(visible.fold<double>(0, (total, p) => total + p.price * p.quantity)),
                Icons.account_balance_wallet_outlined,
              ),
            ],
          ),
        const SizedBox(height: 14),
        // Nút phân tích AI & công cụ học thuật
        Container(
          padding: EdgeInsets.symmetric(horizontal: wide ? 16 : 12, vertical: wide ? 12 : 8),
          decoration: BoxDecoration(
            color: sageWash,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: line),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: academicGold, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  wide
                      ? 'Trợ lý học thuật Gemini AI: Phân tích tồn kho & dự báo đứt gãy cung ứng'
                      : 'Phân tích tồn kho với Gemini AI',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: ink),
                ),
              ),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: academicGreen,
                  side: const BorderSide(color: line),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(0, 32),
                ),
                onPressed: () => _showAiStockSummary(products),
                child: Text('Xem báo cáo', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          onChanged: (text) => setState(() => _search = text),
          decoration: InputDecoration(
            hintText: 'Tìm kiếm sản phẩm, mã ID, UID...',
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            prefixIcon: const Icon(Icons.search, size: 18),
            suffixIcon: _search.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Xóa tìm kiếm',
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _search = '');
                    },
                    icon: const Icon(Icons.close, size: 16),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        if (!wide) ...[
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _sort,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Sắp xếp',
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'name', child: Text('Tên (A–Z)')),
                    DropdownMenuItem(value: 'price-up', child: Text('Giá tăng')),
                    DropdownMenuItem(value: 'price-down', child: Text('Giá giảm')),
                    DropdownMenuItem(value: 'quantity', child: Text('SL tăng')),
                    DropdownMenuItem(value: 'owner', child: Text('Chủ sở hữu')),
                  ],
                  onChanged: (value) => setState(() => _sort = value!),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _stock,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Trạng thái',
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                    DropdownMenuItem(value: 'out', child: Text('Hết hàng')),
                    DropdownMenuItem(value: 'low', child: Text('Sắp hết (≤5)')),
                  ],
                  onChanged: (value) => setState(() => _stock = value!),
                ),
              ),
            ],
          ),
          if (_allOwners) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: ValueKey('mobile_$_owner:${owners.join(',')}'),
              initialValue: owners.contains(_owner) ? _owner : '',
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Lọc chủ sở hữu (UID)',
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              items: [
                const DropdownMenuItem(value: '', child: Text('Tất cả chủ sở hữu')),
                for (final owner in owners)
                  DropdownMenuItem(
                    value: owner,
                    child: Text(owner, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (value) => setState(() => _owner = value == '' ? null : value),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Switch(
                  value: _groupOwners,
                  activeThumbColor: academicGreen,
                  onChanged: (value) => setState(() => _groupOwners = value),
                ),
                const SizedBox(width: 6),
                Text('Nhóm theo học giả/UID', style: GoogleFonts.inter(fontSize: 12, color: muted)),
              ],
            ),
          ],
        ] else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<String>(
                  initialValue: _sort,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Sắp xếp danh mục'),
                  items: const [
                    DropdownMenuItem(value: 'name', child: Text('Tên sản phẩm (A–Z)')),
                    DropdownMenuItem(value: 'price-up', child: Text('Giá: Thấp đến cao')),
                    DropdownMenuItem(value: 'price-down', child: Text('Giá: Cao đến thấp')),
                    DropdownMenuItem(value: 'quantity', child: Text('Số lượng tăng dần')),
                    DropdownMenuItem(value: 'owner', child: Text('Chủ sở hữu')),
                  ],
                  onChanged: (value) => setState(() => _sort = value!),
                ),
              ),
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<String>(
                  initialValue: _stock,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Trạng thái lưu kho'),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Tất cả trạng thái')),
                    DropdownMenuItem(value: 'out', child: Text('Hết hàng (0)')),
                    DropdownMenuItem(value: 'low', child: Text('Sắp hết (1–5)')),
                  ],
                  onChanged: (value) => setState(() => _stock = value!),
                ),
              ),
              if (_allOwners)
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('$_owner:${owners.join(',')}'),
                    initialValue: owners.contains(_owner) ? _owner : '',
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Lọc chủ sở hữu (UID)'),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Tất cả chủ sở hữu')),
                      for (final owner in owners)
                        DropdownMenuItem(
                          value: owner,
                          child: Text(owner, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (value) => setState(() => _owner = value == '' ? null : value),
                  ),
                ),
              if (_allOwners)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: _groupOwners,
                      activeThumbColor: academicGreen,
                      onChanged: (value) => setState(() => _groupOwners = value),
                    ),
                    const SizedBox(width: 6),
                    Text('Nhóm theo học giả/UID', style: GoogleFonts.inter(fontSize: 13, color: muted)),
                  ],
                ),
            ],
          ),
        const SizedBox(height: 16),
        if (visible.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: line),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(color: sageWash, shape: BoxShape.circle),
                  child: const Icon(Icons.inventory_2_outlined, size: 40, color: academicGreen),
                ),
                const SizedBox(height: 16),
                Text(
                  products.isEmpty ? 'Kho lưu trữ đang trống' : 'Không tìm thấy kết quả phù hợp',
                  style: GoogleFonts.newsreader(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  products.isEmpty
                      ? 'Bắt đầu lưu trữ bằng cách thêm sản phẩm mới vào danh mục của bạn.'
                      : 'Thử kiểm tra từ khóa hoặc thay đổi các tiêu chí bộ lọc.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: muted, fontSize: 13.5),
                ),
                const SizedBox(height: 20),
                if (products.isEmpty)
                  FilledButton.icon(
                    onPressed: _edit,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Thêm sản phẩm đầu tiên'),
                  ),
              ],
            ),
          )
        else if (_allOwners && _groupOwners)
          for (final entry in grouped.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_outlined, size: 18, color: academicGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key == _uid ? 'Kho hàng của bạn' : 'Chủ sở hữu lưu trữ',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        SelectableText(
                          entry.key,
                          style: GoogleFonts.jetBrainsMono(fontSize: 11.5, color: muted),
                        ),
                      ],
                    ),
                  ),
                  AcademicBadge(
                    label: '${entry.value.length} danh mục',
                    backgroundColor: sageWash,
                    textColor: academicGreen,
                  ),
                ],
              ),
            ),
            _products(entry.value, wide),
            const SizedBox(height: 24),
          ]
        else
          _products(visible, wide),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = auth.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const ProductBrand(showSubtitle: false),
        actions: [
          Tooltip(
            message: 'Phân tích tồn kho AI',
            child: IconButton(
              icon: const Icon(Icons.auto_awesome, color: academicGold),
              onPressed: () {
                _stream.first.then((snapshot) {
                  final list = snapshot.docs.map(Product.fromDoc).toList();
                  _showAiStockSummary(list);
                });
              },
            ),
          ),
          Tooltip(
            message: 'Làm mới quyền & dữ liệu',
            child: IconButton(
              onPressed: widget.refreshRole,
              icon: const Icon(Icons.refresh, size: 21),
            ),
          ),
          InkWell(
            onTap: _showAvatarDialog,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: line, width: 1.5),
                    ),
                    child: ClipOval(
                      child: _avatarSvg.isNotEmpty
                          ? SvgPicture.string(_avatarSvg)
                          : const Icon(Icons.person, size: 20, color: academicGreen),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Tooltip(
            message: 'Đăng xuất',
            child: IconButton(
              onPressed: _signingOut ? null : _logout,
              icon: const Icon(Icons.logout, size: 20),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sidebar học thuật (Web & Desktop)
          if (MediaQuery.sizeOf(context).width >= 1180)
            Container(
              width: 250,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: line, width: 1)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thẻ học giả cá nhân
                  InkWell(
                    onTap: _showAvatarDialog,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: canvas,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: line),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 44,
                            height: 44,
                            child: ClipOval(
                              child: _avatarSvg.isNotEmpty
                                  ? SvgPicture.string(_avatarSvg)
                                  : const Icon(Icons.person, color: academicGreen),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.manager ? 'Quản Lý Kho' : 'Học Giả',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: academicGreen,
                                  ),
                                ),
                                Text(
                                  userEmail.split('@').first,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(fontSize: 12, color: ink),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 16, color: muted),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'PHẠM VI TRUY XUẤT',
                    style: GoogleFonts.jetBrainsMono(fontSize: 10, letterSpacing: 1.2, color: muted),
                  ),
                  const SizedBox(height: 12),
                  if (widget.manager)
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      selected: _allOwners,
                      selectedTileColor: sageWash,
                      leading: const Icon(Icons.dashboard_outlined, size: 19),
                      title: Text(
                        'Toàn bộ sản phẩm',
                        style: GoogleFonts.inter(fontSize: 13.5, fontWeight: _allOwners ? FontWeight.w700 : FontWeight.w500),
                      ),
                      onTap: () => _scope(true),
                    ),
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    selected: !_allOwners,
                    selectedTileColor: sageWash,
                    leading: const Icon(Icons.inventory_2_outlined, size: 19),
                    title: Text(
                      'Sản phẩm của tôi',
                      style: GoogleFonts.inter(fontSize: 13.5, fontWeight: !_allOwners ? FontWeight.w700 : FontWeight.w500),
                    ),
                    onTap: () => _scope(false),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'CÔNG CỤ GEMINI AI',
                    style: GoogleFonts.jetBrainsMono(fontSize: 10, letterSpacing: 1.2, color: muted),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    leading: const Icon(Icons.auto_awesome, size: 18, color: academicGold),
                    title: Text('Huy hiệu & Avatar AI', style: GoogleFonts.inter(fontSize: 13)),
                    onTap: _showAvatarDialog,
                  ),
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    leading: const Icon(Icons.psychology_outlined, size: 18, color: academicGreen),
                    title: Text('Phân tích tồn kho', style: GoogleFonts.inter(fontSize: 13)),
                    onTap: () {
                      _stream.first.then((snapshot) {
                        final list = snapshot.docs.map(Product.fromDoc).toList();
                        _showAiStockSummary(list);
                      });
                    },
                  ),
                  const Spacer(),
                  const Divider(),
                  const SizedBox(height: 14),
                  Text('UID CỦA BẠN', style: GoogleFonts.jetBrainsMono(fontSize: 9.5, letterSpacing: 1, color: muted)),
                  const SizedBox(height: 4),
                  SelectableText(_uid, style: GoogleFonts.jetBrainsMono(fontSize: 11, color: muted)),
                ],
              ),
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 700;
                return SingleChildScrollView(
                  padding: EdgeInsets.all(isNarrow ? 12 : 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _allOwners ? 'Toàn bộ danh mục vật tư' : 'Kho vật tư của tôi',
                                  style: isNarrow
                                      ? GoogleFonts.newsreader(fontSize: 20, fontWeight: FontWeight.w700, color: ink)
                                      : Theme.of(context).textTheme.headlineLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _allOwners
                                      ? 'Giám sát và phân loại tài nguyên lưu kho của mọi chủ sở hữu.'
                                      : 'Quản lý thông tin, định giá và lượng hàng sẵn có của bạn.',
                                  style: GoogleFonts.inter(color: muted, fontSize: isNarrow ? 12 : 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: _edit,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Thêm sản phẩm'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _exporting ? null : _export,
                            icon: const Icon(Icons.file_download_outlined, size: 16),
                            label: Text(_exporting ? 'Đang xuất…' : 'Xuất JSON'),
                          ),
                        ],
                      ),
                      if (widget.manager) ...[
                        const SizedBox(height: 16),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: true, label: Text('Tất cả chủ sở hữu')),
                            ButtonSegment(value: false, label: Text('Kho của tôi')),
                          ],
                          selected: {_allOwners},
                        onSelectionChanged: (value) => _scope(value.first),
                      ),
                    ],
                    const SizedBox(height: 24),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _stream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Text(errorMessage(snapshot.error!)),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () => setState(_refreshStream),
                                  child: const Text('Tải lại sản phẩm'),
                                ),
                              ],
                            ),
                          );
                        }
                        if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(color: academicGreen, strokeWidth: 2),
                            ),
                          );
                        }
                        final products = snapshot.data!.docs.map(Product.fromDoc).toList();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (snapshot.data!.metadata.isFromCache)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Text(
                                  'Đang hiển thị bản ghi đã lưu bộ đệm. Đang chờ kết nối máy chủ...',
                                  style: GoogleFonts.inter(color: muted, fontSize: 12.5),
                                ),
                              ),
                            _body(products, constraints.maxWidth >= 900),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
  }
}
