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

  static const _accent    = Color(0xFF9B5CF6);
  static const _accentBg  = Color(0x339B5CF6);
  static const _border    = Color(0x269B5CF6);
  static const _cardClr   = Color(0xFF130F1E);
  static const _gold      = Color(0xFFE8B85C);
  static const _skClr1    = Color(0xFF1D1630);
  static const _skClr2    = Color(0xFF2A2040);

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
    if (_loading) return const _SkeletonCard();
    if (_progress == null) return const SizedBox.shrink();

    final p        = _progress!;
    final provider = context.watch<AppProvider>();
    final t        = provider.t;
    final dir      = provider.dir;
    final isAr     = provider.isArabic;

    final chapterText = isAr
        ? (p.totalChapters > 0 ? 'الفصل ${p.chapterNumber} من ${p.totalChapters}' : 'الفصل ${p.chapterNumber}')
        : (p.totalChapters > 0 ? 'Chapter ${p.chapterNumber} of ${p.totalChapters}' : 'Chapter ${p.chapterNumber}');

    return Directionality(
      textDirection: dir,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(color: _accentBg, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.play_arrow_rounded, size: 13, color: _accent),
                ),
                const SizedBox(width: 8),
                Text(t('continue_reading'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                      color: Colors.white, fontFamily: 'Tajawal')),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () { HapticFeedback.selectionClick(); widget.onTap(p); },
              child: Container(
                width: MediaQuery.of(context).size.width * 0.75,
                height: 72,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: _cardClr,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border, width: 1),
                  boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 8, offset: const Offset(0, 3),
                  )],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: p.mangaCover,
                                width: 42, height: 54, fit: BoxFit.cover,
                                placeholder: (_, __) => const SizedBox(
                                  width: 42, height: 54,
                                  child: ColoredBox(color: Color(0xFF1D1630)),
                                ),
                                errorWidget: (_, __, ___) => const SizedBox(
                                  width: 42, height: 54,
                                  child: ColoredBox(
                                    color: Color(0xFF1D1630),
                                    child: Icon(Icons.image_not_supported, color: Colors.white24, size: 16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.mangaTitle,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                                        color: Colors.white, fontFamily: 'Tajawal',
                                        overflow: TextOverflow.ellipsis),
                                    maxLines: 1),
                                  const SizedBox(height: 2),
                                  Text(chapterText,
                                    style: const TextStyle(fontSize: 11, color: Color(0x99FFFFFF), fontFamily: 'Tajawal')),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle, color: _accent,
                                boxShadow: [BoxShadow(color: _accent.withOpacity(0.35), blurRadius: 6)],
                              ),
                              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Directionality(
                      textDirection: dir,
                      child: LinearProgressIndicator(
                        value: p.progress.clamp(0.0, 1.0),
                        minHeight: 2.5,
                        backgroundColor: Colors.white.withOpacity(0.06),
                        valueColor: const AlwaysStoppedAnimation<Color>(_gold),
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

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final clr = Color.lerp(const Color(0xFF1D1630), const Color(0xFF2A2040), _anim.value)!;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(width: 24, height: 24,
                    decoration: BoxDecoration(color: clr, borderRadius: BorderRadius.circular(8))),
                const SizedBox(width: 8),
                Container(height: 14, width: 120,
                    decoration: BoxDecoration(color: clr, borderRadius: BorderRadius.circular(6))),
              ]),
              const SizedBox(height: 8),
              Container(
                width: MediaQuery.of(context).size.width * 0.75,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF130F1E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x269B5CF6), width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(children: [
                    Container(width: 42, height: 54,
                        decoration: BoxDecoration(color: clr, borderRadius: BorderRadius.circular(8))),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 12, width: double.infinity,
                            decoration: BoxDecoration(color: clr, borderRadius: BorderRadius.circular(5))),
                        const SizedBox(height: 6),
                        Container(height: 10, width: 80,
                            decoration: BoxDecoration(color: clr, borderRadius: BorderRadius.circular(5))),
                      ],
                    )),
                    const SizedBox(width: 8),
                    Container(width: 34, height: 34,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: clr)),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
