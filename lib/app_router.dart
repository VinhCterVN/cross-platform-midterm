import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_state.dart';
import 'auth_repo.dart';
import 'pages/login_page.dart';
import 'pages/products_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authUserProvider, (_, _) => refresh.value++);
  final router = GoRouter(
    refreshListenable: refresh,
    redirect: (_, state) {
      final session = ref.read(authUserProvider);
      if (session.isLoading) return state.uri.path == '/' ? null : '/';
      if (session.hasError) {
        return state.uri.path == '/session-error' ? null : '/session-error';
      }
      final public = state.uri.path == '/login' || state.uri.path == '/register';
      if (session.value == null) return public ? null : '/login';
      if (public || state.uri.path == '/' || state.uri.path == '/session-error') {
        return '/products';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, _) => const LoginPage(registering: true)),
      GoRoute(
        path: '/products',
        builder: (_, _) => ProductsPage(key: ValueKey(auth.currentUser?.uid)),
      ),
      GoRoute(
        path: '/session-error',
        builder: (context, _) => Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Không thể khôi phục phiên đăng nhập.'),
                TextButton(onPressed: () => ref.invalidate(authUserProvider), child: const Text('Thử lại')),
              ],
            ),
          ),
        ),
      ),
    ],
    errorBuilder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Không tìm thấy trang')),
      body: Center(
        child: FilledButton(onPressed: () => context.go('/'), child: const Text('Về trang chính')),
      ),
    ),
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
