import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final _supabase = Supabase.instance.client;

  static User? get currentUser => _supabase.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;
  static Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // ── تسجيل حساب جديد ──
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: displayName != null ? {'display_name': displayName} : null,
    );
  }

  // ── تسجيل دخول ──
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // ── تسجيل دخول بـ Google ──
  static Future<void> signInWithGoogle() async {
    const webClientId = '375753192215-llbrij96edhbd7ur824gk3gi2mg6vir3.apps.googleusercontent.com';

    final GoogleSignIn googleSignIn = GoogleSignIn(clientId: webClientId);
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return;

    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (idToken == null) throw Exception('Google ID token is null');

    await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  // ── تسجيل خروج ──
  static Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // ── إعادة تعيين كلمة المرور ──
  static Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // ── اسم المستخدم ──
  static String get displayName {
    final user = currentUser;
    if (user == null) return '';
    return user.userMetadata?['display_name'] ??
        user.userMetadata?['full_name'] ??
        user.email?.split('@').first ??
        '';
  }

  // ── صورة المستخدم ──
  static String? get avatarUrl {
    return currentUser?.userMetadata?['avatar_url'];
  }
}
