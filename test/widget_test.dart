import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:midterm/profile_validation.dart';

void main() {
  test('Kiểm tra email, mật khẩu và họ tên ở biên dữ liệu', () {
    expect(validateEmail(' a@example.com '), isNull);
    expect(validateEmail('abc'), isNotNull);
    expect(validateEmail(null), isNotNull);
    expect(validatePassword('12345'), isNotNull);
    expect(validatePassword('123456'), isNull);
    expect(validatePassword('a' * 129), isNotNull);
    expect(validateName('  '), isNotNull);
    expect(validateName('Nguyễn Văn An'), isNull);
    expect(validateName('a' * 101), isNotNull);
  });

  test('Chuẩn hóa email và giữ đúng bốn trường hồ sơ', () {
    final data = profileData(
      email: ' AN@Example.com ',
      hoten: ' Nguyễn Văn An ',
      hinhanh: 'anh',
    );
    expect(data.keys.toSet(), {'email', 'matkhau', 'hoten', 'hinhanh'});
    expect(data['email'], 'an@example.com');
    expect(data['hoten'], 'Nguyễn Văn An');
    expect(data['matkhau'], passwordMarker);
  });

  test('Chỉ nhận ảnh JPEG/PNG không vượt quá 200 KiB', () {
    expect(validatePhotoBytes(base64Decode('iVBORw0KGgo=')), isNull);
    expect(validatePhotoBytes([0xff, 0xd8, 0xff, 1]), isNull);
    expect(validatePhotoBytes(utf8.encode('<svg></svg>')), isNotNull);
    expect(validatePhotoBytes([]), isNotNull);
    expect(validatePhotoBytes(List.filled(maxPhotoBytes + 1, 0)), isNotNull);
  });
}
