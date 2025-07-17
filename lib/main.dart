import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jevvels/authentication/data/datasources/supabase_auth_datasource.dart';
import 'package:jevvels/authentication/data/repositories/auth_respository_impl.dart';
import 'package:jevvels/authentication/domain/usecases/sign_in.dart';
import 'package:jevvels/authentication/domain/usecases/sign_up.dart';
import 'package:jevvels/authentication/domain/usecases/sign_out.dart';
import 'package:jevvels/authentication/presentation/bloc/auth_bloc.dart';
import 'package:jevvels/authentication/presentation/pages/auth_gate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://pdktygrzzkskuhbqevdi.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBka3R5Z3J6emtza3VoYnFldmRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIxMjkxNTQsImV4cCI6MjA2NzcwNTE1NH0.2VeNsEoCU9nwGgzOhgn7wNfMF8QgeCq2DfNcZJuz5ak',
  );

  // Set up dependencies
  final datasource = SupabaseAuthDatasource();
  final repository = AuthRepositoryImpl(datasource);
  final signIn = SignIn(repository);
  final signUp = SignUp(repository);
  final signOut = SignOut(repository);

  runApp(MyApp(
    signIn: signIn,
    signUp: signUp,
    signOut: signOut,
  ));
}

class MyApp extends StatelessWidget {
  final SignIn signIn;
  final SignUp signUp;
  final SignOut signOut;

  const MyApp({
    super.key,
    required this.signIn,
    required this.signUp,
    required this.signOut,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(
            signIn: signIn,
            signUp: signUp,
            signOut: signOut,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          fontFamily: 'Main Font',
        ),
        home: const AuthGate(),
      ),
    );
  }
}
