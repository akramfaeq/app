import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProvider extends ChangeNotifier {
  static const _themeKey = 'manga_theme';
  static const _langKey  = 'app_lang';

  bool   _isLightTheme = false;
  String _lang = 'ar';

  bool   get isLightTheme => _isLightTheme;
  String get lang          => _lang;
  bool   get isArabic      => _lang == 'ar';

  AppProvider() {
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isLightTheme = prefs.getString(_themeKey) == 'light';
    _lang         = prefs.getString(_langKey) ?? 'ar';
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isLightTheme = !_isLightTheme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _isLightTheme ? 'light' : 'dark');
    notifyListeners();
  }

  Future<void> changeLanguage(String lang) async {
    _lang = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, lang);
    notifyListeners();
  }

  String t(String key) => _translations[_lang]?[key] ?? _translations['ar']![key] ?? key;

  static const _translations = {
    'ar': {
      'home': 'الرئيسية',
      'library': 'المكتبة',
      'search': 'البحث',
      'more': 'المزيد',
      'latestReleases': 'آخر الإصدارات',
      'topRated': 'الأعلى تقييماً',
      'libraryNav': 'مكتبة المانغا',
      'seeAll': 'عرض الكل',
      'today': 'اليوم',
      'yesterday': 'الأمس',
      'thisWeek': 'هذا الأسبوع',
      'older': 'أقدم',
      'loading': 'جاري التحميل...',
      'error': 'حدث خطأ، حاول مجدداً',
      // more page
      'more_title': 'المزيد',
      'account': 'تسجيل الدخول',
      'account_sub': 'أنشئ حسابك أو سجّل دخولك',
      'app_settings': 'إعدادات التطبيق',
      'language': 'اللغة',
      'language_current': 'عربي',
      'language_switch': 'English',
      'day_mode': 'الوضع النهاري',
      'day_mode_sub': 'اضغط للتفعيل',
      'about': 'عن التطبيق',
      'version': 'الإصدار 1.0.0',
      'contact': 'Contact Us',
    },
    'en': {
      'home': 'Home',
      'library': 'Library',
      'search': 'Search',
      'more': 'More',
      'latestReleases': 'Latest Releases',
      'topRated': 'Top Rated',
      'libraryNav': 'Manga Library',
      'seeAll': 'See All',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'thisWeek': 'This Week',
      'older': 'Older',
      'loading': 'Loading...',
      'error': 'Something went wrong, try again',
      // more page
      'more_title': 'More',
      'account': 'Sign In',
      'account_sub': 'Create an account or sign in',
      'app_settings': 'App Settings',
      'language': 'Language',
      'language_current': 'English',
      'language_switch': 'عربي',
      'day_mode': 'Light Mode',
      'day_mode_sub': 'Tap to enable',
      'about': 'About',
      'version': 'Version 1.0.0',
      'contact': 'Contact Us',
    },
  };
}
