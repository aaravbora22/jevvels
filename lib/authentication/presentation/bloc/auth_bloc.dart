import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jevvels/authentication/domain/usecases/sign_in.dart';
import 'package:jevvels/authentication/domain/usecases/sign_out.dart';
import 'package:jevvels/authentication/domain/usecases/sign_up.dart';
import 'package:jevvels/authentication/presentation/bloc/auth_event.dart';
import 'package:jevvels/authentication/presentation/bloc/auth_state.dart'
    as bloc_auth;
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthBloc extends Bloc<AuthEvent, bloc_auth.AuthState> {
  final SignIn signIn;
  final SignUp signUp;
  final SignOut signOut;

  AuthBloc({required this.signIn, required this.signUp, required this.signOut})
      : super(
          Supabase.instance.client.auth.currentSession != null
              ? bloc_auth.AuthAuthenticated()
              : bloc_auth.AuthUnauthenticated(),
        ) {
    on<AuthSignInRequested>((event, emit) async {
      emit(bloc_auth.AuthLoading());
      try {
        await signIn(event.email, event.password);
        emit(bloc_auth.AuthAuthenticated());
      } catch (e) {
        emit(bloc_auth.AuthError(e.toString()));
      }
    });

    on<AuthSignUpRequested>((event, emit) async {
      emit(bloc_auth.AuthLoading());
      try {
        await signUp(event.email, event.password);
        emit(bloc_auth.AuthAuthenticated());
      } catch (e) {
        emit(bloc_auth.AuthError(e.toString()));
      }
    });

    on<AuthSignOutRequested>((event, emit) async {
      emit(bloc_auth.AuthLoading());
      try {
        await signOut();
        emit(bloc_auth.AuthUnauthenticated());
      } catch (e) {
        emit(bloc_auth.AuthError(e.toString()));
      }
    });
  }
}
