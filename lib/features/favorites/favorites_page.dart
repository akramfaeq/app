import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_provider.dart';
import '../../models/manga_model.dart';
import '../../services/favorites_service.dart';
import '../details/detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

const _catColors = {
  'reading':   Color(0xFF9B5CF6),
  'planread':  Color(0xFF3B82F6),
  'paused':    Color(0xFFF59E0B),
  'completed': Color(0xFF10B981),
};
const _catTabLabels = {
  'reading':   'أقرأه',
  'planread':  'سأقرأه',
  'paused':    'متوقف',
  'completed': 'مكتمل',
};

// ── ثوابت الألوان الداكنة ──
const _bg          = Color(0xFF0A0714);
const _cardBg      = Color(0xFF130F1E);
const _textPrimary = Color(0xFFF0EEFF);
const _textSub     = Color(0xFF7A728E);
const _accent      = Color(0xFFBF5FFF);

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});
  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  String _selectedCat = 'all';
  final Set<String> _selectedIds = {};
  bool _selectMode = false;

  List<FavoriteItem> get _filtered {
    final all = FavoritesService.instance.favorites;
    if (_selectedCat == 'all') return all;
    return all.where((f) => f.category == _selectedCat).toList();
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) _selectedIds.remove(id);
      else _selectedIds.add(id);
      _selectMode = _selectedIds.isNotEmpty;
    });
  }

  void _cancelSelect() => setState(() { _selectedIds.clear(); _selectMode = false; });

  void _deleteSelected() {
    for (final id in _selectedIds) FavoritesService.instance.remove(id);
    setState(() { _selectedIds.clear(); _selectMode = false; });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FavoritesService>();
    final provider = context.watch<AppProvider>();
    final t        = provider.t;
    final dir      = provider.dir;
    final items    = _filtered;

    return Directionality(
      textDirection: dir,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () { HapticFeedback.selectionClick(); Navigator.pop(context); },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0x2EBF5FFF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0x8CBF5FFF), width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(t('back') ?? 'رجوع',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFE2DEF0))),
                            const SizedBox(width: 4),
                            const Text('›', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFE2DEF0))),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          width: 26, height: 26,
                          decoration: BoxDecoration(color: const Color(0x2EE85A78), borderRadius: BorderRadius.circular(8)),
                          child: const Center(child: Icon(Icons.favorite_rounded, color: Color(0xFFE85A78), size: 14)),
                        ),
                        const SizedBox(width: 8),
                        Text(t('favorites') ?? 'المفضلة',
                          style: const TextStyle(
                            fontFamily: 'Archivo Black', fontSize: 17,
                            fontWeight: FontWeight.w900, color: _textPrimary,
                          )),
                      ],
                    ),
                    const Spacer(),
                    const SizedBox(width: 70),
                  ],
                ),
              ),

              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: _selectMode ? 46 : 0,
                child: _selectMode ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0x268B5CF6),
                    border: Border(bottom: BorderSide(color: const Color(0x4D8B5CF6))),
                  ),
                  child: Row(
                    children: [
                      Text('${_selectedIds.length} ${t('select_count')}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFC9B6F5))),
                      const Spacer(),
                      GestureDetector(
                        onTap: _cancelSelect,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0x148B5CF6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0x4D8B5CF6)),
                          ),
                          child: Text(t('cancel'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFC9B6F5))),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _deleteSelected,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(10)),
                          child: Text(t('delete_selected'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ) : const SizedBox.shrink(),
              ),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                child: Row(
                  children: [
                    _CatTab(label: t('all'),          cat: 'all',       selected: _selectedCat, onTap: (c) => setState(() => _selectedCat = c)),
                    _CatTab(label: t('reading'),      cat: 'reading',   selected: _selectedCat, onTap: (c) => setState(() => _selectedCat = c)),
                    _CatTab(label: t('planRead'),     cat: 'planread',  selected: _selectedCat, onTap: (c) => setState(() => _selectedCat = c)),
                    _CatTab(label: t('paused'),       cat: 'paused',    selected: _selectedCat, onTap: (c) => setState(() => _selectedCat = c)),
                    _CatTab(label: t('completedCat'), cat: 'completed', selected: _selectedCat, onTap: (c) => setState(() => _selectedCat = c)),
                  ],
                ),
              ),

              Expanded(
                child: items.isEmpty
                    ? _buildEmpty(t)
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, crossAxisSpacing: 10,
                          mainAxisSpacing: 10, childAspectRatio: 0.52,
                        ),
                        itemCount: items.length,
                        itemBuilder: (ctx, i) {
                          final item = items[i];
                          final selected = _selectedIds.contains(item.id);
                          return _FavCard(
                            item: item,
                            selected: selected,
                            selectMode: _selectMode,
                            tFunc: t,
                            onTap: () {
                              if (_selectMode) {
                                _toggleSelect(item.id);
                              } else {
                                Navigator.push(ctx, MaterialPageRoute(
                                    builder: (_) => DetailPage(manga: item.toManga())));
                              }
                            },
                            onLongPress: () {
                              HapticFeedback.mediumImpact();
                              _toggleSelect(item.id);
                            },
                            onCatTap: () => _showCatMenu(item, t),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(String Function(String) t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border_rounded, size: 48, color: _textSub.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(t('empty_list'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFC9B6F5))),
          const SizedBox(height: 6),
          Text(t('empty_list_sub'), style: const TextStyle(fontSize: 13, color: _textSub)),
        ],
      ),
    );
  }

  void _showCatMenu(FavoriteItem item, String Function(String) t) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: const Color(0x40BF5FFF)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t('cat_menu_title'), style: const TextStyle(fontSize: 13, color: Color(0xFF9B8FC0))),
            const SizedBox(height: 8),
            Text(item.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFC9B6F5))),
            const SizedBox(height: 14),
            _menuItem(icon: Icons.menu_book_outlined, color: const Color(0xFF9B5CF6),
                label: t('cat_reading'), cat: 'reading', current: item.category,
                onTap: () { FavoritesService.instance.setCategory(item.id, 'reading'); setState(() {}); Navigator.pop(context); }),
            _menuItem(icon: Icons.bookmark_border_rounded, color: const Color(0xFF3B82F6),
                label: t('cat_planread'), cat: 'planread', current: item.category,
                onTap: () { FavoritesService.instance.setCategory(item.id, 'planread'); setState(() {}); Navigator.pop(context); }),
            _menuItem(icon: Icons.pause_circle_outline_rounded, color: const Color(0xFFF59E0B),
                label: t('cat_paused'), cat: 'paused', current: item.category,
                onTap: () { FavoritesService.instance.setCategory(item.id, 'paused'); setState(() {}); Navigator.pop(context); }),
            _menuItem(icon: Icons.check_circle_outline_rounded, color: const Color(0xFF10B981),
                label: t('cat_completed'), cat: 'completed', current: item.category,
                onTap: () { FavoritesService.instance.setCategory(item.id, 'completed'); setState(() {}); Navigator.pop(context); }),
            GestureDetector(
              onTap: () { FavoritesService.instance.setCategory(item.id, null); setState(() {}); Navigator.pop(context); },
              child: Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: const Color(0x14E85C5C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cancel_outlined, color: Color(0xFFE85C5C), size: 20),
                    const SizedBox(width: 12),
                    Text(t('cat_remove'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFE85C5C))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required Color color,
    required String label,
    required String cat,
    required String? current,
    required VoidCallback onTap,
  }) {
    final isSelected = cat == current;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color.withOpacity(0.4) : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: isSelected ? color : _textPrimary,
            )),
            const Spacer(),
            if (isSelected) Icon(Icons.check_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

class _CatTab extends StatelessWidget {
  final String label, cat, selected;
  final void Function(String) onTap;

  const _CatTab({required this.label, required this.cat, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = cat == selected;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); onTap(cat); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: isActive ? const Color(0x2EBF5FFF) : const Color(0x0AFFFFFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? const Color(0x8CBF5FFF) : const Color(0x33BF5FFF),
              width: 1.5,
            ),
          ),
          child: Text(label, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: isActive ? const Color(0xFFE2DEF0) : const Color(0xFF9B8FC0),
          )),
        ),
      ),
    );
  }
}

class _FavCard extends StatelessWidget {
  final FavoriteItem item;
  final bool selected, selectMode;
  final VoidCallback onTap, onLongPress, onCatTap;
  final String Function(String)? tFunc;

  const _FavCard({
    required this.item, required this.selected, required this.selectMode,
    required this.onTap, required this.onLongPress, required this.onCatTap,
    this.tFunc,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 148,
            width: double.infinity,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    height: 148,
                    decoration: BoxDecoration(
                      color: const Color(0xFF161129),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? _accent : const Color(0x40BF5FFF),
                        width: selected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: selected ? _accent.withOpacity(0.4) : Colors.black.withOpacity(0.4),
                          blurRadius: 12,
                        ),
                        const BoxShadow(color: Color(0x26BF5FFF), blurRadius: 12),
                      ],
                    ),
                    child: item.cover.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.cover, fit: BoxFit.cover,
                            placeholder: (_, __) => const SizedBox.shrink(),
                            errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Colors.white24, size: 22),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),

                if (item.cover.isNotEmpty)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter, end: Alignment.topCenter,
                            colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                            stops: const [0.0, 0.5],
                          ),
                        ),
                      ),
                    ),
                  ),

                Positioned(
                  bottom: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x59E8B85C)),
                      boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8)],
                    ),
                    child: Text('★ ${item.rating.toStringAsFixed(1)}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFE8B85C))),
                  ),
                ),

                if (selectMode)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        color: selected ? const Color(0x728B5CF6) : Colors.transparent,
                        child: selected
                            ? const Center(child: Text('✓', style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)))
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 5),
          Text(item.title,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFFE2DEF0))),

          const SizedBox(height: 3),
          GestureDetector(
            onTap: onCatTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0x1ABF5FFF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0x33BF5FFF)),
              ),
              child: Text(
                item.category != null
                    ? (tFunc != null ? tFunc!('cat_${item.category}') : (item.category ?? '+ تصنيف'))
                    : (tFunc != null ? tFunc!('add_category') : '+ تصنيف'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: Color(0xFFC9B6F5), fontFamily: 'Tajawal'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
