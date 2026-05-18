import 'package:flutter/material.dart';

/// SaaS comparison-engine palette (Deel / Sana inspired).
abstract final class AppColors {
  static const background = Color(0xFFF9FAFB);
  static const surface = Colors.white;
  static const sidebarHover = Color(0xFFF3F4F6);
  static const border = Color(0xFFE5E7EB);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);
  static const accent = Color(0xFF6D28D9);
  static const accentLight = Color(0xFFEDE9FE);
  static const accentPink = Color(0xFFEC4899);
  static const heroPurple = Color(0xFFF5F3FF);
  static const heroPurpleDeep = Color(0xFFDDD6FE);
  static const premium = Color(0xFF111827);
  static const mint = Color(0xFF10B981);
  static const sky = Color(0xFFDBEAFE);
  static const peach = Color(0xFFFFEDD5);
  static const lemon = Color(0xFFFEF9C3);
  static const win = Color(0xFFD1FAE5);
  static const winText = Color(0xFF047857);
  static const error = Color(0xFFDC2626);

  static const chipBlue = Color(0xFFEFF6FF);
  static const chipPink = Color(0xFFFCE7F3);
  static const chipYellow = Color(0xFFFEF9C3);
  static const chipPeach = Color(0xFFFFEDD5);
}

abstract final class AppDecor {
  static const radiusLg = 24.0;
  static const radiusMd = 16.0;
  static const radiusSm = 12.0;

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static BoxDecoration surfaceCard({Color? color}) => BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radiusMd),
        border: Border.all(color: AppColors.border),
        boxShadow: cardShadow,
      );
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.light(
      primary: AppColors.accent,
      secondary: AppColors.accentPink,
      surface: AppColors.surface,
      error: AppColors.error,
      onSurface: AppColors.textPrimary,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.accent,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDecor.radiusLg),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDecor.radiusLg),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDecor.radiusLg),
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDecor.radiusMd),
      ),
    ),
  );
}
