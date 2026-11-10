# Quản lý người dùng — Bài thi giữa kỳ Flutter

- **Web quản trị:** đăng nhập, thêm tài khoản và hồ sơ, hiển thị/sửa/xóa hồ sơ, tìm kiếm, xuất JSON vào clipboard.
- **Android client:** đăng ký/đăng nhập, xem hồ sơ, cập nhật họ tên và ảnh từ thư viện/camera.
- **Firebase Spark:** Flutter kết nối **trực tiếp** Firebase Authentication và Cloud Firestore. Không có backend riêng, không triển khai Cloud Functions, không cần Blaze hoặc khóa tài khoản dịch vụ.

## Bắt đầu

Đọc **[Hướng dẫn Firebase từng bước](docs/huong_dan_firebase.md)**. Cấu hình FlutterFire hiện có liên kết dự án `profile-management-3a2f7`; không cần ghi đè cấu hình thật. Bật Email/Password, tạo Firestore, tạo tài khoản quản trị trên Console và thay `THAY_UID_QUAN_TRI` trong `firestore.rules` bằng UID của tài khoản đó.

```bash
flutter pub get
firebase login
firebase deploy --only firestore --project=profile-management-3a2f7
flutter run -d chrome
```

Không thay các SDK Android đã cấu hình. Spark có hạn mức miễn phí: hết hạn mức thì thao tác có thể bị từ chối; không tự nâng gói hay liên kết thanh toán.

## Phạm vi quản trị

Web tạo người dùng bằng Auth của Firebase App phụ để **không mất phiên admin**. Sau khi tạo, email chỉ đọc trong form; Web sửa họ tên và ảnh. Đổi email, đặt lại mật khẩu, khóa hoặc xóa tài khoản Authentication của người khác thực hiện tại **Firebase Console**.

**Xóa hồ sơ không xóa/khóa tài khoản Auth.** Tài khoản vẫn đăng nhập được và có thể hoàn thiện lại hồ sơ. Không dùng nút xóa hồ sơ như chức năng cấm đăng nhập. Nếu tạo Auth thành công nhưng lưu hồ sơ lỗi, dùng tài khoản đó đăng nhập Android để hoàn thiện; không đăng ký lại email.

## File bàn giao

| File | Nội dung |
|---|---|
| [Báo cáo Word](docs/bao_cao_giua_ky.docx) | Tiếng Việt, Cambria, đen/trắng, có chỗ chèn ảnh |
| [Báo cáo Markdown](docs/bao_cao_giua_ky.md) | Nội dung báo cáo có thể tìm kiếm |
| [Hướng dẫn Firebase](docs/huong_dan_firebase.md) | Thiết lập Spark và vận hành trực tiếp |
| [CSDL JSON mẫu](db/co_so_du_lieu.json) | Ba hồ sơ giả, UID minh họa; không phải bản xuất cloud |
| `firestore.rules` | Phân quyền theo UID và kiểm tra bốn trường |
| `cong_cu/kiem_thu_rules/` | Kiểm thử Rules cục bộ, không phải backend |

Điền thông tin sinh viên/lớp, chèn ảnh, link GitHub và link video vào báo cáo. Sinh viên tự quay video. Sau demo, nhấn **Xuất JSON** trên Web, dán vào file UTF-8 để nộp CSDL thực tế. Không có chức năng nhập JSON tự động.

## CSDL

`users/{Firebase Auth UID}` có **đúng bốn trường** `email`, `matkhau`, `hoten`, `hinhanh`. UID là khóa tài liệu, không phải trường thứ năm. `matkhau` chứa `Được quản lý bởi Firebase Authentication`, không chứa mật khẩu thật hoặc hash tự chế. `hinhanh` là base64 PNG/JPEG, tối đa 200 KiB trước mã hóa; không dùng Cloud Storage.

Quyền admin nằm trong danh sách UID tại Security Rules, không nằm trong document hồ sơ. Client không thể tự cấp quyền bằng cách sửa mã giao diện.

## Kiểm tra cục bộ

```bash
flutter analyze
flutter test
npm --prefix cong_cu/kiem_thu_rules ci
firebase emulators:exec --only firestore --project demo-midterm "node --test cong_cu/kiem_thu_rules/rules.test.cjs"
flutter build web
flutter build apk --debug
```

Xem hướng dẫn nếu Windows gặp lỗi cache Kotlin khác ổ đĩa. Kiểm thử cục bộ không xác nhận Firebase thật hoặc camera điện thoại. Bản học phần chưa có phân trang, App Check/chống lạm dụng hay đối soát tự động Auth–Firestore; không dùng dữ liệu thật để demo và không commit bí mật.
