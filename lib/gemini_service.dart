import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

import 'product_repo.dart';

class GeminiService {
  static const String _envApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _fallbackFirebaseKey = String.fromEnvironment('FIREBASE_WEB_API_KEY');

  static String _runtimeKey = '';

  static void setRuntimeApiKey(String key) {
    _runtimeKey = key.trim();
  }

  static String get apiKey {
    if (_runtimeKey.isNotEmpty) return _runtimeKey;
    if (_envApiKey.isNotEmpty) return _envApiKey;
    return _fallbackFirebaseKey;
  }

  static bool get hasApiKey => apiKey.isNotEmpty && !apiKey.startsWith('THAY_');

  // Gọi REST API của Gemini (thử gemini-1.5-flash hoặc gemini-2.0-flash)
  static Future<String> generateText(String prompt, {int maxTokens = 1200}) async {
    final key = apiKey;
    if (key.isEmpty || key.startsWith('THAY_')) {
      throw StateError('Chưa cấu hình GEMINI_API_KEY trong .env hoặc cài đặt ứng dụng.');
    }

    final models = ['gemini-1.5-flash', 'gemini-2.0-flash', 'gemini-1.5-pro'];
    Exception? lastError;

    for (final model in models) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key',
        );

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.7,
              'maxOutputTokens': maxTokens,
            }
          }),
        ).timeout(const Duration(seconds: 20));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'] as Map<String, dynamic>?;
            final parts = content?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final text = parts[0]['text'] as String?;
              if (text != null && text.trim().isNotEmpty) {
                return text.trim();
              }
            }
          }
          throw Exception('Gemini không trả về nội dung hợp lệ.');
        } else {
          final errorBody = response.body;
          lastError = Exception('Gemini API [$model] lỗi ${response.statusCode}: $errorBody');
        }
      } catch (e) {
        lastError = Exception(e.toString());
      }
    }

    throw lastError ?? Exception('Không thể kết nối đến dịch vụ Gemini AI.');
  }

  // 1. Tóm tắt & Đánh giá tồn kho học thuật (Academic Stock Summary)
  static Future<String> summarizeStock(List<Product> products) async {
    final totalCount = products.length;
    final totalUnits = products.fold<int>(0, (sum, p) => sum + p.quantity);
    final totalValuation = products.fold<double>(0, (sum, p) => sum + p.price * p.quantity);
    final outOfStock = products.where((p) => p.quantity == 0).map((p) => p.name).toList();
    final lowStock = products.where((p) => p.quantity > 0 && p.quantity <= 5).map((p) => '${p.name} (còn ${p.quantity})').toList();

    if (products.isEmpty) {
      return '### Báo Cáo Tồn Kho Học Thuật\n'
          '*Dữ liệu ghi nhận: Kho hiện chưa có sản phẩm nào.*\n\n'
          '- **Trạng thái:** Cơ sở dữ liệu trống.\n'
          '- **Khuyến nghị:** Bắt đầu khởi tạo các mã danh mục và nhập lô hàng đầu tiên để hệ thống tiến hành kiểm kê và dự báo.';
    }

    final catalogOverview = products.take(15).map((p) => '- ${p.name}: ${p.quantity} cái, giá: ${p.price.toStringAsFixed(0)} đ').join('\n');

    final prompt = '''
Bạn là một chuyên gia phân tích chuỗi cung ứng và quản lý kho học thuật theo phong cách Academic Minimalism (chặt chẽ, tinh giản, súc tích, khách quan).
Hãy phân tích dữ liệu kho hàng sau và viết bản tóm tắt học thuật bằng tiếng Việt:

Số liệu tổng quan:
- Tổng số mặt hàng (SKU): $totalCount
- Tổng số đơn vị sản phẩm: $totalUnits
- Tổng giá trị định giá tồn kho: ${totalValuation.toStringAsFixed(0)} VND
- Sản phẩm đã hết hàng (${outOfStock.length}): ${outOfStock.join(', ')}
- Sản phẩm sắp hết hàng (1-5 cái) (${lowStock.length}): ${lowStock.join(', ')}

Mẫu một số mặt hàng:
$catalogOverview

Yêu cầu định dạng theo phong cách học thuật tối giản, rõ ràng:
1. ĐÁNH GIÁ CHỈ SỐ THANH KHOẢN & SỨC KHỎE KHO (Executive Summary)
2. CẢNH BÁO NGUY CƠ ĐỨT GÃY NGUỒN CUNG (Stockout & Supply Risks)
3. PHÂN BỔ TÀI SẢN & DANH MỤC TRỌNG TÂM (Valuation & Asset Concentration)
4. ĐỀ XUẤT ĐIỀU PHỐI & TÁI ĐẶT HÀNG (Actionable Directives)

Không dùng lời chào thừa thãi, đi thẳng vào các luận điểm súc tích.
''';

    try {
      if (hasApiKey) {
        return await generateText(prompt, maxTokens: 1000);
      }
    } catch (_) {
      // Fallback xuống phân tích nội bộ nếu mạng lỗi hoặc chưa có key
    }

    return _generateLocalStockSummary(
      totalCount: totalCount,
      totalUnits: totalUnits,
      totalValuation: totalValuation,
      outOfStock: outOfStock,
      lowStock: lowStock,
    );
  }

  static String _generateLocalStockSummary({
    required int totalCount,
    required int totalUnits,
    required double totalValuation,
    required List<String> outOfStock,
    required List<String> lowStock,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('### Báo Cáo Học Thuật: Phân Tích Hiện Trạng Tồn Kho\n');
    buffer.writeln('#### I. ĐÁNH GIÁ CHỈ SỐ THANH KHOẢN');
    buffer.writeln('- **Quy mô danh mục:** $totalCount SKU với tổng lưu lượng $totalUnits đơn vị sản phẩm.');
    buffer.writeln('- **Tổng định giá tài sản kho:** ${totalValuation.toStringAsFixed(0)} VND.');
    buffer.writeln('- **Tỷ lệ sẵn sàng phục vụ:** ${(totalCount > 0 ? ((totalCount - outOfStock.length) / totalCount * 100).toStringAsFixed(1) : "0")}% SKU còn hàng.\n');

    buffer.writeln('#### II. CẢNH BÁO RỦI RO ĐỨT GÃY NGUỒN CUNG');
    if (outOfStock.isNotEmpty) {
      buffer.writeln('- **Mặt hàng kiệt kho (Cấp bách):** ${outOfStock.join(", ")}.');
    } else {
      buffer.writeln('- **Mặt hàng kiệt kho:** Không ghi nhận tình trạng đứt hàng hoàn toàn.');
    }
    if (lowStock.isNotEmpty) {
      buffer.writeln('- **Ngưỡng tiệm cận nguy hiểm (1–5 đơn vị):** ${lowStock.join(", ")}.');
    } else {
      buffer.writeln('- **Mức đệm an toàn:** Không có mặt hàng trong vùng báo động đỏ.');
    }
    buffer.writeln();

    buffer.writeln('#### III. ĐỀ XUẤT ĐIỀU PHỐI VẬT TƯ');
    buffer.writeln('- Thực hiện đơn đặt hàng bổ sung ngay đối với ${outOfStock.length + lowStock.length} danh mục có nguy cơ thiếu hụt.');
    buffer.writeln('- Tối ưu hóa chu kỳ quay vòng vốn đối với nhóm sản phẩm có tỷ trọng vốn lưu động cao.');
    if (!hasApiKey) {
      buffer.writeln('\n*(Lưu ý: Báo cáo tính toán tự động bằng thuật toán thống kê nội bộ. Thêm GEMINI_API_KEY để kích hoạt suy luận nâng cao của Gemini AI.)*');
    }
    return buffer.toString();
  }

  // 2. Gợi ý mật khẩu mạnh bằng AI (Strong Password Suggestion)
  static Future<PasswordSuggestion> suggestStrongPassword({String userEmail = ''}) async {
    final prompt = '''
Bạn là chuyên gia an toàn thông tin mật mã học thuật.
Hãy tạo 1 mật khẩu cực kỳ an toàn, entropy cao (kết hợp chữ hoa, chữ thường, số, ký tự đặc biệt, độ dài 14-16 ký tự, dễ ghi nhớ theo quy tắc hoặc cụm từ học thuật).
Định dạng đầu ra CHỈ là JSON thuần túy (không kèm markdown ```json):
{
  "password": "Mật khẩu gợi ý ở đây",
  "entropy": "Mức entropy (VD: 94 bit)",
  "strength": "Cực kỳ mạnh",
  "explanation": "Giải thích ngắn gọn lý do an toàn và mẹo ghi nhớ cho người dùng $userEmail"
}
''';

    try {
      if (hasApiKey) {
        final raw = await generateText(prompt, maxTokens: 400);
        final clean = raw.replaceAll(RegExp(r'^```json\s*|^```\s*|```$', multiLine: true), '').trim();
        final map = jsonDecode(clean) as Map<String, dynamic>;
        return PasswordSuggestion(
          password: map['password'] as String? ?? _generateLocalSecurePassword(),
          entropy: map['entropy'] as String? ?? '90+ bits',
          strength: map['strength'] as String? ?? 'Rất mạnh',
          explanation: map['explanation'] as String? ?? 'Mật khẩu độ dài cao, phối hợp đa dạng tập ký tự phòng thủ trước kỹ thuật Brute-force và Dictionary Attack.',
        );
      }
    } catch (_) {
      // Fallback
    }

    final localPass = _generateLocalSecurePassword();
    return PasswordSuggestion(
      password: localPass,
      entropy: '92 bits (Ước tính)',
      strength: 'Rất mạnh (Tiêu chuẩn học thuật)',
      explanation: 'Mật khẩu 16 ký tự gồm tập hợp chữ hoa, thường, số và ký tự đặc biệt được sinh ngẫu nhiên bằng bộ tạo số giả ngẫu nhiên mật mã (CSPRNG).',
    );
  }

  static String _generateLocalSecurePassword() {
    const upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    const lower = 'abcdefghijkmnopqrstuvwxyz';
    const numbers = '23456789';
    const symbols = '!@#\$%^&*-_=+';
    final random = Random.secure();

    final chars = <String>[
      upper[random.nextInt(upper.length)],
      lower[random.nextInt(lower.length)],
      numbers[random.nextInt(numbers.length)],
      symbols[random.nextInt(symbols.length)],
    ];

    const all = upper + lower + numbers + symbols;
    for (var i = 0; i < 12; i++) {
      chars.add(all[random.nextInt(all.length)]);
    }
    chars.shuffle(random);
    return chars.join();
  }

  // 3. Sinh ảnh đại diện / Huy hiệu học thuật cá nhân hóa (Academic Minimalist SVG Avatar)
  static Future<String> generateAvatarSvg({
    required String email,
    String discipline = 'Khoa học & Quản trị',
  }) async {
    final initials = _extractInitials(email);
    final prompt = '''
Bạn là nhà thiết kế huy hiệu học thuật tối giản (Academic Minimalist Seal / Crest Designer).
Hãy tạo mã SVG hoàn chỉnh cho huy hiệu đại diện cá nhân của học giả/người dùng "$email".
Chuyên ngành/Chủ đề: "$discipline".
Ký tự viết tắt: "$initials".

Yêu cầu kỹ thuật:
- Kích thước viewBox="0 0 200 200".
- Phong cách: Academic Minimalism, sang trọng, màu xanh lá cây học thuật (#1B4332, #2D5A27, #406A52, #E2EFE5, #FFFFFF).
- Bao gồm đường viền tròn kép hoặc lục giác học thuật tinh tế (double ring / academic crest border), biểu tượng học thuật tối giản (ngọn đuốc, sách, cán cân, la bàn, tinh thể hoặc khối hình học trang nhã), và chữ lồng "$initials" nổi bật ở trung tâm.
- Định dạng CHỈ là mã SVG hợp lệ bắt đầu bằng <svg và kết thúc bằng </svg>, không kèm bất kỳ văn bản giải thích hay markdown code blocks nào.
''';

    try {
      if (hasApiKey) {
        final raw = await generateText(prompt, maxTokens: 900);
        final cleanSvg = _extractSvg(raw);
        if (cleanSvg.isNotEmpty) {
          return cleanSvg;
        }
      }
    } catch (_) {
      // Fallback
    }

    return generateLocalAcademicSvg(initials: initials, email: email);
  }

  static String _extractInitials(String email) {
    final clean = email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (clean.isEmpty) return 'K';
    if (clean.length == 1) return clean.toUpperCase();
    return (clean[0] + clean[clean.length ~/ 2]).toUpperCase();
  }

  static String _extractSvg(String raw) {
    final startIndex = raw.indexOf('<svg');
    final endIndex = raw.lastIndexOf('</svg>');
    if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
      return raw.substring(startIndex, endIndex + 6);
    }
    return '';
  }

  static String generateLocalAcademicSvg({required String initials, required String email}) {
    final seed = email.hashCode.abs();
    final hue1 = (seed % 30) + 145; // dải xanh học thuật 145 - 175
    return '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" width="200" height="200">
  <defs>
    <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="hsl($hue1, 45%, 22%)"/>
      <stop offset="100%" stop-color="hsl(${hue1 + 10}, 50%, 15%)"/>
    </linearGradient>
  </defs>
  <!-- Vòng tròn nền học thuật -->
  <circle cx="100" cy="100" r="92" fill="url(#grad)" stroke="#E2EFE5" stroke-width="3"/>
  <circle cx="100" cy="100" r="82" fill="none" stroke="#E2EFE5" stroke-width="1.2" stroke-dasharray="4,4"/>
  <circle cx="100" cy="100" r="74" fill="none" stroke="#DCE3DC" stroke-width="0.8"/>

  <!-- Họa tiết học thuật tinh giản -->
  <polygon points="100,32 110,48 100,44 90,48" fill="#E2EFE5" opacity="0.9"/>
  <polygon points="100,168 110,152 100,156 90,152" fill="#E2EFE5" opacity="0.9"/>

  <!-- Chữ lồng danh dự -->
  <text x="100" y="112" font-family="Georgia, serif" font-size="44" font-weight="bold" fill="#FFFFFF" text-anchor="middle" letter-spacing="2">
    $initials
  </text>
  <text x="100" y="136" font-family="'Courier New', monospace" font-size="9" fill="#E2EFE5" text-anchor="middle" letter-spacing="3" opacity="0.85">
    ACADEMIC
  </text>
</svg>
''';
  }
}

class PasswordSuggestion {
  const PasswordSuggestion({
    required this.password,
    required this.entropy,
    required this.strength,
    required this.explanation,
  });

  final String password;
  final String entropy;
  final String strength;
  final String explanation;
}
