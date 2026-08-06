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
                      _buildAccountCard(t, cardClr, textPrimary, textSub),
                      const SizedBox(height: 10),
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
                              const Icon(Icons.chevron_left_rounded, color: Color(0xFF7A728E), size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(t('app_settings') ?? 'إعدادات التطبيق',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSub)),
                      const SizedBox(height: 8),
                      _buildSettingsCard(provider, t, cardClr, textPrimary, textSub),
                      const SizedBox(height: 16),
                      _buildAboutCard(t, cardClr, textPrimary, textSub),
                      const SizedBox(height: 10),
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
          Container(height: 1, color: _accent.withOpacity(0.1), margin: const EdgeInsets.symmetric(horizontal: 16)),
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
                  _ThemeToggle(isLight: provider.isLightTheme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(String Function(String) t, Color cardClr, Color textPrimary, Color textSub) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); _showAboutDialog(context, provider: context.read<AppProvider>()); },
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
                color: const Color(0xFFE8B85C).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Icon(Icons.info_outline_rounded, color: Color(0xFFE8B85C), size: 18)),
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

  void _showAboutDialog(BuildContext context, {required AppProvider provider}) {
    HapticFeedback.selectionClick();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = dark ? const Color(0xFF130F1E) : Colors.white;
    final textPrimary = dark ? const Color(0xFFF0EEFF) : const Color(0xFF111111);
    final textSub = dark ? const Color(0xFFA09AB0) : const Color(0xFF555555);
    
    // إطار واضح جداً: أزرق نيلي بارز بالوضع النهاري، وبنفسجي بالليلي
    final dialogBorderColor = dark ? const Color(0xFF9B5CF6).withOpacity(0.4) : const Color(0xFF3B82F6).withOpacity(0.7);
    
    // اسماء المطورين: بنفسجي بالوضع الليلي، وأزرق نيلي بالوضع النهاري
    final devColor = dark ? const Color(0xFFBF5FFF) : const Color(0xFF3B82F6);

    final isAr = provider.isArabic;
    final align = isAr ? TextAlign.right : TextAlign.left;
    final textDir = isAr ? TextDirection.rtl : TextDirection.ltr;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: dialogBorderColor, width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // الهيدر
              Row(
                textDirection: textDir,
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8B85C).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(Icons.info_outline_rounded, color: Color(0xFFE8B85C), size: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(isAr ? 'عن التطبيق' : 'About',
                          textAlign: align,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary)),
                        const SizedBox(height: 1),
                        Text(isAr ? 'الإصدار 1.0.0' : 'Version 1.0.0',
                          textAlign: align,
                          style: TextStyle(fontSize: 11, color: textSub)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: textSub.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded, color: textPrimary, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // الوصف
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: textSub.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isAr 
                    ? 'تطبيق Manga Nova متكامل لقراءة المانجا، يوفر تجربة سلسة وسريعة مع واجهة عصرية مصممة خصيصاً لعشاق القصص المصورة.'
                    : 'Manga Nova is a comprehensive manga reading app, offering a smooth and fast experience with a modern interface designed specifically for comic fans.',
                  textAlign: align,
                  textDirection: textDir,
                  style: TextStyle(fontSize: 12, color: textSub, height: 1.35),
                ),
              ),
              const SizedBox(height: 10),

              // مميزات التطبيق (تم تثبيت اتجاه النص والعلامات بدقة لتكون الإيموجي قبل الجملة بالعربي)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: textSub.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Directionality(
                      textDirection: textDir,
                      child: Text(isAr ? '✨ مميزات التطبيق' : '✨ App Features',
                        textAlign: align,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary)),
                    ),
                    const SizedBox(height: 6),
                    _featureItem('🌓', isAr ? 'دعم الوضع الداكن والنهاري' : 'Dark and light mode support', align, textSub, textDir),
                    _featureItem('📚', isAr ? 'مكتبة شخصية بتصنيفات متعددة' : 'Personal library with multi-categories', align, textSub, textDir),
                    _featureItem('🔖', isAr ? 'حفظ تقدم القراءة والمفضلة' : 'Save reading progress and favorites', align, textSub, textDir),
                    _featureItem('📖', isAr ? 'قارئ بوضعين عمودي وأفقي' : 'Vertical and horizontal reader modes', align, textSub, textDir),
                    _featureItem('⭐', isAr ? 'نظام تقييم ومتابعة الإصدارات' : 'Rating and release tracking system', align, textSub, textDir),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // إخلاء المسؤولية (تم ضبط اتجاه النص بالكامل لمنع انعكاس النقطتين)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE85A78).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE85A78).withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Directionality(
                      textDirection: textDir,
                      child: Text(isAr ? '⚠️ إخلاء المسؤولية:' : '⚠️ Disclaimer:',
                        textAlign: align,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFE85A78))),
                    ),
                    const SizedBox(height: 3),
                    Directionality(
                      textDirection: textDir,
                      child: Text(
                        isAr 
                          ? 'جميع المحتويات والترجمات والمواد المعروضة في هذا التطبيق هي ملك حصري لأصحابها وصانعيها الأصليين. التطبيق لا يدعي ملكية أي من هذه المحتويات وهو مخصص للاستخدام الشخصي فقط. جميع الحقوق محفوظة لأصحابها.'
                          : 'All contents, translations, and materials displayed in this app are the exclusive property of their original owners and creators. The app does not claim ownership of any of these contents and is intended for personal use only. All rights reserved to their respective owners.',
                        textAlign: align,
                        style: TextStyle(fontSize: 10.5, color: textSub, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // التطوير (تم تثبيت اتجاه السطر والعلامات والأسماء تماماً حسب الطلب)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Directionality(
                  textDirection: textDir,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(isAr ? '💻 التطوير: ' : '💻 Development: ',
                        textAlign: align,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSub)),
                      Text('Akram Faeq & Yousef Sofian',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: devColor)),
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

  Widget _featureItem(String emoji, String text, TextAlign align, Color color, TextDirection textDir) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3.5),
      child: Directionality(
        textDirection: textDir,
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(text,
                textAlign: align,
                style: TextStyle(fontSize: 11, color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

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