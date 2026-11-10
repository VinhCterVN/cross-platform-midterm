import 'package:flutter/material.dart';

const academicNavy = Color(0xFF172D42);
const academicIvory = Color(0xFFF7F4ED);
const academicBrass = Color(0xFFA16F36);
const academicSlate = Color(0xFF5B6975);
const academicLine = Color(0xFFDEDCD4);

TextStyle academicHeading(double size, {Color color = academicNavy}) =>
    TextStyle(
      fontFamily: 'Georgia',
      fontFamilyFallback: const ['Times New Roman', 'serif'],
      fontSize: size,
      height: 1.18,
      fontWeight: FontWeight.w500,
      color: color,
    );

ThemeData academicTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: academicNavy,
        brightness: Brightness.light,
      ).copyWith(
        primary: academicNavy,
        secondary: academicBrass,
        surface: Colors.white,
        onSurface: academicNavy,
        outline: academicSlate,
        outlineVariant: academicLine,
      );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: academicLine),
  );
  return base.copyWith(
    scaffoldBackgroundColor: academicIvory,
    textTheme: base.textTheme.copyWith(
      headlineLarge: academicHeading(40),
      headlineMedium: academicHeading(32),
      headlineSmall: academicHeading(26),
      titleLarge: academicHeading(22),
      bodyLarge: const TextStyle(
        fontSize: 16,
        height: 1.6,
        color: academicNavy,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        height: 1.55,
        color: academicNavy,
      ),
      bodySmall: const TextStyle(
        fontSize: 12,
        height: 1.5,
        color: academicSlate,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: academicIvory,
      foregroundColor: academicNavy,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: academicHeading(23),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: academicBrass, width: 2),
      ),
      labelStyle: const TextStyle(color: academicSlate),
      floatingLabelStyle: const TextStyle(color: academicNavy),
      errorMaxLines: 3,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 50),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        side: const BorderSide(color: academicLine),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    dividerTheme: const DividerThemeData(color: academicLine, space: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: academicNavy,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

class AcademicBrand extends StatelessWidget {
  const AcademicBrand({super.key, this.light = false});
  final bool light;

  @override
  Widget build(BuildContext context) {
    final color = light ? academicIvory : academicNavy;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            border: Border.all(color: light ? Colors.white30 : academicLine),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.school_outlined, color: color, size: 28),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HỒ SƠ HỌC ĐƯỜNG',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Kết nối cộng đồng',
                style: TextStyle(
                  color: light ? Colors.white70 : academicSlate,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AcademicPanel extends StatelessWidget {
  const AcademicPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: academicLine),
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );
}
