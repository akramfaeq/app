import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

// ── الأنواع أولاً ──
enum DownloadStatus { notDownloaded, downloading, downloaded, failed }

class ChapterDownloadState {
  final DownloadStatus status;
  final double progress;

  const ChapterDownloadState({
    required this.status,
    this.progress = 0.0,
  });
}

class DownloadedManga {
  final String mangaId;
  final List<int> chapters;
  const DownloadedManga({required this.mangaId, required this.chapters});
}

// ── الـ Service ──
class DownloadService extends ChangeNotifier {
  static final DownloadService instance = DownloadService._();
  DownloadService._();

  final Map<String, Map<int, ChapterDownloadState>> _states = {};

  ChapterDownloadState getState(String mangaId, int chapter) {
    return _states[mangaId]?[chapter] ??
        const ChapterDownloadState(status: DownloadStatus.notDownloaded);
  }

  bool isDownloaded(String mangaId, int chapter) =>
      getState(mangaId, chapter).status == DownloadStatus.downloaded;

  List<DownloadedManga> get allDownloaded {
    final result = <DownloadedManga>[];
    _states.forEach((mangaId, chapters) {
      final downloaded = chapters.entries
          .where((e) => e.value.status == DownloadStatus.downloaded)
          .map((e) => e.key)
          .toList()
        ..sort();
      if (downloaded.isNotEmpty) {
        result.add(DownloadedManga(mangaId: mangaId, chapters: downloaded));
      }
    });
    return result;
  }

  Future<Directory> _chapterDir(String mangaId, int chapter) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/manga/$mangaId/chapter_$chapter');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  Future<List<String>?> getDownloadedPages(String mangaId, int chapter) async {
    if (!isDownloaded(mangaId, chapter)) return null;
    final dir = await _chapterDir(mangaId, chapter);
    final files = dir.listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.jpg'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    return files.map((f) => f.path).toList();
  }

  Future<void> download({
    required String mangaId,
    required int chapterNumber,
    required List<String> pageUrls,
  }) async {
    if (kIsWeb) return;

    _setState(mangaId, chapterNumber,
        const ChapterDownloadState(status: DownloadStatus.downloading, progress: 0.0));

    try {
      final dir = await _chapterDir(mangaId, chapterNumber);
      final total = pageUrls.length;

      for (int i = 0; i < total; i++) {
        final file = File('${dir.path}/${i.toString().padLeft(3, '0')}.jpg');
        if (!file.existsSync()) {
          final resp = await http.get(Uri.parse(pageUrls[i]))
              .timeout(const Duration(seconds: 30));
          if (resp.statusCode == 200) {
            await file.writeAsBytes(resp.bodyBytes);
          } else {
            throw Exception('HTTP ${resp.statusCode}');
          }
        }
        _setState(mangaId, chapterNumber, ChapterDownloadState(
          status: DownloadStatus.downloading,
          progress: (i + 1) / total,
        ));
      }

      _setState(mangaId, chapterNumber,
          const ChapterDownloadState(status: DownloadStatus.downloaded, progress: 1.0));
    } catch (_) {
      _setState(mangaId, chapterNumber,
          const ChapterDownloadState(status: DownloadStatus.failed, progress: 0.0));
    }
  }

  Future<void> delete(String mangaId, int chapterNumber) async {
    if (kIsWeb) return;
    final dir = await _chapterDir(mangaId, chapterNumber);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    _setState(mangaId, chapterNumber,
        const ChapterDownloadState(status: DownloadStatus.notDownloaded));
  }

  void _setState(String mangaId, int chapter, ChapterDownloadState state) {
    _states.putIfAbsent(mangaId, () => {})[chapter] = state;
    notifyListeners();
  }

  Future<void> loadSavedStates() async {
    if (kIsWeb) return;
    try {
      final base = await getApplicationDocumentsDirectory();
      final mangaRoot = Directory('${base.path}/manga');
      if (!mangaRoot.existsSync()) return;

      for (final mangaDir in mangaRoot.listSync().whereType<Directory>()) {
        final mangaId = mangaDir.path.split('/').last;
        for (final chDir in mangaDir.listSync().whereType<Directory>()) {
          final name = chDir.path.split('/').last;
          if (name.startsWith('chapter_')) {
            final num = int.tryParse(name.replaceFirst('chapter_', ''));
            if (num != null && chDir.listSync().whereType<File>().isNotEmpty) {
              _setState(mangaId, num,
                  const ChapterDownloadState(status: DownloadStatus.downloaded, progress: 1.0));
            }
          }
        }
      }
    } catch (_) {}
  }
}
