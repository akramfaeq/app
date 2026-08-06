import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProvider extends ChangeNotifier {
  bool _isLightTheme = false;
  String _lang = 'ar';

  bool get isLightTheme => _isLightTheme;
  bool get isArabic => _lang == 'ar';
  String get lang => _lang;
  TextDirection get dir => _lang == 'ar' ? TextDirection.rtl : TextDirection.ltr;

  AppProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isLightTheme = prefs.getBool('isLightTheme') ?? false;
    _lang = prefs.getString('app_lang') ?? 'ar';
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isLightTheme = !_isLightTheme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLightTheme', _isLightTheme);
    notifyListeners();
  }

  Future<void> changeLanguage(String lang) async {
    _lang = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_lang', lang);
    notifyListeners();
  }

  // ─── دالة الترجمة ───
  String t(String key) {
    return (_translations[_lang]?[key]) ?? (_translations['ar']?[key]) ?? key;
  }

  static final Map<String, Map<String, String>> _translations = {
    'ar': {
      // ── الصفحة الرئيسية ──
      'app_name': 'تطبيق المانغا',
      'continue_reading': 'أكمل القراءة',
      'latest_releases': 'آخر الإصدارات',
      'top_rated': 'الأعلى تقييماً',
      'manga_library': 'مكتبة المانغا',
      'see_all': 'عرض الكل',
      'error_loading': 'حدث خطأ في تحميل البيانات',
      'home': 'الرئيسية',
      'search': 'البحث',
      'more': 'المزيد',

      // ── صفحة المزيد ──
      'more_title': 'المزيد',
      'app_settings': 'إعدادات التطبيق',
      'account': 'الحساب',
      'account_sub': 'إدارة حسابك والمفضلة',
      'language': 'اللغة',
      'language_current': 'العربية',
      'language_switch': 'English',
      'day_mode': 'الوضع النهاري',
      'day_mode_sub': 'تبديل المظهر',
      'about': 'عن التطبيق',
      'version': 'الإصدار 1.0.0',
      'contact_us': 'تواصل معنا',
      'favorites': 'المفضلة',
      'savedManga': 'المانغا المحفوظة',

      // ── صفحة المفضلة ──
      'back': 'رجوع',
      'all': 'الكل',
      'reading': 'أقرأه',
      'planRead': 'سأقرأه',
      'paused': 'متوقف',
      'completedCat': 'مكتمل',
      'empty_list': 'قائمتك فارغة',
      'empty_list_sub': 'ما أضفت أي مانغا للمفضلة بعد',
      'cat_reading': 'أقرأه حالياً',
      'cat_planread': 'سأقرأه',
      'cat_paused': 'متوقف مؤقتاً',
      'cat_completed': 'مكتمل',
      'cat_remove': 'إزالة التصنيف',
      'cat_menu_title': 'تصنيف المانغا',
      'select_count': 'محدد',
      'cancel': 'إلغاء',
      'delete_selected': 'حذف المحدد',
      'add_category': '+ تصنيف',

      // ── Detail Page ──
      'startReading': 'ابدأ القراءة',
      'chapters': 'الفصول',
      'type': 'النوع',
      'status': 'الحالة',
      'newest': 'الأحدث',
      'oldest': 'الأقدم',
      'chapterSearch': 'ابحث عن فصل...',
      'noChapters': 'لا توجد فصول',
      'chapterWord': 'الفصل',
      'pageWord': 'صفحة',
      'showMore': 'عرض المزيد',

      // ── Library Page ──
      'libraryNav': 'المكتبة',

      // ── Reader Page ──
      'no_pages': 'لا توجد صفحات لهذا الفصل',
      'no_pages_short': 'لا توجد صفحات',
      'page_load_error': 'تعذر تحميل هذه الصفحة',

      // ── Search Page ──
      'search_placeholder': 'ابحث عن مانغا...',
      'filter_by': 'تصنيف بواسطة',
      'clear_all': 'مسح الكل',
      'genre_label': 'التصنيف',
      'type_label': 'النوع',
      'status_label': 'الحالة',
      'apply_filter': 'تطبيق',
      'no_results': 'لا توجد نتائج',
      'try_different': 'جرب تغيير الفلاتر أو كلمة البحث',

      // ── شيت عن التطبيق ──
      'about_desc': 'تطبيق متكامل لقراءة المانجا، يوفر تجربة سلسة وسريعة مع واجهة عصرية مصممة خصيصاً لعشاق القصص المصورة.',
      'features_title': '✨ ميزات التطبيق',
      'feature_1': '🌓 دعم الوضع الداكن والنهاري',
      'feature_2': '📚 مكتبة شخصية بتصنيفات متعددة',
      'feature_3': '🔖 حفظ تقدم القراءة والمفضلة',
      'feature_4': '↕️ قارئ بوضعين عمودي وأفقي',
      'feature_5': '⭐ نظام تقييم ومتابعة الإصدارات',
      'disclaimer': '⚠️ إخلاء المسؤولية: جميع المحتويات والترجمات والمواد المعروضة في هذا التطبيق هي ملك حصري لأصحابها وصانعيها الأصليين.',
      'dev_title': '💻 التطوير',
      'dev_names': 'أكرم فائق & يوسف سفيان',
    },
    'en': {
      // ── Home Page ──
      'app_name': 'Manga App',
      'continue_reading': 'Continue Reading',
      'latest_releases': 'Latest Releases',
      'top_rated': 'Top Rated',
      'manga_library': 'Manga Library',
      'see_all': 'See All',
      'error_loading': 'Error loading data',
      'home': 'Home',
      'search': 'Search',
      'more': 'More',

      // ── More Page ──
      'more_title': 'More',
      'app_settings': 'App Settings',
      'account': 'Account',
      'account_sub': 'Manage your account and favorites',
      'language': 'Language',
      'language_current': 'English',
      'language_switch': 'عربي',
      'day_mode': 'Light Mode',
      'day_mode_sub': 'Toggle appearance',
      'about': 'About',
      'version': 'Version 1.0.0',
      'contact_us': 'Contact Us',
      'favorites': 'Favorites',
      'savedManga': 'Saved Manga',

      // ── Favorites Page ──
      'back': 'Back',
      'all': 'All',
      'reading': 'Reading',
      'planRead': 'Plan to Read',
      'paused': 'On Hold',
      'completedCat': 'Completed',
      'empty_list': 'Your list is empty',
      'empty_list_sub': 'You haven\'t added any manga yet',
      'cat_reading': 'Currently Reading',
      'cat_planread': 'Plan to Read',
      'cat_paused': 'On Hold',
      'cat_completed': 'Completed',
      'cat_remove': 'Remove Category',
      'cat_menu_title': 'Manga Category',
      'select_count': 'selected',
      'cancel': 'Cancel',
      'delete_selected': 'Delete Selected',
      'add_category': '+ Category',

      // ── Detail Page ──
      'startReading': 'Start Reading',
      'chapters': 'Chapters',
      'type': 'Type',
      'status': 'Status',
      'newest': 'Newest',
      'oldest': 'Oldest',
      'chapterSearch': 'Search chapter...',
      'noChapters': 'No chapters found',
      'chapterWord': 'Chapter',
      'pageWord': 'pages',
      'showMore': 'Show More',

      // ── Library Page ──
      'libraryNav': 'Library',

      // ── Reader Page ──
      'no_pages': 'No pages in this chapter',
      'no_pages_short': 'No pages',
      'page_load_error': 'Failed to load this page',

      // ── Search Page ──
      'search_placeholder': 'Search manga...',
      'filter_by': 'Filter by',
      'clear_all': 'Clear All',
      'genre_label': 'Genre',
      'type_label': 'Type',
      'status_label': 'Status',
      'apply_filter': 'Apply',
      'no_results': 'No results found',
      'try_different': 'Try different filters or search terms',

      // ── About Sheet ──
      'about_desc': 'A full-featured manga reading app with a smooth, fast experience and a modern interface designed for comic lovers.',
      'features_title': '✨ App Features',
      'feature_1': '🌓 Dark & Light mode support',
      'feature_2': '📚 Personal library with multiple categories',
      'feature_3': '🔖 Save reading progress and favorites',
      'feature_4': '↕️ Reader with vertical & horizontal modes',
      'feature_5': '⭐ Rating system and release tracking',
      'disclaimer': '⚠️ Disclaimer: All content, translations, and materials in this app are the exclusive property of their original owners and creators.',
      'dev_title': '💻 Development',
      'dev_names': 'Akram Faeq & Yousef Sofian',
    },
  };
}
