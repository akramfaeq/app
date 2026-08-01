import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ReadingProgress {
  final String mangaId;
  final String mangaTitle;
  final String mangaCover;
  final String chapterId;
  final int chapterNumber;
  final int totalChapters;
  final int pageIndex;
  final String pageUrl;
  final double progress;
  final DateTime savedAt;

  const ReadingProgress({
    required this.mangaId,
    required this.mangaTitle,
    required this.mangaCover,
    required this.chapterId,
    required this.chapterNumber,
    this.totalChapters = 0,
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
    'totalChapters': totalChapters,
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
    totalChapters: j['totalChapters'] ?? 0,
    pageIndex: j['pageIndex'] ?? 0,
    pageUrl: j['pageUrl'] ?? '',
    progress: (j['progress'] ?? 0.0).toDouble(),
    savedAt: DateTime.tryParse(j['savedAt'] ?? '') ?? DateTime.now(),
  );
}

class ReadingProgressService {
  static const _key = 'reading_progress_list';
  static const _maxItems = 20;

  static Future<void> save(ReadingProgress entry) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getAll();
    list.removeWhere((e) => e.mangaId == entry.mangaId);
    list.insert(0, entry);
    final trimmed = list.take(_maxItems).toList();
    await prefs.setString(_key, jsonEncode(trimmed.map((e) => e.toJson()).toList()));
  }

  static Future<List<ReadingProgress>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => ReadingProgress.fromJson(e)).toList();
    } catch (_) { return []; }
  }

  static Future<ReadingProgress?> getLatest() async {
    final list = await getAll();
    return list.isEmpty ? null : list.first;
  }

  static Future<void> remove(String mangaId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getAll();
    list.removeWhere((e) => e.mangaId == mangaId);
    await prefs.setString(_key, jsonEncode(list.map((e) => e.toJson()).toList()));
  }
}
