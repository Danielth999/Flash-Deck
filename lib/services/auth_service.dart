class AuthSession {
  const AuthSession({required this.userId});

  final String userId;
}

abstract interface class AuthService {
  AuthSession? get currentSession;
  Stream<AuthSession?> get authStateChanges;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  });

  /// Returns true when email confirmation is not required for this account.
  Future<bool> signUp({
    required String email,
    required String password,
  });

  Future<void> signOut();
}
