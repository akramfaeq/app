import 'package:flutter/material.dart';

/// ألوان التطبيق - مطابقة للتصميم الأصلي بالـ HTML
class AppColors {
  // ===== DARK THEME =====
  static const darkBgDeep       = Color(0xFF0A0714);
  static const darkBgCard       = Color(0xFF130F1E);
  static const darkBgCardHover  = Color(0xFF1D1630);
  static const darkAccentPrimary= Color(0xFF9B5CF6);
  static const darkAccentSoft   = Color(0xFF7B4DC8);
  static const darkAccentNeon   = Color(0xFFBF5FFF);
  static const darkAccentPink   = Color(0xFFFF47D4);
  static const darkTextPrimary  = Color(0xFFF0EEFF);
  static const darkTextSecondary= Color(0xFF7A728E);
  static const darkGold         = Color(0xFFE8B85C);

  static const darkNeonGlow     = Color(0x40BF5FFF); // rgba(191,95,255,0.25)
  static const darkPinkGlow     = Color(0x33FF47D4); // rgba(255,71,212,0.2)

  // ===== LIGHT THEME =====
  static const lightBgDeep       = Color(0xFFEDEEF4);
  static const lightBgCard       = Color(0xFFF5F5FA);
  static const lightBgCardHover  = Color(0xFFEAEBF5);
  static const lightAccentPrimary = Color(0xFF5B5BD6);
  static const lightAccentSoft    = Color(0xFF4848C2);
  static const lightAccentNeon    = Color(0xFF5B5BD6);
  static const lightAccentPink    = Color(0xFF7B7BE8);
  static const lightTextPrimary   = Color(0xFF111111);
  static const lightTextSecondary = Color(0xFF6B7280);
  static const lightGold          = Color(0xFFD97706);

  // ===== SHARED =====
  static const starColor         = Color(0xFFE8B85C);
  static const starEmpty         = Color(0x33FFFFFF);
  static const ratingBadgeBg    = Color(0x99000000);
}

/// الثيم الداكن
ThemeData buildDarkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBgDeep,
    colorScheme: const ColorScheme.dark(
      primary:   AppColors.darkAccentPrimary,
      secondary: AppColors.darkAccentNeon,
      surface:   AppColors.darkBgCard,
    ),
    fontFamily: 'Tajawal',
    useMaterial3: true,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xF0130F1E),
      selectedItemColor: AppColors.darkAccentNeon,
      unselectedItemColor: Color(0xFF4A4460),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerColor: Colors.transparent,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
  );
}

/// الثيم النهاري
ThemeData buildLightTheme() {
  return ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBgDeep,
    colorScheme: const ColorScheme.light(
      primary:   AppColors.lightAccentPrimary,
      secondary: AppColors.lightAccentNeon,
      surface:   AppColors.lightBgCard,
    ),
    fontFamily: 'Tajawal',
    useMaterial3: true,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.lightAccentPrimary,
      unselectedItemColor: Color(0xFF9CA3AF),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerColor: Colors.transparent,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
  );
}
