import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

const passwordHashIterations = 600000;

/// Salt riêng cho mỗi lần băm; isolate trên Android để không khóa giao diện.
Future<String> hashPassword(String password) => compute(_deriveHash, password);

Future<String> _deriveHash(String password) async {
  final random = Random.secure();
  final salt = List<int>.generate(16, (_) => random.nextInt(256));
  final key = await Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: passwordHashIterations,
    bits: 256,
  ).deriveKeyFromPassword(password: password, nonce: salt);
  return 'pbkdf2-sha256\$$passwordHashIterations\$${base64Encode(salt)}\$'
      '${base64Encode(await key.extractBytes())}';
}
