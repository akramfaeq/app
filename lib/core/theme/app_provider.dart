import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProvider extends ChangeNotifier {
  static const _themeKey = 'manga_theme';
  static const _langKey  = 'app_lang';

  bool   _isLightTheme = false;
  String _lang = 'ar'; // 'ar' | 'en'

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

  /// ترجمة بسيطة
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
    },
  };
}
