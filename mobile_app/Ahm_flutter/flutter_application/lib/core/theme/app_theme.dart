import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const primary = Color(0xFF0EA5E9);
  static const bgLight = Color(0xFFF8FAFC);
  static const bgDark = Color(0xFF0F172A);
  static const cardDark = Color(0xFF1E293B);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: bgLight,
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: bgDark,
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
    );
  }
}
