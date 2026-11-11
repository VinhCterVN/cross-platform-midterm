import 'package:flutter/material.dart';

const ink = Color(0xFF173438);
const teal = Color(0xFF087F75);
const canvas = Color(0xFFF3F7F7);
const muted = Color(0xFF52686C);
const line = Color(0xFFD8E5E4);

ThemeData productTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: teal, surface: Colors.white),
  scaffoldBackgroundColor: canvas,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: ink,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: ink, letterSpacing: -1),
    headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: ink),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: ink),
    bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: ink),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.all(16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: line),
    ),
    errorMaxLines: 3,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: teal,
      foregroundColor: Colors.white,
      minimumSize: const Size(48, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(48, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: ink),
  dividerTheme: const DividerThemeData(color: line),
);

class ProductBrand extends StatelessWidget {
  const ProductBrand({super.key, this.light = false});
  final bool light;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.inventory_2_outlined, size: 30, color: light ? Colors.white : teal),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          'Kho hàng',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: light ? Colors.white : ink),
        ),
      ),
    ],
  );
}
