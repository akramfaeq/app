import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_provider.dart';
import '../../models/manga_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/manga_service.dart';
import '../details/detail_page.dart';

// أزرق نيلي للكاردات بالوضع النهاري (القلوب والحدود)
const _lightCardAccent = Color(0xFF3F5EFB);

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _service    = MangaService();
  final _searchCtrl = TextEditingController();
  final _focusNode  = FocusNode();

  List<MangaModel> _allList = [];
  List<MangaModel> _results = [];
  bool _loading = true;

  final Set<String> _selectedGenres = {};
  String? _selectedType;
  String? _selectedStatus;

  static const _genres = [
    'أكشن', 'رعب', 'دراما', 'كوميدي', 'مغامرة', 'فانتازيا',
    'رومانسي', 'خيال علمي', 'رياضة', 'نفسي',
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await _service.fetchMangaList();
      if (!mounted) return;
      setState(() { _allList = list; _results = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _results = _allList.where((m) {
        if (q.isNotEmpty &&
            !m.title.toLowerCase().contains(q) &&
            !(m.description ?? '').toLowerCase().contains(q)) return false;
        if (_selectedType   != null && m.type   != _selectedType)  return false;
        if (_selectedStatus != null && m.status != _selectedStatus) return false;
        if (_selectedGenres.isNotEmpty &&
            !_selectedGenres.every((g) => m.genres.contains(g)))   return false;
        return true;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedGenres.clear();
      _selectedType   = null;
      _selectedStatus = null;
    });
    _applyFilters();
  }

  bool get _hasActiveFilters =>
      _selectedGenres.isNotEmpty || _selectedType != null || _selectedStatus != null;

  List<String> get _activeFilterLabels => [
    ..._selectedGenres,
    if (_selectedType   != null) _selectedType!,
    if (_selectedStatus != null) _selectedStatus!,
  ];

  void _removeFilterLabel(String label) {
    setState(() {
      if (_selectedGenres.contains(label)) _selectedGenres.remove(label);
      else if (_selectedType == label)     _selectedType   = null;
      else if (_selectedStatus == label)   _selectedStatus = null;
    });
    _applyFilters();
  }

  void _openFilterSheet(AppProvider provider) {
    final t      = provider.t;
    const types    = ['مانغا', 'مانهوا'];
    const statuses = ['مستمرة', 'مكتملة'];

    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) {
        final dark    = Theme.of(context).brightness == Brightness.dark;
        final accent  = dark ? AppColors.darkAccentNeon : const Color(0xFF3F5EFB);
        final cardBg  = dark ? const Color(0xFF1A1230) : Colors.white;
        final textClr = dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        final subClr  = dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

        return StatefulBuilder(builder: (ctx, setSheet) {
          void toggleGenre(String g) => setSheet(() {
            if (_selectedGenres.contains(g)) _selectedGenres.remove(g);
            else _selectedGenres.add(g);
          });
          void toggleType(String tp)  => setSheet(() =>
              _selectedType = _selectedType == tp ? null : tp);
          void toggleStatus(String s) => setSheet(() =>
              _selectedStatus = _selectedStatus == s ? null : s);

          return Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: accent.withOpacity(0.12)),
            ),
            child: Directionality(
              textDirection: provider.dir,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.filter_list_rounded, color: accent, size: 20),
                        const SizedBox(width: 6),
                        Text(t('filter_by'),
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textClr)),
                        const Spacer(),
                        if (_hasActiveFilters)
                          GestureDetector(
                            onTap: () { setSheet(_clearFilters); },
                            child: Text(t('clear_all'),
                                style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(t('genre_label'), style: TextStyle(fontSize: 11, color: subClr, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: _genres.map((g) => _Chip(
                        label: g, selected: _selectedGenres.contains(g),
                        accent: accent, dark: dark, textClr: textClr,
                        onTap: () => toggleGenre(g),
                      )).toList(),
                    ),
                    const SizedBox(height: 18),
                    Text(t('type_label'), style: TextStyle(fontSize: 11, color: subClr, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Row(
                      children: types.map((tp) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _Chip(label: tp, selected: _selectedType == tp,
                            accent: accent, dark: dark, textClr: textClr,
                            onTap: () => toggleType(tp)),
                      )).toList(),
                    ),
                    const SizedBox(height: 18),
                    Text(t('status_label'), style: TextStyle(fontSize: 11, color: subClr, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Row(
                      children: statuses.map((s) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _Chip(label: s, selected: _selectedStatus == s,
                            accent: accent, dark: dark, textClr: textClr,
                            onTap: () => toggleStatus(s)),
                      )).toList(),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        onPressed: () { _applyFilters(); Navigator.pop(context); },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent, foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0, shadowColor: Colors.transparent,
                        ),
                        child: Text(t('apply_filter'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final t        = provider.t;
    final dir      = provider.dir;

    final dark    = Theme.of(context).brightness == Brightness.dark;
    final bg      = dark ? AppColors.darkBgDeep : AppColors.lightBgDeep;
    final accent  = dark ? AppColors.darkAccentNeon : const Color(0xFF3F5EFB);
    // أزرق نيلي للكاردات بالنهاري
    final cardAccent = dark ? AppColors.darkAccentNeon : _lightCardAccent;
    final cardBg  = dark ? AppColors.darkBgCard : AppColors.lightBgCard;
    final textClr = dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subClr  = dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final labels  = _activeFilterLabels;

    final headerHeight = labels.isNotEmpty ? 102.0 : 60.0;

    return Directionality(
      textDirection: dir,
      child: Scaffold(
        backgroundColor: bg,
        body: Container(
          color: bg,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverSafeArea(
                bottom: false,
                sliver: SliverPersistentHeader(
                  floating: true,
                  delegate: _SearchHeaderDelegate(
                    minHeight: headerHeight,
                    maxHeight: headerHeight,
                    child: Container(
                      color: bg,
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: dark
                                          ? Colors.transparent
                                          : const Color(0xFF3F5EFB).withOpacity(0.35),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _searchCtrl,
                                    focusNode: _focusNode,
                                    textDirection: dir,
                                    style: TextStyle(color: textClr, fontSize: 14),
                                    decoration: InputDecoration(
                                      hintText: t('search_placeholder'),
                                      hintStyle: TextStyle(color: subClr, fontSize: 13),
                                      suffixIcon: provider.isArabic
                                          ? Icon(Icons.search_rounded,
                                              color: dark ? subClr : const Color(0xFF3F5EFB), size: 20)
                                          : null,
                                      prefixIcon: provider.isArabic
                                          ? (_searchCtrl.text.isNotEmpty
                                              ? GestureDetector(
                                                  onTap: () { _searchCtrl.clear(); _focusNode.unfocus(); },
                                                  child: Icon(Icons.close_rounded, color: subClr, size: 17))
                                              : null)
                                          : Icon(Icons.search_rounded,
                                              color: dark ? subClr : const Color(0xFF3F5EFB), size: 20),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () => _openFilterSheet(provider),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 48, height: 48,
                                      decoration: BoxDecoration(
                                        color: dark
                                            ? (_hasActiveFilters ? accent.withOpacity(0.12) : cardBg)
                                            : (_hasActiveFilters ? const Color(0xFF3F5EFB).withOpacity(0.12) : cardBg),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          // الليلي: حدود فقط لما في فلتر محدد
                                          color: dark
                                              ? (_hasActiveFilters ? accent.withOpacity(0.35) : Colors.transparent)
                                              : const Color(0xFF3F5EFB).withOpacity(_hasActiveFilters ? 0.6 : 0.35),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(Icons.filter_list_rounded,
                                            size: 22,
                                            color: dark
                                                ? (_hasActiveFilters ? accent : subClr)
                                                : const Color(0xFF3F5EFB)),
                                      ),
                                    ),
                                    if (_hasActiveFilters)
                                      Positioned(
                                        top: -2, right: -2,
                                        child: Container(
                                          width: 11, height: 11,
                                          decoration: BoxDecoration(
                                            color: Colors.redAccent,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: bg, width: 1.5),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (labels.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: provider.isArabic
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: labels.map((lbl) {
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: GestureDetector(
                                        onTap: () => _removeFilterLabel(lbl),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            // ليلي: بنفسجي | نهاري: أزرق نيلي
                                            color: dark
                                                ? accent.withOpacity(0.15)
                                                : const Color(0xFF3F5EFB).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: dark ? accent : const Color(0xFF3F5EFB),
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: dark
                                                    ? accent.withOpacity(0.3)
                                                    : const Color(0xFF3F5EFB).withOpacity(0.25),
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(lbl,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: dark ? accent : const Color(0xFF3F5EFB),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              Icon(Icons.close_rounded, size: 13,
                                                  color: dark ? accent : const Color(0xFF3F5EFB)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              if (_loading)
                SliverFillRemaining(
                  hasScrollBody: false,
                  fillOverscroll: true,
                  child: Container(
                    color: bg,
                    child: Center(child: CircularProgressIndicator(color: accent, strokeWidth: 2)),
                  ),
                )
              else if (_results.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  fillOverscroll: true,
                  child: Container(
                    color: bg,
                    child: _EmptyState(dark: dark, accent: accent, t: t),
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 12,
                      childAspectRatio: 110 / 185,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      // نمرر cardAccent للكاردات (أزرق نيلي بالنهاري)
                      (ctx, i) => _SearchCard(manga: _results[i], dark: dark, accent: cardAccent),
                      childCount: _results.length,
                    ),
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  fillOverscroll: true,
                  child: Container(color: bg),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight, maxHeight;
  final Widget child;

  const _SearchHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override double get minExtent => minHeight;
  @override double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox.expand(child: child);

  @override
  bool shouldRebuild(_SearchHeaderDelegate old) =>
      old.maxHeight != maxHeight || old.minHeight != minHeight || old.child != child;
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected, dark;
  final Color accent, textClr;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.selected, required this.accent,
      required this.dark, required this.textClr, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.22) : accent.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? accent.withOpacity(0.8) : accent.withOpacity(0.15),
            width: selected ? 1.5 : 1.2,
          ),
          boxShadow: selected ? [
            BoxShadow(color: accent.withOpacity(0.3), blurRadius: 8),
          ] : null,
        ),
        child: Text(label,
          style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700,
            // المحدد: دائماً accent (أزرق نيلي) | غير محدد: نص عادي
            color: selected ? accent : textClr,
          ),
        ),
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  final MangaModel manga;
  final bool dark;
  final Color accent;

  const _SearchCard({required this.manga, required this.dark, required this.accent});

  @override
  Widget build(BuildContext context) {
    final textClr = dark ? const Color(0xFFE2DEF0) : const Color(0xFF111111);
    final cardClr = dark ? const Color(0xFF161129) : const Color(0xFFF5F5FA);

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
                color: cardClr,
                // النهاري: حدود أزرق نيلي خفيف
                border: Border.all(
                  color: dark ? accent.withOpacity(0.55) : accent.withOpacity(0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: dark ? accent.withOpacity(0.35) : accent.withOpacity(0.12),
                    blurRadius: 10, spreadRadius: dark ? 1 : 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(dark ? 0.5 : 0.08),
                    blurRadius: 8, offset: const Offset(0, 4),
                  ),
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
                            placeholder: (_, __) => Container(color: cardClr),
                            errorWidget: (_, __, ___) => Container(
                              color: cardClr,
                              child: Icon(Icons.broken_image_outlined,
                                  color: dark ? Colors.white24 : const Color(0xFFBBBCE0),
                                  size: 22),
                            ),
                          )
                        : Container(color: cardClr),

                    // تدرج سفلي
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

                    // شارة التقييم — خلفية فاتحة بالنهاري لما ما في صورة
                    Positioned(
                      bottom: 8, left: 8,
                      child: Builder(builder: (context) {
                        final hasImage = manga.cover.isNotEmpty;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: (dark || hasImage)
                                ? Colors.black.withOpacity(0.75)
                                : const Color(0xFFEAEBF5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: (dark || hasImage)
                                  ? const Color(0xFFE8B85C).withOpacity(0.6)
                                  : const Color(0x40D97706),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${manga.rating.toStringAsFixed(1)} ★',
                            style: TextStyle(
                              fontSize: 10,
                              color: dark ? const Color(0xFFE8B85C) : const Color(0xFFD97706),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }),
                    ),

                    // ── زر القلب — أزرق نيلي بالنهاري ──
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: dark
                            ? Colors.black.withOpacity(0.5)
                            : Colors.white.withOpacity(0.85),
                          shape: BoxShape.circle,
                          border: Border.all(color: accent.withOpacity(0.6), width: 1.2),
                          boxShadow: [BoxShadow(color: accent.withOpacity(0.30), blurRadius: 6)],
                        ),
                        child: Icon(Icons.favorite_border_rounded,
                            color: dark ? Colors.white.withOpacity(0.9) : accent, size: 14),
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

class _EmptyState extends StatelessWidget {
  final bool dark;
  final Color accent;
  final String Function(String) t;

  const _EmptyState({required this.dark, required this.accent, required this.t});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 52, color: accent.withOpacity(0.2)),
          const SizedBox(height: 12),
          Text(t('no_results'),
              style: TextStyle(
                  color: dark ? Colors.white38 : Colors.black38,
                  fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(t('try_different'),
              style: TextStyle(color: dark ? Colors.white24 : Colors.black26, fontSize: 12)),
        ],
      ),
    );
  }
}
