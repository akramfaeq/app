import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../models/manga_model.dart';
import '../../services/manga_service.dart';

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
  static const _types    = ['مانغا', 'مانهوا'];
  static const _statuses = ['مستمرة', 'مكتملة'];

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

  void _openFilterSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) {
        final dark    = Theme.of(context).brightness == Brightness.dark;
        final accent  = dark ? AppColors.darkAccentNeon : AppColors.lightAccentPrimary;
        final cardBg  = dark ? const Color(0xFF1A1230) : Colors.white;
        final textClr = dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        final subClr  = dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

        return StatefulBuilder(builder: (ctx, setSheet) {
          void toggleGenre(String g) => setSheet(() {
            if (_selectedGenres.contains(g)) _selectedGenres.remove(g);
            else _selectedGenres.add(g);
          });
          void toggleType(String t) => setSheet(() =>
              _selectedType = _selectedType == t ? null : t);
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
              textDirection: TextDirection.rtl,
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
                        Text('تصنيف بواسطة',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textClr)),
                        const Spacer(),
                        if (_hasActiveFilters)
                          GestureDetector(
                            onTap: () { setSheet(_clearFilters); },
                            child: Text('مسح الكل',
                                style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text('التصنيف', style: TextStyle(fontSize: 11, color: subClr, fontWeight: FontWeight.w600)),
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
                    Text('النوع', style: TextStyle(fontSize: 11, color: subClr, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Row(
                      children: _types.map((t) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _Chip(label: t, selected: _selectedType == t,
                            accent: accent, dark: dark, textClr: textClr,
                            onTap: () => toggleType(t)),
                      )).toList(),
                    ),
                    const SizedBox(height: 18),
                    Text('الحالة', style: TextStyle(fontSize: 11, color: subClr, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Row(
                      children: _statuses.map((s) => Padding(
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
                        child: const Text('تطبيق', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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
    final dark    = Theme.of(context).brightness == Brightness.dark;
    final bg      = dark ? AppColors.darkBgDeep : AppColors.lightBgDeep;
    final accent  = dark ? AppColors.darkAccentNeon : AppColors.lightAccentPrimary;
    final cardBg  = dark ? AppColors.darkBgCard : AppColors.lightBgCard;
    final textClr = dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subClr  = dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final labels  = _activeFilterLabels;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              // ===== الهيدر =====
              Container(
                color: bg,
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
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
                              border: Border.all(color: accent.withOpacity(0.15)),
                            ),
                            child: TextField(
                              controller: _searchCtrl,
                              focusNode: _focusNode,
                              style: TextStyle(color: textClr, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'ابحث عن مانغا...',
                                hintStyle: TextStyle(color: subClr, fontSize: 13),
                                suffixIcon: Icon(Icons.search_rounded, color: subClr, size: 20),
                                prefixIcon: _searchCtrl.text.isNotEmpty
                                    ? GestureDetector(
                                        onTap: () { _searchCtrl.clear(); _focusNode.unfocus(); },
                                        child: Icon(Icons.close_rounded, color: subClr, size: 17))
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                isDense: true,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _openFilterSheet,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  color: _hasActiveFilters ? accent.withOpacity(0.12) : cardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: accent.withOpacity(_hasActiveFilters ? 0.35 : 0.15),
                                    width: 1.2,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.filter_list_rounded,
                                    size: 22,
                                    color: _hasActiveFilters ? accent : subClr,
                                  ),
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
                        alignment: Alignment.centerRight,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: labels.map((lbl) => Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: GestureDetector(
                                onTap: () => _removeFilterLabel(lbl),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: accent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: accent.withOpacity(0.35), width: 1),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(lbl, style: TextStyle(
                                        fontSize: 12,
                                        color: dark ? accent : textClr,
                                        fontWeight: FontWeight.w700,
                                      )),
                                      const SizedBox(width: 5),
                                      Icon(Icons.close_rounded, size: 13, color: dark ? accent : subClr),
                                    ],
                                  ),
                                ),
                              ),
                            )).toList(),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ===== الگريد =====
              Expanded(
                child: _loading
                    ? Center(child: CircularProgressIndicator(color: accent, strokeWidth: 2))
                    : _results.isEmpty
                        ? _EmptyState(dark: dark, accent: accent)
                        : GridView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 12,
                              childAspectRatio: 110 / 185,
                            ),
                            itemCount: _results.length,
                            itemBuilder: (ctx, i) =>
                                _SearchCard(manga: _results[i], dark: dark, accent: accent),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
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

    return GestureDetector(
      onTap: () => debugPrint('تفاصيل: ${manga.title}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFF161129),
                border: Border.all(
                  color: accent.withOpacity(0.55),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.35),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
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
                            imageUrl: manga.cover,
                            fit: BoxFit.cover,
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
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.65),
                              Colors.transparent,
                            ],
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
                          border: Border.all(
                            color: const Color(0xFFE8B85C).withOpacity(0.6),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${manga.rating.toStringAsFixed(1)} ★',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFFE8B85C),
                            fontWeight: FontWeight.bold,
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
                          border: Border.all(color: accent.withOpacity(0.6), width: 1.2),
                          boxShadow: [
                            BoxShadow(color: accent.withOpacity(0.35), blurRadius: 6),
                          ],
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
            child: Text(
              manga.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textClr),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool dark;
  final Color accent;
  const _EmptyState({required this.dark, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 52, color: accent.withOpacity(0.2)),
          const SizedBox(height: 12),
          Text('لا توجد نتائج', style: TextStyle(
              color: dark ? Colors.white38 : Colors.black38,
              fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('جرب تغيير الفلاتر أو كلمة البحث',
              style: TextStyle(color: dark ? Colors.white24 : Colors.black26, fontSize: 12)),
        ],
      ),
    );
  }
}