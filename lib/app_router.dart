import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_state.dart';
import 'pages/admin_page.dart';
import 'pages/login_page.dart';
import 'pages/profile_page.dart';
import 'pages/user_form_page.dart';
import 'user_repo.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authUserProvider, (_, _) => refresh.value++);
  if (kIsWeb) {
    ref.listen(adminAccessProvider, (_, _) => refresh.value++);
  }
  ref.listen(authActionProvider, (_, _) => refresh.value++);

  final router = GoRouter(
    refreshListenable: refresh,
    redirect: (context, state) async {
      final path = state.uri.path;
      if (ref.read(authActionProvider)) {
        return path == '/login' || (!kIsWeb && path == '/register')
            ? null
            : '/login';
      }
      final String? uid;
      try {
        uid = (await ref.read(authUserProvider.future))?.uid;
      } catch (_) {
        return path == '/session-error' ? null : '/session-error';
      }
      if (ref.read(authActionProvider)) return null;
      final public = path == '/login' || (!kIsWeb && path == '/register');
      if (uid == null) return public ? null : '/login';
      if (kIsWeb) {
        final bool admin;
        try {
          admin = await ref.read(adminAccessProvider.future);
        } catch (_) {
          return path == '/session-error' ? null : '/session-error';
        }
        if (ref.read(authActionProvider)) return null;
        // Một lần kiểm tra cũ không được dùng cho phiên đăng nhập mới.
        if (auth.currentUser?.uid != uid) return '/login';
        if (!admin) return path == '/access-denied' ? null : '/access-denied';
        return path == '/admin' || path.startsWith('/admin/') ? null : '/admin';
      }
      return path == '/profile' || path == '/profile/edit' ? null : '/profile';
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const _SessionPage()),
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, _) => const UserFormPage()),
      GoRoute(
        path: '/admin',
        builder: (_, _) => AdminPage(currentId: auth.currentUser?.uid ?? ''),
        routes: [
          GoRoute(path: 'users/new', builder: (_, _) => const UserFormPage()),
          GoRoute(
            path: 'users/:id/edit',
            builder: (_, state) =>
                _EditProfilePage(id: state.pathParameters['id'] ?? ''),
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        builder: (_, _) => ProfilePage(id: auth.currentUser?.uid ?? ''),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, _) => _EditProfilePage(
              id: auth.currentUser?.uid ?? '',
              allowCompletion: true,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/access-denied',
        builder: (_, _) =>
            const _SessionPage(message: 'Web chỉ dành cho quản trị viên.'),
      ),
      GoRoute(
        path: '/session-error',
        builder: (_, _) => const _SessionPage(
          message:
              'Không thể kiểm tra phiên đăng nhập hoặc quyền truy cập. '
              'Kiểm tra mạng và cấu hình Firebase.',
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Không tìm thấy trang')),
      body: Center(
        child: FilledButton(
          onPressed: () => context.go('/'),
          child: const Text('Về trang chính'),
        ),
      ),
    ),
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

class _SessionPage extends ConsumerWidget {
  const _SessionPage({this.message});
  final String? message;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: message == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message!, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      ref.invalidate(authUserProvider);
                      ref.invalidate(adminAccessProvider);
                      context.go('/');
                    },
                    child: const Text('Thử lại'),
                  ),
                  TextButton(
                    onPressed: () async {
                      try {
                        await logout();
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(errorMessage(error))),
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
  );
}

class _EditProfilePage extends ConsumerWidget {
  const _EditProfilePage({required this.id, this.allowCompletion = false});
  final String id;
  final bool allowCompletion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = editableProfileProvider(id);
    return ref
        .watch(provider)
        .when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, _) => Scaffold(
            appBar: AppBar(title: const Text('Chỉnh sửa hồ sơ')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(errorMessage(error), textAlign: TextAlign.center),
                    TextButton(
                      onPressed: () => ref.invalidate(provider),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          data: (data) {
            if (data == null && !allowCompletion) {
              return Scaffold(
                appBar: AppBar(title: const Text('Chỉnh sửa hồ sơ')),
                body: const Center(child: Text('Hồ sơ không còn tồn tại.')),
              );
            }
            return UserFormPage(
              key: ValueKey(id),
              id: id,
              data:
                  data ??
                  {
                    'email': auth.currentUser?.email ?? '',
                    'hoten': '',
                    'hinhanh': '',
                  },
            );
          },
        );
  }
}
