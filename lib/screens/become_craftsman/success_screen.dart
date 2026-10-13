import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../l10n/strings_ar.dart';
import '../../widgets/verified_badge.dart';

/// Application received — profile is in "قيد المراجعة" state.
class BecomeSuccessScreen extends StatelessWidget {
  const BecomeSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mark_email_read,
                  size: 80, color: BricolaTheme.primary),
              const SizedBox(height: 20),
              const Text(S.applicationSent,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              const VerifiedBadge.pending(),
              const SizedBox(height: 12),
              const Text(S.applicationPending,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      height: 1.7,
                      color: BricolaTheme.muted)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil(
                              '/home', (_) => false),
                  child: const Text(S.backToHome),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
