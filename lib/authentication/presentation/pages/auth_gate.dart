import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jevvels/authentication/presentation/bloc/auth_bloc.dart';
import 'package:jevvels/authentication/presentation/bloc/auth_state.dart'
    as bloc_auth;
import 'package:jevvels/authentication/presentation/pages/login_page.dart';
import 'package:jevvels/src/pages/dashboard.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, bloc_auth.AuthState>(
      builder: (context, state) {
        if (state is bloc_auth.AuthAuthenticated) {
          return const Dashboard();
        } else if (state is bloc_auth.AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
