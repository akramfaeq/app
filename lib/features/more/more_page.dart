import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_provider.dart';
import '../../services/favorites_service.dart';
import '../favorites/favorites_page.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});
  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  static const _accentNeon = Color(0xFFBF5FFF);
  static const _gold       = Color(0xFFE8B85C);
  static const _accent     = Color(0xFF9B5CF6);

  @override
  Widget build(BuildContext context) {
    final provider    = context.watch<AppProvider>();
    final t           = provider.t;
    final dir         = provider.dir;
    final dark        = Theme.of(context).brightness == Brightness.dark;
    final bg          = dark ? const Color(0xFF0A0714) : const Color(0xFFEDEEF4);
    final cardClr     = dark ? const Color(0xFF130F1E) : Colors.white;
    final textPrimary = dark ? const Color(0xFFF0EEFF) : const Color(0xFF111111);
    final textSub     = dark ? const Color(0xFF7A728E) : const Color(0xFF6B7280);

    // عداد المفضلة — يُحسب مباشرة من الـ service
    final favCount = FavoritesService.favorites.length;

    return Directionality(
      textDirection: dir,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── هيدر — مطابق HTML ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                  child: Text(t('more_title') ?? 'المزيد',
                    style: TextStyle(
                      fontFamily: 'Archivo Black',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                    )),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── كارد الحساب — مطابق HTML ──
                      _buildAccountCard(t, cardClr, textPrimary, textSub),
                      const SizedBox(height: 10),

                      // ── كارد المفضلة — يظهر دائماً (انت طلبت كذا) ──
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const FavoritesPage()),
                          ).then((_) => setState(() {}));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                          decoration: BoxDecoration(
                            color: cardClr,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _accentNeon.withOpacity(0.15)),
                          ),
                          child: Row(
                            children: [
                              // أيقونة القلب — مطابق HTML
                              Container(
                                width: 42, height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE85A78).withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE85A78).withOpacity(0.2)),
                                ),
                                child: const Center(
                                  child: Icon(Icons.favorite_rounded, color: Color(0xFFE85A78), size: 20),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t('favorites') ?? 'المفضلة',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
                                    const SizedBox(height: 2),
                                    Text(t('savedManga') ?? 'المانغا المحفوظة',
                                      style: TextStyle(fontSize: 11, color: textSub)),
                                  ],
                                ),
                              ),
                              // badge العدد — مطابق #more-fav-badge
                              if (favCount > 0) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE85A78).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFE85A78).withOpacity(0.3)),
                                  ),
                                  child: Text('$favCount',
                                    style: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFE85A78),
                                    )),
                                ),
                                const SizedBox(width: 8),
                              ],
                              // سهم — مطابق HTML
                              const Icon(Icons.chevron_left_rounded, color: Color(0xFF7A728E), size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ── تسمية إعدادات التطبيق ──
                      Text(t('app_settings') ?? 'إعدادات التطبيق',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSub)),
                      const SizedBox(height: 8),

                      // ── إعدادات اللغة + الثيم — مطابق HTML ──
                      _buildSettingsCard(provider, t, cardClr, textPrimary, textSub),
                      const SizedBox(height: 16),

                      // ── عن التطبيق — مطابق HTML ──
                      _buildAboutCard(t, cardClr, textPrimary, textSub),
                      const SizedBox(height: 10),

                      // ── تواصل معنا — مطابق HTML ──
                      _buildContactCard(t, cardClr, textSub),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── بطاقة الحساب — مطابق HTML ──
  Widget _buildAccountCard(String Function(String) t, Color cardClr, Color textPrimary, Color textSub) {
    return GestureDetector(
      onTap: () => HapticFeedback.selectionClick(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardClr,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _accentNeon.withOpacity(0.25)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15)],
        ),
        child: Row(
          children: [
            // أفاتار — مطابق HTML
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF4A1F80), Color(0xFF1A1030)],
                ),
                border: Border.all(color: _accentNeon, width: 2),
                boxShadow: [BoxShadow(color: _accentNeon.withOpacity(0.25), blurRadius: 14)],
              ),
              child: const Center(
                child: Icon(Icons.person_outline_rounded, color: Color(0xFFC084FC), size: 24),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('account') ?? 'تسجيل الدخول',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
                  const SizedBox(height: 2),
                  Text(t('account_sub') ?? 'أنشئ حسابك أو سجّل دخولك',
                    style: TextStyle(fontSize: 12, color: textSub)),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded, color: Color(0xFF7A728E), size: 20),
          ],
        ),
      ),
    );
  }

  // ── إعدادات اللغة + الثيم — مطابق HTML ──
  Widget _buildSettingsCard(AppProvider provider, String Function(String) t,
      Color cardClr, Color textPrimary, Color textSub) {
    return Container(
      decoration: BoxDecoration(
        color: cardClr,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          // اللغة
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              provider.changeLanguage(provider.isArabic ? 'en' : 'ar');
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Icon(Icons.language_rounded, color: Color(0xFF3B82F6), size: 20)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t('language') ?? 'اللغة',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                        const SizedBox(height: 1),
                        Text(t('language_current') ?? 'عربي',
                          style: TextStyle(fontSize: 11, color: textSub)),
                      ],
                    ),
                  ),
                  // زر تبديل اللغة — مطابق HTML
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                    ),
                    child: Text(t('language_switch') ?? 'English',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF3B82F6))),
                  ),
                ],
              ),
            ),
          ),

          // فاصل
          Container(height: 1, color: _accent.withOpacity(0.1), margin: const EdgeInsets.symmetric(horizontal: 16)),

          // الثيم
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () { HapticFeedback.selectionClick(); provider.toggleTheme(); },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F6EF7).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        provider.isLightTheme ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                        color: const Color(0xFF4F6EF7), size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t('day_mode') ?? 'الوضع النهاري',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                        const SizedBox(height: 1),
                        Text(t('day_mode_sub') ?? 'اضغط للتفعيل',
                          style: TextStyle(fontSize: 11, color: textSub)),
                      ],
                    ),
                  ),
                  // تبديل الثيم — مطابق HTML
                  _ThemeToggle(isLight: provider.isLightTheme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── عن التطبيق — مطابق HTML ──
  Widget _buildAboutCard(String Function(String) t, Color cardClr, Color textPrimary, Color textSub) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); _showAboutSheet(t); },
      child: Container(
        decoration: BoxDecoration(
          color: cardClr,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _accent.withOpacity(0.15)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _gold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Icon(Icons.info_outline_rounded, color: _gold, size: 18)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('about') ?? 'عن التطبيق',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                  const SizedBox(height: 1),
                  Text(t('version') ?? 'الإصدار 1.0.0',
                    style: TextStyle(fontSize: 11, color: textSub)),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded, color: Color(0xFF7A728E), size: 16),
          ],
        ),
      ),
    );
  }

  // ── تواصل معنا — مطابق HTML ──
  Widget _buildContactCard(String Function(String) t, Color cardClr, Color textSub) {
    return Container(
      decoration: BoxDecoration(
        color: cardClr,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(t('contact_us') ?? 'تواصل معنا',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textSub)),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _SocialBtn(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF833AB4), Color(0xFFE1306C)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  label: 'Instagram',
                  icon: Icons.camera_alt_outlined,
                  textSub: textSub,
                ),
                const SizedBox(width: 10),
                _SocialBtn(color: const Color(0xFF1DA1F2), label: 'Twitter',
                    icon: Icons.alternate_email_rounded, textSub: textSub),
                const SizedBox(width: 10),
                _SocialBtn(color: const Color(0xFF25D366), label: 'WhatsApp',
                    icon: Icons.chat_rounded, textSub: textSub),
                const SizedBox(width: 10),
                _SocialBtn(color: const Color(0xFF0088CC), label: 'Telegram',
                    icon: Icons.send_rounded, textSub: textSub),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── صفحة عن التطبيق ──
  void _showAboutSheet(String Function(String) t) {
    HapticFeedback.selectionClick();
    Navigator.push(context, MaterialPageRoute(builder: (_) => _AboutPage(t: t)));
  }

}

// ══════════════════════════════════════════
// ── صفحة عن التطبيق — تصميم جديد كامل ──
// ══════════════════════════════════════════
class _AboutPage extends StatelessWidget {
  final String Function(String) t;
  const _AboutPage({required this.t});

  static const _accentNeon = Color(0xFFBF5FFF);
  static const _accent     = Color(0xFF9B5CF6);
  static const _gold       = Color(0xFFE8B85C);

  @override
  Widget build(BuildContext context) {
    final provider    = context.watch<AppProvider>();
    final dir         = provider.dir;
    final dark        = Theme.of(context).brightness == Brightness.dark;
    final bg          = dark ? const Color(0xFF0A0714) : const Color(0xFFEDEEF4);
    final cardClr     = dark ? const Color(0xFF130F1E) : Colors.white;
    final textPrimary = dark ? const Color(0xFFF0EEFF) : const Color(0xFF111111);
    final textSub     = dark ? const Color(0xFF7A728E) : const Color(0xFF6B7280);

    return Directionality(
      textDirection: dir,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Column(
            children: [
              // ── هيدر ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: dark ? const Color(0x2EBF5FFF) : const Color(0xFFEEF0FA),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: dark ? const Color(0x8CBF5FFF) : const Color(0xFF5B5BD6),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(t('back'),
                              style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700,
                                color: dark ? const Color(0xFFE2DEF0) : const Color(0xFF5B5BD6),
                              )),
                            const SizedBox(width: 4),
                            Text('›', style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700,
                              color: dark ? const Color(0xFFE2DEF0) : const Color(0xFF5B5BD6),
                            )),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: _gold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(child: Icon(Icons.info_outline_rounded, color: _gold, size: 15)),
                        ),
                        const SizedBox(width: 8),
                        Text(t('about'),
                          style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w900, color: textPrimary,
                          )),
                      ],
                    ),
                    const Spacer(),
                    const SizedBox(width: 80),
                  ],
                ),
              ),

              // ── المحتوى ──
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  child: Column(
                    children: [

                      // ── لوغو + اسم التطبيق ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        decoration: BoxDecoration(
                          color: cardClr,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _accentNeon.withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(color: _accentNeon.withOpacity(dark ? 0.12 : 0.05), blurRadius: 20),
                          ],
                        ),
                        child: Column(
                          children: [
                            // أيقونة التطبيق
                            Container(
                              width: 72, height: 72,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF4A1F80), Color(0xFF0A0714)],
                                ),
                                border: Border.all(color: _accentNeon.withOpacity(0.4), width: 2),
                                boxShadow: [
                                  BoxShadow(color: _accentNeon.withOpacity(0.3), blurRadius: 20),
                                ],
                              ),
                              child: const Center(
                                child: Text('M', style: TextStyle(
                                  fontSize: 34, fontWeight: FontWeight.w900,
                                  color: Colors.white, fontFamily: 'Archivo Black',
                                )),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text('Manga Nova',
                              style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w900,
                                color: Color(0xFFBF5FFF), fontFamily: 'Archivo Black',
                              )),
                            const SizedBox(height: 4),
                            Text(t('version'),
                              style: TextStyle(fontSize: 13, color: textSub)),
                            const SizedBox(height: 12),
                            // شريط فاصل
                            Container(height: 1, color: _accentNeon.withOpacity(0.1),
                              margin: const EdgeInsets.symmetric(horizontal: 24)),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(t('about_desc'),
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: textSub, height: 1.7)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── ميزات التطبيق ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: cardClr,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _accentNeon.withOpacity(0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                    color: _accent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(child: Text('✨', style: TextStyle(fontSize: 15))),
                                ),
                                const SizedBox(width: 10),
                                Text(t('features_title').replaceAll('✨ ', ''),
                                  style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary,
                                  )),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ...[
                              ('🌓', t('feature_1').replaceAll('🌓 ', '')),
                              ('📚', t('feature_2').replaceAll('📚 ', '')),
                              ('🔖', t('feature_3').replaceAll('🔖 ', '')),
                              ('↕️', t('feature_4').replaceAll('↕️ ', '')),
                              ('⭐', t('feature_5').replaceAll('⭐ ', '')),
                            ].map((f) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34, height: 34,
                                    decoration: BoxDecoration(
                                      color: _accent.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(child: Text(f.$1, style: const TextStyle(fontSize: 16))),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(f.$2,
                                      style: TextStyle(fontSize: 13, color: textSub, height: 1.4)),
                                  ),
                                ],
                              ),
                            )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── إخلاء المسؤولية ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4081).withOpacity(0.07),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFF4081).withOpacity(0.25)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF4081).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(child: Text('⚠️', style: TextStyle(fontSize: 16))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                t('disclaimer').replaceAll('⚠️ إخلاء المسؤولية: ', '').replaceAll('⚠️ Disclaimer: ', ''),
                                style: TextStyle(fontSize: 12, color: textSub, height: 1.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── المطورون ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: cardClr,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _accentNeon.withOpacity(0.15)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                    color: _accent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(child: Text('💻', style: TextStyle(fontSize: 15))),
                                ),
                                const SizedBox(width: 10),
                                Text(t('dev_title').replaceAll('💻 ', ''),
                                  style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary,
                                  )),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // المطور 1
                            _DevCard(name: 'أكرم فائق', nameEn: 'Akram Faeq', role: 'Flutter Developer', dark: dark),
                            const SizedBox(height: 10),
                            // المطور 2
                            _DevCard(name: 'يوسف سفيان', nameEn: 'Yousef Sofian', role: 'UI / UX Designer', dark: dark),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── نسخة / حقوق ──
                      Text('© 2025 Manga Nova. All rights reserved.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: textSub.withOpacity(0.6))),
                    ],
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

// ── كارد المطور ──
class _DevCard extends StatelessWidget {
  final String name, nameEn, role;
  final bool dark;
  const _DevCard({required this.name, required this.nameEn, required this.role, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1A1035) : const Color(0xFFF5F5FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBF5FFF).withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF4A1F80), Color(0xFF1A1030)],
              ),
              border: Border.all(color: const Color(0xFFBF5FFF).withOpacity(0.4), width: 1.5),
            ),
            child: Center(
              child: Text(name[0],
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nameEn,
                style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: dark ? const Color(0xFFF0EEFF) : const Color(0xFF111111),
                )),
              const SizedBox(height: 2),
              Text(role,
                style: const TextStyle(fontSize: 11, color: Color(0xFF9B5CF6))),
            ],
          ),
        ],
      ),
    );
  }
}

// ── تبديل الثيم — مطابق HTML ──
class _ThemeToggle extends StatelessWidget {
  final bool isLight;
  const _ThemeToggle({required this.isLight});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 50, height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isLight ? const Color(0xFF4F6EF7) : const Color(0xFF1E1B4B),
        border: Border.all(color: const Color(0xFF4F6EF7).withOpacity(0.35), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 300),
          alignment: isLight ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLight ? Colors.white : const Color(0xFF4F6EF7),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 6)],
            ),
          ),
        ),
      ),
    );
  }
}

// ── زر التواصل الاجتماعي — مطابق HTML ──
class _SocialBtn extends StatelessWidget {
  final Color? color;
  final Gradient? gradient;
  final String label;
  final IconData icon;
  final Color textSub;

  const _SocialBtn({this.color, this.gradient, required this.label, required this.icon, required this.textSub});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => HapticFeedback.selectionClick(),
        child: Column(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: color,
                gradient: gradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Icon(icon, color: Colors.white, size: 22)),
            ),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 10, color: textSub)),
          ],
        ),
      ),
    );
  }
}
