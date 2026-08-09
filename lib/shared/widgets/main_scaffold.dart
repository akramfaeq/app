import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_provider.dart';
import '../../features/home/home_page.dart';
import '../../features/library/library_page.dart';
import '../../features/search/search_page.dart';
import '../../features/more/more_page.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});
  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _index = 0;
  bool _librarySortByRating = false;

  void _nav(int index, {bool sortByRating = false}) {
    setState(() {
      _index = index;
      if (index == 1) _librarySortByRating = sortByRating;
      if (index == 0) _librarySortByRating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomePage(onNavigate: _nav),
          LibraryPage(sortByRating: _librarySortByRating),
          const SearchPage(),
          const MorePage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xF70A0714),
          border: const Border(
            top: BorderSide(color: Color(0x33BF5FFF), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0x406428C8),
              blurRadius: 30,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Directionality(
              textDirection: provider.dir,
              child: Row(
                children: [
                  _NavItem(
                    icon: Icons.home_rounded,
                    label: provider.t('home'),
                    isActive: _index == 0,
                    onTap: () => _nav(0),
                  ),
                  _NavItem(
                    icon: Icons.grid_view_rounded,
                    label: provider.t('libraryNav'),
                    isActive: _index == 1,
                    onTap: () => _nav(1, sortByRating: false),
                  ),
                  _NavItem(
                    icon: Icons.search_rounded,
                    label: provider.t('search'),
                    isActive: _index == 2,
                    onTap: () => _nav(2),
                  ),
                  _NavItem(
                    icon: Icons.more_horiz_rounded,
                    label: provider.t('more'),
                    isActive: _index == 3,
                    onTap: () => _nav(3),
                  ),
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
  final VoidCallback onTap;

  const _NavItem({
    required this.icon, required this.label,
    required this.isActive, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final clr = isActive ? AppColors.darkAccentNeon : const Color(0xFF4A4460);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () { HapticFeedback.lightImpact(); onTap(); },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, size: 22, color: clr,
              shadows: isActive
                  ? [Shadow(color: AppColors.darkAccentNeon, blurRadius: 8)]
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: clr,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              width: 28, height: 3,
              decoration: BoxDecoration(
                color: isActive ? AppColors.darkAccentNeon : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
                boxShadow: isActive
                    ? [BoxShadow(color: AppColors.darkAccentNeon, blurRadius: 16)]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
