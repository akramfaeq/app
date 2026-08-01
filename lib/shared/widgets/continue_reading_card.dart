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

  // الألوان الشبيهة بالصورة الثانية
  static const _accent       = Color(0xFF9B5CF6);
  static const _card         = Color(0xFF140F23);
  static const _cardBorder   = Color(0x269B5CF6);
  static const _textPrimary  = Color(0xFFFFFFFF);
  static const _textSub       = Color(0x99FFFFFF);

  @override
  void initState() {
    super.initState();
    _load();
  }

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

    return Padding(
      // تقليل المسافات الجانبية لتكبير الكارد مثل الصورة الثانية
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap(p);
        },
        child: Container(
          // زيادة الارتفاع ليعطي نظرة احترافية ومريحة
          height: 84,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cardBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      // 1. زر التشغيل البنفسجي المضيء
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _accent,
                          boxShadow: [
                            BoxShadow(
                              color: _accent.withOpacity(0.4),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // 2. تفاصيل الفصل والعنوان
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              p.mangaTitle,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _textPrimary,
                                fontFamily: 'Tajawal',
                                overflow: TextOverflow.ellipsis,
                              ),
                              maxLines: 1,
                              textAlign: TextAlign.right,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'الفصل ${p.chapterNumber}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _textSub,
                                fontFamily: 'Tajawal',
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // 3. صورة الغلاف الواضحة مثل الصورة الثانية
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: p.mangaCover,
                          width: 48,
                          height: 64,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            width: 48, height: 64,
                            color: const Color(0xFF1E1735),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            width: 48, height: 64,
                            color: const Color(0xFF1E1735),
                            child: const Icon(Icons.image_not_supported, color: Colors.white24, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // 4. شريط التقدم السفلي الرفيع والأنيق
              LinearProgressIndicator(
                value: p.progress.clamp(0.0, 1.0),
                minHeight: 3,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor: const AlwaysStoppedAnimation<Color>(_accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}