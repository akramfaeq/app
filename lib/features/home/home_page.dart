import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_provider.dart';
import '../../models/manga_model.dart';
import '../../services/manga_service.dart';
import '../../services/reading_progress_service.dart';
import '../../shared/widgets/manga_card.dart';
import '../../shared/widgets/continue_reading_card.dart';
import '../details/detail_page.dart';
import '../reader/reader_page.dart';
import '../timeline/timeline_page.dart';

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

  // ── فتح Timeline ──
  void _goToTimeline() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => TimelinePage(mangaList: _list),
    ));
  }

  Future<void> _openFromProgress(ReadingProgress progress) async {
    final manga = _list.firstWhere(
      (m) => m.id == progress.mangaId,
      orElse: () => _list.first,
    );
    final chapters = await _service.fetchChapters(manga.id);
    if (!mounted) return;
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
    _continueKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider  = context.watch<AppProvider>();
    final t         = provider.t;
    final dir       = provider.dir;
    final dark      = Theme.of(context).brightness == Brightness.dark;
    final accentClr = dark ? AppColors.darkAccentNeon : AppColors.lightAccentPrimary;

    return Directionality(
      textDirection: dir,
      child: Scaffold(
        backgroundColor: dark ? AppColors.darkBgDeep : AppColors.lightBgDeep,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _topBar(dark, provider)),

              SliverToBoxAdapter(
                child: ContinueReadingCard(
                  key: _continueKey,
                  onTap: _openFromProgress,
                ),
              ),

              if (_loading)
                SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: accentClr, strokeWidth: 2.5),
                  ),
                )
              else if (_error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      t('error_loading'),
                      style: TextStyle(
                        color: dark ? Colors.white54 : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                )
              else ...[
                // ── آخر الإصدارات — عرض الكل يفتح Timeline ──
                SliverToBoxAdapter(
                  child: _section(
                    dark, provider, t('latest_releases'),
                    Icons.access_time_rounded,
                    dark ? const Color(0xFF8B5CF6) : AppColors.lightAccentPrimary,
                    dark ? const Color(0x338B5CF6) : const Color(0x1A5B5BD6),
                    _latestReleases,
                    _goToTimeline, // ← Timeline بدل Library
                  ),
                ),
                SliverToBoxAdapter(
                  child: _section(
                    dark, provider, t('top_rated'),
                    Icons.star_rounded,
                    dark ? AppColors.starColor : AppColors.lightGold,
                    dark ? const Color(0x33E8B85C) : const Color(0x1AD97706),
                    _topRated,
                    () => widget.onNavigate?.call(1, sortByRating: true),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _section(
                    dark, provider, t('manga_library'),
                    null, null, null,
                    _randomManga,
                    () => widget.onNavigate?.call(1),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(bool dark, AppProvider provider) {
    final accent   = dark ? AppColors.darkAccentNeon   : AppColors.lightAccentPrimary;
    final neonGlow = dark ? const Color(0x40BF5FFF)    : const Color(0x305B5BD6);
    final textClr  = dark ? AppColors.darkTextPrimary  : AppColors.lightTextPrimary;
    final isAr     = provider.isArabic;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        textDirection: isAr ? TextDirection.ltr : TextDirection.rtl,
        children: [
          GestureDetector(
            onTap: () => widget.onNavigate?.call(3),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: dark
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF4A1F80), Color(0xFF1A1030)],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.lightAccentPrimary.withOpacity(0.2),
                          AppColors.lightBgCardHover,
                        ],
                      ),
                border: Border.all(color: accent, width: 2),
                boxShadow: [
                  BoxShadow(color: neonGlow, blurRadius: 16),
                  BoxShadow(
                    color: dark
                        ? const Color(0x4DBF5FFF)
                        : AppColors.lightAccentPrimary.withOpacity(0.2),
                    blurRadius: 32,
                  ),
                ],
              ),
              child: Icon(
                Icons.person_outline_rounded,
                color: dark ? const Color(0xFFC9B6F5) : AppColors.lightAccentPrimary,
                size: 22,
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Manga',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: textClr,
              shadows: dark
                  ? [
                      Shadow(color: accent, blurRadius: 20),
                      Shadow(color: neonGlow, blurRadius: 40),
                    ]
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(
    bool dark,
    AppProvider provider,
    String title,
    IconData? icon,
    Color? iconClr,
    Color? iconBg,
    List<MangaModel> items,
    VoidCallback onSeeAll,
  ) {
    final titleClr  = dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final seeAllClr = dark ? AppColors.darkAccentNeon  : const Color(0xFF3F5EFB);
    final t         = provider.t;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              textDirection: provider.dir,
              children: [
                if (icon != null) ...[
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 13, color: iconClr),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(title,
                  style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: titleClr,
                  )),
                const Spacer(),
                GestureDetector(
                  onTap: onSeeAll,
                  child: Text(t('see_all'),
                    style: TextStyle(
                      fontSize: 13, color: seeAllClr, fontWeight: FontWeight.w600,
                    )),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: kCardH + 45,
            child: Directionality(
              textDirection: provider.dir,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                itemBuilder: (ctx, i) => Padding(
                  padding: provider.isArabic
                      ? const EdgeInsets.only(left: 10)
                      : const EdgeInsets.only(right: 10),
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
