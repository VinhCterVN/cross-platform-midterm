import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'profile_validation.dart';
export 'profile_validation.dart';

final auth = FirebaseAuth.instance;
final users = FirebaseFirestore.instance.collection('users');
Future<FirebaseAuth>? _registrationAuth;

// Security Rules quyết định quyền; không tin cờ admin từ giao diện/client.
Future<bool> isAdmin() async {
  if (auth.currentUser == null) return false;
  try {
    await users.limit(1).get(const GetOptions(source: Source.server));
    return true;
  } on FirebaseException catch (error) {
    if (error.code == 'permission-denied') return false;
    rethrow;
  }
}

Future<String?> login(String email, String password) async {
  final credential = await auth.signInWithEmailAndPassword(
    email: normalizeEmail(email),
    password: password,
  );
  return credential.user?.uid;
}

Future<void> logout() => auth.signOut();

Future<FirebaseAuth> _secondaryAuth() async {
  final app = await Firebase.initializeApp(
    name: 'tao-nguoi-dung',
    options: Firebase.app().options,
  );
  final secondary = FirebaseAuth.instanceFor(app: app);
  if (kIsWeb) await secondary.setPersistence(Persistence.NONE);
  return secondary;
}

class ProfileWriteException implements Exception {
  const ProfileWriteException();
}

Future<String> saveUser({
  String? id,
  required String email,
  required String hoten,
  required String hinhanh,
  String? password,
}) async {
  final data = profileData(email: email, hoten: hoten, hinhanh: hinhanh);
  if (validateEmail(email) != null || validateName(hoten) != null) {
    throw const FormatException('Thông tin không hợp lệ');
  }
  final bytes = base64Decode(hinhanh);
  if (validatePhotoBytes(bytes) != null || base64Encode(bytes) != hinhanh) {
    throw const FormatException('Ảnh không hợp lệ');
  }
  final creating = id == null;
  if (creating) {
    if (validatePassword(password) != null) {
      throw const FormatException('Mật khẩu không hợp lệ');
    }
    if (kIsWeb) {
      if (!await isAdmin()) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
        );
      }
      final secondary = await (_registrationAuth ??= _secondaryAuth());
      // App Auth phụ không thay phiên đăng nhập quản trị viên ở app chính.
      try {
        final credential = await secondary.createUserWithEmailAndPassword(
          email: data['email']!,
          password: password!,
        );
        id = credential.user!.uid;
      } finally {
        await secondary.signOut();
      }
    } else {
      final credential = await auth.createUserWithEmailAndPassword(
        email: data['email']!,
        password: password!,
      );
      id = credential.user!.uid;
    }
  }
  try {
    if (creating) {
      await users.doc(id).set(data);
    } else {
      // Giao dịch chỉ sửa tên/ảnh; hồ sơ thiếu được tạo lại để hoàn thiện đăng ký.
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final ref = users.doc(id);
        final before = await transaction.get(ref);
        if (before.exists) {
          transaction.update(ref, {'hoten': data['hoten'], 'hinhanh': hinhanh});
        } else {
          transaction.set(ref, data);
        }
      });
    }
  } catch (_) {
    // Auth và Firestore không có giao dịch chung; không xóa Auth khi mạng chập chờn.
    if (creating) throw const ProfileWriteException();
    rethrow;
  }
  return id;
}

/// Chỉ xóa hồ sơ Firestore; không xóa/khóa tài khoản Authentication.
Future<void> deleteUser(String id) => users.doc(id).delete();

Future<String> exportUsersJson() async {
  final snapshot = await users.get(const GetOptions(source: Source.server));
  return const JsonEncoder.withIndent('  ').convert({
    'users': {for (final doc in snapshot.docs) doc.id: doc.data()},
  });
}

String errorMessage(Object error) {
  if (error is ProfileWriteException) {
    return 'Đã tạo tài khoản Auth nhưng chưa xác nhận lưu hồ sơ. '
        'Đăng nhập Android để hoàn thiện hồ sơ; không đăng ký lại email này.';
  }
  if (error is FormatException) return 'Thông tin hoặc ảnh không hợp lệ';
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'Sai email hoặc mật khẩu',
      'email-already-in-use' => 'Email đã được sử dụng',
      'weak-password' => 'Mật khẩu chưa đủ mạnh',
      'too-many-requests' => 'Quá nhiều yêu cầu. Vui lòng thử lại sau',
      'network-request-failed' => 'Không có kết nối mạng',
      _ => 'Không thể xác thực. Vui lòng kiểm tra cấu hình Firebase',
    };
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' =>
        'Không có quyền. Kiểm tra UID quản trị và Firestore Rules',
      'unauthenticated' => 'Vui lòng đăng nhập lại',
      _ => 'Không thể truy cập Firebase. Kiểm tra mạng và cấu hình',
    };
  }
  return 'Thao tác thất bại. Vui lòng thử lại';
}
