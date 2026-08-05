import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_provider.dart';
import '../../models/manga_model.dart';
import '../../services/favorites_service.dart';
import '../details/detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    final all = FavoritesService.favorites;
    if (_selectedCat == 'all') return all;
    return all.where((f) => f.category == _selectedCat).toList();
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      _selectMode = _selectedIds.isNotEmpty;
    });
  }

  void _cancelSelect() => setState(() {
        _selectedIds.clear();
        _selectMode = false;
      });

  void _deleteSelected() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF1A1622) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              const Text('حذف من المفضلة؟',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('سيتم حذف ${_selectedIds.length} مانغا من قائمتك',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF7A728E))),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: dark
                                ? Colors.white.withOpacity(0.08)
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('إلغاء',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          for (final id in _selectedIds) {
                            FavoritesService.remove(id);
                          }
                          setState(() {
                            _selectedIds.clear();
                            _selectMode = false;
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE85C5C),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('حذف',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final t = provider.t;
    final dir = provider.dir;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? const Color(0xFF0A0714) : const Color(0xFFEDEEF4);
    final textPrimary = dark ? const Color(0xFFF0EEFF) : const Color(0xFF111111);
    final textSub = dark ? const Color(0xFF7A728E) : const Color(0xFF6B7280);
    final accent = dark ? AppColors.darkAccentNeon : const Color(0xFF3F5EFB);
    final accentSoft = dark ? AppColors.darkAccentPrimary : const Color(0xFF5B5BD6);

    final items = _filtered;

    return Directionality(
      textDirection: dir,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Column(
            children: [

              // ── هيدر ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    // زر رجوع
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: dark
                              ? const Color(0xFF1D1630)
                              : const Color(0xFFEEF0FA),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: accentSoft.withOpacity(0.55), width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(t('back') ?? 'رجوع',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: dark
                                        ? const Color(0xFFE2DEF0)
                                        : accentSoft)),
                            const SizedBox(width: 2),
                            Icon(Icons.chevron_right_rounded,
                                color: dark
                                    ? const Color(0xFFE2DEF0)
                                    : accentSoft,
                                size: 16),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    // عنوان وسط
                    Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE85A78).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.favorite_rounded,
                              color: Color(0xFFE85A78), size: 14),
                        ),
                        const SizedBox(width: 8),
                        Text(t('favorites') ?? 'المفضلة',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: textPrimary)),
                      ],
                    ),
                    const Spacer(),
                    // مساحة لموازنة الهيدر
                    const SizedBox(width: 70),
                  ],
                ),
              ),

              // ── شريط التحديد المتعدد ──
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: _selectMode ? 48 : 0,
                child: _selectMode
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: dark
                              ? const Color(0xFF1A1035)
                              : const Color(0xFF3F5EFB).withOpacity(0.1),
                          border: Border(
                            bottom: BorderSide(
                              color: dark
                                  ? const Color(0x339B5CF6)
                                  : const Color(0xFF3F5EFB).withOpacity(0.2),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text('${_selectedIds.length} محدد',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: dark
                                        ? const Color(0xFFC9B6F5)
                                        : accent)),
                            const Spacer(),
                            GestureDetector(
                              onTap: _cancelSelect,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: dark
                                      ? Colors.white.withOpacity(0.08)
                                      : accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: dark
                                          ? const Color(0x4D9B5CF6)
                                          : accent.withOpacity(0.3)),
                                ),
                                child: Text('إلغاء',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: dark
                                            ? const Color(0xFFC9B6F5)
                                            : accent)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _deleteSelected,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('حذف المحدد',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // ── تبويبات التصنيف ──
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                child: Row(
                  children: [
                    _CatTab(
                        label: t('all') ?? 'الكل',
                        cat: 'all',
                        selected: _selectedCat,
                        dark: dark,
                        accent: accent,
                        onTap: (c) => setState(() => _selectedCat = c)),
                    _CatTab(
                        label: t('reading') ?? 'أقرأه',
                        cat: 'reading',
                        selected: _selectedCat,
                        dark: dark,
                        accent: accent,
                        onTap: (c) => setState(() => _selectedCat = c)),
                    _CatTab(
                        label: t('planRead') ?? 'سأقرأه',
                        cat: 'planread',
                        selected: _selectedCat,
                        dark: dark,
                        accent: accent,
                        onTap: (c) => setState(() => _selectedCat = c)),
                    _CatTab(
                        label: t('paused') ?? 'متوقف',
                        cat: 'paused',
                        selected: _selectedCat,
                        dark: dark,
                        accent: accent,
                        onTap: (c) => setState(() => _selectedCat = c)),
                    _CatTab(
                        label: t('completedCat') ?? 'مكتمل',
                        cat: 'completed',
                        selected: _selectedCat,
                        dark: dark,
                        accent: accent,
                        onTap: (c) => setState(() => _selectedCat = c)),
                  ],
                ),
              ),

              // ── المحتوى ──
              Expanded(
                child: items.isEmpty
                    ? _buildEmpty(textSub)
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 14,
                          childAspectRatio: 110 / 185,
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
                            onTap: () {
                              if (_selectMode) {
                                _toggleSelect(item.id);
                              } else {
                                Navigator.push(
                                    ctx,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            DetailPage(manga: item.toManga())));
                              }
                            },
                            onLongPress: () {
                              HapticFeedback.mediumImpact();
                              _toggleSelect(item.id);
                            },
                            onCatTap: () =>
                                _showCatMenu(item, dark, accent, textPrimary),
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

  Widget _buildEmpty(Color textSub) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border_rounded,
              size: 52, color: textSub.withOpacity(0.5)),
          const SizedBox(height: 12),
          const Text('قائمتك فارغة',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFC9B6F5))),
          const SizedBox(height: 6),
          Text('ما أضفت أي مانغا للمفضلة بعد',
              style: TextStyle(fontSize: 13, color: textSub)),
        ],
      ),
    );
  }

  void _showCatMenu(
      FavoriteItem item, bool dark, Color accent, Color textPrimary) {
    HapticFeedback.selectionClick();
    final cardClr = dark ? const Color(0xFF130F1E) : Colors.white;
    final textSub =
        dark ? const Color(0xFF7A728E) : const Color(0xFF6B7280);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: cardClr,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: const Color(0xFFBF5FFF).withOpacity(0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(3)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('تصنيف المانغا',
                  style: TextStyle(
                      fontSize: 13,
                      color: textSub,
                      fontWeight: FontWeight.w600)),
            ),
            Text(item.title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: dark ? const Color(0xFFC9B6F5) : accent)),
            const SizedBox(height: 12),
            _CatMenuItem(
                icon: Icons.menu_book_rounded,
                color: const Color(0xFF9B5CF6),
                label: 'أقرأه حالياً',
                cat: 'reading',
                current: item.category,
                onTap: () {
                  FavoritesService.setCategory(item.id, 'reading');
                  setState(() {});
                  Navigator.pop(context);
                }),
            _CatMenuItem(
                icon: Icons.bookmark_rounded,
                color: const Color(0xFF3B82F6),
                label: 'سأقرأه',
                cat: 'planread',
                current: item.category,
                onTap: () {
                  FavoritesService.setCategory(item.id, 'planread');
                  setState(() {});
                  Navigator.pop(context);
                }),
            _CatMenuItem(
                icon: Icons.pause_circle_rounded,
                color: const Color(0xFFF59E0B),
                label: 'متوقف مؤقتاً',
                cat: 'paused',
                current: item.category,
                onTap: () {
                  FavoritesService.setCategory(item.id, 'paused');
                  setState(() {});
                  Navigator.pop(context);
                }),
            _CatMenuItem(
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF10B981),
                label: 'مكتمل',
                cat: 'completed',
                current: item.category,
                onTap: () {
                  FavoritesService.setCategory(item.id, 'completed');
                  setState(() {});
                  Navigator.pop(context);
                }),
            Divider(color: accent.withOpacity(0.1)),
            ListTile(
              leading: const Icon(Icons.cancel_rounded,
                  color: Color(0xFFE85C5C)),
              title: const Text('إزالة التصنيف',
                  style: TextStyle(
                      color: Color(0xFFE85C5C),
                      fontWeight: FontWeight.w600)),
              onTap: () {
                FavoritesService.setCategory(item.id, null);
                setState(() {});
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── تبويب التصنيف ──
class _CatTab extends StatelessWidget {
  final String label, cat, selected;
  final bool dark;
  final Color accent;
  final void Function(String) onTap;

  const _CatTab(
      {required this.label,
      required this.cat,
      required this.selected,
      required this.dark,
      required this.accent,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = cat == selected;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap(cat);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: isActive
                ? accent.withOpacity(0.18)
                : (dark
                    ? Colors.white.withOpacity(0.04)
                    : const Color(0xFFF5F5FA)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? accent.withOpacity(0.55)
                  : (dark
                      ? Colors.white.withOpacity(0.08)
                      : const Color(0xFFD1D5DB)),
              width: 1.5,
            ),
          ),
          child: Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? (dark ? const Color(0xFFE2DEF0) : accent)
                    : (dark
                        ? const Color(0xFF9B8FC0)
                        : const Color(0xFF374151)),
              )),
        ),
      ),
    );
  }
}

// ── كارد المفضلة ──
class _FavCard extends StatelessWidget {
  final FavoriteItem item;
  final bool dark, selected, selectMode;
  final Color accent;
  final VoidCallback onTap, onLongPress, onCatTap;

  const _FavCard(
      {required this.item,
      required this.dark,
      required this.selected,
      required this.selectMode,
      required this.accent,
      required this.onTap,
      required this.onLongPress,
      required this.onCatTap});

  void _showDeleteMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1035) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFFE85A78).withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.delete_rounded,
                  color: Color(0xFFE85A78)),
              title: const Text('حذف من المفضلة',
                  style: TextStyle(
                      color: Color(0xFFE85A78),
                      fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(context);
                onLongPress();
              },
            ),
            ListTile(
              leading: Icon(Icons.label_rounded, color: accent),
              title: Text('تغيير التصنيف',
                  style: TextStyle(
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF111111),
                      fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                onCatTap();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardBg =
        dark ? const Color(0xFF161129) : const Color(0xFFF5F5FA);
    final textClr =
        dark ? const Color(0xFFE2DEF0) : const Color(0xFF111111);

    return GestureDetector(
      onTap: onTap,
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showDeleteMenu(context);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: cardBg,
                border: Border.all(
                  color: selected
                      ? accent
                      : accent.withOpacity(dark ? 0.35 : 0.2),
                  width: selected ? 2.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                      color: selected
                          ? accent.withOpacity(0.35)
                          : Colors.black.withOpacity(dark ? 0.4 : 0.08),
                      blurRadius: 10),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // صورة الغلاف
                    item.cover.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.cover,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: cardBg),
                            errorWidget: (_, __, ___) => Container(
                                color: cardBg,
                                child: Icon(
                                    Icons.broken_image_outlined,
                                    color: dark
                                        ? Colors.white24
                                        : const Color(0xFFBBBCE0),
                                    size: 22)))
                        : Container(color: cardBg),

                    // gradient سفلي
                    if (item.cover.isNotEmpty)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.65),
                                Colors.transparent
                              ],
                              stops: const [0.0, 0.45],
                            ),
                          ),
                        ),
                      ),

                    // شارة التقييم
                    Positioned(
                      bottom: 7,
                      left: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                              color: const Color(0xFFE8B85C)
                                  .withOpacity(0.6)),
                        ),
                        child: Text(
                            '${item.rating.toStringAsFixed(1)} ★',
                            style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xFFE8B85C),
                                fontWeight: FontWeight.bold)),
                      ),
                    ),

                    // دائرة التحديد (select mode)
                    if (selectMode)
                      Positioned(
                        top: 7,
                        right: 7,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: selected
                                ? accent
                                : Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: accent, width: 1.5),
                          ),
                          child: Icon(
                            selected
                                ? Icons.check_rounded
                                : Icons.circle_outlined,
                            color: Colors.white,
                            size: 13,
                          ),
                        ),
                      ),

                    // badge التصنيف
                    if (item.category != null && !selectMode)
                      Positioned(
                        top: 7,
                        left: 7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _catColor(item.category!)
                                .withOpacity(0.85),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(_catLabel(item.category!),
                              style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 5),

          // اسم المانغا
          Text(item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: textClr)),

          const SizedBox(height: 4),

          // زر التصنيف
          GestureDetector(
            onTap: onCatTap,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: item.category != null
                    ? _catColor(item.category!).withOpacity(0.15)
                    : accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: item.category != null
                      ? _catColor(item.category!).withOpacity(0.5)
                      : accent.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.label_rounded,
                      size: 10,
                      color: item.category != null
                          ? _catColor(item.category!)
                          : accent),
                  const SizedBox(width: 3),
                  Text(
                    item.category != null
                        ? _catLabel(item.category!)
                        : '+ تصنيف',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: item.category != null
                          ? _catColor(item.category!)
                          : accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _catColor(String cat) {
    switch (cat) {
      case 'reading':
        return const Color(0xFF9B5CF6);
      case 'planread':
        return const Color(0xFF3B82F6);
      case 'paused':
        return const Color(0xFFF59E0B);
      case 'completed':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  String _catLabel(String cat) {
    switch (cat) {
      case 'reading':
        return 'أقرأه';
      case 'planread':
        return 'سأقرأه';
      case 'paused':
        return 'متوقف';
      case 'completed':
        return 'مكتمل';
      default:
        return '';
    }
  }
}

// ── عنصر قائمة التصنيف ──
class _CatMenuItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, cat;
  final String? current;
  final VoidCallback onTap;

  const _CatMenuItem(
      {required this.icon,
      required this.color,
      required this.label,
      required this.cat,
      required this.current,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = cat == current;
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(label,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? color : null)),
      trailing: isSelected
          ? Icon(Icons.check_rounded, color: color, size: 18)
          : null,
      onTap: onTap,
    );
  }
}
