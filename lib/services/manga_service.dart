import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/manga_model.dart';

class MangaService {
  static final MangaService _instance = MangaService._internal();
  factory MangaService() => _instance;
  MangaService._internal();

  // كاش محلي حتى ما يحمل مرتين
  List<MangaModel>? _cachedList;

  Future<List<MangaModel>> fetchMangaList({bool forceRefresh = false}) async {
    if (_cachedList != null && !forceRefresh) return _cachedList!;

    try {
      final response = await http
          .get(Uri.parse(AppConstants.mangaListUrl()))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _cachedList = data.map((e) => MangaModel.fromJson(e)).toList();
        return _cachedList!;
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      // إذا فشل الاتصال وعندنا كاش، نرجع الكاش
      if (_cachedList != null) return _cachedList!;
      rethrow;
    }
  }

  /// آخر الإصدارات - مرتبة بالتاريخ (اليوم، الأمس، هذا الأسبوع، أقدم)
  List<MangaModel> getLatestReleases(List<MangaModel> list) {
    final withNew = list.where((m) => m.newChapter).toList();
    final result  = withNew.isNotEmpty ? withNew : list;
    // رتب بالتاريخ من الأحدث للأقدم
    result.sort((a, b) {
      final aDate = a.updatedAt ?? DateTime(2000);
      final bDate = b.updatedAt ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });
    return result;
  }

  /// الأعلى تقييماً
  List<MangaModel> getTopRated(List<MangaModel> list) {
    final sorted = [...list];
    sorted.sort((a, b) => b.rating.compareTo(a.rating));
    return sorted;
  }

  /// تجميع المانغا بالجدول الزمني
  Map<String, List<MangaModel>> groupByTimeline(List<MangaModel> list) {
    final now       = DateTime.now();
    final today     = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo   = today.subtract(const Duration(days: 7));

    final groups = <String, List<MangaModel>>{
      'today':     [],
      'yesterday': [],
      'week':      [],
      'older':     [],
    };

    for (final m in list) {
      final date = m.updatedAt;
      if (date == null) {
        groups['older']!.add(m);
        continue;
      }
      final day = DateTime(date.year, date.month, date.day);
      if (!day.isBefore(today))         groups['today']!.add(m);
      else if (!day.isBefore(yesterday)) groups['yesterday']!.add(m);
      else if (!day.isBefore(weekAgo))   groups['week']!.add(m);
      else                               groups['older']!.add(m);
    }
    return groups;
  }
}
