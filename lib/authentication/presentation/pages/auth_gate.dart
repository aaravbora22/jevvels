import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jevvels/authentication/presentation/bloc/auth_bloc.dart';
import 'package:jevvels/authentication/presentation/bloc/auth_state.dart'
    as bloc_auth;
import 'package:jevvels/authentication/presentation/pages/login_page.dart';
import 'package:jevvels/src/pages/dashboard.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, bloc_auth.AuthState>(
      builder: (context, state) {
        if (state is bloc_auth.AuthAuthenticated) {
          // ✅ User is logged in → now pass through biometric gate
          return const BiometricProtectedDashboard();
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

/// 🔐 This widget runs Face ID / biometrics BEFORE showing Dashboard.
class BiometricProtectedDashboard extends StatefulWidget {
  const BiometricProtectedDashboard({super.key});

  @override
  State<BiometricProtectedDashboard> createState() =>
      _BiometricProtectedDashboardState();
}

class _BiometricProtectedDashboardState
    extends State<BiometricProtectedDashboard> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _checking = true; // while we’re deciding what to do

  @override
  void initState() {
    super.initState();
    _runBiometricCheck();
  }

  Future<void> _runBiometricCheck() async {
    // 1️⃣ Is biometric lock even enabled?
    final enabled =
        await _secureStorage.read(key: 'biometric_enabled') == 'true';

    if (!enabled) {
      // No lock → just show Dashboard
      if (!mounted) return;
      setState(() {
        _checking = false;
      });
      return;
    }

    // 2️⃣ Ask for Face ID / biometrics
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: 'Unlock Jevvels with Face ID',
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: false,
        ),
      );

      if (!mounted) return;

      if (ok) {
        // success → show Dashboard
        setState(() {
          _checking = false;
        });
      } else {
        // failed or cancelled → send to login (or keep a lock screen)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      // In case of any error, fail open or closed (your choice)
      if (!mounted) return;
      setState(() {
        _checking = false;
       } // here we just show Dashboard anyway
      );
      // If you prefer fail-closed, instead push LoginPage here.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      // While Face ID sheet is up / we are checking
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ✅ Authenticated + (if enabled) passed biometrics → enter app
    return const Dashboard();
  }
}
