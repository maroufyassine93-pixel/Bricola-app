import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_config.dart';
import '../core/theme.dart';
import '../l10n/strings_ar.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

/// Two-step phone OTP login (+213).
class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _codeSent = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Scaffold(
      appBar: AppBar(title: const Text(S.loginTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.phone_android,
                size: 64, color: BricolaTheme.primary),
            const SizedBox(height: 16),
            Text(
              _codeSent ? S.codeTitle : S.loginSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, height: 1.6),
            ),
            const SizedBox(height: 24),
            if (!_codeSent)
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20),
                decoration: const InputDecoration(
                  labelText: S.phoneNumber,
                  hintText: S.phoneHint,
                  prefixText: '+213 ',
                ),
              )
            else
              Column(
                children: [
                  Text(
                    '${S.codeSubtitle} ${_phoneCtrl.text}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: BricolaTheme.muted),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _codeCtrl,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    style: const TextStyle(
                        fontSize: 28, letterSpacing: 8),
                    decoration: const InputDecoration(
                        counterText: ''),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            if (auth.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  auth.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ElevatedButton(
              onPressed: auth.busy
                  ? null
                  : () => _codeSent ? _verify(auth) : _send(auth),
              child: auth.busy
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(_codeSent ? S.verify : S.sendCode),
            ),
            if (_codeSent)
              TextButton(
                onPressed: auth.busy
                    ? null
                    : () => setState(() => _codeSent = false),
                child: const Text(S.resendCode),
              ),
            // Demo mode: no real phone auth — let the user browse as guest.
            if (!AppConfig.firebaseReady) ...[
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.of(context)
                    .pushNamedAndRemoveUntil('/home', (_) => false),
                child: const Text('المتابعة كزائر (وضع العرض)'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _send(AuthService auth) async {
    final ok = await auth.sendCode(_phoneCtrl.text);
    if (ok && mounted) setState(() => _codeSent = true);
  }

  Future<void> _verify(AuthService auth) async {
    final ok = await auth.verifyCode(_codeCtrl.text);
    if (!mounted) return;
    if (ok && auth.currentUser != null) {
      // Create / merge the user doc — but never let a Firestore failure
      // block the login itself.
      try {
        await context
            .read<FirestoreService>()
            .ensureUserDoc(
              uid: auth.currentUser!.uid,
              phone: auth.currentUser!.phoneNumber ?? '',
            )
            .timeout(const Duration(seconds: 20));
      } catch (e) {
        debugPrint('ensureUserDoc failed (non-blocking): $e');
      }
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
      }
    }
  }
}
