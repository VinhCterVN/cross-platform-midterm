import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'user_repo.dart';

final authUserProvider = StreamProvider<User?>(
  (ref) => auth.authStateChanges(),
  retry: (_, _) => null,
);

// Chờ lưu hash/hồ sơ xong trước khi chuyển trang theo sự kiện Auth.
class AuthAction extends Notifier<bool> {
  @override
  bool build() => false;

  void setBusy(bool value) => state = value;
}

final authActionProvider = NotifierProvider<AuthAction, bool>(AuthAction.new);

// Quyền thật do Firestore Rules quyết định, không suy ra từ URL hoặc hồ sơ.
final adminAccessProvider = FutureProvider<bool>((ref) async {
  final user = await ref.watch(authUserProvider.future);
  if (user == null) return false;
  return isAdmin();
}, retry: (_, _) => null);

final editableProfileProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, id) async {
      final user = await ref.watch(authUserProvider.future);
      if (user == null) return null;
      return (await users.doc(id).get()).data();
    }, retry: (_, _) => null);
