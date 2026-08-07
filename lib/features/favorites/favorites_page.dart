import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_provider.dart';
import '../../models/manga_model.dart';
import '../../services/favorites_service.dart';
import '../details/detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ألوان التصنيفات — مطابقة HTML
const _catColors = {
  'reading':   Color(0xFF9B5CF6),
  'planread':  Color(0xFF3B82F6),
  'paused':    Color(0xFFF59E0B),
  'completed': Color(0xFF10B981),
};
const _catLabels = {
  'reading':   'أقرأه حالياً',
  'planread':  'سأقرأه',
  'paused':    'متوقف مؤقتاً',
  'completed': 'مكتمل',
};
const _catTabLabels = {
  'reading':   'أقرأه',
  'planread':  'سأقرأه',
  'paused':    'متوقف',
  'completed': 'مكتمل',
};

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
    context.watch<FavoritesService>(); //[cite: 5] يتحدث لما تتغير المفضلة
    final provider    = context.watch<AppProvider>();
    final t           = provider.t;
    final dir         = provider.dir;
    final dark        = Theme.of(context).brightness == Brightness.dark;
    final bg          = dark ? const Color(0xFF0A0714) : const Color(0xFFEDEEF4);
    final textPrimary = dark ? const Color(0xFFF0EEFF) : const Color(0xFF111111);
    final textSub     = dark ? const Color(0xFF7A728E) : const Color(0xFF6B7280);
    // تم تعديل اللون النهاري للأزرق النيلي 3B82F6
    final accent      = dark ? const Color(0xFFBF5FFF) : const Color(0xFF3B82F6);

    final items = _filtered;

    return Directionality(
      textDirection: dir,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Column(
            children: [

              // ── هيدر — مطابق HTML ──[cite: 5]
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    // زر رجوع — نفس .fav-back-btn[cite: 5]
                    GestureDetector(
                      onTap: () { HapticFeedback.selectionClick(); Navigator.pop(context); },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: dark ? const Color(0x2EBF5FFF) : const Color(0xFFEEF0FA),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: dark ? const Color(0x8CBF5FFF) : const Color(0xFF3B82F6),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(t('back') ?? 'رجوع',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: dark ? const Color(0xFFE2DEF0) : const Color(0xFF3B82F6),
                              )),
                            const SizedBox(width: 4),
                            Text('›',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: dark ? const Color(0xFFE2DEF0) : const Color(0xFF3B82F6),
                              )),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    // عنوان + أيقونة قلب — مطابق HTML[cite: 5]
                    Row(
                      children: [
                        Container(
                          width: 26, height: 26,
                          decoration: BoxDecoration(
                            color: const Color(0x2EE85A78),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(Icons.favorite_rounded, color: Color(0xFFE85A78), size: 14),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(t('favorites') ?? 'المفضلة',
                          style: TextStyle(
                            fontFamily: 'Archivo Black',
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                          )),
                      ],
                    ),
                    const Spacer(),
                    const SizedBox(width: 70),
                  ],
                ),
              ),

              // ── شريط التحديد — مطابق .fav-select-bar ──[cite: 5]
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: _selectMode ? 46 : 0,
                child: _selectMode ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: dark
                        ? const Color(0x268B5CF6)
                        : const Color(0x1A3B82F6),
                    border: Border(
                      bottom: BorderSide(
                        color: dark
                            ? const Color(0x4D8B5CF6)
                            : const Color(0x333B82F6),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text('${_selectedIds.length} ${t('select_count')}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: dark ? const Color(0xFFC9B6F5) : const Color(0xFF3B82F6),
                        )),
                      const Spacer(),
                      GestureDetector(
                        onTap: _cancelSelect,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: dark ? const Color(0x148B5CF6) : const Color(0x1A3B82F6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: dark ? const Color(0x4D8B5CF6) : const Color(0x4D3B82F6),
                            ),
                          ),
                          child: Text(t('cancel'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: dark ? const Color(0xFFC9B6F5) : const Color(0xFF3B82F6),
                            )),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _deleteSelected,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(t('delete_selected'),
                            style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white,
                            )),
                        ),
                      ),
                    ],
                  ),
                ) : const SizedBox.shrink(),
              ),

              // ── تبويبات التصنيف — مطابق .fav-cat-btn ──[cite: 5]
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                child: Row(
                  children: [
                    _CatTab(label: t('all'),          cat: 'all',       selected: _selectedCat, dark: dark, accent: accent, onTap: (c) => setState(() => _selectedCat = c)),
                    _CatTab(label: t('reading'),      cat: 'reading',   selected: _selectedCat, dark: dark, accent: accent, onTap: (c) => setState(() => _selectedCat = c)),
                    _CatTab(label: t('planRead'),     cat: 'planread',  selected: _selectedCat, dark: dark, accent: accent, onTap: (c) => setState(() => _selectedCat = c)),
                    _CatTab(label: t('paused'),       cat: 'paused',    selected: _selectedCat, dark: dark, accent: accent, onTap: (c) => setState(() => _selectedCat = c)),
                    _CatTab(label: t('completedCat'), cat: 'completed', selected: _selectedCat, dark: dark, accent: accent, onTap: (c) => setState(() => _selectedCat = c)),
                  ],
                ),
              ),

              // ── المحتوى ──[cite: 5]
              Expanded(
                child: items.isEmpty
                    ? _buildEmpty(dark, textSub, t)
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.52, // تقريبي لـ 148px cover + نص + نجوم + زر[cite: 5]
                        ),
                        itemCount: items.length,
                        itemBuilder: (ctx, i) {
                          final item = items[i];
                          final selected = _selectedIds.contains(item.id);
                          return _FavCard(
                            item: item,
                            dark: dark,
                            accent: accent,
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
                            onCatTap: () => _showCatMenu(item, dark, accent, textPrimary, t),
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

  // ── حالة فارغة — مطابق HTML ──[cite: 5]
  Widget _buildEmpty(bool dark, Color textSub, String Function(String) t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border_rounded, size: 48, color: textSub.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(t('empty_list'),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: dark ? const Color(0xFFC9B6F5) : const Color(0xFF374151),
            )),
          const SizedBox(height: 6),
          Text(t('empty_list_sub'),
            style: TextStyle(fontSize: 13, color: textSub)),
        ],
      ),
    );
  }

  // ── قائمة التصنيف — مطابق #fav-cat-menu ──[cite: 5]
  void _showCatMenu(FavoriteItem item, bool dark, Color accent, Color textPrimary, String Function(String) t) {
    HapticFeedback.selectionClick();
    final bgColor = dark ? const Color(0xFF130F1E) : const Color(0xFFF5F5FA);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: dark ? const Color(0x40BF5FFF) : const Color(0x403B82F6)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t('cat_menu_title'),
              style: TextStyle(fontSize: 13, color: dark ? const Color(0xFF9B8FC0) : const Color(0xFF6B7280)),
            ),
            const SizedBox(height: 8),
            Text(item.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: dark ? const Color(0xFFC9B6F5) : const Color(0xFF111111),
              )),
            const SizedBox(height: 14),
            _menuItem(dark: dark, icon: Icons.menu_book_outlined, color: const Color(0xFF9B5CF6),
                label: t('cat_reading'), cat: 'reading', current: item.category,
                onTap: () { FavoritesService.instance.setCategory(item.id, 'reading'); setState(() {}); Navigator.pop(context); }),
            _menuItem(dark: dark, icon: Icons.bookmark_border_rounded, color: const Color(0xFF3B82F6),
                label: t('cat_planread'), cat: 'planread', current: item.category,
                onTap: () { FavoritesService.instance.setCategory(item.id, 'planread'); setState(() {}); Navigator.pop(context); }),
            _menuItem(dark: dark, icon: Icons.pause_circle_outline_rounded, color: const Color(0xFFF59E0B),
                label: t('cat_paused'), cat: 'paused', current: item.category,
                onTap: () { FavoritesService.instance.setCategory(item.id, 'paused'); setState(() {}); Navigator.pop(context); }),
            _menuItem(dark: dark, icon: Icons.check_circle_outline_rounded, color: const Color(0xFF10B981),
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
                  border: Border.all(color: Colors.transparent),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cancel_outlined, color: Color(0xFFE85C5C), size: 20),
                    const SizedBox(width: 12),
                    Text(t('cat_remove'),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFE85C5C))),
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
    required bool dark,
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
          color: isSelected ? color.withOpacity(0.15) : (dark ? const Color(0x0AFFFFFF) : const Color(0x0A000000)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.4) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? color : (dark ? const Color(0xFFF0EEFF) : const Color(0xFF111111)),
              )),
            const Spacer(),
            if (isSelected) Icon(Icons.check_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── تبويب التصنيف — مطابق .fav-cat-btn ──[cite: 5]
class _CatTab extends StatelessWidget {
  final String label, cat, selected;
  final bool dark;
  final Color accent;
  final void Function(String) onTap;

  const _CatTab({required this.label, required this.cat, required this.selected,
      required this.dark, required this.accent, required this.onTap});

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
            color: isActive
                ? (dark ? const Color(0x2EBF5FFF) : const Color(0xFF3B82F6).withOpacity(0.12))
                : (dark ? const Color(0x0AFFFFFF) : const Color(0xFFF5F5FA)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? (dark ? const Color(0x8CBF5FFF) : const Color(0xFF3B82F6))
                  : (dark ? const Color(0x33BF5FFF) : const Color(0xFFD1D5DB)),
              width: 1.5,
            ),
          ),
          child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isActive
                  ? (dark ? const Color(0xFFE2DEF0) : const Color(0xFF3B82F6))
                  : (dark ? const Color(0xFF9B8FC0) : const Color(0xFF374151)),
            )),
        ),
      ),
    );
  }
}

// ── كارد المفضلة — مطابق .grid-item-v2 ──[cite: 5]
class _FavCard extends StatelessWidget {
  final FavoriteItem item;
  final bool dark, selected, selectMode;
  final Color accent;
  final VoidCallback onTap, onLongPress, onCatTap;
  final String Function(String)? tFunc;

  const _FavCard({required this.item, required this.dark, required this.selected,
      required this.selectMode, required this.accent,
      required this.onTap, required this.onLongPress, required this.onCatTap,
      this.tFunc});

  @override
  Widget build(BuildContext context) {
    final catColor = _catColors[item.category];
    final catLabel = _catTabLabels[item.category];

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── الغلاف — height: 148px مطابق HTML ──[cite: 5]
          SizedBox(
            height: 148,
            width: double.infinity,
            child: Stack(
              children: [
                // صورة الغلاف[cite: 5]
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    height: 148,
                    decoration: BoxDecoration(
                      color: dark ? const Color(0xFF161129) : const Color(0xFFE2E4ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? accent
                            : (dark ? const Color(0x40BF5FFF) : const Color(0xFFD1D5DB)),
                        width: selected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: selected
                              ? accent.withOpacity(0.4)
                              : const Color(0xFF000000).withOpacity(dark ? 0.4 : 0.08),
                          blurRadius: 12,
                        ),
                        if (dark)
                          const BoxShadow(
                            color: Color(0x26BF5FFF),
                            blurRadius: 12,
                          ),
                      ],
                    ),
                    child: item.cover.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.cover,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const SizedBox.shrink(),
                            errorWidget: (_, __, ___) => Icon(
                              Icons.broken_image_outlined,
                              color: dark ? Colors.white24 : const Color(0xFFBBBCE0),
                              size: 22,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),

                // gradient سفلي فوق الصورة[cite: 5]
                if (item.cover.isNotEmpty)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                            stops: const [0.0, 0.5],
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── badge تقييم — أسفل يسار، مطابق .cover-rating-badge ──[cite: 5]
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
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE8B85C),
                      )),
                  ),
                ),

                // ── checkmark في وضع التحديد ──[cite: 5]
                if (selectMode)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        color: selected ? (dark ? const Color(0x728B5CF6) : const Color(0x723B82F6)) : Colors.transparent,
                        child: selected
                            ? const Center(
                                child: Text('✓',
                                  style: TextStyle(
                                    fontSize: 32,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  )))
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── اسم المانغا — مطابق .item-title ──[cite: 5]
          const SizedBox(height: 5),
          Text(item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textDirection: TextDirection.ltr, // مطابق HTML: direction: ltr[cite: 5]
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: dark ? const Color(0xFFE2DEF0) : const Color(0xFF111111),
            )),

          // ── زر التصنيف ──[cite: 5]
          const SizedBox(height: 3),
          GestureDetector(
            onTap: onCatTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 3),
              decoration: BoxDecoration(
                color: dark ? const Color(0x1ABF5FFF) : const Color(0xFFEEF0FA),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: dark ? const Color(0x33BF5FFF) : const Color(0xFFC7D2FE),
                ),
              ),
              child: Text(
                item.category != null
                    ? (tFunc != null ? tFunc!('cat_${item.category}') : (item.category ?? '+ تصنيف'))
                    : (tFunc != null ? tFunc!('add_category') : '+ تصنيف'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: dark ? const Color(0xFFC9B6F5) : const Color(0xFF3B82F6),
                  fontFamily: 'Tajawal',
                )),
            ),
          ),
        ],
      ),
    );
  }
}