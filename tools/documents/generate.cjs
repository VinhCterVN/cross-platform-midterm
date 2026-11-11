// Tạo bộ tài liệu Word tiếng Việt, Cambria, chữ đen trên nền trắng.
const fs = require('node:fs');
const path = require('node:path');
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  HeadingLevel, WidthType, BorderStyle, ShadingType, AlignmentType,
  VerticalAlign, HeightRule, Footer, Header, PageNumber,
} = require('docx');

const root = path.resolve(__dirname, '../..');
const width = 9638;
const border = { style: BorderStyle.SINGLE, size: 4, color: '000000' };
const run = (text, extra = {}) => new TextRun({ text, font: 'Cambria', size: 26, color: '000000', ...extra });
const p = (text, extra = {}) => new Paragraph({ children: [run(text)], spacing: { after: 140, line: 300 }, ...extra });
const h = (text, first = false) => new Paragraph({ heading: HeadingLevel.HEADING_1,
  pageBreakBefore: !first, keepNext: true, children: [run(text, { bold: true, size: 34 })],
  spacing: { after: 220, before: first ? 0 : 60 } });
const sub = (text) => new Paragraph({ heading: HeadingLevel.HEADING_2, keepNext: true,
  children: [run(text, { bold: true, size: 28 })], spacing: { before: 180, after: 120 } });
const cmd = (text) => p(text, { indent: { left: 200 }, spacing: { after: 90, line: 280 } });
const table = (head, rows, widths = head.map(() => Math.floor(width / head.length))) => {
  widths[widths.length - 1] += width - widths.reduce((a, b) => a + b, 0);
  return new Table({ width: { size: width, type: WidthType.DXA }, columnWidths: widths,
    borders: { top: border, bottom: border, left: border, right: border, insideHorizontal: border, insideVertical: border },
    rows: [head, ...rows].map((row, i) => new TableRow({ tableHeader: i === 0, cantSplit: true,
      children: row.map((text, j) => new TableCell({ width: { size: widths[j], type: WidthType.DXA },
        shading: { type: ShadingType.CLEAR, fill: 'FFFFFF' },
        margins: { top: 100, bottom: 100, left: 120, right: 120 },
        children: [new Paragraph({ children: [run(String(text), { bold: i === 0, size: 23 })],
          spacing: { after: 40, line: 270 } })] }))
    })) });
};
const imageSlot = (caption, height = 1550) => [
  new Table({ width: { size: width, type: WidthType.DXA }, columnWidths: [width],
    borders: { top: border, bottom: border, left: border, right: border },
    rows: [new TableRow({ cantSplit: true, height: { value: height, rule: HeightRule.ATLEAST }, children: [
      new TableCell({ width: { size: width, type: WidthType.DXA }, verticalAlign: VerticalAlign.CENTER,
        shading: { type: ShadingType.CLEAR, fill: 'FFFFFF' },
        children: [p('[Chèn ảnh chụp thực tế tại đây]', { alignment: AlignmentType.CENTER })] })
    ] })] }),
  p(caption, { alignment: AlignmentType.CENTER, spacing: { before: 100, after: 180 } }),
];
const source = (label, url) => p(`${label}: ${url}`);
const github = 'https://github.com/VinhCterVN/cross-platform-midterm';

const report = [
  h('BÁO CÁO GIỮA KỲ', true),
  p('HỌC PHẦN: LẬP TRÌNH ĐA NỀN TẢNG', { alignment: AlignmentType.CENTER }),
  p('Đề tài: Quản lý sản phẩm trên Web và Android', { alignment: AlignmentType.CENTER, spacing: { before: 400, after: 400 } }),
  table(['Thông tin', 'Nội dung'], [
    ['Khoa', 'Khoa học máy tính'], ['Giảng viên hướng dẫn', 'ThS. Ngô Lê Quân'],
    ['Sinh viên thực hiện', 'Trần Thành Vinh'], ['Mã số sinh viên', '23IT.EB119'],
    ['Lớp', '[Điền lớp học phần]'], ['Tên ứng dụng', 'Kho hàng'],
    ['Mã nguồn GitHub', github], ['Video minh họa', '[Điền liên kết video sau khi quay]'],
    ['Dự án Firebase', '[Điền Project ID của dự án mới]'],
  ], [3000, 6638]),
  p('Tài liệu được cập nhật theo docs/new-requirements.jpg. Thông tin giảng viên và sinh viên kế thừa báo cáo cũ; cần rà soát trước khi nộp.', { spacing: { before: 240, after: 140 } }),
  p('Báo cáo mô tả phần mã nguồn đã triển khai. Ảnh minh họa, dữ liệu cloud và liên kết video cần được bổ sung sau khi cấu hình Firebase mới. Không ghi nhận kết quả kiểm thử thực tế.'),

  h('1. Yêu cầu và phạm vi thực hiện'),
  p('Ứng dụng cho phép đăng ký, đăng nhập và quản lý hàng hóa. Người dùng chỉ thao tác sản phẩm của mình; tài khoản quản lý có thể xem và quản lý sản phẩm của mọi chủ sở hữu. Web và Android sử dụng chung mã nguồn Flutter.'),
  table(['Yêu cầu trong đề', 'Phần thực hiện', 'Mức điểm'], [
    ['Thêm, hiển thị sản phẩm bằng Firebase trên Web', 'Danh mục có ảnh, tên, giá và số lượng; dữ liệu Firestore cập nhật qua stream.', '8,0'],
    ['Đăng nhập, sửa, xóa, chức năng nâng cao', 'Firebase Auth; CRUD; tìm kiếm; sắp xếp; lọc tồn kho; nhóm theo UID; xuất JSON.', '1,5'],
    ['Nhận hình ảnh, hiển thị sản phẩm trên di động', 'Android chọn ảnh thư viện hoặc chụp camera; xem danh sách và chi tiết.', '0,5'],
    ['Báo cáo, CSDL, GitHub, video', 'Bộ DOCX, JSON mẫu; chức năng xuất dữ liệu thực tế; chỗ điền video và ảnh.', 'Bắt buộc'],
  ], [2800, 5700, 1138]),
  sub('Ràng buộc bốn trường'),
  p('Mỗi document sản phẩm chỉ chứa name, price, soluong, image. UID chủ sở hữu và mã sản phẩm nằm trong đường dẫn; không thêm ownerId, role, createdAt hoặc trường khác. Tài khoản và mật khẩu được quản lý riêng bởi Firebase Authentication.'),
  ...imageSlot('Hình 1. Chèn ảnh đề bài mới để đối chiếu yêu cầu.', 1500),

  h('2. Công nghệ và cấu trúc chương trình'),
  table(['Thành phần', 'Vai trò'], [
    ['Flutter / Dart', 'Giao diện dùng chung cho Web và Android.'],
    ['firebase_core / firebase_auth', 'Khởi tạo Firebase, đăng ký, đăng nhập, đặt lại mật khẩu và đăng xuất.'],
    ['cloud_firestore', 'Lưu bốn trường sản phẩm, cập nhật thời gian thực và áp dụng Security Rules.'],
    ['flutter_riverpod / go_router', 'Theo dõi phiên, xác định quyền và bảo vệ đường dẫn.'],
    ['image_picker / web', 'Nhận ảnh thư viện/camera; tải JSON trên trình duyệt.'],
  ], [3200, 6438]),
  sub('Các tệp chính'),
  table(['Tệp', 'Trách nhiệm'], [
    ['lib/auth_repo.dart; lib/app_state.dart', 'Xác thực, thông báo lỗi, trạng thái phiên và kiểm tra quyền quản lý.'],
    ['lib/product_repo.dart', 'Model sản phẩm, truy vấn theo chủ sở hữu, thêm/sửa/xóa và xuất JSON.'],
    ['lib/pages/products_page.dart', 'Danh mục, thống kê, nhóm chủ sở hữu, lọc, sắp xếp và chi tiết.'],
    ['lib/pages/product_form.dart', 'Biểu mẫu, kiểm tra dữ liệu, chọn/chụp và xem trước ảnh.'],
    ['firestore.rules; firestore.indexes.json', 'Phân quyền, kiểm tra cấu trúc và bỏ chỉ mục trường ảnh.'],
  ], [4400, 5238]),
  p('Luồng chính: người dùng → Firebase Authentication → UID → truy vấn Firestore → danh mục sản phẩm. Dữ liệu ghi chỉ được chấp nhận khi Security Rules cho phép.'),

  h('3. Thiết kế cơ sở dữ liệu'),
  p('Đường dẫn: owners/{uid}/products/{productId}. Document owners/{uid} có thể không tồn tại; Firestore vẫn cho phép lưu subcollection products. Không cần tạo document cha có các trường bổ sung.'),
  table(['Trường', 'Kiểu', 'Ý nghĩa và giới hạn'], [
    ['name', 'string', 'Tên sản phẩm sau khi bỏ khoảng trắng đầu/cuối; 1–120 ký tự.'],
    ['price', 'number', 'Giá VNĐ; từ 0 đến 1.000.000.000.000; phải là số hữu hạn.'],
    ['soluong', 'integer', 'Số lượng từ 0 đến 1.000.000.000.'],
    ['image', 'string', 'Base64 PNG/JPEG; ảnh gốc tối đa 200 KiB; chuỗi tối đa 273.068 ký tự.'],
  ], [1500, 1500, 6638]),
  sub('Ví dụ đường dẫn và dữ liệu'),
  cmd('owners/UID_NGUOI_DUNG/products/MA_SAN_PHAM'),
  cmd('{ "name": "Bàn phím cơ", "price": 750000, "soluong": 12,'),
  cmd('  "image": "<chuỗi base64 PNG/JPEG đầy đủ>" }'),
  p('Ví dụ trên rút gọn ảnh để trình bày. File db/co_so_du_lieu.json chứa base64 đầy đủ và UID minh họa. File db/db.json có cùng cấu trúc. Đây là dữ liệu mẫu, không phải bản xuất từ dự án Firebase mới.'),
  p('Ảnh được lưu trong trường image, không dùng Cloud Storage. Chủ sở hữu là thông tin trong đường dẫn và chỉ được suy ra khi tạo model hiển thị; không được ghi thành trường thứ năm.'),
  ...imageSlot('Hình 2. Chèn ảnh Console thể hiện đường dẫn và đúng bốn trường.', 1450),

  h('4. Chuẩn bị môi trường và Firebase mới'),
  p('Các thao tác thực hiện trong PowerShell tại thư mục dự án. Hướng dẫn đầy đủ nằm trong huong_dan_chuyen_firebase.docx, bao gồm cấu hình .env và lựa chọn dùng FlutterFire CLI.'),
  cmd('Set-Location D:\\Projects\\flutter\\midterm'),
  cmd('flutter pub get'),
  cmd('npm install -g firebase-tools'),
  cmd('firebase login'),
  cmd('firebase projects:list'),
  cmd('$FirebaseProject = "PROJECT_ID_MOI_CUA_BAN"'),
  p('Trong Console của dự án mới: bật Authentication → Email/Password; tạo Cloud Firestore ở chế độ production; đăng ký Web app và Android app với package com.vincent.midterm. Tải google-services.json mới vào android/app/google-services.json.'),
  cmd('Copy-Item .env.example .env'),
  p('Nếu đã có .env, sao lưu trước khi sao chép. Điền toàn bộ cấu hình của dự án mới, không chỉ API key. Tạo tài khoản quản lý và thay THAY_UID_QUAN_LY trong firestore.rules bằng UID mới.'),
  cmd('firebase deploy --only firestore --project=$FirebaseProject'),
  cmd('flutter run -d chrome --dart-define-from-file=.env'),
  ...imageSlot('Hình 3. Chèn ảnh dự án mới, Authentication và kết quả deploy Rules.', 1500),

  h('5. Phân quyền và quản lý phiên'),
  table(['Vai trò', 'Quyền'], [
    ['Chưa đăng nhập', 'Đăng ký, đăng nhập, yêu cầu email đặt lại mật khẩu; không đọc/ghi sản phẩm.'],
    ['Người dùng', 'Xem, thêm, sửa, xóa và xuất JSON sản phẩm trong owners/{UID của mình}/products.'],
    ['Quản lý', 'Quyền người dùng; đọc toàn bộ collection group products; sửa/xóa mọi sản phẩm; nhóm và lọc theo UID.'],
  ], [2300, 7338]),
  p('Danh sách UID quản lý nằm trong hàm manager() của firestore.rules. Đổi danh sách phải deploy Rules lại. Người dùng không tự chọn vai trò khi đăng ký. Không cần service account hoặc collection phân quyền.'),
  p('Sau khi đăng nhập, ứng dụng thử truy vấn collectionGroup("products").limit(1) từ server. Rules chỉ cho quản lý thực hiện truy vấn này; lỗi permission-denied được hiểu là quyền người dùng. Lỗi mạng được hiển thị để thử lại.'),
  p('GoRouter theo dõi Firebase Auth: chưa đăng nhập được chuyển đến /login; đăng nhập thành công đến /products; đăng xuất quay lại đăng nhập. Web và Android cùng hỗ trợ đăng ký và quản lý sản phẩm.'),
  p('Quản lý thêm sản phẩm mới vào kho của chính mình. Khi sửa sản phẩm của người khác, sản phẩm giữ nguyên đường dẫn và chủ sở hữu. Giao diện nhóm theo UID vì đề không cho thêm trường tên chủ sở hữu vào sản phẩm.'),
  ...imageSlot('Hình 4. Chèn ảnh danh mục của tài khoản thường và quản lý.', 1750),

  h('6. Thực hiện thêm, sửa, xóa và xem sản phẩm'),
  table(['Thao tác', 'Các bước và kết quả'], [
    ['Thêm', 'Bấm Thêm sản phẩm → chọn/chụp ảnh → nhập tên, giá, số lượng → Lưu sản phẩm. Tạo document mới dưới UID hiện tại.'],
    ['Hiển thị', 'Stream Firestore tải dữ liệu và cập nhật danh mục; ảnh base64 được giải mã thành ảnh xem trước.'],
    ['Chi tiết', 'Bấm sản phẩm hoặc nút xem chi tiết; hiển thị ảnh lớn, tên, giá, số lượng, UID và mã sản phẩm.'],
    ['Sửa', 'Mở biểu mẫu có dữ liệu hiện tại, cập nhật và lưu. Dùng update để không tự tạo lại document đã bị xóa.'],
    ['Xóa', 'Bấm biểu tượng xóa, đọc tên sản phẩm và xác nhận. Chỉ xóa document sản phẩm.'],
  ], [1600, 8038]),
  p('Biểu mẫu kiểm tra tên, giá, số lượng, kích thước và định dạng ảnh. Ảnh phải giải mã được bằng bộ giải mã ảnh của Flutter trước khi lưu. Không khóa quyền chỉ bằng giao diện; Firestore Rules kiểm tra lại dữ liệu và quyền ghi.'),
  p('Giá nhập không dùng dấu phân cách hàng nghìn; ví dụ 125000 hoặc 125000,50. Giao diện danh mục trình bày giá làm tròn theo đồng. Trạng thái đang lưu ngăn người dùng gửi lại cùng thao tác.'),
  ...imageSlot('Hình 5. Chèn ảnh biểu mẫu thêm/sửa có đủ ảnh, tên, giá và số lượng.', 2050),

  h('7. Thiết kế giao diện và chức năng nâng cao'),
  p('Tên ứng dụng Kho hàng; bảng màu xanh ngọc, xanh đậm, nền sáng. Màn hình tập trung vào ảnh sản phẩm và thông tin kho. Desktop có thanh điều hướng và bảng; màn hình nhỏ dùng thẻ sản phẩm, cùng bộ thao tác.'),
  table(['Chức năng', 'Cách hoạt động'], [
    ['Tìm kiếm', 'So khớp tên, mã sản phẩm hoặc UID, không phân biệt hoa/thường.'],
    ['Sắp xếp', 'Tên A–Z, giá tăng/giảm, số lượng tăng, UID chủ sở hữu.'],
    ['Lọc tồn kho', 'Tất cả; hết hàng (0); sắp hết (1–5).'],
    ['Nhóm chủ sở hữu', 'Quản lý bật/tắt nhóm UID hoặc chọn một UID cụ thể.'],
    ['Thống kê', 'Đếm sản phẩm, tổng số lượng và giá trị tồn kho của kết quả đang hiển thị.'],
    ['Phạm vi quản lý', 'Tất cả hoặc Của tôi; dữ liệu và JSON tuân theo phạm vi này.'],
  ], [2700, 6938]),
  p('Tìm kiếm, lọc và sắp xếp được xử lý sau khi tải dữ liệu, phù hợp dữ liệu học phần nhỏ. Sắp xếp áp dụng trong từng nhóm khi đang bật nhóm theo chủ sở hữu.'),
  ...imageSlot('Hình 6. Chèn ảnh Web có thống kê, bộ lọc và nhóm chủ sở hữu.', 2100),

  h('8. Nhận ảnh và hiển thị trên Android'),
  p('Android dùng cùng Firebase Auth và Firestore với Web. Người dùng đăng nhập, mở danh mục, thêm sản phẩm và bấm Chọn ảnh hoặc Chụp ảnh. Thư viện image_picker sử dụng bộ chọn ảnh/camera của hệ thống.'),
  p('Ảnh được yêu cầu thu nhỏ tối đa 960 × 960, chất lượng JPEG 75. Đây là gợi ý xử lý; ứng dụng vẫn kiểm tra số byte thực tế sau khi đọc. Nếu vượt 200 KiB, người dùng cần chọn ảnh nhỏ hơn. Chỉ chấp nhận PNG/JPEG.'),
  p('Ảnh xem trước xuất hiện trong biểu mẫu trước khi lưu. Hủy thao tác chọn ảnh giữ nguyên ảnh hiện tại. Khi lưu thành công, danh mục và trang chi tiết hiển thị ảnh từ dữ liệu Firestore.'),
  p('Ứng dụng có quyền INTERNET. Khi hệ thống yêu cầu quyền thư viện/camera, người dùng cấp quyền để tiếp tục. Nếu không đọc được ảnh hoặc camera không có sẵn, biểu mẫu hiển thị thông báo chọn ảnh khác.'),
  cmd('flutter devices'),
  cmd('flutter run -d MA_THIET_BI --dart-define-from-file=.env'),
  cmd('flutter build apk --release --dart-define-from-file=.env'),
  p('APK của cấu hình học phần hiện dùng khóa ký debug cho biến thể release. Nếu phát hành chính thức cần cấu hình khóa ký riêng. Việc chạy trên điện thoại và camera thực tế chưa được xác nhận trong lần bàn giao này.'),
  ...imageSlot('Hình 7. Chèn ảnh Android chọn/chụp ảnh và trang chi tiết sản phẩm.', 2200),

  h('9. Xuất dữ liệu và hoàn thiện bài nộp'),
  p('Bấm Xuất JSON trên Web để tải co_so_du_lieu_thuc_te.json. Chức năng tải toàn bộ sản phẩm trong phạm vi Tất cả hoặc Của tôi, không áp dụng bộ lọc hoặc từ khóa tìm kiếm. Quản lý chọn Tất cả trước khi xuất bản nộp tổng hợp.'),
  p('Trên Android, ứng dụng mở hộp thoại JSON và nút sao chép. Dán nội dung vào trình soạn thảo rồi lưu UTF-8. File xuất dùng cấu trúc owners → UID → products → productId → bốn trường sản phẩm.'),
  table(['Tệp bàn giao', 'Việc cần hoàn thiện'], [
    ['bao_cao_quan_ly_san_pham.docx', 'Điền lớp, Project ID, ảnh thực tế và video.'],
    ['huong_dan_chuyen_firebase.docx', 'Thực hiện cấu hình và lệnh theo thứ tự.'],
    ['huong_dan_su_dung.docx', 'Tham khảo thao tác tài khoản thường và quản lý.'],
    ['db/co_so_du_lieu.json; db/db.json', 'JSON mẫu, UID giả; có ảnh base64 đầy đủ.'],
    ['co_so_du_lieu_thuc_te.json', 'Xuất từ app sau demo để nộp CSDL thực tế.'],
    ['GitHub và video', 'Đẩy mã nguồn đã hoàn thiện; tự quay video thao tác Web/Android.'],
  ], [4300, 5338]),
  p('JSON ứng dụng là bản xuất phục vụ bài nộp, không phải định dạng backup/import gốc của Cloud Firestore. Không dùng firebase database:import vì lệnh đó dành cho Realtime Database.'),
  ...imageSlot('Hình 8. Chèn ảnh file JSON thực tế và thư mục bài nộp.', 1500),

  h('10. Trạng thái bàn giao, giới hạn và tài liệu tham khảo'),
  p('Đã thay chức năng quản lý hồ sơ bằng quản lý sản phẩm, cập nhật giao diện, phân quyền, file mẫu và hướng dẫn cấu hình dự án mới. Dự án Firebase mới chưa được kết nối hoặc deploy từ phiên làm việc này vì chưa có Project ID và UID quản lý được cung cấp.'),
  p('Theo yêu cầu, không tạo hoặc chạy kiểm thử. Phân tích tĩnh chỉ xác nhận vấn đề mã nguồn mà analyzer có thể phát hiện; không thay thế việc đăng nhập, phân quyền và nhận ảnh trên Firebase/Android thật. Các khung ảnh trong tài liệu đang chờ ảnh chụp sau khi cấu hình.'),
  p('Giới hạn: dữ liệu danh mục được tải toàn bộ, chưa phân trang; ảnh base64 làm tăng dung lượng đọc/ghi; nhóm chủ sở hữu chỉ hiển thị UID; chưa có lịch sử thay đổi hoặc chuyển chủ sở hữu. Dùng dữ liệu học phần nhỏ và theo dõi hạn mức Firebase của dự án.'),
  p('Hướng phát triển: phân trang, tìm kiếm phía server, phân quyền động và kho ảnh riêng nếu yêu cầu tương lai cho phép thay đổi mô hình bốn trường.'),
  source('Firebase cho Flutter', 'https://firebase.google.com/docs/flutter/setup'),
  source('Security Rules và truy vấn', 'https://firebase.google.com/docs/firestore/security/rules-query'),
  source('Firestore Security Rules', 'https://firebase.google.com/docs/firestore/security/get-started'),
  source('image_picker', 'https://pub.dev/packages/image_picker'),
  source('Mã nguồn dự án', github),
];

const firebaseGuide = [
  h('HƯỚNG DẪN CHUYỂN SANG FIREBASE MỚI', true),
  p('Ứng dụng Kho hàng – Web và Android. Các lệnh dưới đây dùng PowerShell. Làm theo từng bước; thay chuỗi ví dụ bằng thông tin dự án thật. Không cần chuyển dữ liệu hồ sơ cũ vì mô hình mới quản lý sản phẩm.'),
  sub('1. Xác định dự án mới và chuẩn bị công cụ'),
  p('Mở Firebase Console → Project settings → General, ghi lại Project ID và Project number. Project ID khác với tên hiển thị. Chỉ thao tác trên dự án mới đã tạo.'),
  cmd('Set-Location D:\\Projects\\flutter\\midterm'),
  cmd('$FirebaseProject = "PROJECT_ID_MOI_CUA_BAN"'),
  cmd('flutter pub get'),
  cmd('npm install -g firebase-tools'),
  cmd('firebase login'),
  cmd('firebase projects:list'),
  p('Đối chiếu Project ID trong danh sách với biến $FirebaseProject. Mỗi lệnh deploy bên dưới truyền --project rõ ràng, không phụ thuộc dự án mặc định hoặc alias cũ.'),
  table(['Thông tin cần có', 'Nơi lấy'], [
    ['Project ID / Project number', 'Project settings → General'],
    ['Web App ID / API key / authDomain', 'General → Your apps → Web app → SDK setup and configuration'],
    ['Android App ID / API key', 'Android app → google-services.json'],
    ['UID quản lý', 'Authentication → Users → mở tài khoản quản lý'],
  ], [3200, 6438]),

  h('2. Bật Authentication và tạo Firestore'),
  p('Trong Firebase Console của dự án mới, mở Build → Authentication → Get started → Sign-in method. Bật Email/Password và lưu. Email link không bắt buộc.'),
  p('Mở Build → Firestore Database → Create database. Chọn Cloud Firestore Standard / Native mode nếu Console yêu cầu loại database. Tạo database mặc định (default), chọn vị trí phù hợp và chế độ production. Giữ cơ chế khóa mặc định cho đến khi deploy Rules của dự án.'),
  p('Ở Authentication → Settings → Authorized domains, thêm localhost nếu chưa có để chạy Web cục bộ. Sau khi đưa Web lên tên miền khác, thêm đúng tên miền đó. Không nhập cả đường dẫn hoặc cổng vào tên miền được cho phép.'),
  p('Ở Authentication → Users → Add user, tạo một tài khoản quản lý với email/mật khẩu. Sao chép UID của tài khoản này để dùng ở bước 5. Có thể tạo thêm hai tài khoản thường để demo quyền sở hữu.'),
  p('Firebase Auth và Firestore là hai dịch vụ riêng. Tạo tài khoản Auth không tạo document sản phẩm. Khi người dùng thêm hàng, subcollection products được tạo tự động.'),
  ...imageSlot('Ảnh A. Chèn ảnh Email/Password đã bật và danh sách tài khoản mới.', 1850),
  ...imageSlot('Ảnh B. Chèn ảnh database Firestore mới.', 1500),

  h('3. Đăng ký Web app và Android app'),
  sub('Web app'),
  p('Project settings → General → Your apps → biểu tượng Web (</>). Nhập tên Kho hàng Web và đăng ký. Hosting có thể cấu hình sau. Trong SDK setup, lấy apiKey, appId, messagingSenderId, projectId và authDomain.'),
  sub('Android app'),
  p('Cùng trang Your apps → Add app → Android. Nhập package chính xác: com.vincent.midterm. Tên hiển thị tùy chọn; SHA-1 chưa bắt buộc cho Email/Password. Đăng ký app và tải google-services.json.'),
  p('Chép file mới vào android/app/google-services.json, thay file thuộc dự án cũ. Giữ nguyên applicationId và namespace hiện có trong android/app/build.gradle.kts. Không dán API key vào source Kotlin hoặc Dart.'),
  table(['Trong google-services.json', 'Biến .env tương ứng'], [
    ['project_info.project_id', 'FIREBASE_PROJECT_ID'],
    ['project_info.project_number', 'FIREBASE_MESSAGING_SENDER_ID'],
    ['client đúng package → client_info.mobilesdk_app_id', 'FIREBASE_ANDROID_APP_ID'],
    ['client đúng package → api_key.current_key', 'FIREBASE_ANDROID_API_KEY'],
  ], [5400, 4238]),
  p('File google-services.json được Git bỏ qua. Mỗi người clone dự án cần tự tải file đúng app từ Console. Cấu hình Web và Android phải cùng Project ID.'),
  ...imageSlot('Ảnh C. Chèn ảnh Web app và Android app thuộc dự án mới.', 1550),

  h('4. Điền cấu hình .env cho mã nguồn hiện tại'),
  p('Cách A này giữ nguyên lib/firebase_options.dart hiện tại. Nếu đã có .env, sao lưu để không mất cấu hình cũ; chỉ chạy lệnh sao chép sau khi đã sao lưu.'),
  cmd('Copy-Item .env .env.profile-backup -ErrorAction SilentlyContinue'),
  cmd('Copy-Item .env.example .env'),
  cmd('notepad .env'),
  p('Điền đủ bảy biến; không giữ lại giá trị THAY_ hoặc thông tin thuộc profile-management cũ. .env dùng định dạng KEY=VALUE, không thêm dấu ngoặc kép vào giá trị.'),
  table(['Biến', 'Giá trị lấy từ dự án mới'], [
    ['FIREBASE_PROJECT_ID', 'Project ID'], ['FIREBASE_MESSAGING_SENDER_ID', 'Project number / messagingSenderId'],
    ['FIREBASE_AUTH_DOMAIN', 'authDomain của Web app'], ['FIREBASE_WEB_API_KEY', 'apiKey của Web app'],
    ['FIREBASE_WEB_APP_ID', 'appId của Web app'], ['FIREBASE_ANDROID_API_KEY', 'current_key của Android app'],
    ['FIREBASE_ANDROID_APP_ID', 'mobilesdk_app_id của Android app'],
  ], [4600, 5038]),
  p('Các giá trị Firebase client là cấu hình định danh ứng dụng. Không đặt khóa service account hoặc private key vào .env. Quyền truy cập sản phẩm được kiểm soát bằng Authentication và Security Rules.'),
  p('Sau khi đổi .env hoặc google-services.json, dừng app rồi chạy lại hoàn toàn. Hot reload không nạp lại hằng String.fromEnvironment.'),

  h('5. Cấp quyền quản lý và triển khai Rules'),
  p('Mở firestore.rules, tìm hàm manager() và thay THAY_UID_QUAN_LY bằng UID vừa sao chép từ Authentication của dự án mới. Giữ dấu nháy quanh UID.'),
  cmd('notepad firestore.rules'),
  cmd("return signedIn() && request.auth.uid in ['UID_QUAN_LY_THAT'];"),
  p('Nếu có nhiều người quản lý, thêm các UID vào danh sách, phân cách bằng dấu phẩy. Không dùng email, không dùng UID từ dự án cũ và không thêm trường role vào sản phẩm.'),
  cmd('firebase deploy --only firestore --project=$FirebaseProject'),
  p('Lệnh trên triển khai firestore.rules và cấu hình firestore.indexes.json. Ảnh bị loại khỏi chỉ mục; tìm kiếm và sắp xếp đang chạy phía client nên không cần composite index.'),
  p('Sau deploy, đăng nhập lại hoặc bấm biểu tượng làm mới quyền truy cập trên thanh trên cùng. Tài khoản quản lý sẽ có hai lựa chọn Tất cả và Của tôi. Nếu chỉ có kho cá nhân, kiểm tra UID và dự án vừa deploy.'),
  p('Rules cho người dùng thao tác đường dẫn sở hữu; quản lý được đọc collection group và sửa/xóa mọi sản phẩm. Cả hai chỉ ghi document đúng bốn trường. Các document khác không được cấp quyền ghi.'),
  ...imageSlot('Ảnh D. Chèn ảnh UID quản lý, Rules và thông báo deploy thành công.', 1950),

  h('6. Chạy ứng dụng, tạo sản phẩm và xuất CSDL'),
  cmd('flutter run -d chrome --dart-define-from-file=.env'),
  p('Đăng nhập bằng tài khoản quản lý đã tạo trên Console. Đăng ký tài khoản thường bằng liên kết Đăng ký ở trang đăng nhập. Thêm sản phẩm của từng tài khoản để có dữ liệu nhiều chủ sở hữu.'),
  cmd('flutter devices'),
  cmd('flutter run -d MA_THIET_BI --dart-define-from-file=.env'),
  p('Thay MA_THIET_BI bằng mã Android trong flutter devices. Dùng ảnh PNG/JPEG dưới 200 KiB. Android có cả Chọn ảnh và Chụp ảnh; Web có bộ chọn file.'),
  p('Trong Firestore Console, các document hiển thị dưới owners → UID → products → productId. Document owners/UID có thể hiện dạng document cha không có dữ liệu; không cần thêm trường để tạo document cha.'),
  p('Trên Web, tài khoản quản lý chọn Tất cả → Xuất JSON. Trình duyệt tải co_so_du_lieu_thuc_te.json. JSON này chứa dữ liệu thật để nộp; file db/co_so_du_lieu.json chỉ là ví dụ và không tự được nhập vào Firestore.'),
  sub('Build khi cần bàn giao'),
  cmd('flutter build web --dart-define-from-file=.env'),
  cmd('flutter build apk --release --dart-define-from-file=.env'),
  p('Đầu ra: build/web và build/app/outputs/flutter-apk/app-release.apk. Các lệnh build ở đây để người thực hiện chạy sau cấu hình, không phải kết quả đã được xác nhận trong báo cáo.'),
  sub('Hosting tùy chọn'),
  cmd('firebase deploy --only hosting --project=$FirebaseProject'),
  p('Chỉ chạy sau khi đã build Web. firebase.json đã trỏ Hosting tới build/web. Thêm tên miền Hosting vào Authorized domains nếu chưa có.'),

  h('7. Lựa chọn B: dùng FlutterFire CLI thay cho .env'),
  p('Đây là lựa chọn thay thế bước 3–4, không bắt buộc. Công cụ chính thức đăng ký/đối chiếu app và sinh lib/firebase_options.dart. Sao lưu file cấu hình trước vì CLI sẽ ghi đè bản đọc .env.'),
  cmd('dart pub global activate flutterfire_cli'),
  cmd('Copy-Item lib/firebase_options.dart lib/firebase_options.dart.backup'),
  cmd('flutterfire configure --project=$FirebaseProject --platforms=web,android --android-package-name=com.vincent.midterm'),
  p('Nếu PowerShell chưa nhận flutterfire, thêm thư mục Dart Pub Cache/bin vào PATH rồi mở terminal mới, hoặc dùng lệnh thay thế:'),
  cmd('dart pub global run flutterfire_cli:flutterfire configure --project=$FirebaseProject --platforms=web,android --android-package-name=com.vincent.midterm'),
  p('Khi được hỏi tái sử dụng cấu hình Firebase hiện có, luôn đối chiếu và chọn dự án mới. Kiểm tra file được sinh có projectId chính xác và google-services.json mới đã nằm đúng chỗ. Sau cấu hình, vẫn cần bước 2 và 5 để bật dịch vụ, cấp quyền và deploy Rules.'),
  p('Nếu dùng file Dart do FlutterFire sinh trực tiếp, cấu hình đã nằm trong file đó; chạy không cần --dart-define-from-file=.env. Không trộn cấu hình của hai dự án. Lựa chọn A vẫn là cách dùng .env đi kèm mã nguồn bàn giao.'),
  cmd('flutter run -d chrome'),
  p('Chưa có thao tác chuyển tài khoản Auth cũ hoặc dữ liệu users cũ tự động. Với đề tài mới, tạo tài khoản/sản phẩm mới. Nếu cần giữ danh tính cũ, phải lập quy trình xuất/nhập Auth và ánh xạ UID riêng.'),
  source('Hướng dẫn FlutterFire chính thức', 'https://firebase.google.com/docs/flutter/setup'),

  h('8. Xử lý lỗi thường gặp và hoàn thiện tài liệu'),
  table(['Hiện tượng', 'Cách xử lý'], [
    ['Chưa kết nối được Firebase', 'Điền đủ .env; kiểm tra appId, Project ID và cờ dart-define; dừng/chạy lại app.'],
    ['operation-not-allowed', 'Bật Email/Password trong Authentication của dự án mới.'],
    ['No matching client found for package name', 'Tải google-services.json cho package com.vincent.midterm.'],
    ['permission-denied khi tải sản phẩm', 'Deploy Rules đúng Project ID; kiểm tra UID đang đăng nhập và đường dẫn owner.'],
    ['Quản lý chỉ thấy Của tôi', 'Thay đúng UID trong manager(), deploy lại rồi làm mới quyền.'],
    ['Không thể xác định quyền khi mất mạng', 'Kết nối mạng và bấm Thử lại; kiểm tra quyền cần phản hồi server.'],
    ['Ảnh bị từ chối', 'Chọn PNG/JPEG hợp lệ, nhỏ hơn 200 KiB; ảnh HEIC/GIF/WebP chưa hỗ trợ.'],
    ['JSON mẫu không xuất hiện trong Console', 'JSON không được tự nhập; tạo sản phẩm bằng app hoặc nhập từng document đúng bốn trường.'],
  ], [3500, 6138]),
  p('Sau khi cấu hình và demo: chụp ảnh Web, Android, CSDL, Rules và kết quả lệnh; thay các khung ảnh trong báo cáo. Điền liên kết video, Project ID và thông tin lớp. Theo yêu cầu của đợt chuyển đổi, không chạy kiểm thử tự động.'),
  source('Truy vấn và Security Rules', 'https://firebase.google.com/docs/firestore/security/rules-query'),
  source('Triển khai Security Rules', 'https://firebase.google.com/docs/firestore/security/get-started'),
];

const manual = [
  h('HƯỚNG DẪN SỬ DỤNG KHO HÀNG', true),
  p('Tài liệu dành cho người dùng và tài khoản quản lý. Ứng dụng cần được cấu hình Firebase theo huong_dan_chuyen_firebase.docx trước khi sử dụng.'),
  sub('1. Đăng ký, đăng nhập và đặt lại mật khẩu'),
  p('Mở ứng dụng → Chưa có tài khoản? Đăng ký → nhập email, mật khẩu và xác nhận mật khẩu → Tạo tài khoản. Mật khẩu từ 6 đến 128 ký tự. Đăng ký thành công mở danh mục sản phẩm cá nhân.'),
  p('Nếu đã có tài khoản, nhập email/mật khẩu rồi bấm Đăng nhập. Khi quên mật khẩu, nhập email trên màn hình đăng nhập rồi bấm Quên mật khẩu? và làm theo email nhận được.'),
  p('Tài khoản đăng ký mới mặc định là người dùng. Quản lý được cấp quyền bằng UID trong Firestore Rules bởi người cấu hình dự án. Không có lựa chọn tự cấp quyền quản lý trong ứng dụng.'),
  table(['Nút hoặc khu vực', 'Công dụng'], [
    ['Làm mới quyền truy cập', 'Kiểm tra lại quyền sau khi người cấu hình cập nhật Rules.'],
    ['Đăng xuất', 'Kết thúc phiên hiện tại, trở về trang đăng nhập.'],
    ['Email và UID', 'Nhận biết tài khoản và mã chủ sở hữu hiện tại.'],
  ], [3300, 6338]),
  ...imageSlot('Hình 1. Chèn ảnh trang đăng nhập và đăng ký.', 2100),

  h('2. Thêm, xem, sửa và xóa sản phẩm'),
  p('Thêm: bấm Thêm sản phẩm → Chọn ảnh hoặc Chụp ảnh trên Android → nhập tên, giá, số lượng → Lưu sản phẩm. Sản phẩm mới thuộc tài khoản đang đăng nhập.'),
  p('Ảnh: dùng PNG/JPEG, tối đa 200 KiB. Biểu mẫu hiển thị ảnh xem trước. Ảnh vượt giới hạn hoặc không đọc được sẽ có thông báo; chọn ảnh nhỏ hơn hoặc ảnh định dạng được hỗ trợ.'),
  p('Giá: nhập số VNĐ không có dấu phân cách hàng nghìn, ví dụ 125000 hoặc 125000,50. Số lượng phải là số nguyên từ 0 trở lên. Tên tối đa 120 ký tự.'),
  p('Xem: bấm sản phẩm hoặc biểu tượng xem chi tiết để xem ảnh lớn, tên, giá, số lượng, UID chủ sở hữu và mã sản phẩm.'),
  p('Sửa: bấm biểu tượng bút, cập nhật thông tin rồi Lưu sản phẩm. Xóa: bấm biểu tượng thùng rác và xác nhận tên sản phẩm. Xóa không thể hoàn tác.'),
  ...imageSlot('Hình 2. Chèn ảnh biểu mẫu sản phẩm trên Web.', 1750),
  ...imageSlot('Hình 3. Chèn ảnh chọn/chụp và xem sản phẩm trên Android.', 1750),

  h('3. Tìm kiếm, lọc và sử dụng tài khoản quản lý'),
  p('Ô tìm kiếm nhận tên, mã sản phẩm hoặc UID chủ sở hữu. Có thể chọn tên A–Z, giá tăng/giảm, số lượng tăng hoặc UID trong danh sách Sắp xếp.'),
  p('Bộ lọc Tình trạng có Tất cả, Hết hàng và Sắp hết (1–5). Số liệu thống kê được tính theo kết quả đang hiển thị. Giá trị tồn kho bằng tổng giá × số lượng.'),
  table(['Phạm vi / tùy chọn quản lý', 'Ý nghĩa'], [
    ['Tất cả', 'Hiển thị sản phẩm của mọi chủ sở hữu.'],
    ['Của tôi', 'Chỉ hiển thị sản phẩm thuộc UID của tài khoản hiện tại.'],
    ['Chủ sở hữu (UID)', 'Chọn một chủ sở hữu hoặc tất cả.'],
    ['Nhóm theo chủ sở hữu', 'Gộp sản phẩm theo UID; khi bật, sắp xếp được áp dụng trong từng nhóm.'],
    ['Sửa/xóa', 'Quản lý có thể thao tác sản phẩm của mọi tài khoản.'],
  ], [3200, 6438]),
  p('Quản lý thêm sản phẩm vào kho của chính mình. Chỉnh sửa sản phẩm của người khác giữ nguyên quyền sở hữu. Khi cần đối chiếu UID và email, dùng Authentication → Users trong Firebase Console.'),
  ...imageSlot('Hình 4. Chèn ảnh quản lý xem nhóm chủ sở hữu và bộ lọc.', 2100),

  h('4. Xuất JSON và chuẩn bị minh họa bài nộp'),
  p('Trên Web: chọn phạm vi phù hợp → Xuất JSON → lưu file co_so_du_lieu_thuc_te.json. Quản lý cần chọn Tất cả để xuất dữ liệu của toàn hệ thống.'),
  p('Trên Android: bấm Xuất JSON → Sao chép JSON → dán vào trình soạn thảo → lưu thành file UTF-8. Có thể dùng Web để tải file trực tiếp thuận tiện hơn.'),
  p('Xuất JSON luôn lấy toàn bộ phạm vi đang chọn, không phụ thuộc từ khóa, bộ lọc tồn kho hoặc UID đang lọc. File mẫu trong thư mục db không phải dữ liệu cloud mới.'),
  sub('Trình tự video minh họa gợi ý'),
  p('1. Đăng ký/đăng nhập tài khoản thường, thêm sản phẩm có hình ảnh và xem danh mục.'),
  p('2. Sửa giá/số lượng, mở chi tiết, xóa một sản phẩm có xác nhận.'),
  p('3. Đăng nhập quản lý, xem các nhóm UID, tìm kiếm, sắp xếp và lọc tồn kho.'),
  p('4. Mở Android, chọn hoặc chụp ảnh, lưu sản phẩm và hiển thị đồng bộ trên Web.'),
  p('5. Mở Firestore Console để chỉ rõ bốn trường; xuất JSON thực tế và cho xem file đã tải.'),
  p('Quy trình trên là gợi ý quay video sau cấu hình, không phải biên bản kiểm thử đã thực hiện. Bổ sung liên kết video và ảnh chụp vào báo cáo Word trước khi nộp.'),
  ...imageSlot('Hình 5. Chèn ảnh xuất JSON và file dữ liệu thực tế.', 1700),
];

async function writeDoc(filename, title, children) {
  const doc = new Document({ creator: 'Trần Thành Vinh', title, description: 'Tiếng Việt; Cambria; chữ đen, nền trắng',
    background: { color: 'FFFFFF' },
    styles: {
      default: {
        ...Object.fromEntries(['heading3', 'heading4', 'heading5', 'heading6', 'caption', 'hyperlink'].map(name =>
          [name, { run: { font: 'Cambria', color: '000000' } }])),
        document: { run: { font: 'Cambria', size: 26, color: '000000', language: { value: 'vi-VN' } },
        paragraph: { spacing: { after: 140, line: 300 } } } },
      paragraphStyles: [
        { id: 'Normal', name: 'Normal', run: { font: 'Cambria', size: 26, color: '000000' } },
        { id: 'Heading1', name: 'heading 1', basedOn: 'Normal', next: 'Normal', quickFormat: true,
          run: { font: 'Cambria', size: 34, bold: true, color: '000000' }, paragraph: { outlineLevel: 0, keepNext: true } },
        { id: 'Heading2', name: 'heading 2', basedOn: 'Normal', next: 'Normal', quickFormat: true,
          run: { font: 'Cambria', size: 28, bold: true, color: '000000' }, paragraph: { outlineLevel: 1, keepNext: true } },
      ],
    },
    sections: [{ properties: { page: { size: { width: 11906, height: 16838 },
      margin: { top: 1134, bottom: 1134, left: 1134, right: 1134, header: 500, footer: 500 } } },
      headers: { default: new Header({ children: [p('Kho hàng | Quản lý sản phẩm trên Web và Android', { spacing: { after: 0 } })] }) },
      footers: { default: new Footer({ children: [new Paragraph({ alignment: AlignmentType.RIGHT,
        children: [run('Trang ', { size: 22 }), new TextRun({ children: [PageNumber.CURRENT], font: 'Cambria', color: '000000', size: 22 })] })] }) },
      children,
    }],
  });
  const output = path.join(root, 'docs', filename);
  fs.mkdirSync(path.dirname(output), { recursive: true });
  fs.writeFileSync(output, await Packer.toBuffer(doc));
  console.log(path.relative(root, output));
}

(async () => {
  await writeDoc('bao_cao_quan_ly_san_pham.docx', 'Báo cáo giữa kỳ – Quản lý sản phẩm', report);
  await writeDoc('huong_dan_chuyen_firebase.docx', 'Hướng dẫn chuyển Firebase mới', firebaseGuide);
  await writeDoc('huong_dan_su_dung.docx', 'Hướng dẫn sử dụng Kho hàng', manual);
})().catch(error => { console.error(error); process.exitCode = 1; });
