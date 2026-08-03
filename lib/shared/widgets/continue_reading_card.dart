import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_provider.dart';
import '../../services/reading_progress_service.dart';

class ContinueReadingCard extends StatefulWidget {
  final void Function(ReadingProgress progress) onTap;
  const ContinueReadingCard({super.key, required this.onTap});

  @override
  ContinueReadingCardState createState() => ContinueReadingCardState();
}

class ContinueReadingCardState extends State<ContinueReadingCard> {
  ReadingProgress? _progress;
  bool _loading = true;

  // ألوان ثابتة للداكن فقط
  static const _accentDark     = Color(0xFF9B5CF6);
  static const _accentLight    = Color(0xFF3F5EFB); // أزرق نيلي للنهاري
  static const _gold            = Color(0xFFE8B85C);

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await ReadingProgressService.getLatest();
    if (!mounted) return;
    setState(() { _progress = p; _loading = false; });
  }

  void refresh() => _load();

  @override
  Widget build(BuildContext context) {
    if (_loading || _progress == null) return const SizedBox.shrink();
    final p        = _progress!;
    final provider = context.watch<AppProvider>();
    final t        = provider.t;
    final dir      = provider.dir;
    final isAr     = provider.isArabic;
    final dark     = Theme.of(context).brightness == Brightness.dark;

    // ألوان حسب الثيم
    final accent      = dark ? _accentDark : _accentLight;
    final accentBg    = dark ? const Color(0x339B5CF6) : const Color(0x1A3F5EFB);
    final cardBorder  = dark ? const Color(0x269B5CF6) : const Color(0x263F5EFB);
    final cardClr     = dark ? const Color(0xFF130F1E) : Colors.white;
    final textPrimary = dark ? Colors.white : const Color(0xFF111111);
    final textSub     = dark ? const Color(0x99FFFFFF) : const Color(0xFF6B7280);

    // نص الفصل حسب اللغة
    final chapterText = isAr
        ? (p.totalChapters > 0
            ? 'الفصل ${p.chapterNumber} من ${p.totalChapters}'
            : 'الفصل ${p.chapterNumber}')
        : (p.totalChapters > 0
            ? 'Chapter ${p.chapterNumber} of ${p.totalChapters}'
            : 'Chapter ${p.chapterNumber}');

    return Directionality(
      textDirection: dir,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── عنوان القسم ──
            Row(
              children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: accentBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.play_arrow_rounded, size: 13, color: accent),
                ),
                const SizedBox(width: 8),
                Text(
                  t('continue_reading'),
                  style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: textPrimary, fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── الكارد ──
            GestureDetector(
              onTap: () { HapticFeedback.selectionClick(); widget.onTap(p); },
              child: Container(
                width: MediaQuery.of(context).size.width * 0.75,
                height: 72,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: cardClr,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cardBorder, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(dark ? 0.4 : 0.06),
                      blurRadius: 8, offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Row(
                          children: [
                            // صورة الغلاف
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: p.mangaCover,
                                width: 42, height: 54,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  width: 42, height: 54,
                                  color: dark ? const Color(0xFF1D1630) : const Color(0xFFEAEBF5),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  width: 42, height: 54,
                                  color: dark ? const Color(0xFF1D1630) : const Color(0xFFEAEBF5),
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: dark ? Colors.white24 : const Color(0xFFBBBCE0),
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // النص
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.mangaTitle,
                                    style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.bold,
                                      color: textPrimary, fontFamily: 'Tajawal',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    maxLines: 1,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    chapterText,
                                    style: TextStyle(
                                      fontSize: 11, color: textSub, fontFamily: 'Tajawal',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // ── زر Play ──
                            Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accent,
                                boxShadow: [
                                  BoxShadow(color: accent.withOpacity(0.35), blurRadius: 6),
                                ],
                              ),
                              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // شريط التقدم
                    Directionality(
                      textDirection: dir,
                      child: LinearProgressIndicator(
                        value: p.progress.clamp(0.0, 1.0),
                        minHeight: 2.5,
                        backgroundColor: dark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          dark ? _gold : accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
