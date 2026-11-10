const passwordMarker = 'Được quản lý bởi Firebase Authentication';
const maxPhotoBytes = 200 * 1024;

String normalizeEmail(String value) => value.trim().toLowerCase();

String? validateEmail(String? value) {
  final email = normalizeEmail(value ?? '');
  return email.length <= 254 &&
          RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
      ? null
      : 'Email không hợp lệ';
}

String? validatePassword(String? value) =>
    (value ?? '').length >= 6 && value!.length <= 128
    ? null
    : 'Mật khẩu từ 6 đến 128 ký tự';

String? validateName(String? value) =>
    (value ?? '').trim().isNotEmpty && value!.trim().length <= 100
    ? null
    : 'Họ tên từ 1 đến 100 ký tự';

String? validatePhotoBytes(List<int> bytes) {
  if (bytes.isEmpty || bytes.length > maxPhotoBytes) {
    return 'Ảnh phải có dung lượng không quá 200 KiB';
  }
  final png =
      bytes.length >= 8 &&
      List.generate(8, (i) => bytes[i]).join(',') == '137,80,78,71,13,10,26,10';
  final jpeg =
      bytes.length >= 3 &&
      bytes[0] == 255 &&
      bytes[1] == 216 &&
      bytes[2] == 255;
  return png || jpeg ? null : 'Chỉ chấp nhận ảnh PNG hoặc JPEG';
}

Map<String, String> profileData({
  required String email,
  required String hoten,
  required String hinhanh,
  required String matkhau,
}) => {
  'email': normalizeEmail(email),
  'matkhau': matkhau,
  'hoten': hoten.trim(),
  'hinhanh': hinhanh,
};
