import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthDatasource {
  final SupabaseClient _client = Supabase.instance.client;

// sign in method for authentication
  Future<AuthResponse> signIn(String email, String password) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

// sign up method for creating a new user
  Future<AuthResponse> signUp(String email, String password) {
    return _client.auth.signUp(email: email, password: password);
  }

// sign out method to log out the user
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
