import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

class SupabaseAuthService implements AuthService {
  SupabaseAuthService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  AuthSession? get currentSession {
    final user = _client.auth.currentSession?.user;
    return user == null ? null : AuthSession(userId: user.id);
  }

  @override
  Stream<AuthSession?> get authStateChanges =>
      _client.auth.onAuthStateChange.map((state) {
        final user = state.session?.user;
        return user == null ? null : AuthSession(userId: user.id);
      });

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<bool> signUp({required String email, required String password}) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    return response.session != null;
  }

  @override
  Future<void> signOut() => _client.auth.signOut();
}
