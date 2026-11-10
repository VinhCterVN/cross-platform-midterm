import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'academic_theme.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const MainApp());
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

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hồ sơ học đường',
      debugShowCheckedModeBanner: false,
      theme: academicTheme(),
      home: const LoginPage(),
    );
  }
}
