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
    final provider = context.watch<AppProvider>();
    final t        = provider.t;
    final dir      = provider.dir;

    return Directionality(
      textDirection: dir,
      child: Scaffold(
        backgroundColor: AppColors.darkBgDeep,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _topBar(provider)),

              SliverToBoxAdapter(
                child: ContinueReadingCard(
                  key: _continueKey,
                  onTap: _openFromProgress,
                ),
              ),

              if (_loading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.darkAccentNeon, strokeWidth: 2.5),
                  ),
                )
              else if (_error != null)
                const SliverFillRemaining(
                  child: Center(
                    child: Text('حدث خطأ في تحميل البيانات',
                      style: TextStyle(color: AppColors.darkTextSecondary)),
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: _section(
                    provider, t('latest_releases'),
                    Icons.access_time_rounded,
                    const Color(0xFF8B5CF6),
                    const Color(0x338B5CF6),
                    _latestReleases,
                    _goToTimeline,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _section(
                    provider, t('top_rated'),
                    Icons.star_rounded,
                    AppColors.starColor,
                    const Color(0x33E8B85C),
                    _topRated,
                    () => widget.onNavigate?.call(1, sortByRating: true),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _section(
                    provider, t('manga_library'),
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

  Widget _topBar(AppProvider provider) {
    final isAr = provider.isArabic;

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
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4A1F80), Color(0xFF1A1030)],
                ),
                border: Border.all(color: AppColors.darkAccentNeon, width: 2),
                boxShadow: [
                  BoxShadow(color: AppColors.darkNeonGlow, blurRadius: 16),
                  const BoxShadow(color: Color(0x4DBF5FFF), blurRadius: 32),
                ],
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: Color(0xFFC9B6F5),
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
              color: AppColors.darkTextPrimary,
              shadows: [
                Shadow(color: AppColors.darkAccentNeon, blurRadius: 20),
                Shadow(color: AppColors.darkNeonGlow, blurRadius: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(
    AppProvider provider,
    String title,
    IconData? icon,
    Color? iconClr,
    Color? iconBg,
    List<MangaModel> items,
    VoidCallback onSeeAll,
  ) {
    final t = provider.t;

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
                  style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkTextPrimary,
                  )),
                const Spacer(),
                GestureDetector(
                  onTap: onSeeAll,
                  child: Text(t('see_all'),
                    style: const TextStyle(
                      fontSize: 13, color: AppColors.darkAccentNeon, fontWeight: FontWeight.w600,
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
