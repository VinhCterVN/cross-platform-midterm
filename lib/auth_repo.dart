import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final auth = FirebaseAuth.instance;
final firestore = FirebaseFirestore.instance;

String? validateEmail(String? value) {
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch((value ?? '').trim())) {
    return 'Nhập địa chỉ email hợp lệ';
  }
  return null;
}

String? validatePassword(String? value) =>
    value == null || value.length < 6 || value.length > 128 ? 'Mật khẩu từ 6 đến 128 ký tự' : null;

Future<void> login(String email, String password) async {
  await auth.signInWithEmailAndPassword(email: email.trim(), password: password);
}

Future<void> register(String email, String password) async {
  await auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
}

Future<void> logout() => auth.signOut();

// Quyền truy vấn toàn bộ sản phẩm do Security Rules quyết định.
Future<bool> isManager() async {
  try {
    await firestore.collectionGroup('products').limit(1).get(const GetOptions(source: Source.server));
    return true;
  } on FirebaseException catch (error) {
    if (error.code == 'permission-denied') return false;
    rethrow;
  }
}

String errorMessage(Object error) {
  if (error is FormatException) return error.message;
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-credential' || 'wrong-password' || 'user-not-found' => 'Email hoặc mật khẩu không đúng.',
      'invalid-email' => 'Địa chỉ email không hợp lệ.',
      'email-already-in-use' => 'Email đã được sử dụng. Hãy đăng nhập.',
      'weak-password' => 'Mật khẩu chưa đủ mạnh.',
      'too-many-requests' => 'Quá nhiều yêu cầu. Vui lòng thử lại sau.',
      'user-disabled' => 'Tài khoản đã bị vô hiệu hóa.',
      'network-request-failed' => 'Không có kết nối mạng. Vui lòng thử lại.',
      'operation-not-allowed' => 'Chưa bật Email/Password trong Firebase Authentication.',
      _ => 'Không thể xác thực. Kiểm tra kết nối và cấu hình Firebase.',
    };
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' => 'Không có quyền truy cập. Kiểm tra phiên đăng nhập và Firestore Rules.',
      'unavailable' => 'Không thể kết nối Firebase. Kiểm tra mạng rồi thử lại.',
      'failed-precondition' => 'Firestore chưa sẵn sàng. Kiểm tra database và chỉ mục.',
      'not-found' => 'Sản phẩm không còn tồn tại. Vui lòng tải lại.',
      _ => 'Không thể truy cập Firebase. Kiểm tra cấu hình và thử lại.',
    };
  }
  return 'Thao tác thất bại. Vui lòng thử lại.';
}
