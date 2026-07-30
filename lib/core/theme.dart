import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RooflixTheme {
  // Apple-inspired color palette
  static const Color background = Color(0xFFF2F2F7);
  static const Color surface = Colors.white;
  static const Color surfaceSecondary = Color(0xFFEFEFF4);
  static const Color primary = Color(0xFF0A84FF);       // iOS blue
  static const Color primaryDark = Color(0xFF0071E3);
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF6E6E73);
  static const Color textTertiary = Color(0xFFAEAEB2);
  static const Color separator = Color(0xFFD1D1D6);
  static const Color cardShadow = Color(0x14000000);
  static const Color focusRing = Color(0xFF0A84FF);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.light(
        primary: primary,
        surface: surface,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textTertiary,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
    );
  }

  // Card shadow decoration
  static BoxDecoration cardDecoration({bool focused = false}) {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: focused ? focusRing : Colors.transparent,
        width: focused ? 2.5 : 0,
      ),
      boxShadow: focused
          ? [
              BoxShadow(
                color: focusRing.withValues(alpha: 0.30),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: cardShadow,
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ]
          : [
              BoxShadow(
                color: cardShadow,
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
    );
  }
}
