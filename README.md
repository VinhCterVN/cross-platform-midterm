# Kho hàng — Quản lý sản phẩm

Ứng dụng Flutter cho Web và Android theo [đề bài mới](docs/new-requirements.jpg). Người dùng đăng ký/đăng nhập, quản lý sản phẩm của mình. Quản lý xem, sửa, xóa sản phẩm của mọi chủ sở hữu, nhóm/lọc theo UID, tìm kiếm, sắp xếp và xuất JSON.

Mỗi sản phẩm có **đúng bốn trường**: `name`, `price`, `soluong`, `image`. Quyền sở hữu nằm ở đường dẫn `owners/{uid}/products/{productId}`. Không thêm trường role, ownerId hoặc thời gian vào document. Tài khoản và mật khẩu do Firebase Authentication quản lý.

## Tài liệu Word tiếng Việt

Tất cả dùng Cambria, chữ đen, nền trắng, có bảng và khung chèn ảnh thực tế:

- [Báo cáo quản lý sản phẩm](docs/bao_cao_quan_ly_san_pham.docx).
- [Hướng dẫn chuyển Firebase từng bước](docs/huong_dan_chuyen_firebase.docx).
- [Hướng dẫn sử dụng và quay video](docs/huong_dan_su_dung.docx).

Đây là bộ tài liệu hiện hành. Các báo cáo quản lý hồ sơ cũ trong thư mục local không mô tả phiên bản này. Điền Project ID, lớp, ảnh chụp và liên kết video trước khi nộp.

## Chuyển sang Firebase mới

Mở **hướng dẫn Word** để thực hiện đầy đủ. Không có Project ID hoặc UID mới được điền sẵn; source không còn mặc định trỏ tới Firebase profile-management cũ.

1. Trong Firebase Console mới, bật Authentication → Email/Password, tạo Cloud Firestore mặc định ở chế độ production.
2. Đăng ký Web app và Android app với package `com.vincent.midterm`. Tải `google-services.json` mới vào `android/app/google-services.json`.
3. Sao lưu `.env` hiện có rồi sao chép `.env.example` thành `.env`. Điền đủ bảy biến từ dự án mới, gồm Project ID, Project number, authDomain, API key và App ID cho cả Web/Android.
4. Tạo tài khoản quản lý trong Authentication, lấy UID mới và thay `THAY_UID_QUAN_LY` trong `firestore.rules`.
5. Chạy PowerShell tại thư mục dự án:

```powershell
Set-Location D:\Projects\flutter\midterm
$FirebaseProject = "PROJECT_ID_MOI_CUA_BAN"
flutter pub get
npm install -g firebase-tools
firebase login
firebase projects:list
firebase deploy --only firestore --project=$FirebaseProject
flutter run -d chrome --dart-define-from-file=.env
```

Thêm `localhost` vào Authentication → Settings → Authorized domains nếu chưa có. Dừng và chạy lại app sau khi thay `.env` hoặc cấu hình Android.

Hướng dẫn Word cũng có lựa chọn dùng `flutterfire configure` để sinh `firebase_options.dart` trực tiếp. Nếu chọn cách đó, file sinh thay thế bản đọc `.env`; không cần cờ `--dart-define-from-file` khi chạy. Không trộn cấu hình hai dự án. Quy trình này dựa trên [hướng dẫn FlutterFire chính thức](https://firebase.google.com/docs/flutter/setup).

## Quyền và giao diện

- Chưa đăng nhập: đăng ký, đăng nhập và đặt lại mật khẩu bằng email.
- Người dùng: xem/thêm/sửa/xóa/xuất sản phẩm tại UID của mình trên cả Web và Android.
- Quản lý: có thêm phạm vi **Tất cả**, nhóm và lọc theo UID, sửa/xóa mọi sản phẩm. Sản phẩm mới luôn được thêm vào kho tài khoản hiện tại.

UID quản lý nằm trong danh sách ở Rules; cập nhật danh sách cần deploy lại. Ứng dụng kiểm tra quyền qua truy vấn collection group được Rules bảo vệ. [Firebase yêu cầu Rules phù hợp cho truy vấn collection group](https://firebase.google.com/docs/firestore/security/rules-query).

Web rộng hiển thị bảng; màn hình nhỏ hiển thị thẻ. Bộ lọc hỗ trợ tên/mã/UID, sắp xếp tên/giá/số lượng, hết hàng và sắp hết (1–5). Thống kê tính theo kết quả đang hiển thị. Khi bật nhóm, sắp xếp áp dụng trong từng nhóm.

## Hình ảnh và CSDL bàn giao

`image` chứa base64 PNG/JPEG, ảnh gốc tối đa **200 KiB**. Không dùng Cloud Storage. Android nhận ảnh thư viện/camera; Web nhận file ảnh. Ảnh được xem trước và giải mã trước khi lưu. Giá nhập không có dấu phân cách hàng nghìn, ví dụ `125000` hoặc `125000,50`; số lượng là số nguyên không âm.

`db/co_so_du_lieu.json` và `db/db.json` là dữ liệu mẫu giống nhau: ba sản phẩm, hai UID minh họa và ảnh PNG rất nhỏ. Các file này không tự nhập vào Firebase. Tạo dữ liệu bằng app sau khi cấu hình dự án mới.

Bấm **Xuất JSON** trên Web để tải `co_so_du_lieu_thuc_te.json`; quản lý chọn **Tất cả** để nộp toàn bộ CSDL. Xuất dữ liệu không áp dụng bộ lọc/tìm kiếm. Android hiển thị JSON với nút sao chép. Đây là JSON phục vụ bài nộp, không phải định dạng backup gốc của Firestore; không dùng `firebase database:import` cho file này.

## Chạy Android và build

```powershell
flutter devices
flutter run -d MA_THIET_BI --dart-define-from-file=.env
flutter build web --dart-define-from-file=.env
flutter build apk --release --dart-define-from-file=.env
```

Hosting tùy chọn, sau khi build Web: `firebase deploy --only hosting --project=$FirebaseProject`. Cấu hình đã trỏ tới `build/web`. APK release của cấu hình học phần dùng chữ ký debug hiện có.

Theo yêu cầu, không viết/chạy tests cho lần chuyển đổi này. Firebase mới, đăng nhập và camera thực tế cần được sử dụng sau khi điền cấu hình. Danh mục hiện tải toàn bộ dữ liệu, phù hợp bài học phần nhỏ; chưa có phân trang hoặc lịch sử thay đổi.

## Tạo lại tài liệu

```powershell
npm --prefix tools/documents ci
npm --prefix tools/documents run generate
```

Nội dung và định dạng nằm trong `tools/documents/generate.cjs`. Mở các file DOCX bằng Word để bổ sung ảnh chụp thực tế và hoàn thiện thông tin trước khi nộp.
