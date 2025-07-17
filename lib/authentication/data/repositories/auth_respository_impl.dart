import 'package:jevvels/authentication/data/datasources/supabase_auth_datasource.dart';
import 'package:jevvels/authentication/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseAuthDatasource datasource;

  AuthRepositoryImpl(this.datasource);

  @override
  Future<void> signIn(String email, String password) async {
    await datasource.signIn(email, password);
  }

  @override
  Future<void> signUp(String email, String password) async {
    await datasource.signUp(email, password);
  }

  @override
  Future<void> signOut() async {
    await datasource.signOut();
  }
}
