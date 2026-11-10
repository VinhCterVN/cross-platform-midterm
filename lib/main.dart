import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'academic_theme.dart';
import 'app_router.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const ProviderScope(child: MainApp()));
  } catch (_) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Chưa kết nối được Firebase.\n'
                'Kiểm tra .env theo .env.example và cấu hình Firebase. '
                'Chạy với --dart-define-from-file=.env rồi khởi động lại.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Hồ sơ học đường',
      debugShowCheckedModeBanner: false,
      theme: academicTheme(),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
