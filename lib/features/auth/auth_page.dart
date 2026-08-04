import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_provider.dart';
import '../../services/auth_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _nameCtrl     = TextEditingController();
  final _emailSignCtrl = TextEditingController();
  final _passSignCtrl  = TextEditingController();

  bool _loading       = false;
  bool _showPass      = false;
  bool _showPassSign  = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _emailSignCtrl.dispose();
    _passSignCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'يرجى إدخال البريد وكلمة المرور');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.signIn(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = _parseError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUp() async {
    if (_emailSignCtrl.text.trim().isEmpty || _passSignCtrl.text.isEmpty) {
      setState(() => _error = 'يرجى إدخال البريد وكلمة المرور');
      return;
    }
    if (_passSignCtrl.text.length < 6) {
      setState(() => _error = 'كلمة المرور يجب أن تكون 6 أحرف على الأقل');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.signUp(
        email: _emailSignCtrl.text.trim(),
        password: _passSignCtrl.text,
        displayName: _nameCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = _parseError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.signInWithGoogle();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = _parseError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _parseError(String e) {
    if (e.contains('Invalid login credentials')) return 'البريد أو كلمة المرور غير صحيحة';
    if (e.contains('Email not confirmed')) return 'يرجى تأكيد بريدك الإلكتروني';
    if (e.contains('already registered')) return 'البريد مسجل مسبقاً';
    if (e.contains('network')) return 'خطأ في الاتصال بالإنترنت';
    return 'حدث خطأ، يرجى المحاولة مرة أخرى';
  }

  @override
  Widget build(BuildContext context) {
    final provider    = context.watch<AppProvider>();
    final dark        = Theme.of(context).brightness == Brightness.dark;
    final bg          = dark ? const Color(0xFF0A0714) : const Color(0xFFEDEEF4);
    final cardClr     = dark ? const Color(0xFF130F1E) : Colors.white;
    final textPrimary = dark ? const Color(0xFFF0EEFF) : const Color(0xFF111111);
    final textSub     = dark ? const Color(0xFF7A728E) : const Color(0xFF6B7280);
    final accent      = dark ? AppColors.darkAccentNeon : const Color(0xFF3F5EFB);
    final borderClr   = dark ? AppColors.darkAccentNeon.withOpacity(0.2) : const Color(0xFF3F5EFB).withOpacity(0.2);

    return Directionality(
      textDirection: provider.dir,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // ── اللوجو ──
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: dark
                          ? [const Color(0xFF4A1F80), const Color(0xFF1A1030)]
                          : [accent.withOpacity(0.8), accent],
                    ),
                    boxShadow: [BoxShadow(color: accent.withOpacity(0.3), blurRadius: 20)],
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 38),
                ),

                const SizedBox(height: 16),

                Text('Manga Nova',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900,
                      color: textPrimary, fontFamily: 'Tajawal')),
                const SizedBox(height: 4),
                Text('سجّل دخولك للوصول إلى مكتبتك',
                  style: TextStyle(fontSize: 13, color: textSub, fontFamily: 'Tajawal')),

                const SizedBox(height: 32),

                // ── Tabs ──
                Container(
                  decoration: BoxDecoration(
                    color: cardClr,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderClr),
                  ),
                  child: TabBar(
                    controller: _tab,
                    indicator: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: textSub,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Tajawal'),
                    tabs: const [Tab(text: 'تسجيل الدخول'), Tab(text: 'حساب جديد')],
                  ),
                ),

                const SizedBox(height: 20),

                // ── محتوى الـ Tabs ──
                SizedBox(
                  height: 320,
                  child: TabBarView(
                    controller: _tab,
                    children: [
                      // تسجيل دخول
                      _buildSignInForm(cardClr, textPrimary, textSub, accent, borderClr),
                      // حساب جديد
                      _buildSignUpForm(cardClr, textPrimary, textSub, accent, borderClr),
                    ],
                  ),
                ),

                // ── خطأ ──
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!,
                          style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontFamily: 'Tajawal'))),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // ── فاصل ──
                Row(children: [
                  Expanded(child: Divider(color: borderClr)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('أو', style: TextStyle(color: textSub, fontSize: 12, fontFamily: 'Tajawal')),
                  ),
                  Expanded(child: Divider(color: borderClr)),
                ]),

                const SizedBox(height: 16),

                // ── زر Google ──
                GestureDetector(
                  onTap: _loading ? null : _signInWithGoogle,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: cardClr,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderClr),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                          'https://www.google.com/favicon.ico',
                          width: 20, height: 20,
                          errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata_rounded, size: 24, color: Colors.redAccent),
                        ),
                        const SizedBox(width: 10),
                        Text('متابعة مع Google',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                              color: textPrimary, fontFamily: 'Tajawal')),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInForm(Color cardClr, Color textPrimary, Color textSub, Color accent, Color borderClr) {
    return Column(
      children: [
        _buildTextField(
          controller: _emailCtrl,
          hint: 'البريد الإلكتروني',
          icon: Icons.email_outlined,
          cardClr: cardClr, textPrimary: textPrimary,
          textSub: textSub, accent: accent, borderClr: borderClr,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _passCtrl,
          hint: 'كلمة المرور',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          showPass: _showPass,
          onTogglePass: () => setState(() => _showPass = !_showPass),
          cardClr: cardClr, textPrimary: textPrimary,
          textSub: textSub, accent: accent, borderClr: borderClr,
        ),
        const SizedBox(height: 20),
        _buildBtn('تسجيل الدخول', accent, _signIn),
      ],
    );
  }

  Widget _buildSignUpForm(Color cardClr, Color textPrimary, Color textSub, Color accent, Color borderClr) {
    return Column(
      children: [
        _buildTextField(
          controller: _nameCtrl,
          hint: 'الاسم (اختياري)',
          icon: Icons.person_outline_rounded,
          cardClr: cardClr, textPrimary: textPrimary,
          textSub: textSub, accent: accent, borderClr: borderClr,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _emailSignCtrl,
          hint: 'البريد الإلكتروني',
          icon: Icons.email_outlined,
          cardClr: cardClr, textPrimary: textPrimary,
          textSub: textSub, accent: accent, borderClr: borderClr,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _passSignCtrl,
          hint: 'كلمة المرور',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          showPass: _showPassSign,
          onTogglePass: () => setState(() => _showPassSign = !_showPassSign),
          cardClr: cardClr, textPrimary: textPrimary,
          textSub: textSub, accent: accent, borderClr: borderClr,
        ),
        const SizedBox(height: 20),
        _buildBtn('إنشاء حساب', accent, _signUp),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color cardClr,
    required Color textPrimary,
    required Color textSub,
    required Color accent,
    required Color borderClr,
    bool isPassword = false,
    bool showPass = false,
    VoidCallback? onTogglePass,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: cardClr,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderClr),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !showPass,
        keyboardType: keyboardType,
        style: TextStyle(color: textPrimary, fontSize: 14, fontFamily: 'Tajawal'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: textSub, fontSize: 13),
          prefixIcon: Icon(icon, color: textSub, size: 20),
          suffixIcon: isPassword
              ? GestureDetector(
                  onTap: onTogglePass,
                  child: Icon(
                    showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: textSub, size: 18,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildBtn(String label, Color accent, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(label,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Tajawal')),
      ),
    );
  }
}
