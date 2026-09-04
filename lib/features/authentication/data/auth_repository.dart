import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository({SupabaseClient? client}) : _injectedClient = client;

  final SupabaseClient? _injectedClient;
  SupabaseClient get _client => _injectedClient ?? Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw _parseAuthException(e);
    } catch (e) {
      throw Exception(
        'An unexpected error occurred during registration. Please try again.',
      );
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw _parseAuthException(e);
    } catch (e) {
      throw Exception(
        'An unexpected error occurred during login. Please try again.',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {
      // Ignore sign-out errors to clear client state cleanly
    }
  }

  Exception _parseAuthException(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return Exception(
        'Invalid email or password. Please check your credentials and try again.',
      );
    } else if (msg.contains('user already registered') ||
        msg.contains('already exists')) {
      return Exception(
        'An account with this email already exists. Please log in instead.',
      );
    } else if (msg.contains('weak password')) {
      return Exception(
        'The password is too weak. Please use a stronger password.',
      );
    }
    return Exception(e.message);
  }
}
