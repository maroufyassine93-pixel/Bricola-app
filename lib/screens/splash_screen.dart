import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_config.dart';
import '../core/theme.dart';
import '../l10n/strings_ar.dart';

/// Splash: logo → routes to home (signed in) or onboarding/login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      // In demo mode (no real Firebase) there is never a signed-in user.
      final signedIn = AppConfig.firebaseReady &&
          FirebaseAuth.instance.currentUser != null;
      Navigator.of(context).pushReplacementNamed(
        signedIn ? '/home' : '/onboarding',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BricolaTheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.handyman,
                size: 64,
                color: BricolaTheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              S.appName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 44,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              S.appTagline,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
