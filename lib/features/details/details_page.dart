import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../models/manga_model.dart';
import '../../services/manga_service.dart';

class DetailPage extends StatefulWidget {
  final MangaModel manga;
  const DetailPage({super.key, required this.manga});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final _service = MangaService();
  List<ChapterModel> _chapters = [];
  bool _loadingChapters = true;
  bool _sortDescending = true;
  bool _isFav = false;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int _visibleCount = 30;

  @override
  void initState() {
    super.initState();
    _loadChapters();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadChapters() async {
    try {
      final chapters = await _service.fetchChapters(widget.manga.id);
      if (!mounted) return;
      setState(() {
        _chapters = chapters;
        _loadingChapters = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingChapters = false);
    }
  }

  List<ChapterModel> get _filteredChapters {
    var list = [..._chapters];
    list.sort((a, b) => _sortDescending
        ? b.number.compareTo(a.number)
        : a.number.compareTo(b.number));
    if (_searchQuery.isNotEmpty) {
      list = list.where((c) => c.number.toString().contains(_searchQuery)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? AppColors.darkBgDeep : AppColors.lightBgDeep;
    final cardBg = dark ? AppColors.darkBgCard : AppColors.lightBgCard;
    final accent = dark ? AppColors.darkAccentNeon : AppColors.lightAccentPrimary;
    final textClr = dark ? const Color(0xFFE2DEF0) : const Color(0xFF111111);
    final subClr = dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ===== Hero Cover =====
          SliverToBoxAdapter(
            child: _HeroCover(
              manga: widget.manga,
              dark: dark,
              accent: accent,
              isFav: _isFav,
              onFavTap: () => setState(() => _isFav = !_isFav),
              onBack: () => Navigator.pop(context),
            ),
          ),

          // ===== المحتوى =====
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -50),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // التقييم
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8B85C).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE8B85C).withOpacity(0.6),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE8B85C).withOpacity(0.25),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Text(
                        '★ ${widget.manga.rating.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFE8B85C),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // العنوان
                    Text(
                      widget.manga.title,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: textClr,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // التصنيفات
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: widget.manga.genres.map((g) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: accent.withOpacity(0.3)),
                        ),
                        child: Text(g, style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, color: accent,
                        )),
                      )).toList(),
                    ),
                    const SizedBox(height: 18),

                    // الوصف
                    Text(
                      widget.manga.description ?? '',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: subClr,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // أزرار الإجراءات
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              // فتح القارئ
                            },
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF8B3CF6), Color(0xFFA855F7)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF8B3CF6).withOpacity(0.5),
                                    blurRadius: 20,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF8B3CF6).withOpacity(0.2),
                                    blurRadius: 30,
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text('ابدأ القراءة', style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white,
                                  )),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() => _isFav = !_isFav);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 50, height: 50,
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isFav
                                    ? accent.withOpacity(0.6)
                                    : accent.withOpacity(0.15),
                              ),
                            ),
                            child: Icon(
                              _isFav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                              color: _isFav ? accent : subClr,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // معلومات (فصول / نوع / حالة)
                    Row(
                      children: [
                        _InfoCard(
                          label: 'الفصول',
                          value: widget.manga.chapters.toString(),
                          dark: dark, cardBg: cardBg, textClr: textClr,
                        ),
                        const SizedBox(width: 8),
                        _InfoCard(
                          label: 'النوع',
                          value: widget.manga.type ?? 'مانغا',
                          dark: dark, cardBg: cardBg, textClr: textClr,
                        ),
                        const SizedBox(width: 8),
                        _InfoCard(
                          label: 'الحالة',
                          value: widget.manga.status ?? 'مستمرة',
                          dark: dark, cardBg: cardBg, textClr: textClr,
                          isStatus: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // ===== قسم الفصول =====
                    Container(
                      decoration: BoxDecoration(
                        color: dark ? const Color(0x801A1625) : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: accent.withOpacity(0.1)),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // رأس الفصول
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('الفصول', style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700, color: textClr,
                              )),
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _sortDescending = !_sortDescending);
                                },
                                child: AnimatedRotation(
                                  turns: _sortDescending ? 0 : 0.5,
                                  duration: const Duration(milliseconds: 250),
                                  child: Container(
                                    width: 34, height: 34,
                                    decoration: BoxDecoration(
                                      color: cardBg,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: accent.withOpacity(0.15)),
                                    ),
                                    child: Icon(Icons.sort_rounded, size: 18, color: subClr),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // بحث الفصول
                          Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: dark ? AppColors.darkBgDeep : const Color(0xFFF0F1F7),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: accent.withOpacity(0.15)),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 14),
                                Icon(Icons.search_rounded, size: 16, color: subClr),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _searchCtrl,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(color: textClr, fontSize: 13),
                                    decoration: InputDecoration(
                                      hintText: 'ابحث برقم الفصل...',
                                      hintStyle: TextStyle(color: subClr, fontSize: 13),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // قائمة الفصول
                          if (_loadingChapters)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Center(child: CircularProgressIndicator(
                                color: accent, strokeWidth: 2,
                              )),
                            )
                          else if (_filteredChapters.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Text('لا توجد فصول مطابقة',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: subClr, fontSize: 13)),
                            )
                          else
                            ...() {
                              final toShow = _searchQuery.isNotEmpty
                                  ? _filteredChapters
                                  : _filteredChapters.take(_visibleCount).toList();
                              return [
                                ...toShow.map((ch) => _ChapterItem(
                                  chapter: ch,
                                  dark: dark,
                                  accent: accent,
                                  cardBg: cardBg,
                                  textClr: textClr,
                                  subClr: subClr,
                                  onTap: () {
                                    // فتح القارئ
                                    debugPrint('فتح فصل ${ch.number}');
                                  },
                                )),
                                if (_searchQuery.isEmpty && _filteredChapters.length > _visibleCount)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: GestureDetector(
                                      onTap: () => setState(() => _visibleCount += 30),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: accent.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: accent.withOpacity(0.2)),
                                        ),
                                        child: Text('عرض المزيد',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 13, fontWeight: FontWeight.w700, color: accent,
                                          )),
                                      ),
                                    ),
                                  ),
                              ];
                            }(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== Hero Cover =====
class _HeroCover extends StatelessWidget {
  final MangaModel manga;
  final bool dark;
  final Color accent;
  final bool isFav;
  final VoidCallback onFavTap;
  final VoidCallback onBack;

  const _HeroCover({
    required this.manga, required this.dark, required this.accent,
    required this.isFav, required this.onFavTap, required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // صورة الغلاف
          manga.cover.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: manga.cover,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: const Color(0xFF3A2960),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF3A2960), Color(0xFF1A1622)],
                      ),
                    ),
                  ),
                )
              : Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF3A2960), Color(0xFF1A1622)],
                    ),
                  ),
                ),

          // Gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF0E0B14).withOpacity(0.15),
                    const Color(0xFF0E0B14).withOpacity(0.75),
                    dark ? const Color(0xFF0A0714) : const Color(0xFFEDEEF4),
                  ],
                  stops: const [0.0, 0.4, 0.75, 1.0],
                ),
              ),
            ),
          ),

          // زر الرجوع
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: GestureDetector(
              onTap: onBack,
              child: Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.25)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 14),
                  ],
                ),
                child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== Info Card =====
class _InfoCard extends StatelessWidget {
  final String label, value;
  final bool dark, isStatus;
  final Color cardBg, textClr;

  const _InfoCard({
    required this.label, required this.value,
    required this.dark, required this.cardBg, required this.textClr,
    this.isStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    Color valueColor = Colors.white;
    if (isStatus) {
      valueColor = value == 'مكتملة' ? const Color(0xFFF87171) : const Color(0xFF4ADE80);
    } else {
      valueColor = Colors.white;
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(
              fontSize: 9.5, color: Color(0xFFA1A1AA), fontWeight: FontWeight.w500,
            )),
            const SizedBox(height: 5),
            Text(value, style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w800, color: valueColor,
            )),
          ],
        ),
      ),
    );
  }
}

// ===== Chapter Item =====
class _ChapterItem extends StatelessWidget {
  final ChapterModel chapter;
  final bool dark;
  final Color accent, cardBg, textClr, subClr;
  final VoidCallback onTap;

  const _ChapterItem({
    required this.chapter, required this.dark, required this.accent,
    required this.cardBg, required this.textClr, required this.subClr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الفصل ${chapter.number}', style: TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w600, color: textClr,
                  )),
                  const SizedBox(height: 3),
                  Text('${chapter.pages} صفحة', style: TextStyle(
                    fontSize: 10.5, color: subClr,
                  )),
                ],
              ),
            ),
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.play_arrow_rounded, color: accent, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
