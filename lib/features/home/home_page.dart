import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/manga_model.dart';
import '../../services/manga_service.dart';
import '../../services/reading_progress_service.dart';
import '../../shared/widgets/manga_card.dart';
import '../../shared/widgets/continue_reading_card.dart';
import '../details/detail_page.dart';
import '../reader/reader_page.dart';

class HomePage extends StatefulWidget {
  final void Function(int, {bool sortByRating})? onNavigate;
  const HomePage({super.key, this.onNavigate});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _service = MangaService();
  final _continueKey = GlobalKey<ContinueReadingCardState>();
  List<MangaModel> _list = [];
  List<MangaModel> _latestReleases = [];
  List<MangaModel> _topRated = [];
  List<MangaModel> _randomManga = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_list.isNotEmpty) return;
    try {
      setState(() { _loading = true; _error = null; });
      final list = await _service.fetchMangaList();
      if (!mounted) return;
      final latest   = _service.getLatestReleases(list).take(15).toList();
      final top      = _service.getTopRated(list).take(15).toList();
      final shuffled = (list.toList()..shuffle()).take(15).toList();
      setState(() {
        _list = list; _latestReleases = latest;
        _topRated = top; _randomManga = shuffled; _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _goToDetail(BuildContext context, MangaModel manga) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPage(manga: manga)));
  }

  Future<void> _openFromProgress(ReadingProgress progress) async {
    // جيب المانغا من القائمة
    final manga = _list.firstWhere(
      (m) => m.id == progress.mangaId,
      orElse: () => _list.first,
    );

    // جيب الفصول
    final chapters = await _service.fetchChapters(manga.id);
    if (!mounted) return;

    // لقي index الفصل
    final chapterIdx = chapters.indexWhere(
      (c) => c.number.toString() == progress.chapterId,
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderPage(
          manga: manga,
          allChapters: chapters,
          initialChapterIndex: chapterIdx < 0 ? 0 : chapterIdx,
          initialPageIndex: progress.pageIndex,
        ),
      ),
    );

    // بعد الرجوع — حدّث البطاقة
    _continueKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accentClr = dark ? AppColors.darkAccentNeon : AppColors.lightAccentPrimary;

    return Scaffold(
      backgroundColor: dark ? AppColors.darkBgDeep : AppColors.lightBgDeep,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _topBar(dark)),

            // ── بطاقة أكمل القراءة ──
            SliverToBoxAdapter(
              child: ContinueReadingCard(
                key: _continueKey,
                onTap: _openFromProgress,
              ),
            ),

            if (_loading)
              SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: accentClr, strokeWidth: 2.5)),
              )
            else if (_error != null)
              const SliverFillRemaining(
                child: Center(child: Text('حدث خطأ في تحميل البيانات', style: TextStyle(color: Colors.white54))),
              )
            else ...[
              SliverToBoxAdapter(child: _section(dark, 'آخر الإصدارات', Icons.access_time_rounded,
                  const Color(0xFF8B5CF6), const Color(0x338B5CF6), _latestReleases,
                  () => widget.onNavigate?.call(0))),
              SliverToBoxAdapter(child: _section(dark, 'الأعلى تقييماً', Icons.star_rounded,
                  AppColors.starColor, const Color(0x33E8B85C), _topRated,
                  () => widget.onNavigate?.call(1, sortByRating: true))),
              SliverToBoxAdapter(child: _section(dark, 'مكتبة المانغا', null, null, null,
                  _randomManga, () => widget.onNavigate?.call(1))),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _topBar(bool dark) {
    final accent   = dark ? AppColors.darkAccentNeon : AppColors.lightAccentPrimary;
    final neonGlow = dark ? const Color(0x40BF5FFF) : const Color(0x305B5BD6);
    final textClr  = dark ? const Color(0xFFE2DEF0) : const Color(0xFF111111);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          GestureDetector(
            onTap: () => widget.onNavigate?.call(3),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF4A1F80), Color(0xFF1A1030)],
                ),
                border: Border.all(color: accent, width: 2),
                boxShadow: [
                  BoxShadow(color: neonGlow, blurRadius: 16),
                  const BoxShadow(color: Color(0x4DBF5FFF), blurRadius: 32),
                ],
              ),
              child: const Icon(Icons.person_outline_rounded, color: Color(0xFFC9B6F5), size: 22),
            ),
          ),
          const Spacer(),
          Text('Manga', style: TextStyle(
            fontFamily: 'Tajawal', fontSize: 22, fontWeight: FontWeight.w900, color: textClr,
            shadows: [Shadow(color: accent, blurRadius: 20), Shadow(color: neonGlow, blurRadius: 40)],
          )),
        ],
      ),
    );
  }

  Widget _section(bool dark, String title, IconData? icon, Color? iconClr,
      Color? iconBg, List<MangaModel> items, VoidCallback onSeeAll) {
    final accent   = dark ? AppColors.darkAccentNeon : AppColors.lightAccentPrimary;
    final titleClr = dark ? const Color(0xFFE2DEF0) : const Color(0xFF111111);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                if (icon != null) ...[
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, size: 13, color: iconClr),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: titleClr)),
                const Spacer(),
                GestureDetector(
                  onTap: onSeeAll,
                  child: Text('عرض الكل', style: TextStyle(fontSize: 13, color: accent, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: kCardH + 45,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                itemBuilder: (ctx, i) => Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: MangaCard(
                    manga: items[i],
                    onTap: () => _goToDetail(ctx, items[i]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
