import 'package:flutter_test/flutter_test.dart';
import 'package:midterm/gemini_service.dart';
import 'package:midterm/product_repo.dart';
import 'package:midterm/product_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GeminiService Unit Tests', () {
    test('suggestStrongPassword generates high-entropy password', () async {
      final suggestion = await GeminiService.suggestStrongPassword(userEmail: 'scholar@university.edu');
      expect(suggestion.password.length, greaterThanOrEqualTo(14));
      expect(suggestion.strength.isNotEmpty, isTrue);
      expect(suggestion.explanation.isNotEmpty, isTrue);
    });

    test('generateLocalAcademicSvg generates valid SVG avatar', () {
      final svg = GeminiService.generateLocalAcademicSvg(
        initials: 'AB',
        email: 'alex.brown@oxford.edu',
      );
      expect(svg.startsWith('<svg'), isTrue);
      expect(svg.trimRight().endsWith('</svg>'), isTrue);
      expect(svg.contains('AB'), isTrue);
      expect(svg.contains('viewBox="0 0 200 200"'), isTrue);
    });

    test('summarizeStock generates structured academic summary', () async {
      const sample = [
        Product(
          id: 'item_1',
          ownerId: 'owner_a',
          name: 'Tập bài giảng Giải tích I',
          price: 85000,
          quantity: 2,
          image: '',
        ),
        Product(
          id: 'item_2',
          ownerId: 'owner_a',
          name: 'Hóa chất thí nghiệm chuẩn',
          price: 450000,
          quantity: 0,
          image: '',
        ),
      ];

      final summary = await GeminiService.summarizeStock(sample);
      expect(summary.contains('Báo Cáo Học Thuật') || summary.contains('Báo Cáo Tồn Kho'), isTrue);
      expect(summary.contains('Hóa chất thí nghiệm chuẩn'), isTrue);
      expect(summary.contains('THANH KHOẢN') || summary.contains('QUY MÔ'), isTrue);
    });
  });

  group('ProductTheme Tests', () {
    test('ThemeData uses academic green seed color and compact mobile typography', () {
      final theme = productTheme();
      expect(theme.colorScheme.primary, equals(academicGreen));
      expect(theme.scaffoldBackgroundColor, equals(canvas));
      expect(theme.textTheme.headlineLarge?.fontSize, lessThanOrEqualTo(26));
      expect(theme.textTheme.bodyMedium?.fontSize, lessThanOrEqualTo(13));
    });
  });
}
