import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_provider.dart';
import '../../features/home/home_page.dart';
import '../../features/library/library_page.dart';
import '../../features/search/search_page.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});
  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _index = 0;
  bool _librarySortByRating = false;

  int _libraryKey = 0;

  void _nav(int index, {bool sortByRating = false}) {
    setState(() {
      _index = index;
      if (index == 1) {
        _librarySortByRating = sortByRating;
        _libraryKey++; // يجبر إعادة بناء المكتبة في كل مرة
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final navBg = dark ? const Color(0xF70A0714) : Colors.white.withOpacity(0.97);
    final selectedClr = dark ? AppColors.darkAccentNeon : AppColors.lightAccentPrimary;
    final unselectedClr = dark ? const Color(0xFF4A4460) : const Color(0xFF9CA3AF);

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomePage(onNavigate: _nav),
          LibraryPage(key: ValueKey(_libraryKey), sortByRating: _librarySortByRating),
          const SearchPage(),
          _PlaceholderPage(label: provider.t('more'), icon: Icons.more_horiz_rounded, dark: dark),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          border: Border(
            top: BorderSide(
              color: dark ? const Color(0x33BF5FFF) : Colors.black.withOpacity(0.06),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: dark ? const Color(0x406428C8) : Colors.black.withOpacity(0.06),
              blurRadius: 30,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            // RTL: الرئيسية يمين ← المكتبة ← البحث ← المزيد يسار
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                children: [
                  _NavItem(icon: Icons.home_rounded, label: provider.t('home'), isActive: _index == 0, selectedClr: selectedClr, unselectedClr: unselectedClr, onTap: () => _nav(0)),
                  _NavItem(icon: Icons.grid_view_rounded, label: provider.t('library'), isActive: _index == 1, selectedClr: selectedClr, unselectedClr: unselectedClr, onTap: () => _nav(1)),
                  _NavItem(icon: Icons.search_rounded, label: provider.t('search'), isActive: _index == 2, selectedClr: selectedClr, unselectedClr: unselectedClr, onTap: () => _nav(2)),
                  _NavItem(icon: Icons.more_horiz_rounded, label: provider.t('more'), isActive: _index == 3, selectedClr: selectedClr, unselectedClr: unselectedClr, onTap: () => _nav(3)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color selectedClr;
  final Color unselectedClr;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon, required this.label, required this.isActive,
    required this.selectedClr, required this.unselectedClr, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () { HapticFeedback.lightImpact(); onTap(); },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, size: 22,
              color: isActive ? selectedClr : unselectedClr,
              shadows: isActive ? [Shadow(color: selectedClr, blurRadius: 8)] : null,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? selectedClr : unselectedClr,
              ),
            ),
            const SizedBox(height: 5),
            // خط المؤشر تحت النص
            Container(
              width: 28, height: 3,
              decoration: BoxDecoration(
                color: isActive ? selectedClr : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
                boxShadow: isActive ? [BoxShadow(color: selectedClr, blurRadius: 16)] : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool dark;
  const _PlaceholderPage({required this.label, required this.icon, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: dark ? AppColors.darkBgDeep : AppColors.lightBgDeep,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.white24),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 14)),
            const SizedBox(height: 8),
            const Text('قريباً...', style: TextStyle(color: Colors.white24, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
