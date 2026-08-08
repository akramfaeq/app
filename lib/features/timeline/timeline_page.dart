import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_provider.dart';
import '../../models/manga_model.dart';
import '../../services/manga_service.dart';
import '../details/detail_page.dart';

class TimelinePage extends StatelessWidget {
  final List<MangaModel> mangaList;
  const TimelinePage({super.key, required this.mangaList});

  String _timeAgo(DateTime date, bool isAr) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return isAr ? 'الآن'                        : 'Just now';
    if (diff.inHours < 1)   return isAr ? 'قبل ${diff.inMinutes} دقيقة' : '${diff.inMinutes}m ago';
    if (diff.inDays < 1)    return isAr ? 'قبل ${diff.inHours} ساعة'    : '${diff.inHours}h ago';
    if (diff.inDays < 2)    return isAr ? 'الأمس'                        : 'Yesterday';
    return '${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    final provider    = context.watch<AppProvider>();
    final t           = provider.t;
    final dir         = provider.dir;
    final isAr        = provider.isArabic;
    final dark        = Theme.of(context).brightness == Brightness.dark;
    final bg          = dark ? const Color(0xFF0A0714) : const Color(0xFFEDEEF4);
    final textPrimary = dark ? const Color(0xFFF0EEFF) : const Color(0xFF111111);
    final textSub     = dark ? const Color(0xFF7A728E) : const Color(0xFF6B7280);
    final accent      = dark ? const Color(0xFFBF5FFF) : const Color(0xFF5B5BD6);
    final cardBg      = dark ? const Color(0xFF130F1E) : Colors.white;

    // فلتر + ترتيب بآخر تحديث
    final newList = mangaList
        .where((m) => m.newChapter && m.updatedAt != null)
        .toList()
      ..sort((a, b) => b.updatedAt!.compareTo(a.updatedAt!));

    // استخدام groupByTimeline من الـ service
    final groups = MangaService().groupByTimeline(newList);

    final groupLabels = {
      'today':     isAr ? 'اليوم'       : 'Today',
      'yesterday': isAr ? 'الأمس'       : 'Yesterday',
      'week':      isAr ? 'هذا الأسبوع' : 'This Week',
      'older':     isAr ? 'أقدم'         : 'Older',
    };

    return Directionality(
      textDirection: dir,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Column(
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
                            color: const Color(0xFF8B5CF6).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(Icons.access_time_rounded,
                                color: Color(0xFF8B5CF6), size: 15),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(isAr ? 'فصول جديدة' : 'New Chapters',
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
                child: newList.isEmpty
                    ? _buildEmpty(textSub, isAr)
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                        children: [
                          for (final key in ['today', 'yesterday', 'week', 'older'])
                            if (groups[key]!.isNotEmpty) ...[
                              // label المجموعة
                              Padding(
                                padding: const EdgeInsets.only(top: 20, bottom: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: accent.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: accent.withOpacity(0.3)),
                                      ),
                                      child: Text(groupLabels[key]!,
                                        style: TextStyle(
                                          fontSize: 12, fontWeight: FontWeight.w700,
                                          color: accent,
                                        )),
                                    ),
                                  ],
                                ),
                              ),
                              // كاردات المجموعة
                              for (final m in groups[key]!)
                                _TimelineCard(
                                  manga: m,
                                  dark: dark,
                                  cardBg: cardBg,
                                  textPrimary: textPrimary,
                                  textSub: textSub,
                                  accent: accent,
                                  timeAgo: m.updatedAt != null
                                      ? _timeAgo(m.updatedAt!, isAr)
                                      : '',
                                  isAr: isAr,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => DetailPage(manga: m),
                                    ));
                                  },
                                ),
                            ],
                        ],
                      ),
              ),
            ],
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
          Icon(Icons.access_time_rounded,
              size: 52, color: textSub.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(isAr ? 'لا توجد تحديثات' : 'No Updates',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textSub)),
          const SizedBox(height: 6),
          Text(isAr ? 'ما في فصول جديدة حالياً' : 'No new chapters right now',
            style: TextStyle(fontSize: 13, color: textSub.withOpacity(0.7))),
        ],
      ),
    );
  }
}

// ── كارد المانغا ──
class _TimelineCard extends StatelessWidget {
  final MangaModel manga;
  final bool dark, isAr;
  final Color cardBg, textPrimary, textSub, accent;
  final String timeAgo;
  final VoidCallback onTap;

  const _TimelineCard({
    required this.manga,
    required this.dark,
    required this.isAr,
    required this.cardBg,
    required this.textPrimary,
    required this.textSub,
    required this.accent,
    required this.timeAgo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withOpacity(dark ? 0.2 : 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(dark ? 0.3 : 0.06),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          children: [
            // غلاف المانغا
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 56, height: 78,
                child: manga.cover.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: manga.cover,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: dark ? const Color(0xFF1D1630) : const Color(0xFFE8E9F4),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: dark ? const Color(0xFF1D1630) : const Color(0xFFE8E9F4),
                          child: Icon(Icons.broken_image_outlined,
                              color: textSub.withOpacity(0.5), size: 18),
                        ),
                      )
                    : Container(
                        color: dark ? const Color(0xFF1D1630) : const Color(0xFFE8E9F4),
                        child: Icon(Icons.image_not_supported_outlined,
                            color: textSub.withOpacity(0.5), size: 18),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // المعلومات
            Expanded(
              child: Column(
                crossAxisAlignment: isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(manga.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: isAr ? TextAlign.right : TextAlign.left,
                    style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary,
                    )),
                  const SizedBox(height: 5),
                  // الفصل الجديد
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accent.withOpacity(0.3)),
                    ),
                    child: Text(
                      manga.latestChapter != null
                          ? (isAr ? 'الفصل ${manga.latestChapter} 🆕' : 'Ch.${manga.latestChapter} 🆕')
                          : (isAr ? 'فصل جديد 🆕' : 'New Chapter 🆕'),
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: accent,
                      )),
                  ),
                  const SizedBox(height: 5),
                  // التصنيفات
                  if (manga.genres.isNotEmpty)
                    Text(manga.genres.take(2).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: textSub)),
                  const SizedBox(height: 4),
                  // الوقت
                  Row(
                    mainAxisAlignment: isAr ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 11, color: textSub.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Text(timeAgo,
                        style: TextStyle(fontSize: 11, color: textSub.withOpacity(0.7))),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            Icon(
              isAr ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
              color: textSub.withOpacity(0.5), size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
