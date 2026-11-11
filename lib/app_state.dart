import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repo.dart';

final authUserProvider = StreamProvider<User?>((ref) => auth.authStateChanges(), retry: (_, _) => null);
final managerAccessProvider = FutureProvider.autoDispose<bool>((ref) async {
  final user = await ref.watch(authUserProvider.future);
  if (user == null) return false;
  return isManager();
}, retry: (_, _) => null);
