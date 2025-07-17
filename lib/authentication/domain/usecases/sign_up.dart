import 'package:jevvels/authentication/domain/repositories/auth_repository.dart';

class SignUp {
  final AuthRepository repository;

  SignUp(this.repository);

  Future<void> call(String email, String password) {
    return repository.signUp(email, password);
  }
}
