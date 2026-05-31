import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────
//  APP COLORS — Navy + Saffron Gold professional palette
//  Inspired by premium Indian edu-tech: BYJU's × Notion × Linear
// ─────────────────────────────────────────────────────────────
class AppColors {
  // ── BRAND ────────────────────────────────────────────────────
  static const Color primaryNavy   = Color(0xFF0D1B2A); // Deep midnight navy
  static const Color primaryBlue   = Color(0xFF1A56DB); // Royal blue CTA
  static const Color accentGold    = Color(0xFFF59E0B); // Saffron gold accent
  static const Color accentIndigo  = Color(0xFF6366F1); // Indigo for badges/tags

  // ── SEMANTIC ─────────────────────────────────────────────────
  static const Color successGreen  = Color(0xFF10B981); // Emerald
  static const Color warningOrange = Color(0xFFF59E0B); // Amber/gold
  static const Color errorRed      = Color(0xFFEF4444); // Rose red
  static const Color infoCyan      = Color(0xFF06B6D4); // Sky cyan

  // ── LIGHT MODE ───────────────────────────────────────────────
  static const Color bgLight         = Color(0xFFDDE4EE); // Comfortable muted blue-slate (not glaring)
  static const Color surfaceLight    = Color(0xFFF0F4F8); // Card faces (lighter than bg for depth)
  static const Color surface2Light   = Color(0xFFE4EBF5); // Inset surfaces, inputs
  static const Color borderLight     = Color(0xFFCED8E7); // Visible but not harsh borders
  static const Color textDark        = Color(0xFF0F172A); // Slate900
  static const Color textMuted       = Color(0xFF4A5A72); // Warm muted slate
  static const Color textSubtle      = Color(0xFF7D90AA); // Very subtle text

  // ── DARK MODE ────────────────────────────────────────────────
  static const Color bgDark          = Color(0xFF0B1120); // Deep navy bg
  static const Color surfaceDark     = Color(0xFF131D2E); // Card bg
  static const Color surface2Dark    = Color(0xFF1E293B); // Secondary surface
  static const Color borderDark      = Color(0xFF1E293B); // Slate800
  static const Color textDarkMode    = Color(0xFFF1F5F9); // Light text
  static const Color textMutedDark   = Color(0xFF94A3B8); // Muted text dark

  // ── GLASS EFFECTS ────────────────────────────────────────────
  static Color glassLight = const Color(0xFFFFFFFF).withValues(alpha: 0.7);
  static Color glassDark  = const Color(0xFF1E293B).withValues(alpha: 0.85);
  static Color glassBorderLight = const Color(0xFFE2E8F0).withValues(alpha: 0.8);
  static Color glassBorderDark  = const Color(0xFF334155).withValues(alpha: 0.6);

  // ── LEGACY ALIASES (keep old refs working) ───────────────────
  static const Color bgSoftWhite  = bgLight;
  static const Color accentIndigoLegacy = accentIndigo;
  static Color get glassBg => glassLight;
  static Color get glassBorder => glassBorderLight;

  // ── SHADOWS ──────────────────────────────────────────────────
  static BoxShadow softShadow = BoxShadow(
    color: const Color(0xFF0D1B2A).withValues(alpha: 0.06),
    blurRadius: 24,
    spreadRadius: 0,
    offset: const Offset(0, 8),
  );

  static BoxShadow sharpShadow = BoxShadow(
    color: const Color(0xFF1A56DB).withValues(alpha: 0.12),
    blurRadius: 12,
    offset: const Offset(0, 4),
  );

  static BoxShadow goldGlow = BoxShadow(
    color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
    blurRadius: 20,
    offset: const Offset(0, 4),
  );

  // ── GRADIENTS ────────────────────────────────────────────────
  static const LinearGradient navyGold = LinearGradient(
    colors: [Color(0xFF0D1B2A), Color(0xFF1A3A5C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF1A56DB), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─────────────────────────────────────────────────────────────
//  APP THEME
// ─────────────────────────────────────────────────────────────
class AppTheme {
  static TextTheme _buildTextTheme(Color textColor, Color mutedColor) {
    return GoogleFonts.interTextTheme(TextTheme(
      displayLarge: TextStyle(
        fontSize: 34, fontWeight: FontWeight.w800,
        color: textColor, letterSpacing: -1.0, height: 1.15,
      ),
      displayMedium: TextStyle(
        fontSize: 28, fontWeight: FontWeight.w700,
        color: textColor, letterSpacing: -0.5, height: 1.2,
      ),
      displaySmall: TextStyle(
        fontSize: 22, fontWeight: FontWeight.w700,
        color: textColor, letterSpacing: -0.3, height: 1.25,
      ),
      titleLarge: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w700,
        color: textColor, letterSpacing: -0.2,
      ),
      titleMedium: TextStyle(
        fontSize: 15, fontWeight: FontWeight.w600,
        color: textColor, letterSpacing: -0.1,
      ),
      titleSmall: TextStyle(
        fontSize: 13, fontWeight: FontWeight.w600,
        color: mutedColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 15, fontWeight: FontWeight.w400,
        color: textColor, height: 1.6,
      ),
      bodyMedium: TextStyle(
        fontSize: 13, fontWeight: FontWeight.w400,
        color: mutedColor, height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w400,
        color: mutedColor, height: 1.4,
      ),
      labelLarge: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w600,
        color: textColor, letterSpacing: 0.2,
      ),
      labelMedium: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w500,
        color: mutedColor, letterSpacing: 0.3,
      ),
      labelSmall: TextStyle(
        fontSize: 10, fontWeight: FontWeight.w600,
        color: mutedColor, letterSpacing: 0.5,
      ),
    ));
  }

  // ── LIGHT THEME ──────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primaryBlue,
      scaffoldBackgroundColor: AppColors.bgLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryBlue,
        secondary: AppColors.accentGold,
        tertiary: AppColors.accentIndigo,
        surface: AppColors.surfaceLight,
        error: AppColors.errorRed,
        onPrimary: Colors.white,
        onSecondary: AppColors.primaryNavy,
        onSurface: AppColors.textDark,
      ),
      textTheme: _buildTextTheme(AppColors.textDark, AppColors.textMuted),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        shadowColor: Colors.transparent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textDark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface2Light,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 1),
        ),
        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        hintStyle: const TextStyle(color: AppColors.textSubtle, fontSize: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface2Light,
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        side: const BorderSide(color: AppColors.borderLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight, thickness: 1, space: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textSubtle,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // ── DARK THEME ───────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryBlue,
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryBlue,
        secondary: AppColors.accentGold,
        tertiary: AppColors.accentIndigo,
        surface: AppColors.surfaceDark,
        error: AppColors.errorRed,
        onPrimary: Colors.white,
        onSecondary: AppColors.primaryNavy,
        onSurface: AppColors.textDarkMode,
      ),
      textTheme: _buildTextTheme(AppColors.textDarkMode, AppColors.textMutedDark),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
        shadowColor: Colors.transparent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textDarkMode),
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textDarkMode,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface2Dark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 1),
        ),
        labelStyle: const TextStyle(color: AppColors.textMutedDark, fontSize: 14),
        hintStyle: const TextStyle(color: AppColors.textMutedDark, fontSize: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface2Dark,
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textDarkMode),
        side: const BorderSide(color: AppColors.borderDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark, thickness: 1, space: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textMutedDark,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // ── DECORATION HELPERS ───────────────────────────────────────
  static BoxDecoration glassCardDecoration({bool dark = false}) {
    return BoxDecoration(
      color: dark ? AppColors.glassDark : AppColors.glassLight,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: dark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
        width: 1,
      ),
      boxShadow: [AppColors.softShadow],
    );
  }

  static BoxDecoration gradientCardDecoration({
    required List<Color> colors,
    double radius = 20,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: colors.first.withValues(alpha: 0.25),
          blurRadius: 20,
          offset: const Offset(0, 6),
        )
      ],
    );
  }

  static BoxDecoration navyHeroDecoration() {
    return BoxDecoration(
      gradient: AppColors.navyGold,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [AppColors.softShadow],
    );
  }

  static BoxDecoration goldAccentDecoration({double radius = 12}) {
    return BoxDecoration(
      gradient: AppColors.goldGradient,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [AppColors.goldGlow],
    );
  }

  // ── STAT CARD COLORS ─────────────────────────────────────────
  // Returns subject-specific colors for variety
  static Color subjectColor(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('physics')) return const Color(0xFF6366F1);  // Indigo
    if (s.contains('chem')) return const Color(0xFF10B981);      // Emerald
    if (s.contains('math') || s.contains('maths')) return const Color(0xFFF59E0B); // Gold
    if (s.contains('bio')) return const Color(0xFF06B6D4);       // Cyan
    if (s.contains('english')) return const Color(0xFFEC4899);   // Pink
    if (s.contains('hindi')) return const Color(0xFFEF4444);     // Red
    return const Color(0xFF8B5CF6); // Purple fallback
  }
}
