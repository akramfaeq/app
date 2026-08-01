import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  static const _accent      = Color(0xFF9B5CF6);
  static const _gold        = Color(0xFFE8B85C);
  static const _card        = Color(0xFF130F1E);
  static const _cardBorder  = Color(0x269B5CF6);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textSub     = Color(0x99FFFFFF);

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
    final p = _progress!;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // عنوان القسم — نفس style الرئيسية
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0x339B5CF6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.play_arrow_rounded, size: 13, color: _accent),
                ),
                const SizedBox(width: 8),
                const Text('أكمل القراءة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                      color: _textPrimary, fontFamily: 'Tajawal')),
              ],
            ),

            const SizedBox(height: 8),

            // الكارد
            GestureDetector(
              onTap: () { HapticFeedback.selectionClick(); widget.onTap(p); },
              child: Container(
                width: MediaQuery.of(context).size.width * 0.75,
                height: 72,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _cardBorder, width: 1),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Row(
                          children: [
                            // صورة يمين
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: p.mangaCover,
                                width: 42, height: 54,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(width: 42, height: 54, color: const Color(0xFF1D1630)),
                                errorWidget: (_, __, ___) => Container(
                                  width: 42, height: 54, color: const Color(0xFF1D1630),
                                  child: const Icon(Icons.image_not_supported, color: Colors.white24, size: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // نص وسط
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.mangaTitle,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                                        color: _textPrimary, fontFamily: 'Tajawal', overflow: TextOverflow.ellipsis),
                                    maxLines: 1),
                                  const SizedBox(height: 2),
                                  Text(
                                    p.totalChapters > 0
                                        ? 'الفصل ${p.chapterNumber} من ${p.totalChapters}'
                                        : 'الفصل ${p.chapterNumber}',
                                    style: const TextStyle(fontSize: 11, color: _textSub, fontFamily: 'Tajawal'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // play يسار
                            Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _accent,
                                boxShadow: [BoxShadow(color: _accent.withOpacity(0.35), blurRadius: 6)],
                              ),
                              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // شريط ذهبي
                    LinearProgressIndicator(
                      value: p.progress.clamp(0.0, 1.0),
                      minHeight: 2.5,
                      backgroundColor: Colors.white.withOpacity(0.06),
                      valueColor: const AlwaysStoppedAnimation<Color>(_gold),
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
