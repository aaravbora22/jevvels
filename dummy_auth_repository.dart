import 'package:jevvels/authentication/domain/repositories/auth_repository.dart';

class DummyAuthRepository implements AuthRepository {
  @override
  Future<void> signIn(String email, String password) async {}

  @override
  Future<void> signUp(String email, String password) async {}

  @override
  Future<void> signOut() async {}
}
