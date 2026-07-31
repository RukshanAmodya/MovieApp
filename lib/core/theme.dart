import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RooflixTheme {
  // Apple TV Light Theme - Crisp, clean, minimalist high-contrast aesthetics
  static const Color background = Color(0xFFF2F2F7);
  static const Color surface = Colors.white;
  static const Color surfaceSecondary = Color(0xFFE5E5EA);
  static const Color surfaceGlass = Color(0xCCFFFFFF); // 80% frosted glass
  
  // Apple TV Blue / Indigo vibrant focus accent
  static const Color primary = Color(0xFF007AFF);       // Apple TV System Blue
  static const Color primaryDark = Color(0xFF0056B3);
  static const Color primaryLight = Color(0xFFE5F1FF);
  
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF3C3C43);
  static const Color textMuted = Color(0xFF8E8E93);
  static const Color separator = Color(0x1F000000);     // 12% black border
  
  // Focus ring glow color for TV navigation
  static const Color focusRing = Color(0xFF007AFF);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        surface: surface,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
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
          borderRadius: BorderRadius.circular(24),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }

  // Apple TV Style dynamic focus card decoration
  static BoxDecoration cardDecoration({bool focused = false}) {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: focused ? focusRing : Colors.transparent,
        width: focused ? 3.0 : 0,
      ),
      boxShadow: focused
          ? [
              BoxShadow(
                color: focusRing.withValues(alpha: 0.35),
                blurRadius: 30,
                spreadRadius: 4,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ]
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
    );
  }
}
