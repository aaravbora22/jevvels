import 'package:flutter_test/flutter_test.dart';
import 'package:jevvels/main.dart';
import 'package:jevvels/authentication/domain/usecases/sign_in.dart';
import 'package:jevvels/authentication/domain/usecases/sign_up.dart';
import 'package:jevvels/authentication/domain/usecases/sign_out.dart';
import 'package:jevvels/authentication/domain/repositories/auth_repository.dart';

class DummyAuthRepository implements AuthRepository {
  @override
  Future<void> signIn(String email, String password) async {}

  @override
  Future<void> signUp(String email, String password) async {}

  @override
  Future<void> signOut() async {}
}

void main() {
  final dummyRepo = DummyAuthRepository();
  final dummySignIn = SignIn(dummyRepo);
  final dummySignUp = SignUp(dummyRepo);
  final dummySignOut = SignOut(dummyRepo);

  testWidgets('App loads and shows expected widget',
      (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(
      signIn: dummySignIn,
      signUp: dummySignUp,
      signOut: dummySignOut,
    ));

    expect(find.text('Flutter Demo'), findsOneWidget);
  });
}
