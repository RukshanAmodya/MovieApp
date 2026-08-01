import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RooflixTheme {
  // Netflix Dark Theme Aesthetics
  static const Color background = Color(0xFF141414);
  static const Color surface = Color(0xFF181818);
  static const Color surfaceSecondary = Color(0xFF2F2F2F);
  static const Color surfaceGlass = Color(0xE6141414); // 90% dark glass

  // Netflix Signature Red focus accent
  static const Color primary = Color(0xFFE50914); // Netflix Red
  static const Color primaryDark = Color(0xFFB81D24);
  static const Color primaryLight = Color(0xFFFF3B30);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textMuted = Color(0xFF808080);
  static const Color separator = Color(0x1AFFFFFF); // 10% white border

  // Focus ring glow color for TV navigation
  static const Color focusRing = Color(0xFFE50914);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        surface: surface,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -0.6,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.4,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }

  // Netflix Style dynamic focus card decoration
  static BoxDecoration cardDecoration({bool focused = false}) {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: focused ? focusRing : Colors.transparent,
        width: focused ? 3.0 : 0,
      ),
      boxShadow: focused
          ? [
              BoxShadow(
                color: focusRing.withValues(alpha: 0.5),
                blurRadius: 28,
                spreadRadius: 3,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ]
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
    );
  }
}
