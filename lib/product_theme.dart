import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Bảng màu Academic Minimalism (Xanh học thuật chủ đạo - Forest Green & Archival Paper)
const academicGreen = Color(0xFF1B4332); // Oxford Forest Green (Seed Color)
const greenSeed = academicGreen;
const teal = academicGreen; // Giữ bí danh tương thích
const canvas = Color(0xFFF7F9F6); // Giấy lưu trữ cổ điển (Archival Paper Ivory)
const ink = Color(0xFF121B14); // Mực học thuật đậm (Scholarly Carbon Ink)
const muted = Color(0xFF4D5E52); // Ghi xám rêu nhạt (Muted Sage)
const line = Color(0xFFDCE3DC); // Đường kẻ chuẩn xác 1px (Hairline Divider)
const sageWash = Color(0xFFE9F0EA); // Lớp phủ xanh thảo mộc mờ
const academicGold = Color(0xFF8A6D3B); // Điểm nhấn vàng đồng học thuật
const academicAmber = Color(0xFF7A5800);
const academicCrimson = Color(0xFF8C1D26);

ThemeData productTheme() {
  final serifHeadingStyle = GoogleFonts.newsreader(
    color: ink,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: academicGreen,
      primary: academicGreen,
      surface: Colors.white,
      surfaceContainerLowest: canvas,
      surfaceContainerLow: Colors.white,
      onPrimary: Colors.white,
      primaryContainer: sageWash,
      onPrimaryContainer: academicGreen,
      outline: line,
      outlineVariant: const Color(0xFFE8ECE7),
    ),
    scaffoldBackgroundColor: canvas,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: serifHeadingStyle.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
      shape: const Border(bottom: BorderSide(color: line, width: 1)),
    ),
    textTheme: TextTheme(
      headlineLarge: serifHeadingStyle.copyWith(fontSize: 26, height: 1.25),
      headlineMedium: serifHeadingStyle.copyWith(fontSize: 21, height: 1.25),
      headlineSmall: serifHeadingStyle.copyWith(fontSize: 18, height: 1.3),
      titleLarge: serifHeadingStyle.copyWith(fontSize: 16.5, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: ink),
      titleSmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3, color: muted),
      bodyLarge: GoogleFonts.inter(fontSize: 14, height: 1.5, color: ink),
      bodyMedium: GoogleFonts.inter(fontSize: 13, height: 1.45, color: ink),
      bodySmall: GoogleFonts.inter(fontSize: 11.5, height: 1.35, color: muted),
      labelLarge: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.2),
      labelSmall: GoogleFonts.jetBrainsMono(fontSize: 10, letterSpacing: 0.5, color: muted),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: line, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      labelStyle: GoogleFonts.inter(color: muted, fontSize: 13),
      floatingLabelStyle: GoogleFonts.inter(color: academicGreen, fontWeight: FontWeight.w600),
      hintStyle: GoogleFonts.inter(color: muted.withValues(alpha: 0.7), fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: line, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: line, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: academicGreen, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: academicCrimson, width: 1),
      ),
      errorMaxLines: 3,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: academicGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(40, 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: academicGreen,
        minimumSize: const Size(40, 40),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        side: const BorderSide(color: line, width: 1),
        textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: academicGreen,
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: ink,
      contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dividerTheme: const DividerThemeData(color: line, thickness: 1, space: 1),
    dataTableTheme: DataTableThemeData(
      headingRowColor: const WidgetStatePropertyAll(Color(0xFFF2F5F2)),
      headingTextStyle: GoogleFonts.newsreader(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: ink,
        letterSpacing: 0.2,
      ),
      dataTextStyle: GoogleFonts.inter(fontSize: 13, color: ink),
      dividerThickness: 1,
    ),
  );
}

// Logo & Brand học thuật tối giản (Academic Minimalist Emblem)
class ProductBrand extends StatelessWidget {
  const ProductBrand({super.key, this.light = false, this.showSubtitle = true});
  final bool light;
  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    final titleColor = light ? Colors.white : ink;
    final accentColor = light ? const Color(0xFFC8E6D3) : academicGreen;
    final subColor = light ? Colors.white70 : muted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: light ? Colors.white.withValues(alpha: 0.15) : sageWash,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: light ? Colors.white30 : line,
              width: 1,
            ),
          ),
          child: Icon(
            Icons.account_balance_outlined,
            size: 18,
            color: accentColor,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KHO HÀNG',
              style: GoogleFonts.newsreader(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: titleColor,
                letterSpacing: 0.5,
              ),
            ),
            if (showSubtitle)
              Text(
                'ACADEMIC INVENTORY',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: subColor,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// Thẻ định danh học thuật tối giản (Academic Badge / Pill Tag)
class AcademicBadge extends StatelessWidget {
  const AcademicBadge({
    super.key,
    required this.label,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
  });

  final String label;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? sageWash;
    final fg = textColor ?? academicGreen;
    final border = borderColor ?? line;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
