import '../services/api_service.dart';

class AuthService {
  // Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Stream of auth state changes — emits AuthUser? (null = signed out)
  Stream<AuthUser?> get authStateChanges => ApiService.authStateChanges;

  /// Currently signed-in user
  AuthUser? get currentUser => ApiService.currentUser;

  /// Sign in with email and password
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await ApiService.signIn(email: email, password: password);
  }

  /// Register with email and password
  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return await ApiService.signUp(email: email, password: password);
  }

  /// Sign out
  Future<void> signOut() async {
    await ApiService.signOut();
  }
}
