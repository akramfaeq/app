import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_provider.dart';
import '../../features/home/home_page.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  bool _librarySortByRating = false;

  void _navigateTo(int index, {bool sortByRating = false}) {
    setState(() {
      _currentIndex         = index;
      _librarySortByRating  = sortByRating;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider  = context.watch<AppProvider>();
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final navBg     = isDark
        ? const Color(0xF0130F1E)
        : Colors.white.withOpacity(0.97);
    final selectedClr   = isDark ? AppColors.darkAccentNeon : AppColors.lightAccentPrimary;
    final unselectedClr = isDark ? const Color(0xFF4A4460) : const Color(0xFF9CA3AF);
    final borderClr     = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.06);

    // تبديل اتجاه الشريط حسب اللغة
    final isAr = provider.isArabic;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            // ===== Tab 0: الرئيسية =====
            HomePage(onNavigate: _navigateTo),

            // ===== Tab 1: المكتبة =====
            // ##LIBRARY_PAGE##
            _PlaceholderPage(
              label: provider.t('library'),
              icon: Icons.grid_view_rounded,
              isDark: isDark,
            ),

            // ===== Tab 2: البحث =====
            // ##SEARCH_PAGE##
            _PlaceholderPage(
              label: provider.t('search'),
              icon: Icons.search_rounded,
              isDark: isDark,
            ),

            // ===== Tab 3: المزيد =====
            // ##MORE_PAGE##
            _PlaceholderPage(
              label: provider.t('more'),
              icon: Icons.more_horiz_rounded,
              isDark: isDark,
            ),
          ],
        ),

        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: navBg,
            border: Border(
              top: BorderSide(color: borderClr, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 58,
              child: Row(
                children: [
                  _NavItem(
                    icon: Icons.home_rounded,
                    label: provider.t('home'),
                    isActive: _currentIndex == 0,
                    selectedClr: selectedClr,
                    unselectedClr: unselectedClr,
                    onTap: () => _navigateTo(0),
                  ),
                  _NavItem(
                    icon: Icons.grid_view_rounded,
                    label: provider.t('library'),
                    isActive: _currentIndex == 1,
                    selectedClr: selectedClr,
                    unselectedClr: unselectedClr,
                    onTap: () => _navigateTo(1),
                  ),
                  _NavItem(
                    icon: Icons.search_rounded,
                    label: provider.t('search'),
                    isActive: _currentIndex == 2,
                    selectedClr: selectedClr,
                    unselectedClr: unselectedClr,
                    onTap: () => _navigateTo(2),
                  ),
                  _NavItem(
                    icon: Icons.more_horiz_rounded,
                    label: provider.t('more'),
                    isActive: _currentIndex == 3,
                    selectedClr: selectedClr,
                    unselectedClr: unselectedClr,
                    onTap: () => _navigateTo(3),
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

// ===== Nav Item =====
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String   label;
  final bool     isActive;
  final Color    selectedClr;
  final Color    unselectedClr;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.selectedClr,
    required this.unselectedClr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // نقطة أعلى الأيقونة النشطة
            if (isActive)
              Container(
                width: 18,
                height: 3,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: selectedClr,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: selectedClr.withOpacity(0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              )
            else
              const SizedBox(height: 7),
            Icon(
              icon,
              size: 22,
              color: isActive ? selectedClr : unselectedClr,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? selectedClr : unselectedClr,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== Placeholder للصفحات اللي لم تُبنى بعد =====
class _PlaceholderPage extends StatelessWidget {
  final String   label;
  final IconData icon;
  final bool     isDark;

  const _PlaceholderPage({
    required this.label,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBgDeep : AppColors.lightBgDeep,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.white24),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'قريباً...',
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
