import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

// Có thể dùng .env hoặc thay file này bằng đầu ra của flutterfire configure.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError('Ứng dụng hỗ trợ Web và Android.');
    }
    final options = kIsWeb ? web : android;
    if ([
      options.apiKey,
      options.appId,
      options.projectId,
      options.messagingSenderId,
    ].any((value) => value.isEmpty || value.startsWith('THAY_'))) {
      throw StateError('Điền cấu hình dự án Firebase mới vào .env.');
    }
    return options;
  }

  static const web = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_WEB_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_WEB_APP_ID'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
  );
  static const android = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_ANDROID_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_ANDROID_APP_ID'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
  );
}
