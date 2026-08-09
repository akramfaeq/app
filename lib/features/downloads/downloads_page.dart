import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_provider.dart';
import '../../services/download_service.dart';

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider    = context.watch<AppProvider>();
    final t           = provider.t;
    final dir         = provider.dir;
    final isAr        = provider.isArabic;
    final dark        = Theme.of(context).brightness == Brightness.dark;
    final bg          = dark ? const Color(0xFF0A0714) : const Color(0xFFEDEEF4);
    final cardBg      = dark ? const Color(0xFF130F1E) : Colors.white;
    final textPrimary = dark ? const Color(0xFFF0EEFF) : const Color(0xFF111111);
    final textSub     = dark ? const Color(0xFF7A728E) : const Color(0xFF6B7280);

    return Directionality(
      textDirection: dir,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: DownloadService.instance,
            builder: (context, _) {
              final states = DownloadService.instance.allDownloaded;

              return Column(
                children: [
                  // ── هيدر ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: dark ? const Color(0x2EBF5FFF) : const Color(0xFFEEF0FA),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: dark ? const Color(0x8CBF5FFF) : const Color(0xFF5B5BD6),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(t('back'),
                                  style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700,
                                    color: dark ? const Color(0xFFE2DEF0) : const Color(0xFF5B5BD6),
                                  )),
                                const SizedBox(width: 4),
                                Text('›', style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700,
                                  color: dark ? const Color(0xFFE2DEF0) : const Color(0xFF5B5BD6),
                                )),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(Icons.download_rounded,
                                    color: Color(0xFF3B82F6), size: 15),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(isAr ? 'التحميلات' : 'Downloads',
                              style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w900,
                                color: textPrimary,
                              )),
                          ],
                        ),
                        const Spacer(),
                        const SizedBox(width: 80),
                      ],
                    ),
                  ),

                  // ── المحتوى ──
                  Expanded(
                    child: states.isEmpty
                        ? _buildEmpty(textSub, isAr)
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                            itemCount: states.length,
                            itemBuilder: (ctx, i) {
                              final entry   = states[i];
                              final mangaId = entry.mangaId;
                              final chapters = entry.chapters;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF3B82F6).withOpacity(0.15),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // اسم المانغا
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 32, height: 32,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF3B82F6).withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Center(
                                              child: Icon(Icons.auto_stories_rounded,
                                                  color: Color(0xFF3B82F6), size: 16),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(mangaId,
                                              style: TextStyle(
                                                fontSize: 14, fontWeight: FontWeight.w800,
                                                color: textPrimary,
                                              )),
                                          ),
                                          // مساحة الفصول
                                          Text('${chapters.length} ${isAr ? 'فصل' : 'chapters'}',
                                            style: TextStyle(fontSize: 11, color: textSub)),
                                        ],
                                      ),
                                    ),

                                    // فاصل
                                    Divider(height: 1,
                                        color: const Color(0xFF3B82F6).withOpacity(0.1)),

                                    // قائمة الفصول
                                    ...chapters.map((ch) => _DownloadedChapterRow(
                                      mangaId: mangaId,
                                      chapter: ch,
                                      dark: dark,
                                      textPrimary: textPrimary,
                                      textSub: textSub,
                                      isAr: isAr,
                                    )),
                                    const SizedBox(height: 4),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(Color textSub, bool isAr) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.download_rounded, size: 52, color: textSub.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(isAr ? 'لا توجد تحميلات' : 'No Downloads',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textSub)),
          const SizedBox(height: 6),
          Text(isAr ? 'حمّل فصولاً للقراءة بدون نت' : 'Download chapters to read offline',
            style: TextStyle(fontSize: 13, color: textSub.withOpacity(0.7))),
        ],
      ),
    );
  }
}

class _DownloadedChapterRow extends StatelessWidget {
  final String mangaId;
  final int chapter;
  final bool dark, isAr;
  final Color textPrimary, textSub;

  const _DownloadedChapterRow({
    required this.mangaId, required this.chapter,
    required this.dark, required this.isAr,
    required this.textPrimary, required this.textSub,
  });

  Future<int> _getSize() async {
    try {
      final svc = DownloadService.instance;
      final pages = await svc.getDownloadedPages(mangaId, chapter);
      if (pages == null) return 0;
      int total = 0;
      for (final p in pages) {
        final f = File(p);
        if (f.existsSync()) total += f.lengthSync();
      }
      return total;
    } catch (_) { return 0; }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          // أيقونة
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(Icons.download_done_rounded,
                  color: Color(0xFF10B981), size: 18),
            ),
          ),
          const SizedBox(width: 12),

          // اسم الفصل
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${isAr ? 'الفصل' : 'Chapter'} $chapter',
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: textPrimary,
                  )),
                FutureBuilder<int>(
                  future: _getSize(),
                  builder: (_, snap) => Text(
                    snap.hasData ? _formatSize(snap.data!) : '...',
                    style: TextStyle(fontSize: 11, color: textSub),
                  ),
                ),
              ],
            ),
          ),

          // زر الحذف
          GestureDetector(
            onTap: () async {
              HapticFeedback.selectionClick();
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: dark ? const Color(0xFF130F1E) : Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: Text(isAr ? 'حذف الفصل؟' : 'Delete Chapter?',
                    style: TextStyle(
                        color: textPrimary, fontSize: 15,
                        fontWeight: FontWeight.w700)),
                  content: Text(
                    isAr ? 'سيتم حذف الفصل من التخزين'
                          : 'Chapter will be deleted from storage',
                    style: TextStyle(color: textSub, fontSize: 13)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('إلغاء',
                          style: TextStyle(color: Color(0xFF9B5CF6)))),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('حذف',
                          style: TextStyle(color: Color(0xFFE85C5C)))),
                  ],
                ),
              );
              if (confirm == true) {
                await DownloadService.instance.delete(mangaId, chapter);
              }
            },
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFE85C5C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFE85C5C), size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
