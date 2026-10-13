import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../l10n/strings_ar.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

/// Email/password login + registration (used while phone SMS is unavailable).
class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController(); // registration only
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _valid {
    final emailOk = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
        .hasMatch(_emailCtrl.text.trim());
    return emailOk && _passCtrl.text.length >= 6;
  }

  Future<void> _submit(AuthService auth, bool isRegister) async {
    final ok = isRegister
        ? await auth.registerWithEmail(_emailCtrl.text, _passCtrl.text)
        : await auth.signInWithEmail(_emailCtrl.text, _passCtrl.text);
    if (!mounted) return;
    if (ok && auth.currentUser != null) {
      // Create / merge the user doc — never let a Firestore failure
      // block the login itself.
      try {
        await context
            .read<FirestoreService>()
            .ensureUserDoc(
              uid: auth.currentUser!.uid,
              email: auth.currentUser!.email ?? _emailCtrl.text.trim(),
              displayName: isRegister
                  ? _nameCtrl.text.trim().isEmpty
                      ? null
                      : _nameCtrl.text.trim()
                  : null,
            )
            .timeout(const Duration(seconds: 20));
      } catch (e) {
        debugPrint('ensureUserDoc failed (non-blocking): $e');
      }
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
      }
    } else if (mounted && auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!)),
      );
    }
  }

  Future<void> _forgot(AuthService auth) async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل بريدك الإلكتروني أولاً')),
      );
      return;
    }
    final ok = await auth.sendPasswordReset(email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'أُرسل رابط الاستعادة إلى بريدك'
            : (auth.error ?? 'فشل الإرسال')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Scaffold(
      appBar: AppBar(title: const Text(S.appName)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 8),
          const Icon(Icons.handyman,
              size: 64, color: BricolaTheme.primary),
          const SizedBox(height: 12),
          const Text(
            'سجّل الدخول ببريدك الإلكتروني',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'الدخول بالهاتف سيعود قريباً',
            textAlign: TextAlign.center,
            style: TextStyle(color: BricolaTheme.muted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabs,
            labelColor: BricolaTheme.primary,
            tabs: const [
              Tab(text: 'دخول'),
              Tab(text: 'حساب جديد'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 340,
            child: TabBarView(
              controller: _tabs,
              children: [
                _form(auth, isRegister: false),
                _form(auth, isRegister: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _form(AuthService auth, {required bool isRegister}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isRegister)
          TextField(
            controller: _nameCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'الاسم الكامل',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
        if (isRegister) const SizedBox(height: 12),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'البريد الإلكتروني',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passCtrl,
          obscureText: _obscure,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'كلمة المرور (6 أحرف على الأقل)',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: auth.busy || !_valid
              ? null
              : () => _submit(auth, isRegister),
          child: auth.busy
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Text(isRegister ? 'إنشاء الحساب' : 'دخول'),
        ),
        if (!isRegister)
          TextButton(
            onPressed: auth.busy ? null : () => _forgot(auth),
            child: const Text('نسيت كلمة المرور؟'),
          ),
      ],
    );
  }
}
