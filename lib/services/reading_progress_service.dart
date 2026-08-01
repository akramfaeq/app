import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════
//  ReadingProgressService — حفظ واسترجاع تقدم القراءة
//
//  الشروط:
//  ✅ قرأ أكثر من 9 ثواني
//  ✅ لم يصل لـ 95% من الفصل (ما اكتمل)
// ═══════════════════════════════════════════════════════

class ReadingProgress {
  final String mangaId;
  final String mangaTitle;
  final String mangaCover;
  final String chapterId;
  final int chapterNumber;
  final int pageIndex;      // الصفحة اللي وقف عليها
  final String pageUrl;     // صورة الصفحة
  final double progress;    // نسبة التقدم 0.0 → 1.0
  final DateTime savedAt;

  const ReadingProgress({
    required this.mangaId,
    required this.mangaTitle,
    required this.mangaCover,
    required this.chapterId,
    required this.chapterNumber,
    required this.pageIndex,
    required this.pageUrl,
    required this.progress,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
    'mangaId': mangaId,
    'mangaTitle': mangaTitle,
    'mangaCover': mangaCover,
    'chapterId': chapterId,
    'chapterNumber': chapterNumber,
    'pageIndex': pageIndex,
    'pageUrl': pageUrl,
    'progress': progress,
    'savedAt': savedAt.toIso8601String(),
  };

  factory ReadingProgress.fromJson(Map<String, dynamic> j) => ReadingProgress(
    mangaId: j['mangaId'] ?? '',
    mangaTitle: j['mangaTitle'] ?? '',
    mangaCover: j['mangaCover'] ?? '',
    chapterId: j['chapterId'] ?? '',
    chapterNumber: j['chapterNumber'] ?? 0,
    pageIndex: j['pageIndex'] ?? 0,
    pageUrl: j['pageUrl'] ?? '',
    progress: (j['progress'] ?? 0.0).toDouble(),
    savedAt: DateTime.tryParse(j['savedAt'] ?? '') ?? DateTime.now(),
  );
}

class ReadingProgressService {
  static const _key = 'reading_progress_list';
  static const _maxItems = 20; // أقصى عدد محفوظ

  // ── حفظ التقدم ──
  static Future<void> save(ReadingProgress entry) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getAll();

    // احذف القديم لنفس المانغا إذا موجود
    list.removeWhere((e) => e.mangaId == entry.mangaId);

    // أضف الجديد في المقدمة
    list.insert(0, entry);

    // حافظ على الحد الأقصى
    final trimmed = list.take(_maxItems).toList();

    await prefs.setString(
      _key,
      jsonEncode(trimmed.map((e) => e.toJson()).toList()),
    );
  }

  // ── جلب كل التقدم ──
  static Future<List<ReadingProgress>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => ReadingProgress.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── جلب أحدث واحد (للرئيسية) ──
  static Future<ReadingProgress?> getLatest() async {
    final list = await getAll();
    return list.isEmpty ? null : list.first;
  }

  // ── حذف تقدم مانغا معينة ──
  static Future<void> remove(String mangaId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getAll();
    list.removeWhere((e) => e.mangaId == mangaId);
    await prefs.setString(
      _key,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }
}
