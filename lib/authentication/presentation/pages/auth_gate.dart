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
          // ✅ Logged in → go through biometric gate
          return const BiometricProtectedDashboard();
        } else if (state is bloc_auth.AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else {
          // ❌ Not logged in → show read-only dashboard
          return const PublicDashboard();
        }
      },
    );
  }
}

class PublicDashboard extends StatelessWidget {
  const PublicDashboard({super.key});

  Future<void> _showLoginDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: const Color(0xFF0F0F0F), // Jevvels Deep Black
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Login Required',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Login to access your portfolio dashboard.',
                style: TextStyle(
                  color: Color(0xFFB8B8B8),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),

              // Login Button (Gold)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFF4D47E),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Login',
                  style: TextStyle(
                    color: Color(0xFF0F0F0F),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Not now button
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFF4D47E)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Not Now',
                  style: TextStyle(
                    color: Color(0xFFF4D47E),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (result == true) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 👀 Dashboard is fully visible
        const Dashboard(),

        // 🛡 Overlay that catches taps, but still allows scrolling
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _showLoginDialog(context),
          ),
        ),
      ],
    );
  }
}


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
    final enabled =
        await _secureStorage.read(key: 'biometric_enabled') == 'true';

    if (!enabled) {
      if (!mounted) return;
      setState(() {
        _checking = false; // no biometric → just show Dashboard
      });
      return;
    }

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
        setState(() {
          _checking = false; // passed Face ID
        });
      } else {
        // failed or cancelled → send to login
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      // Here we "fail open" and show Dashboard anyway.
      // If you want fail-closed, push LoginPage instead.
      setState(() {
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return const Dashboard();
  }
}
