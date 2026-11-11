import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_state.dart';
import '../auth_repo.dart';
import '../export_download.dart';
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return ref
        .watch(managerAccessProvider)
        .when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, _) => Scaffold(
            appBar: AppBar(title: const Text('Kho hàng')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(errorMessage(error), textAlign: TextAlign.center),
                    TextButton(onPressed: () => ref.invalidate(managerAccessProvider), child: const Text('Thử lại')),
                    TextButton(
                      onPressed: () async {
                        try {
                          await logout();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage(e))));
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
  const _Catalog({super.key, required this.uid, required this.manager, required this.refreshRole});
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
  @override
  void initState() {
    super.initState();
    _uid = widget.uid;
    _allOwners = widget.manager;
    _refreshStream();
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
      _toast(product == null ? 'Đã thêm sản phẩm.' : 'Đã cập nhật sản phẩm.');
    }
  }

  Future<void> _delete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa sản phẩm?'),
        content: Text('“${product.name}” sẽ bị xóa khỏi kho hàng. Không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Giữ lại')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa sản phẩm'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await deleteProduct(product);
      if (mounted) _toast('Đã xóa sản phẩm.');
    } catch (e) {
      if (mounted) _toast(errorMessage(e));
    }
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final json = await exportProducts(uid: _uid, allOwners: _allOwners);
      if (!mounted) return;
      if (downloadJson(json, 'co_so_du_lieu_thuc_te.json')) {
        _toast('Đã tải JSON của toàn bộ phạm vi đang chọn.');
      } else {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xuất cơ sở dữ liệu'),
            content: SizedBox(width: 580, child: SingleChildScrollView(child: SelectableText(json))),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
              FilledButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: json));
                  if (context.mounted) Navigator.pop(context);
                  if (mounted) {
                    _toast('Đã sao chép JSON. Lưu thành file UTF-8 để nộp.');
                  }
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

  Future<void> _details(Product product) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(product.name),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: ProductImage(image: product.image, size: 240, fit: BoxFit.contain),
              ),
              const SizedBox(height: 24),
              Text(money(product.price), style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('Số lượng: ${product.quantity}'),
              const SizedBox(height: 16),
              const Text('Chủ sở hữu (UID)', style: TextStyle(color: muted)),
              SelectableText(product.ownerId),
              const SizedBox(height: 8),
              const Text('Mã sản phẩm', style: TextStyle(color: muted)),
              SelectableText(product.id),
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

  Widget _stat(String title, String value, IconData icon) => SizedBox(
    width: 235,
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(color: muted)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700), maxLines: 2),
        ],
      ),
    ),
  );
  Widget _stockLabel(int quantity) => Text(
    quantity == 0
        ? 'Hết hàng'
        : quantity <= 5
        ? 'Sắp hết · $quantity'
        : '$quantity trong kho',
    style: TextStyle(
      color: quantity == 0
          ? const Color(0xFFAB3333)
          : quantity <= 5
          ? const Color(0xFF856000)
          : teal,
      fontWeight: FontWeight.w600,
    ),
  );
  Widget _actions(Product product) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        tooltip: 'Xem chi tiết',
        onPressed: () => _details(product),
        icon: const Icon(Icons.open_in_new, size: 20),
      ),
      IconButton(
        tooltip: 'Sửa sản phẩm',
        onPressed: () => _edit(product),
        icon: const Icon(Icons.edit_outlined, size: 20),
      ),
      IconButton(
        tooltip: 'Xóa sản phẩm',
        onPressed: () => _delete(product),
        icon: const Icon(Icons.delete_outline, size: 20),
      ),
    ],
  );
  Widget _products(List<Product> products, bool wide) {
    if (wide) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: line),
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: const WidgetStatePropertyAll(canvas),
            dataRowMinHeight: 88,
            dataRowMaxHeight: 88,
            columnSpacing: 30,
            columns: [
              const DataColumn(label: Text('Sản phẩm')),
              const DataColumn(label: Text('Đơn giá'), numeric: true),
              const DataColumn(label: Text('Số lượng')),
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
                            ProductImage(image: p.image, size: 56),
                            const SizedBox(width: 14),
                            SizedBox(
                              width: 205,
                              child: Text(
                                p.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _details(p),
                      ),
                      DataCell(Text(money(p.price))),
                      DataCell(_stockLabel(p.quantity)),
                      if (_allOwners && !_groupOwners)
                        DataCell(
                          SizedBox(
                            width: 150,
                            child: Tooltip(
                              message: p.ownerId,
                              child: Text(p.ownerId, maxLines: 1, overflow: TextOverflow.ellipsis),
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
    return Column(
      children: products
          .map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: line),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => _details(p),
                      borderRadius: BorderRadius.circular(10),
                      child: Row(
                        children: [
                          ProductImage(image: p.image, size: 84),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                const SizedBox(height: 6),
                                Text(money(p.price)),
                                const SizedBox(height: 6),
                                _stockLabel(p.quantity),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_allOwners && !_groupOwners)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text('Chủ sở hữu: ${p.ownerId}', style: const TextStyle(color: muted, fontSize: 12)),
                      ),
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerRight, child: _actions(p)),
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
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _stat('Sản phẩm đang hiển thị', '${visible.length}', Icons.inventory_2_outlined),
            _stat('Tổng số lượng', '${visible.fold<int>(0, (total, p) => total + p.quantity)}', Icons.shelves),
            _stat(
              'Giá trị tồn kho',
              money(visible.fold<double>(0, (total, p) => total + p.price * p.quantity)),
              Icons.payments_outlined,
            ),
          ],
        ),
        const SizedBox(height: 28),
        TextField(
          controller: _searchController,
          onChanged: (text) => setState(() => _search = text),
          decoration: InputDecoration(
            hintText: 'Tìm tên, mã sản phẩm hoặc UID chủ sở hữu',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _search.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Xóa tìm kiếm',
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _search = '');
                    },
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String>(
                initialValue: _sort,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Sắp xếp'),
                items: const [
                  DropdownMenuItem(value: 'name', child: Text('Tên A–Z')),
                  DropdownMenuItem(value: 'price-up', child: Text('Giá tăng dần')),
                  DropdownMenuItem(value: 'price-down', child: Text('Giá giảm dần')),
                  DropdownMenuItem(value: 'quantity', child: Text('Số lượng tăng dần')),
                  DropdownMenuItem(value: 'owner', child: Text('Chủ sở hữu')),
                ],
                onChanged: (value) => setState(() => _sort = value!),
              ),
            ),
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                initialValue: _stock,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Tình trạng'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                  DropdownMenuItem(value: 'out', child: Text('Hết hàng')),
                  DropdownMenuItem(value: 'low', child: Text('Sắp hết (1–5)')),
                ],
                onChanged: (value) => setState(() => _stock = value!),
              ),
            ),
            if (_allOwners)
              SizedBox(
                width: 260,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('$_owner:${owners.join(',')}'),
                  initialValue: owners.contains(_owner) ? _owner : '',
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Chủ sở hữu (UID)'),
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
                  Switch(value: _groupOwners, onChanged: (value) => setState(() => _groupOwners = value)),
                  const Text('Nhóm theo chủ sở hữu'),
                ],
              ),
          ],
        ),
        const SizedBox(height: 24),
        if (visible.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 24),
            child: Column(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 52, color: teal),
                const SizedBox(height: 16),
                Text(
                  products.isEmpty ? 'Kho hàng đang trống' : 'Không tìm thấy sản phẩm',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  products.isEmpty
                      ? 'Thêm sản phẩm đầu tiên với hình ảnh, giá và số lượng.'
                      : 'Thử từ khóa khác hoặc thay đổi bộ lọc.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: muted),
                ),
                const SizedBox(height: 20),
                if (products.isEmpty)
                  FilledButton.icon(onPressed: _edit, icon: const Icon(Icons.add), label: const Text('Thêm sản phẩm')),
              ],
            ),
          )
        else if (_allOwners && _groupOwners)
          for (final entry in grouped.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 20, color: teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key == _uid ? 'Kho hàng của bạn' : 'Chủ sở hữu',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        SelectableText(entry.key, style: const TextStyle(fontSize: 12, color: muted)),
                      ],
                    ),
                  ),
                  Text('${entry.value.length} sản phẩm', style: const TextStyle(color: muted)),
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const ProductBrand(),
      actions: [
        IconButton(tooltip: 'Làm mới quyền truy cập', onPressed: widget.refreshRole, icon: const Icon(Icons.refresh)),
        IconButton(tooltip: 'Đăng xuất', onPressed: _signingOut ? null : _logout, icon: const Icon(Icons.logout)),
        const SizedBox(width: 12),
      ],
    ),
    body: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (MediaQuery.sizeOf(context).width >= 1180)
          Container(
            width: 230,
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Text('Không gian quản lý', style: TextStyle(color: muted)),
                const SizedBox(height: 16),
                if (widget.manager)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    selected: _allOwners,
                    leading: const Icon(Icons.dashboard_outlined),
                    title: const Text('Tất cả sản phẩm'),
                    onTap: () => _scope(true),
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  selected: !_allOwners,
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: const Text('Sản phẩm của tôi'),
                  onTap: () => _scope(false),
                ),
                const Spacer(),
                const Divider(),
                const SizedBox(height: 20),
                Text(
                  widget.manager ? 'Quản lý' : 'Người dùng',
                  style: const TextStyle(color: teal, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(auth.currentUser?.email ?? '', style: const TextStyle(color: muted)),
                const SizedBox(height: 12),
                const Text('UID của bạn', style: TextStyle(fontSize: 12, color: muted)),
                SelectableText(_uid, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: EdgeInsets.all(constraints.maxWidth >= 700 ? 32 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _allOwners ? 'Toàn bộ sản phẩm' : 'Sản phẩm của tôi',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _allOwners
                        ? 'Theo dõi và quản lý hàng hóa của mọi chủ sở hữu.'
                        : 'Quản lý hình ảnh, giá và số lượng hàng hóa của bạn.',
                    style: const TextStyle(color: muted, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.manager ? 'Quản lý' : 'Người dùng'}: ${auth.currentUser?.email ?? ''}',
                    style: const TextStyle(color: muted),
                  ),
                  const SizedBox(height: 8),
                  SelectableText('UID: $_uid', style: const TextStyle(fontSize: 12, color: muted)),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: _edit,
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm sản phẩm'),
                      ),
                      Tooltip(
                        message: 'Xuất toàn bộ phạm vi đã chọn, không áp dụng tìm kiếm hoặc bộ lọc.',
                        child: OutlinedButton.icon(
                          onPressed: _exporting ? null : _export,
                          icon: const Icon(Icons.file_download_outlined),
                          label: Text(_exporting ? 'Đang xuất…' : 'Xuất JSON'),
                        ),
                      ),
                    ],
                  ),
                  if (widget.manager) ...[
                    const SizedBox(height: 24),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: true, label: Text('Tất cả')),
                        ButtonSegment(value: false, label: Text('Của tôi')),
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
                              TextButton(
                                onPressed: () => setState(_refreshStream),
                                child: const Text('Tải lại sản phẩm'),
                              ),
                            ],
                          ),
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final products = snapshot.data!.docs.map(Product.fromDoc).toList();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (snapshot.data!.metadata.isFromCache)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: Text(
                                'Đang hiển thị dữ liệu đã lưu. Chờ kết nối để đồng bộ.',
                                style: TextStyle(color: muted),
                              ),
                            ),
                          _body(products, constraints.maxWidth >= 900),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
