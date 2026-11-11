import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_repo.dart';

const maxImageBytes = 200 * 1024;

class Product {
  const Product({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.image,
  });
  final String id, ownerId, name, image;
  final double price;
  final int quantity;
  factory Product.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Product(
      id: doc.id,
      ownerId: doc.reference.parent.parent!.id,
      name: data['name'] as String,
      price: (data['price'] as num).toDouble(),
      quantity: data['soluong'] as int,
      image: data['image'] as String,
    );
  }
  Map<String, dynamic> toData() => {'name': name, 'price': price, 'soluong': quantity, 'image': image};
}

CollectionReference<Map<String, dynamic>> ownerProducts(String owner) =>
    firestore.collection('owners').doc(owner).collection('products');
Query<Map<String, dynamic>> productQuery({required String uid, required bool allOwners}) =>
    allOwners ? firestore.collectionGroup('products') : ownerProducts(uid);

Uint8List? imageBytes(String value) {
  try {
    return base64Decode(value);
  } on FormatException {
    return null;
  }
}

String? validateImage(List<int> bytes) {
  if (bytes.isEmpty || bytes.length > maxImageBytes) {
    return 'Ảnh tối đa 200 KiB. Chọn ảnh nhỏ hơn.';
  }
  final png =
      bytes.length >= 8 &&
      bytes[0] == 137 &&
      bytes[1] == 80 &&
      bytes[2] == 78 &&
      bytes[3] == 71 &&
      bytes[4] == 13 &&
      bytes[5] == 10 &&
      bytes[6] == 26 &&
      bytes[7] == 10;
  final jpeg = bytes.length >= 3 && bytes[0] == 255 && bytes[1] == 216 && bytes[2] == 255;
  return png || jpeg ? null : 'Chỉ chấp nhận ảnh PNG hoặc JPEG.';
}

Future<void> saveProduct({
  Product? original,
  required String name,
  required double price,
  required int quantity,
  required String image,
}) async {
  final user = auth.currentUser;
  if (user == null) throw const FormatException('Vui lòng đăng nhập lại.');
  if (name.trim().isEmpty ||
      name.trim().length > 120 ||
      !price.isFinite ||
      price < 0 ||
      price > 1000000000000 ||
      quantity < 0 ||
      quantity > 1000000000) {
    throw const FormatException('Tên, giá hoặc số lượng không hợp lệ.');
  }
  final bytes = imageBytes(image);
  if (bytes == null || validateImage(bytes) != null) {
    throw const FormatException('Ảnh sản phẩm không hợp lệ.');
  }
  final collection = ownerProducts(original?.ownerId ?? user.uid);
  final data = {'name': name.trim(), 'price': price, 'soluong': quantity, 'image': image};
  if (original == null) {
    await collection.add(data);
  } else {
    await collection.doc(original.id).update(data);
  }
}

Future<void> deleteProduct(Product product) => ownerProducts(product.ownerId).doc(product.id).delete();
Future<String> exportProducts({required String uid, required bool allOwners}) async {
  final snapshot = await productQuery(uid: uid, allOwners: allOwners).get(const GetOptions(source: Source.server));
  final owners = <String, Map<String, dynamic>>{};
  for (final doc in snapshot.docs) {
    final product = Product.fromDoc(doc);
    (owners[product.ownerId] ??= {'products': <String, dynamic>{}})['products'][product.id] = product.toData();
  }
  return const JsonEncoder.withIndent('  ').convert({'owners': owners});
}

String money(num value) {
  final parts = value.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  return '$parts ₫';
}
