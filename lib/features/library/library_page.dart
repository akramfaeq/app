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
    final provider  = context.watch<AppProvider>();
    final t         = provider.t;
    final dir       = provider.dir;
    final dark      = Theme.of(context).brightness == Brightness.dark;
    final bgColor   = dark ? AppColors.darkBgDeep : AppColors.lightBgDeep;
    final accentClr = dark ? AppColors.darkAccentNeon : AppColors.lightAccentPrimary;
    final textClr   = dark ? const Color(0xFFE2DEF0) : const Color(0xFF111111);

    return Directionality(
      textDirection: dir,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: accentClr, strokeWidth: 2.5))
              : _error != null
                  ? Center(child: Text(t('error_loading'),
                      style: TextStyle(color: dark ? Colors.white54 : Colors.black54, fontSize: 13)))
                  : CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverPersistentHeader(
                          floating: true,
                          delegate: _LibraryHeaderDelegate(
                            bgColor: bgColor,
                            child: Container(
                              color: bgColor,
                              padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 28, height: 28,
                                    decoration: BoxDecoration(
                                      color: accentClr.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: Icon(Icons.grid_view_rounded, size: 14, color: accentClr),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(t('libraryNav'), style: TextStyle(
                                    fontFamily: 'Tajawal', fontSize: 17,
                                    fontWeight: FontWeight.w900, color: textClr,
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
                              (ctx, i) => _LibraryCard(
                                manga: _list[i], dark: dark, accent: accentClr,
                              ),
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
  final Color bgColor;
  const _LibraryHeaderDelegate({required this.child, required this.bgColor});

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
  final bool dark;
  final Color accent;

  const _LibraryCard({required this.manga, required this.dark, required this.accent});

  @override
  Widget build(BuildContext context) {
    final textClr = dark ? const Color(0xFFE2DEF0) : const Color(0xFF111111);
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
                border: Border.all(color: accent.withOpacity(0.55), width: 1.5),
                boxShadow: [
                  BoxShadow(color: accent.withOpacity(0.35), blurRadius: 10, spreadRadius: 1),
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
                            placeholder: (_, __) => Container(color: const Color(0xFF161129)),
                            errorWidget: (_, __, ___) => Container(
                              color: const Color(0xFF161129),
                              child: const Icon(Icons.broken_image_outlined, color: Colors.white24, size: 22),
                            ),
                          )
                        : Container(color: const Color(0xFF161129)),
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
                        child: Text('${manga.rating.toStringAsFixed(1)} ★',
                            style: const TextStyle(fontSize: 10, color: Color(0xFFE8B85C), fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                          border: Border.all(color: accent.withOpacity(0.6), width: 1.2),
                          boxShadow: [BoxShadow(color: accent.withOpacity(0.35), blurRadius: 6)],
                        ),
                        child: Icon(Icons.favorite_border_rounded, color: Colors.white.withOpacity(0.9), size: 14),
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
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textClr)),
          ),
        ],
      ),
    );
  }
}
