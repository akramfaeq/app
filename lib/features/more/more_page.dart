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

  static const _bg          = Color(0xFF0A0714);
  static const _cardClr     = Color(0xFF130F1E);
  static const _textPrimary = Color(0xFFF0EEFF);
  static const _textSub     = Color(0xFF7A728E);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final t        = provider.t;
    final dir      = provider.dir;
    final favCount = context.watch<FavoritesService>().count;

    return Directionality(
      textDirection: dir,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                  child: Text(t('more_title') ?? 'المزيد',
                    style: const TextStyle(
                      fontFamily: 'Archivo Black',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: _textPrimary,
                    )),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAccountCard(t),
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
                            color: _cardClr,
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
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textPrimary)),
                                    const SizedBox(height: 2),
                                    Text(t('savedManga') ?? 'المانغا المحفوظة',
                                      style: const TextStyle(fontSize: 11, color: _textSub)),
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
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _textSub)),
                      const SizedBox(height: 8),
                      _buildSettingsCard(provider, t),
                      const SizedBox(height: 16),
                      _buildAboutCard(t),
                      const SizedBox(height: 10),
                      _buildContactCard(t),
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

  Widget _buildAccountCard(String Function(String) t) {
    return GestureDetector(
      onTap: () => HapticFeedback.selectionClick(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardClr,
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
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textPrimary)),
                  const SizedBox(height: 2),
                  Text(t('account_sub') ?? 'أنشئ حسابك أو سجّل دخولك',
                    style: const TextStyle(fontSize: 12, color: _textSub)),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded, color: Color(0xFF7A728E), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(AppProvider provider, String Function(String) t) {
    return Container(
      decoration: BoxDecoration(
        color: _cardClr,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withOpacity(0.15)),
      ),
      child: GestureDetector(
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
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary)),
                    const SizedBox(height: 1),
                    Text(t('language_current') ?? 'عربي',
                      style: const TextStyle(fontSize: 11, color: _textSub)),
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
    );
  }

  Widget _buildAboutCard(String Function(String) t) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); _showAboutDialog(context, provider: context.read<AppProvider>()); },
      child: Container(
        decoration: BoxDecoration(
          color: _cardClr,
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
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary)),
                  const SizedBox(height: 1),
                  Text(t('version') ?? 'الإصدار 1.0.0',
                    style: const TextStyle(fontSize: 11, color: _textSub)),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded, color: Color(0xFF7A728E), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(String Function(String) t) {
    return Container(
      decoration: BoxDecoration(
        color: _cardClr,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(t('contact_us') ?? 'تواصل معنا',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textSub)),
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
                ),
                const SizedBox(width: 10),
                _SocialBtn(color: const Color(0xFF1DA1F2), label: 'Twitter', icon: Icons.alternate_email_rounded),
                const SizedBox(width: 10),
                _SocialBtn(color: const Color(0xFF25D366), label: 'WhatsApp', icon: Icons.chat_rounded),
                const SizedBox(width: 10),
                _SocialBtn(color: const Color(0xFF0088CC), label: 'Telegram', icon: Icons.send_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context, {required AppProvider provider}) {
    HapticFeedback.selectionClick();
    const cardBg      = Color(0xFF130F1E);
    const textPrimary = Color(0xFFF0EEFF);
    const textSub     = Color(0xFFA09AB0);
    const devColor    = Color(0xFFBF5FFF);
    final dialogBorderColor = const Color(0xFF9B5CF6).withOpacity(0.4);

    final isAr    = provider.isArabic;
    final align   = isAr ? TextAlign.right : TextAlign.left;
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
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary)),
                        const SizedBox(height: 1),
                        Text(isAr ? 'الإصدار 1.0.0' : 'Version 1.0.0',
                          textAlign: align,
                          style: const TextStyle(fontSize: 11, color: textSub)),
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
                      child: const Icon(Icons.close_rounded, color: textPrimary, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
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
                  style: const TextStyle(fontSize: 12, color: textSub, height: 1.35),
                ),
              ),
              const SizedBox(height: 10),
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
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary)),
                    ),
                    const SizedBox(height: 6),
                    _featureItem('📚', isAr ? 'مكتبة شخصية بتصنيفات متعددة' : 'Personal library with multi-categories', align, textSub, textDir),
                    _featureItem('🔖', isAr ? 'حفظ تقدم القراءة والمفضلة' : 'Save reading progress and favorites', align, textSub, textDir),
                    _featureItem('📖', isAr ? 'قارئ بوضعين عمودي وأفقي' : 'Vertical and horizontal reader modes', align, textSub, textDir),
                    _featureItem('⭐', isAr ? 'نظام تقييم ومتابعة الإصدارات' : 'Rating and release tracking system', align, textSub, textDir),
                  ],
                ),
              ),
              const SizedBox(height: 10),
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
                        style: const TextStyle(fontSize: 10.5, color: textSub, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
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
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSub)),
                      const Text('Akram Faeq & Yousef Sofian',
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

class _SocialBtn extends StatelessWidget {
  final Color? color;
  final Gradient? gradient;
  final String label;
  final IconData icon;

  const _SocialBtn({this.color, this.gradient, required this.label, required this.icon});

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
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF7A728E))),
          ],
        ),
      ),
    );
  }
}
