import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_provider.dart';
import '../../services/auth_service.dart';
import '../auth/auth_page.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});
  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  static const _gold = Color(0xFFE8B85C);
  late final _authSub = AuthService.authStateChanges.listen((_) {
    if (mounted) setState(() {});
  });

  @override
  void initState() {
    super.initState();
    _authSub; // تفعيل الـ listener
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

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
    final accent      = dark ? AppColors.darkAccentNeon : const Color(0xFF3F5EFB);
    final accentNeon  = dark ? const Color(0xFFBF5FFF) : const Color(0xFF3F5EFB);
    final borderClr   = accent.withOpacity(0.15);

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
                  child: Text(t('more_title'),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textPrimary)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAccountCard(t, dark, cardClr, textPrimary, textSub, accent, accentNeon),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(t('app_settings'),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSub)),
                      ),
                      _buildSettingsCard(provider, t, dark, cardClr, textPrimary, textSub, borderClr),
                      const SizedBox(height: 16),
                      _buildAboutCard(t, cardClr, textPrimary, textSub, borderClr),
                      const SizedBox(height: 10),
                      _buildContactCard(t, cardClr, textSub, borderClr),
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

  Widget _buildAccountCard(String Function(String) t, bool dark, Color cardClr,
      Color textPrimary, Color textSub, Color accent, Color accentNeon) {
    final isLoggedIn = AuthService.isLoggedIn;
    final name       = AuthService.displayName;
    final avatarUrl  = AuthService.avatarUrl;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        if (!isLoggedIn) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthPage()));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardClr,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentNeon.withOpacity(0.25)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(dark ? 0.3 : 0.06), blurRadius: 15)],
        ),
        child: Row(
          children: [
            // أفاتار
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: dark
                      ? [const Color(0xFF4A1F80), const Color(0xFF1A1030)]
                      : [accent.withOpacity(0.7), accent],
                ),
                border: Border.all(color: accentNeon, width: 2),
                boxShadow: [BoxShadow(color: accentNeon.withOpacity(0.25), blurRadius: 14)],
              ),
              child: avatarUrl != null
                  ? ClipOval(child: Image.network(avatarUrl, fit: BoxFit.cover))
                  : Icon(Icons.person_outline_rounded,
                      color: dark ? const Color(0xFFC084FC) : Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLoggedIn ? (name.isNotEmpty ? name : t('account')) : t('account'),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isLoggedIn
                        ? (AuthService.currentUser?.email ?? '')
                        : t('account_sub'),
                    style: TextStyle(fontSize: 12, color: textSub),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isLoggedIn)
              GestureDetector(
                onTap: () async {
                  HapticFeedback.selectionClick();
                  await AuthService.signOut();
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: const Text('خروج',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.redAccent)),
                ),
              )
            else
              Icon(Icons.chevron_left_rounded, color: textSub, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(AppProvider provider, String Function(String) t, bool dark,
      Color cardClr, Color textPrimary, Color textSub, Color borderClr) {
    return Container(
      decoration: BoxDecoration(
        color: cardClr,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderClr),
      ),
      child: Column(
        children: [
          _buildRowItem(
            iconBg: const Color(0x263B82F6),
            icon: Icons.language_rounded,
            iconColor: const Color(0xFF3B82F6),
            title: t('language'),
            subtitle: t('language_current'),
            textPrimary: textPrimary, textSub: textSub,
            trailing: GestureDetector(
              onTap: () { HapticFeedback.selectionClick(); provider.changeLanguage(provider.isArabic ? 'en' : 'ar'); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x263B82F6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x663B82F6)),
                ),
                child: Text(t('language_switch'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF3B82F6))),
              ),
            ),
            onTap: () { HapticFeedback.selectionClick(); provider.changeLanguage(provider.isArabic ? 'en' : 'ar'); },
          ),
          Divider(height: 1, color: borderClr, indent: 16, endIndent: 16),
          _buildRowItem(
            iconBg: const Color(0x1F4F6EF7),
            icon: provider.isLightTheme ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            iconColor: const Color(0xFF4F6EF7),
            title: t('day_mode'),
            subtitle: t('day_mode_sub'),
            trailing: _buildThemeToggle(provider),
            textPrimary: textPrimary, textSub: textSub,
            onTap: () { HapticFeedback.selectionClick(); provider.toggleTheme(); },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(String Function(String) t, Color cardClr,
      Color textPrimary, Color textSub, Color borderClr) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); _showAboutSheet(t); },
      child: Container(
        decoration: BoxDecoration(
          color: cardClr,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderClr),
        ),
        child: _buildRowItem(
          iconBg: _gold.withOpacity(0.15),
          icon: Icons.info_outline_rounded,
          iconColor: _gold,
          title: t('about'),
          subtitle: t('version'),
          trailing: Icon(Icons.chevron_left_rounded, color: textSub, size: 18),
          textPrimary: textPrimary, textSub: textSub,
          onTap: () { HapticFeedback.selectionClick(); _showAboutSheet(t); },
        ),
      ),
    );
  }

  Widget _buildContactCard(String Function(String) t, Color cardClr, Color textSub, Color borderClr) {
    return Container(
      decoration: BoxDecoration(
        color: cardClr,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderClr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(t('contact_us'),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textSub)),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _buildSocialBtn(gradient: const LinearGradient(
                    colors: [Color(0xFF833AB4), Color(0xFFE1306C)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  label: 'Instagram', icon: Icons.camera_alt_outlined, textSub: textSub),
                const SizedBox(width: 10),
                _buildSocialBtn(color: const Color(0xFF1DA1F2), label: 'Twitter', icon: Icons.alternate_email_rounded, textSub: textSub),
                const SizedBox(width: 10),
                _buildSocialBtn(color: const Color(0xFF25D366), label: 'WhatsApp', icon: Icons.chat_rounded, textSub: textSub),
                const SizedBox(width: 10),
                _buildSocialBtn(color: const Color(0xFF0088CC), label: 'Telegram', icon: Icons.send_rounded, textSub: textSub),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowItem({
    required Color iconBg, required IconData icon, required Color iconColor,
    required String title, required String subtitle,
    required Widget trailing, required VoidCallback onTap,
    required Color textPrimary, required Color textSub,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                  const SizedBox(height: 1),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: textSub)),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle(AppProvider provider) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 50, height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: provider.isLightTheme ? const Color(0xFF4F6EF7) : const Color(0xFF1E1B4B),
        border: Border.all(color: const Color(0xFF4F6EF7).withOpacity(0.35), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 300),
          alignment: provider.isLightTheme ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: provider.isLightTheme ? Colors.white : const Color(0xFF4F6EF7),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 6)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialBtn({Color? color, Gradient? gradient, required String label, required IconData icon, required Color textSub}) {
    return Expanded(
      child: GestureDetector(
        onTap: () => HapticFeedback.selectionClick(),
        child: Column(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(color: color, gradient: gradient, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 10, color: textSub)),
          ],
        ),
      ),
    );
  }

  void _showAboutSheet(String Function(String) t) {
    HapticFeedback.selectionClick();
    final dark        = Theme.of(context).brightness == Brightness.dark;
    final cardClr     = dark ? const Color(0xFF130F1E) : Colors.white;
    final textPrimary = dark ? const Color(0xFFF0EEFF) : const Color(0xFF111111);
    final textSub     = dark ? const Color(0xFF7A728E) : const Color(0xFF6B7280);
    final accent      = dark ? AppColors.darkAccentNeon : const Color(0xFF3F5EFB);
    final accentNeon  = dark ? const Color(0xFFBF5FFF) : const Color(0xFF3F5EFB);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Directionality(
        textDirection: context.read<AppProvider>().dir,
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardClr,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentNeon.withOpacity(0.2)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 60)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: accentNeon.withOpacity(0.1)))),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: _gold.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.info_outline_rounded, color: _gold, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t('about'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
                        Text(t('version'), style: TextStyle(fontSize: 11, color: textSub)),
                      ],
                    )),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.close_rounded, color: textSub, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(text: TextSpan(
                      style: TextStyle(fontSize: 13, color: textSub, height: 1.7),
                      children: [
                        TextSpan(text: 'Manga Nova ', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700)),
                        TextSpan(text: t('about_desc')),
                      ],
                    )),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: accentNeon.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t('features_title'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)),
                          const SizedBox(height: 8),
                          for (var i = 1; i <= 5; i++)
                            Text(t('feature_$i'), style: TextStyle(fontSize: 12, color: textSub, height: 1.8)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4081).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: const Border(right: BorderSide(color: Color(0xFFFF4081), width: 3)),
                      ),
                      child: Text(t('disclaimer'), style: TextStyle(fontSize: 12, color: textSub, height: 1.6)),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: accentNeon.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t('dev_title'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)),
                          const SizedBox(height: 6),
                          Text(t('dev_names'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: accent)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
