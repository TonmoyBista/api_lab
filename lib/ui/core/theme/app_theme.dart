import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// ThemeNotifier – drives dark / light / system mode switching at runtime
// ---------------------------------------------------------------------------
class ThemeNotifier extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.dark;

  ThemeMode get themeMode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  void toggle() {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    AppColors.isDark = _mode == ThemeMode.dark;
    notifyListeners();
  }

  void setDark() {
    _mode = ThemeMode.dark;
    AppColors.isDark = true;
    notifyListeners();
  }

  void setLight() {
    _mode = ThemeMode.light;
    AppColors.isDark = false;
    notifyListeners();
  }

  void setMode(ThemeMode mode) {
    _mode = mode;
    if (mode == ThemeMode.dark) {
      AppColors.isDark = true;
    } else if (mode == ThemeMode.light) {
      AppColors.isDark = false;
    }
    notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// AppColorsDark – static dark palette
// ---------------------------------------------------------------------------
class AppColorsDark {
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
}

// ---------------------------------------------------------------------------
// AppColorsLight – static light palette
// ---------------------------------------------------------------------------
class AppColorsLight {
  static const Color background = Color(0xFFF1F5F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFEDF2F7);

  static const Color primary = Color(0xFF2563EB);
  static const Color primaryHover = Color(0xFF1D4ED8);
  static const Color secondary = Color(0xFF4F46E5);
  static const Color accent = Color(0xFF0891B2);

  static const Color textMain = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
}

// ---------------------------------------------------------------------------
// AppColors – unified facade adapting dynamically to active theme
// ---------------------------------------------------------------------------
class AppColors {
  static bool isDark = true;

  // Dynamic getters reflecting current theme
  static Color get background => isDark ? AppColorsDark.background : AppColorsLight.background;
  static Color get surface => isDark ? AppColorsDark.surface : AppColorsLight.surface;
  static Color get surfaceLight => isDark ? AppColorsDark.surfaceLight : AppColorsLight.surfaceLight;
  static Color get border => isDark ? AppColorsDark.border : AppColorsLight.border;
  static Color get borderSubtle => isDark ? AppColorsDark.borderSubtle : AppColorsLight.borderSubtle;

  static Color get primary => isDark ? AppColorsDark.primary : AppColorsLight.primary;
  static Color get primaryHover => isDark ? AppColorsDark.primaryHover : AppColorsLight.primaryHover;
  static Color get secondary => isDark ? AppColorsDark.secondary : AppColorsLight.secondary;
  static Color get accent => isDark ? AppColorsDark.accent : AppColorsLight.accent;

  static Color get textMain => isDark ? AppColorsDark.textMain : AppColorsLight.textMain;
  static Color get textSecondary => isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary;
  static Color get textMuted => isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;

  // Direct access to explicit dark palette constants if specifically required
  static const Color darkBackground = AppColorsDark.background;
  static const Color darkSurface = AppColorsDark.surface;
  static const Color darkSurfaceLight = AppColorsDark.surfaceLight;
  static const Color darkBorder = AppColorsDark.border;

  // HTTP Method colors (shared across themes)
  static const Color methodGet = Color(0xFF10B981);
  static const Color methodPost = Color(0xFFF59E0B);
  static const Color methodPut = Color(0xFF3B82F6);
  static const Color methodDelete = Color(0xFFEF4444);
  static const Color methodPatch = Color(0xFF8B5CF6);
  static const Color methodHead = Color(0xFF6B7280);
  static const Color methodOptions = Color(0xFF14B8A6);

  // Status code colors (shared across themes)
  static const Color statusSuccess = Color(0xFF10B981);
  static const Color statusRedirect = Color(0xFF06B6D4);
  static const Color statusClientError = Color(0xFFF59E0B);
  static const Color statusServerError = Color(0xFFEF4444);
  static const Color statusMock = Color(0xFFEC4899);

  // Syntax highlighting colors for JSON viewer
  static Color get jsonKey => isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8);
  static Color get jsonString => isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D);
  static Color get jsonNumber => isDark ? const Color(0xFFF97316) : const Color(0xFFC2410C);
  static Color get jsonBool => isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
  static Color get jsonNull => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
}

// ---------------------------------------------------------------------------
// AppTheme – provides both dark and light ThemeData
// ---------------------------------------------------------------------------
class AppTheme {
  // ── Dark Theme ──────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColorsDark.background,
      primaryColor: AppColorsDark.primary,
      fontFamily: 'Segoe UI, San Francisco, Roboto, Arial, sans-serif',
      colorScheme: const ColorScheme.dark(
        primary: AppColorsDark.primary,
        secondary: AppColorsDark.secondary,
        surface: AppColorsDark.surface,
        error: AppColors.statusServerError,
        onPrimary: Colors.white,
        onSurface: AppColorsDark.textMain,
      ),
      cardTheme: CardThemeData(
        color: AppColorsDark.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColorsDark.border, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColorsDark.border,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColorsDark.surface,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColorsDark.border, width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsDark.surfaceLight,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColorsDark.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColorsDark.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColorsDark.primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColorsDark.textMuted, fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsDark.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorsDark.textMain,
          side: const BorderSide(color: AppColorsDark.border),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(AppColorsDark.border),
        radius: const Radius.circular(4),
        thickness: WidgetStateProperty.all(6),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColorsDark.surfaceLight,
          border: Border.all(color: AppColorsDark.border),
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: const TextStyle(color: AppColorsDark.textMain, fontSize: 12),
      ),
    );
  }

  // ── Light Theme ──────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    const bg = AppColorsLight.background;
    const surf = AppColorsLight.surface;
    const surfLight = AppColorsLight.surfaceLight;
    const border = AppColorsLight.border;
    const primary = AppColorsLight.primary;
    const textMain = AppColorsLight.textMain;
    const textMuted = AppColorsLight.textMuted;

    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: bg,
      primaryColor: primary,
      fontFamily: 'Segoe UI, San Francisco, Roboto, Arial, sans-serif',
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: AppColorsLight.secondary,
        surface: surf,
        error: AppColors.statusServerError,
        onPrimary: Colors.white,
        onSurface: textMain,
      ),
      cardTheme: CardThemeData(
        color: surf,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: border, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surf,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: border, width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfLight,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textMuted, fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textMain,
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(border),
        radius: const Radius.circular(4),
        thickness: WidgetStateProperty.all(6),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: surfLight,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: const TextStyle(color: textMain, fontSize: 12),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surf,
        foregroundColor: textMain,
        elevation: 0,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(surfLight),
        ),
      ),
    );
  }
}
