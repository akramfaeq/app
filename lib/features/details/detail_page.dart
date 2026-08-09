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
import '../../services/download_service.dart';
import 'package:manga_nova/features/reader/reader_page.dart';

class DetailPage extends StatefulWidget {
  final MangaModel manga;
  const DetailPage({super.key, required this.manga});
  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final _service    = MangaService();
  final _svc        = FavoritesService.instance;
  List<ChapterModel> _chapters = [];
  bool _loadingChapters = true;
  bool _sortDescending  = true;
  bool _isFav           = false;
  final _searchCtrl     = TextEditingController();
  String _searchQuery   = '';
  int _visibleCount     = 30;

  static const _bg      = AppColors.darkBgDeep;
  static const _cardBg  = AppColors.darkBgCard;
  static const _accent  = AppColors.darkAccentNeon;
  static const _textClr = Color(0xFFE2DEF0);
  static const _subClr  = AppColors.darkTextSecondary;

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

  String _translateType(String type, bool isAr) {
    if (isAr) return type;
    const map = {
      'مانغا': 'Manga', 'مانهوا': 'Manhwa', 'مانها': 'Manhua',
      'رواية': 'Novel', 'ويب تون': 'Webtoon',
    };
    return map[type] ?? type;
  }

  String _translateStatus(String status, bool isAr) {
    if (isAr) return status;
    const map = {
      'مستمرة': 'Ongoing', 'مكتملة': 'Completed',
      'متوقفة': 'Hiatus', 'ملغاة': 'Cancelled',
    };
    return map[status] ?? status;
  }

  void _openReader(ChapterModel chapter) async {
    final sortedAsc = [..._chapters]..sort((a, b) => a.number.compareTo(b.number));
    final idx = sortedAsc.indexWhere((c) => c.number == chapter.number);

    // تحقق من وجود صور محملة
    final savedPages = await DownloadService.instance
        .getDownloadedPages(widget.manga.id, chapter.number);

    ChapterModel finalChapter = chapter;
    if (savedPages != null && savedPages.isNotEmpty) {
      finalChapter = ChapterModel(
        number: chapter.number,
        pages: savedPages.length,
        pageUrls: savedPages,
      );
    }

    final updatedList = sortedAsc.map((c) =>
        c.number == chapter.number ? finalChapter : c).toList();

    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ReaderPage(
        manga: widget.manga,
        allChapters: updatedList,
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

    return Directionality(
      textDirection: dir,
      child: Scaffold(
        backgroundColor: _bg,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _HeroCover(
                manga: widget.manga,
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
                      Text(widget.manga.title, style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w900, color: _textClr, height: 1.15)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6, runSpacing: 6,
                        children: widget.manga.genres.map((g) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: _accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _accent.withOpacity(0.3)),
                          ),
                          child: Text(g, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _accent)),
                        )).toList(),
                      ),
                      const SizedBox(height: 18),
                      Text(widget.manga.description ?? '',
                          style: const TextStyle(fontSize: 13.5, color: _subClr, height: 1.7)),
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
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF8B3CF6), Color(0xFFA855F7)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF8B3CF6).withOpacity(0.5),
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
                                color: _cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _isFav ? _accent.withOpacity(0.6) : _accent.withOpacity(0.15)),
                              ),
                              child: Icon(_isFav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                  color: _isFav ? _accent : _subClr, size: 22),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _InfoCard(label: t('chapters'), value: widget.manga.chaptersCount.toString()),
                          const SizedBox(width: 8),
                          _InfoCard(label: t('type'), value: _translateType(widget.manga.type, isAr)),
                          const SizedBox(width: 8),
                          _InfoCard(label: t('status'), value: _translateStatus(widget.manga.status, isAr), isStatus: true),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.06)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(t('chapters'),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textClr)),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => setState(() => _sortDescending = !_sortDescending),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _accent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: _accent.withOpacity(0.2)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(_sortDescending
                                            ? Icons.arrow_downward_rounded
                                            : Icons.arrow_upward_rounded,
                                            size: 12, color: _accent),
                                        const SizedBox(width: 4),
                                        Text(_sortDescending ? t('newest') : t('oldest'),
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _accent)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1622),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _accent.withOpacity(0.15)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Icon(Icons.search_rounded, size: 18,
                                        color: _searchQuery.isNotEmpty ? _accent : _subClr),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchCtrl,
                                      textAlign: isAr ? TextAlign.right : TextAlign.left,
                                      textAlignVertical: TextAlignVertical.center,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                                      style: const TextStyle(fontSize: 13, color: _textClr),
                                      decoration: InputDecoration(
                                        hintText: t('chapterSearch'),
                                        hintStyle: const TextStyle(fontSize: 12, color: _subClr),
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
                                                    color: _subClr.withOpacity(0.25),
                                                  ),
                                                  child: const Icon(Icons.close_rounded, size: 12, color: _subClr),
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
                            if (_loadingChapters)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: CircularProgressIndicator(color: _accent, strokeWidth: 2),
                                ),
                              )
                            else if (_filteredChapters.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Center(
                                  child: Text(t('noChapters'),
                                      style: const TextStyle(color: _subClr, fontSize: 13)),
                                ),
                              )
                            else
                              ...() {
                                final visible = _filteredChapters.take(_visibleCount).toList();
                                return [
                                  ...visible.map((ch) => _ChapterItem(
                                    chapter: ch,
                                    chapterLabel: t('chapterWord'),
                                    pageLabel: t('pageWord'),
                                    mangaId: widget.manga.id,
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
                                            color: _accent.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: _accent.withOpacity(0.2)),
                                          ),
                                          child: Text(t('showMore'), textAlign: TextAlign.center,
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _accent)),
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
  final bool isArabic, isFav;
  final VoidCallback onFavTap, onBack;

  const _HeroCover({
    required this.manga, required this.isFav, required this.isArabic,
    required this.onFavTap, required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'cover-${manga.id}',
            child: manga.cover.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: manga.cover, fit: BoxFit.cover,
                    placeholder: (_, __) => const ColoredBox(color: Color(0xFF3A2960)),
                    errorWidget: (_, __, ___) => const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF3A2960), Color(0xFF1A1622)]),
                      ),
                    ),
                  )
                : const DecoratedBox(
                    decoration: BoxDecoration(
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
                    const Color(0xFF0A0714),
                  ],
                  stops: const [0.0, 0.4, 0.75, 1.0],
                ),
              ),
            ),
          ),
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
                  border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.25)),
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
  final bool isStatus;

  const _InfoCard({required this.label, required this.value, this.isStatus = false});

  @override
  Widget build(BuildContext context) {
    final valueColor = isStatus
        ? (value == 'مكتملة' || value == 'Completed' || value == 'Cancelled' || value == 'ملغاة'
            ? const Color(0xFFF87171)
            : const Color(0xFF4ADE80))
        : Colors.white;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.darkBgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(
              fontSize: 9.5, color: Color(0xFFA1A1AA), fontWeight: FontWeight.w500,
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
  final String chapterLabel, pageLabel;
  final String mangaId;
  final VoidCallback onTap;

  const _ChapterItem({
    required this.chapter, required this.chapterLabel,
    required this.pageLabel, required this.mangaId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: DownloadService.instance,
      builder: (context, _) {
        final dlSvc  = DownloadService.instance;
        final state  = dlSvc.getState(mangaId, chapter.number);
        final status = state.status;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.darkBgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: status == DownloadStatus.downloaded
                    ? const Color(0xFF10B981).withOpacity(0.3)
                    : Colors.white.withOpacity(0.05),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$chapterLabel ${chapter.number}',
                              style: const TextStyle(
                                  fontSize: 13.5, fontWeight: FontWeight.w600,
                                  color: Color(0xFFE2DEF0))),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text('${chapter.pages} $pageLabel',
                                  style: const TextStyle(
                                      fontSize: 10.5,
                                      color: AppColors.darkTextSecondary)),
                              if (status == DownloadStatus.downloaded) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.download_done_rounded,
                                    size: 12, color: Color(0xFF10B981)),
                                const SizedBox(width: 2),
                                const Text('محمل',
                                    style: TextStyle(
                                        fontSize: 10, color: Color(0xFF10B981),
                                        fontWeight: FontWeight.w600)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── زر التشغيل ──
                    Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                          color: AppColors.darkAccentNeon.withOpacity(0.15),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: AppColors.darkAccentNeon, size: 16),
                    ),
                    const SizedBox(width: 8),

                    // ── زر التحميل ──
                    GestureDetector(
                      onTap: () async {
                        if (status == DownloadStatus.downloading) return;
                        if (status == DownloadStatus.downloaded) {
                          // خيار الحذف
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: const Color(0xFF130F1E),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              title: const Text('حذف الفصل المحمل؟',
                                  style: TextStyle(color: Colors.white,
                                      fontSize: 15, fontWeight: FontWeight.w700)),
                              content: const Text('سيتم حذف الفصل من التخزين',
                                  style: TextStyle(color: Color(0xFF7A728E), fontSize: 13)),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('إلغاء',
                                        style: TextStyle(color: Color(0xFF9B5CF6)))),
                                TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('حذف',
                                        style: TextStyle(color: Color(0xFFE85C5C)))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await dlSvc.delete(mangaId, chapter.number);
                          }
                          return;
                        }
                        // بدء التحميل
                        dlSvc.download(
                          mangaId: mangaId,
                          chapterNumber: chapter.number,
                          pageUrls: chapter.pageUrls,
                        );
                      },
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          color: _btnColor(status).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: status == DownloadStatus.downloading
                            ? Padding(
                                padding: const EdgeInsets.all(7),
                                child: CircularProgressIndicator(
                                  value: state.progress,
                                  strokeWidth: 2,
                                  color: _btnColor(status),
                                  backgroundColor: Colors.white12,
                                ),
                              )
                            : Icon(_btnIcon(status),
                                color: _btnColor(status), size: 16),
                      ),
                    ),
                  ],
                ),

                // ── شريط التقدم ──
                if (status == DownloadStatus.downloading) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: state.progress,
                      minHeight: 3,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation(Color(0xFFBF5FFF)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${(state.progress * 100).toInt()}%',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF9B8FC0))),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Color _btnColor(DownloadStatus s) {
    switch (s) {
      case DownloadStatus.downloaded:  return const Color(0xFF10B981);
      case DownloadStatus.downloading: return const Color(0xFFBF5FFF);
      case DownloadStatus.failed:      return const Color(0xFFE85C5C);
      default:                         return const Color(0xFF7A728E);
    }
  }

  IconData _btnIcon(DownloadStatus s) {
    switch (s) {
      case DownloadStatus.downloaded: return Icons.download_done_rounded;
      case DownloadStatus.failed:     return Icons.refresh_rounded;
      default:                        return Icons.download_rounded;
    }
  }
}
