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
flutter run -d chrome --dart-define-from-file=.env
```

### Cấu hình API key cục bộ

Sao chép `.env.example` thành `.env`, điền `FIREBASE_WEB_API_KEY` và `FIREBASE_ANDROID_API_KEY` từ Firebase Console → Project settings. `.env` không được Git theo dõi. File `android/app/google-services.json` cũng chỉ giữ cục bộ; tải file đúng Android app `com.vincent.midterm` từ Firebase Console khi clone mới. Không commit file này trở lại.

VS Code đã có cấu hình chạy tự truyền `.env`. Khi dùng terminal, thêm cờ cho mọi lệnh run/build:

```bash
flutter run --dart-define-from-file=.env
flutter build apk --release --dart-define-from-file=.env
flutter build web --dart-define-from-file=.env
```

Firebase client API key là mã định danh công khai, không phải khóa service account; chuyển sang `.env` chỉ bỏ giá trị khỏi source, không giấu được key trong APK/Web đã build. Phân quyền vẫn do Authentication và Security Rules. Giới hạn API/application phù hợp trong Google Cloud Console; không đặt service-account key vào `.env` của app. Key đã nằm trong lịch sử Git trước đây không bị xóa bằng amend commit mới nhất; nếu cần vô hiệu hóa key cũ, phải thay key trên Console và cập nhật `.env`/cấu hình Android cục bộ. Chạy lại FlutterFire có thể sinh key literal trở lại, cần kiểm tra diff trước khi commit.

Không thay các SDK Android đã cấu hình. Spark có hạn mức miễn phí: hết hạn mức thì thao tác có thể bị từ chối; không tự nâng gói hay liên kết thanh toán.

## Điều hướng và trạng thái ứng dụng

Ứng dụng dùng **GoRouter** cho điều hướng và **Riverpod** cho phiên Firebase Auth, trạng thái thao tác đăng nhập/đăng ký, quyền admin và dữ liệu tải cho form sửa. `ProviderScope` được khởi tạo sau Firebase; `MainApp` dùng `MaterialApp.router`. Trạng thái tìm kiếm, nhập liệu, chọn ảnh và loading của từng form vẫn giữ cục bộ bằng `StatefulWidget`/`ConsumerStatefulWidget`, không thêm code generation.

| Đường dẫn | Chức năng |
|---|---|
| `/login` | Đăng nhập |
| `/register` | Đăng ký trên Android |
| `/admin` | Danh sách hồ sơ trên Web |
| `/admin/users/new` | Admin tạo tài khoản và hồ sơ |
| `/admin/users/:id/edit` | Admin sửa hồ sơ theo UID |
| `/profile` | Hồ sơ của người đang đăng nhập trên Android |
| `/profile/edit` | Sửa hoặc hoàn thiện hồ sơ của mình |

Router theo dõi thay đổi phiên Auth, khôi phục phiên hiện có khi mở app và chuyển về đăng nhập khi đăng xuất. Web kiểm tra quyền admin qua truy vấn Firestore; Android chỉ mở các trang hồ sơ cá nhân. Form sửa tải dữ liệu theo UID nên không phụ thuộc `extra` hoặc dữ liệu truyền qua lịch sử trình duyệt. Lỗi tải hồ sơ/kiểm tra phiên có thông báo và nút thử lại. URL Web dùng chế độ hash mặc định, ví dụ `/#/admin`; không cần cấu hình rewrite cho đường dẫn này.

Guard chỉ phục vụ điều hướng, **không thay thế Firestore Security Rules**. Không đưa mật khẩu, hash hoặc ảnh vào URL. Việc đăng nhập/đăng ký chỉ hoàn tất điều hướng sau khi bước lưu hash/hồ sơ kết thúc; tài khoản Auth đã tạo nhưng ghi hồ sơ lỗi vẫn có thể đăng nhập Android để hoàn thiện. Theo yêu cầu, không thêm/chạy tests và không cập nhật các file trong `docs/` cho lần thay đổi này.

## Phạm vi quản trị

Web tạo người dùng bằng Auth của Firebase App phụ để **không mất phiên admin**. Sau khi tạo, email chỉ đọc trong form; Web sửa họ tên và ảnh. Đổi email, đặt lại mật khẩu, khóa hoặc xóa tài khoản Authentication của người khác thực hiện tại **Firebase Console**.

**Xóa hồ sơ không xóa/khóa tài khoản Auth.** Tài khoản vẫn đăng nhập được và có thể hoàn thiện lại hồ sơ. Không dùng nút xóa hồ sơ như chức năng cấm đăng nhập. Nếu tạo Auth thành công nhưng lưu hồ sơ lỗi, dùng tài khoản đó đăng nhập Android để hoàn thiện; không đăng ký lại email.

## File bàn giao

| File | Nội dung |
|---|---|
| [Báo cáo Word cập nhật](docs/bao_cao_giua_ky_hoc_vu.docx) | Tiếng Việt, Cambria, đen/trắng, có chỗ chèn ảnh |
| [Báo cáo Markdown](docs/bao_cao_giua_ky.md) | Nội dung báo cáo có thể tìm kiếm |
| [Hướng dẫn Firebase](docs/huong_dan_firebase.md) | Thiết lập Spark và vận hành trực tiếp |
| [CSDL JSON mẫu](db/co_so_du_lieu.json) | Ba hồ sơ giả, UID minh họa; không phải bản xuất cloud |
| `firestore.rules` | Phân quyền theo UID và kiểm tra bốn trường |
| `cong_cu/kiem_thu_rules/` | Kiểm thử Rules cục bộ, không phải backend |

Điền thông tin sinh viên/lớp, chèn ảnh, link GitHub và link video vào báo cáo. Sinh viên tự quay video. Sau demo, nhấn **Xuất JSON** trên Web, dán vào file UTF-8 để nộp CSDL thực tế. Không có chức năng nhập JSON tự động.

## CSDL

`users/{Firebase Auth UID}` có **đúng bốn trường** `email`, `matkhau`, `hoten`, `hinhanh`. UID là khóa tài liệu, không phải trường thứ năm. `matkhau` lưu và hiển thị đầy đủ `pbkdf2-sha256$600000$SALT_BASE64$HASH_BASE64`, dùng thư viện cryptography, salt ngẫu nhiên 16 byte và kết quả 32 byte. Không lưu mật khẩu gốc. `hinhanh` là base64 PNG/JPEG, tối đa 200 KiB trước mã hóa; không dùng Cloud Storage.

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


## Cập nhật giao diện học vụ và mật khẩu băm

Giao diện Web/Android dùng tông navy, nền ngà, điểm nhấn đồng và tiêu đề serif. Hash được hiển thị đầy đủ, có thể chọn/sao chép. Firebase Auth vẫn là nguồn xác thực; hash Firestore không dùng để đăng nhập. Mỗi lần đăng nhập thành công, app ghi lại hash mới với salt riêng, nên mật khẩu đã reset sẽ được cập nhật khi đăng nhập tiếp theo. Hồ sơ thiếu yêu cầu nhập lại mật khẩu để xác thực trước khi tạo hash. Tài khoản cũ chưa đăng nhập vẫn giữ marker, giao diện ghi rõ chưa có hash; không thể trích mật khẩu từ Auth.

Cần triển khai Rules mới trước khi dùng bản này: `firebase deploy --only firestore --project=profile-management-3a2f7`. UID admin hiện có được giữ nguyên. Rules chỉ kiểm tra định dạng hash, không chứng minh nó khớp mật khẩu Auth. Người có quyền đọc hash có thể thử đoán mật khẩu ngoại tuyến; chỉ dùng dữ liệu giả cho demo và không công khai JSON tài khoản thật. JSON mẫu chứa hash minh họa, không phải tài khoản đăng nhập.

Theo yêu cầu, không chạy kiểm thử, analyzer, build hoặc kiểm tra thiết bị cho lần sửa giao diện/hash này. Các kết quả kiểm thử cũ trong tài liệu không xác nhận phiên bản mới.
