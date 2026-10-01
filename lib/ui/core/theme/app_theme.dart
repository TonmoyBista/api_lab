import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF14171E);
  static const Color surface = Color(0xFF1B202B);
  static const Color surfaceLight = Color(0xFF252C3B);
  static const Color border = Color(0xFF2E3648);
  static const Color borderSubtle = Color(0xFF222938);
  
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryHover = Color(0xFF60A5FA);
  static const Color secondary = Color(0xFF6366F1);
  static const Color accent = Color(0xFF06B6D4);
  
  static const Color textMain = Color(0xFFF3F4F6);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  // HTTP Method colors
  static const Color methodGet = Color(0xFF10B981);
  static const Color methodPost = Color(0xFFF59E0B);
  static const Color methodPut = Color(0xFF3B82F6);
  static const Color methodDelete = Color(0xFFEF4444);
  static const Color methodPatch = Color(0xFF8B5CF6);
  static const Color methodHead = Color(0xFF6B7280);
  static const Color methodOptions = Color(0xFF14B8A6);

  // Status code colors
  static const Color statusSuccess = Color(0xFF10B981);
  static const Color statusRedirect = Color(0xFF06B6D4);
  static const Color statusClientError = Color(0xFFF59E0B);
  static const Color statusServerError = Color(0xFFEF4444);
  static const Color statusMock = Color(0xFFEC4899);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      fontFamily: 'Segoe UI, San Francisco, Roboto, Arial, sans-serif',
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.statusServerError,
        onPrimary: Colors.white,
        onSurface: AppColors.textMain,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.border, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textMain,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.border),
        radius: const Radius.circular(4),
        thickness: WidgetStateProperty.all(6),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: const TextStyle(color: AppColors.textMain, fontSize: 12),
      ),
    );
  }
}
