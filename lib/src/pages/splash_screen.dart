import 'package:flutter/material.dart';
import 'package:jevvels/authentication/presentation/pages/auth_gate.dart';

class JevvelsSplashScreen extends StatefulWidget {
  const JevvelsSplashScreen({super.key});

  @override
  State<JevvelsSplashScreen> createState() => _JevvelsSplashScreenState();
}

class _JevvelsSplashScreenState extends State<JevvelsSplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const AuthGate(), // ⬅️ Your widget here
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color.fromARGB(255, 39, 36, 36),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.diamond,
              size: 110,
              color: Color(0xFFB99750),
            ),
            SizedBox(height: 20),
            Text(
              'Jevvels',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB99750),
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Example target page
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("Home Page")),
    );
  }
}
