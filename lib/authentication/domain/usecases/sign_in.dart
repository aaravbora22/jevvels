import 'package:jevvels/authentication/domain/repositories/auth_repository.dart';

class SignIn {
  final AuthRepository repository;

  SignIn(this.repository);

  Future<void> call(String email, String password) {
    return repository.signIn(email, password);
  }
}
