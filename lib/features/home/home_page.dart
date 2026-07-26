import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_provider.dart';
import '../../models/manga_model.dart';
import '../../services/manga_service.dart';
import '../../shared/widgets/manga_card.dart';

class HomePage extends StatefulWidget {
  final void Function(int, {bool sortByRating})? onNavigate;
  const HomePage({super.key, this.onNavigate});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _service = MangaService();
  List<MangaModel> _list = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() { _loading = true; _error = null; });
      final list = await _service.fetchMangaList();
      if (mounted) setState(() { _list = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? AppColors.darkBgDeep : AppColors.lightBgDeep,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: dark ? AppColors.darkAccentNeon : AppColors.lightAccentPrimary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: _topBar(p, dark)),
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'خطأ، اسحب للتحديث',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: _section(
                    p, dark,
                    'آخر الإصدارات',
                    Icons.access_time_rounded,
                    const Color(0xFF8B5CF6),
                    const Color(0x338B5CF6),
                    _service.getLatestReleases(_list).take(15).toList(),
                    () => widget.onNavigate?.call(0),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _section(
                    p, dark,
                    'الأعلى تقييماً',
                    Icons.star_rounded,
                    AppColors.starColor,
                    const Color(0x33E8B85C),
                    _service.getTopRated(_list).take(15).toList(),
                    () => widget.onNavigate?.call(1, sortByRating: true),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _section(
                    p, dark,
                    'مكتبة المانغا',
                    null, null, null,
                    (_list.toList()..shuffle()).take(15).toList(),
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

  Widget _topBar(AppProvider p, bool dark) {
    final accent = dark ? AppColors.darkAccentNeon : AppColors.lightAccentPrimary;
    final textClr = dark ? const Color(0xFFE2DEF0) : const Color(0xFF111111);
    final neonGlow = dark ? const Color(0x40BF5FFF) : const Color(0x305B5BD6);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          // الأفاتار - دائرة مطابقة للأصلي
          GestureDetector(
            onTap: () => widget.onNavigate?.call(3),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4A1F80), Color(0xFF1A1030)],
                ),
                border: Border.all(color: accent, width: 2),
                boxShadow: [
                  BoxShadow(color: neonGlow, blurRadius: 16),
                  BoxShadow(
                    color: const Color(0x4DBF5FFF),
                    blurRadius: 32,
                  ),
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
          // اللوغو - "Manga" فقط مطابق للأصلي مع text shadow نيون
          Text(
            'Manga',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: textClr,
              shadows: [
                Shadow(color: accent, blurRadius: 20),
                Shadow(color: neonGlow, blurRadius: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(
    AppProvider p,
    bool dark,
    String title,
    IconData? icon,
    Color? iconClr,
    Color? iconBg,
    List<MangaModel> items,
    VoidCallback onSeeAll,
  ) {
    final accent = dark ? AppColors.darkAccentNeon : AppColors.lightAccentPrimary;
    final titleClr = dark ? const Color(0xFFE2DEF0) : const Color(0xFF111111);

    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // هيدر السكشن
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 13, color: iconClr),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: titleClr,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onSeeAll,
                  child: Text(
                    'عرض الكل',
                    style: TextStyle(
                      fontSize: 13,
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // السلايدر - padding-left: 40 لإظهار نص الكارد الرابعة
          SizedBox(
            height: 222,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              // padding يمين 16 + يسار 40 لإظهار نص الكارد الرابعة كتلميح
              padding: const EdgeInsets.only(right: 16, left: 40),
              itemCount: items.length,
              itemBuilder: (ctx, i) => Padding(
                padding: const EdgeInsets.only(left: 12),
                child: MangaCard(
                  manga: items[i],
                  onTap: () => debugPrint(items[i].title),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
