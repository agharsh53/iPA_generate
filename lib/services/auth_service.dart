import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AuthService {

  /// SIGN UP
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user != null) {
      await supabase.from('profiles').insert({
        'id': user.id,
        'email': user.email,
      });
    }

    return response;
  }

  /// LOGIN
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// LOGOUT
  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  /// CURRENT USER
  User? get currentUser => supabase.auth.currentUser;
}
