import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_provider.dart';
import '../../models/manga_model.dart';
import '../../services/manga_service.dart';
import '../details/detail_page.dart';

class LibraryPage extends StatefulWidget {
  final bool sortByRating;
  const LibraryPage({super.key, this.sortByRating = false});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static List<MangaModel>? _cachedSorted;
  static List<MangaModel>? _cachedShuffled;

  final _service = MangaService();
  List<MangaModel> _list = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _loadDataOnce(); }

  @override
  void didUpdateWidget(LibraryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sortByRating != widget.sortByRating) {
      if (widget.sortByRating && _cachedSorted != null)
        setState(() => _list = _cachedSorted!);
      else if (!widget.sortByRating && _cachedShuffled != null)
        setState(() => _list = _cachedShuffled!);
      else _loadDataOnce();
    }
  }

  Future<void> _loadDataOnce() async {
    if (widget.sortByRating && _cachedSorted != null) {
      setState(() { _list = _cachedSorted!; _loading = false; }); return;
    }
    if (!widget.sortByRating && _cachedShuffled != null) {
      setState(() { _list = _cachedShuffled!; _loading = false; }); return;
    }
    try {
      setState(() { _loading = true; _error = null; });
      final list = await _service.fetchMangaList();
      if (!mounted) return;
      List<MangaModel> data;
      if (widget.sortByRating) {
        data = [...list]..sort((a, b) => b.rating.compareTo(a.rating));
        _cachedSorted = data;
      } else {
        data = [...list]..shuffle();
        _cachedShuffled = data;
      }
      setState(() { _list = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
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
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.darkAccentNeon, strokeWidth: 2.5))
              : _error != null
                  ? const Center(child: Text('حدث خطأ في تحميل البيانات',
                      style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13)))
                  : CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverPersistentHeader(
                          floating: true,
                          delegate: _LibraryHeaderDelegate(
                            child: Container(
                              color: AppColors.darkBgDeep,
                              padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 28, height: 28,
                                    decoration: BoxDecoration(
                                      color: AppColors.darkAccentNeon.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: const Icon(Icons.grid_view_rounded, size: 14, color: AppColors.darkAccentNeon),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(t('libraryNav'), style: const TextStyle(
                                    fontFamily: 'Tajawal', fontSize: 17,
                                    fontWeight: FontWeight.w900, color: AppColors.darkTextPrimary,
                                  )),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3, crossAxisSpacing: 10,
                              mainAxisSpacing: 14, childAspectRatio: 110 / 180,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => _LibraryCard(manga: _list[i]),
                              childCount: _list.length,
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}

class _LibraryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  const _LibraryHeaderDelegate({required this.child});

  @override double get minExtent => 62;
  @override double get maxExtent => 62;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox.expand(child: child);

  @override
  bool shouldRebuild(_LibraryHeaderDelegate old) => old.child != child;
}

class _LibraryCard extends StatelessWidget {
  final MangaModel manga;
  const _LibraryCard({required this.manga});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailPage(manga: manga)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFF161129),
                border: Border.all(color: AppColors.darkAccentNeon.withOpacity(0.55), width: 1.5),
                boxShadow: [
                  BoxShadow(color: AppColors.darkAccentNeon.withOpacity(0.35), blurRadius: 10, spreadRadius: 1),
                  BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    manga.cover.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: manga.cover, fit: BoxFit.cover,
                            placeholder: (_, __) => const ColoredBox(color: Color(0xFF161129)),
                            errorWidget: (_, __, ___) => const ColoredBox(
                              color: Color(0xFF161129),
                              child: Icon(Icons.broken_image_outlined, color: Colors.white24, size: 22),
                            ),
                          )
                        : const ColoredBox(color: Color(0xFF161129)),

                    if (manga.cover.isNotEmpty)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter, end: Alignment.topCenter,
                              colors: [Colors.black.withOpacity(0.65), Colors.transparent],
                              stops: const [0.0, 0.45],
                            ),
                          ),
                        ),
                      ),

                    Positioned(
                      bottom: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE8B85C).withOpacity(0.6), width: 1),
                        ),
                        child: Text(
                          '${manga.rating.toStringAsFixed(1)} ★',
                          style: const TextStyle(
                            fontSize: 10, color: Color(0xFFE8B85C), fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.darkAccentNeon.withOpacity(0.6), width: 1.2),
                          boxShadow: [BoxShadow(color: AppColors.darkAccentNeon.withOpacity(0.30), blurRadius: 6)],
                        ),
                        child: Icon(Icons.favorite_border_rounded,
                            color: Colors.white.withOpacity(0.9), size: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(manga.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFE2DEF0))),
          ),
        ],
      ),
    );
  }
}
