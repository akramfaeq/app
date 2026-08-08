import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_provider.dart';
import '../../models/manga_model.dart';
import '../../models/chapter_model.dart';
import '../../services/manga_service.dart';
import '../../services/favorites_service.dart';
import 'package:manga_nova/features/reader/reader_page.dart';

class DetailPage extends StatefulWidget {
  final MangaModel manga;
  const DetailPage({super.key, required this.manga});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final _service = MangaService();
  final _svc = FavoritesService.instance;
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
    _loadFavStatus();
    _svc.addListener(_onFavChanged);
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim());
    });
  }

  void _onFavChanged() {
    if (mounted) setState(() => _isFav = _svc.isFavorite(widget.manga.id));
  }

  Future<void> _loadFavStatus() async {
    await _svc.load();
    if (mounted) setState(() => _isFav = _svc.isFavorite(widget.manga.id));
  }

  Future<void> _toggleFav() async {
    HapticFeedback.selectionClick();
    await _svc.toggle(widget.manga);
  }

  @override
  void dispose() {
    _svc.removeListener(_onFavChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadChapters() async {
    try {
      final chapters = await _service.fetchChapters(widget.manga.id);
      if (!mounted) return;
      setState(() { _chapters = chapters; _loadingChapters = false; });
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

  // ترجمة قيم البيانات القادمة من الـ API
  String _translateType(String type, String Function(String) t, bool isAr) {
    if (isAr) return type;
    const map = {
      'مانغا': 'Manga', 'مانهوا': 'Manhwa', 'مانها': 'Manhua',
      'رواية': 'Novel', 'ويب تون': 'Webtoon',
    };
    return map[type] ?? type;
  }

  String _translateStatus(String status, String Function(String) t, bool isAr) {
    if (isAr) return status;
    const map = {
      'مستمرة': 'Ongoing', 'مكتملة': 'Completed',
      'متوقفة': 'Hiatus', 'ملغاة': 'Cancelled',
    };
    return map[status] ?? status;
  }

  void _openReader(ChapterModel chapter) {
    final sortedAsc = [..._chapters]
      ..sort((a, b) => a.number.compareTo(b.number));
    final idx = sortedAsc.indexWhere((c) => c.number == chapter.number);
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ReaderPage(
        manga: widget.manga,
        allChapters: sortedAsc,
        initialChapterIndex: idx == -1 ? 0 : idx,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final t        = provider.t;
    final dir      = provider.dir;
    final isAr     = provider.isArabic;

    final dark    = Theme.of(context).brightness == Brightness.dark;
    final bg      = dark ? AppColors.darkBgDeep : AppColors.lightBgDeep;
    final cardBg  = dark ? AppColors.darkBgCard : AppColors.lightBgCard;
    final accent  = dark ? AppColors.darkAccentNeon : const Color(0xFF3F5EFB);
    final textClr = dark ? const Color(0xFFE2DEF0) : const Color(0xFF111111);
    final subClr  = dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Directionality(
      textDirection: dir,
      child: Scaffold(
        backgroundColor: bg,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _HeroCover(
                manga: widget.manga, dark: dark, accent: accent,
                isFav: _isFav,
                isArabic: isAr,
                onFavTap: _toggleFav,
                onBack: () => Navigator.pop(context),
              ),
            ),
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -50),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8B85C).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE8B85C).withOpacity(0.6), width: 1.5),
                          boxShadow: [BoxShadow(color: const Color(0xFFE8B85C).withOpacity(0.25), blurRadius: 12)],
                        ),
                        child: Text('★ ${widget.manga.rating.toStringAsFixed(1)}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFE8B85C))),
                      ),
                      const SizedBox(height: 10),
                      Text(widget.manga.title, style: TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w900, color: textClr, height: 1.15)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6, runSpacing: 6,
                        children: widget.manga.genres.map((g) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: accent.withOpacity(0.3)),
                          ),
                          child: Text(g, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accent)),
                        )).toList(),
                      ),
                      const SizedBox(height: 18),
                      Text(widget.manga.description ?? '',
                          style: TextStyle(fontSize: 13.5, color: subClr, height: 1.7)),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                if (_chapters.isEmpty) return;
                                final first = [..._chapters]..sort((a, b) => a.number.compareTo(b.number));
                                _openReader(first.first);
                              },
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: dark
                                        ? [const Color(0xFF8B3CF6), const Color(0xFFA855F7)]
                                        : [const Color(0xFF3F5EFB), const Color(0xFF5B7BFF)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: dark
                                          ? const Color(0xFF8B3CF6).withOpacity(0.5)
                                          : const Color(0xFF3F5EFB).withOpacity(0.4),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Text(t('startReading'),
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () { HapticFeedback.lightImpact(); _toggleFav(); },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 50, height: 50,
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _isFav ? accent.withOpacity(0.6) : accent.withOpacity(0.15)),
                              ),
                              child: Icon(_isFav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                  color: _isFav ? accent : subClr, size: 22),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _InfoCard(label: t('chapters'), value: widget.manga.chaptersCount.toString(),
                              dark: dark, cardBg: cardBg, textClr: textClr),
                          const SizedBox(width: 8),
                          _InfoCard(label: t('type'),
                              value: _translateType(widget.manga.type, t, provider.isArabic),
                              dark: dark, cardBg: cardBg, textClr: textClr),
                          const SizedBox(width: 8),
                          _InfoCard(label: t('status'),
                              value: _translateStatus(widget.manga.status, t, provider.isArabic),
                              dark: dark, cardBg: cardBg, textClr: textClr, isStatus: true),
                        ],
                      ),
                      const SizedBox(height: 22),
                      // ─── قسم الفصول ───
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.06)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // هيدر الفصول
                            Row(
                              children: [
                                Text(t('chapters'),
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textClr)),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => setState(() => _sortDescending = !_sortDescending),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: accent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: accent.withOpacity(0.2)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(_sortDescending
                                            ? Icons.arrow_downward_rounded
                                            : Icons.arrow_upward_rounded,
                                            size: 12, color: accent),
                                        const SizedBox(width: 4),
                                        Text(_sortDescending ? t('newest') : t('oldest'),
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // بحث
                            Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: dark ? const Color(0xFF1A1622) : const Color(0xFFF5F5FA),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: accent.withOpacity(0.15)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Icon(Icons.search_rounded, size: 18,
                                        color: _searchQuery.isNotEmpty ? accent : subClr),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchCtrl,
                                      textAlign: isAr ? TextAlign.right : TextAlign.left,
                                      textAlignVertical: TextAlignVertical.center,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                                      style: TextStyle(fontSize: 13, color: textClr),
                                      decoration: InputDecoration(
                                        hintText: t('chapterSearch'),
                                        hintStyle: TextStyle(fontSize: 12, color: subClr),
                                        hintTextDirection: dir,
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                        isCollapsed: true,
                                        suffixIcon: _searchQuery.isNotEmpty
                                            ? GestureDetector(
                                                onTap: () {
                                                  _searchCtrl.clear();
                                                  setState(() => _searchQuery = '');
                                                },
                                                child: Container(
                                                  margin: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: subClr.withOpacity(0.25),
                                                  ),
                                                  child: Icon(Icons.close_rounded, size: 12, color: subClr),
                                                ),
                                              )
                                            : null,
                                        suffixIconConstraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // قائمة الفصول
                            if (_loadingChapters)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: CircularProgressIndicator(color: accent, strokeWidth: 2),
                                ),
                              )
                            else if (_filteredChapters.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Center(
                                  child: Text(t('noChapters'),
                                      style: TextStyle(color: subClr, fontSize: 13)),
                                ),
                              )
                            else
                              ...() {
                                final visible = _filteredChapters.take(_visibleCount).toList();
                                return [
                                  ...visible.map((ch) => _ChapterItem(
                                    chapter: ch,
                                    dark: dark,
                                    accent: accent,
                                    cardBg: cardBg,
                                    textClr: textClr,
                                    subClr: subClr,
                                    chapterLabel: t('chapterWord'),
                                    pageLabel: t('pageWord'),
                                    onTap: () => _openReader(ch),
                                  )),
                                  if (_visibleCount < _filteredChapters.length)
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
                                          child: Text(t('showMore'), textAlign: TextAlign.center,
                                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: accent)),
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
      ),
    );
  }
}

class _HeroCover extends StatelessWidget {
  final MangaModel manga;
  final bool dark, isArabic;
  final Color accent;
  final bool isFav;
  final VoidCallback onFavTap, onBack;

  const _HeroCover({
    required this.manga, required this.dark, required this.accent,
    required this.isFav, required this.isArabic,
    required this.onFavTap, required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Hero Animation — نفس الـ tag بالكارد ──
          Hero(
            tag: 'cover-${manga.id}',
            child: manga.cover.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: manga.cover, fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: const Color(0xFF3A2960)),
                    errorWidget: (_, __, ___) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF3A2960), Color(0xFF1A1622)]),
                      ),
                    ),
                  )
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF3A2960), Color(0xFF1A1622)]),
                    ),
                  ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
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
          // زر الرجوع — يمين بالعربي، يسار بالإنجليزي
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: isArabic ? null : 16,
            right: isArabic ? 16 : null,
            child: GestureDetector(
              onTap: onBack,
              child: Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: dark
                      ? const Color(0xFF8B5CF6).withOpacity(0.25)
                      : const Color(0xFF3F5EFB).withOpacity(0.25)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 14)],
                ),
                child: Icon(
                  isArabic ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_rounded,
                  color: Colors.white, size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    final valueColor = isStatus
        ? (value == 'مكتملة' || value == 'Completed' || value == 'Cancelled' || value == 'ملغاة'
            ? const Color(0xFFF87171)
            : const Color(0xFF4ADE80))
        : (dark ? Colors.white : textClr);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: dark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.07),
          ),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(
              fontSize: 9.5,
              color: dark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            )),
            const SizedBox(height: 5),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: valueColor)),
          ],
        ),
      ),
    );
  }
}

class _ChapterItem extends StatelessWidget {
  final ChapterModel chapter;
  final bool dark;
  final Color accent, cardBg, textClr, subClr;
  final String chapterLabel, pageLabel;
  final VoidCallback onTap;

  const _ChapterItem({
    required this.chapter, required this.dark, required this.accent,
    required this.cardBg, required this.textClr, required this.subClr,
    required this.chapterLabel, required this.pageLabel,
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
                  Text('$chapterLabel ${chapter.number}',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: textClr)),
                  const SizedBox(height: 3),
                  Text('${chapter.pages} $pageLabel',
                      style: TextStyle(fontSize: 10.5, color: subClr)),
                ],
              ),
            ),
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(color: accent.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(Icons.play_arrow_rounded, color: accent, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
