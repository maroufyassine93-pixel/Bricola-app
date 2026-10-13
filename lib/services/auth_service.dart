import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/app_config.dart';

/// Firebase Phone OTP auth (+213). ChangeNotifier for simple provider wiring.
class AuthService extends ChangeNotifier {
  late final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _verificationId;
  bool _busy = false;
  String? _error;

  bool get busy => _busy;
  String? get error => _error;
  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null;
  Stream<User?> get authState => _auth.authStateChanges();

  void _setBusy(bool v) {
    _busy = v;
    notifyListeners();
  }

  /// Step 1: send SMS code to an Algerian number. [phone] like "0550123456"
  /// or "+213550123456" — normalized to +213 here.
  Future<bool> sendCode(String phone) async {
    _error = null;
    if (!AppConfig.firebaseReady) {
      _error = 'وضع العرض التجريبي: اربط Firebase لتفعيل تسجيل الدخول بالهاتف';
      notifyListeners();
      return false;
    }
    final normalized = _normalizeDz(phone);
    if (normalized == null) {
      _error = 'يرجى إدخال رقم هاتف جزائري صحيح';
      notifyListeners();
      return false;
    }
    _setBusy(true);
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: normalized,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          // Auto-retrieval on Android.
          await _auth.signInWithCredential(credential);
          _setBusy(false);
        },
        verificationFailed: (e) {
          _error = e.message ?? 'فشل إرسال الرمز';
          _setBusy(false);
        },
        codeSent: (verificationId, _) {
          _verificationId = verificationId;
          _setBusy(false);
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
          _setBusy(false);
        },
      );
      return true;
    } catch (e) {
      _error = e.toString();
      _setBusy(false);
      return false;
    }
  }

  /// Step 2: verify the 6-digit SMS code.
  /// Never leaves [busy] stuck: every path resets it, and a timeout guards
  /// against a sign-in Future that never completes.
  Future<bool> verifyCode(String smsCode) async {
    if (_verificationId == null) {
      _error = 'أرسل الرمز أولاً';
      notifyListeners();
      return false;
    }
    _setBusy(true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode.trim(),
      );
      await _auth
          .signInWithCredential(credential)
          .timeout(const Duration(seconds: 45));
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.code == 'invalid-verification-code'
          ? 'الرمز غير صحيح، حاول مجدداً'
          : 'فشل التحقق (${e.code}): ${e.message ?? ''}';
      return false;
    } on TimeoutException {
      _error = 'انتهت المهلة — تحقق من الاتصال بالإنترنت وحاول مجدداً';
      return false;
    } catch (e) {
      _error = 'خطأ غير متوقع: $e';
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// Email/password login (used while phone/SMS is unavailable).
  Future<bool> signInWithEmail(String email, String password) async {
    _error = null;
    if (!AppConfig.firebaseReady) {
      _error = 'وضع العرض التجريبي: اربط Firebase لتفعيل تسجيل الدخول';
      notifyListeners();
      return false;
    }
    _setBusy(true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _emailErrorAr(e.code);
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  /// Email/password registration.
  Future<bool> registerWithEmail(String email, String password) async {
    _error = null;
    if (!AppConfig.firebaseReady) {
      _error = 'وضع العرض التجريبي: اربط Firebase لتفعيل تسجيل الدخول';
      notifyListeners();
      return false;
    }
    _setBusy(true);
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _emailErrorAr(e.code);
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  /// Send a password-reset email.
  Future<bool> sendPasswordReset(String email) async {
    _error = null;
    if (!AppConfig.firebaseReady) {
      notifyListeners();
      return false;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _emailErrorAr(e.code);
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  String _emailErrorAr(String code) {
    switch (code) {
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح';
      case 'user-not-found':
        return 'لا يوجد حساب بهذا البريد — أنشئ حساباً جديداً';
      case 'wrong-password':
      case 'invalid-credential':
        return 'البريد أو كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'هذا البريد مسجّل مسبقاً — سجّل الدخول';
      case 'weak-password':
        return 'كلمة المرور ضعيفة — 6 أحرف على الأقل';
      case 'too-many-requests':
        return 'محاولات كثيرة — انتظر قليلاً وحاول مجدداً';
      default:
        return 'فشل تسجيل الدخول ($code)';
    }
  }

  /// Accepts "0550123456", "213550123456", "+213550123456".
  String? _normalizeDz(String input) {
    var p = input.replaceAll(RegExp(r'[\s\-()]'), '');
    if (p.startsWith('+')) p = p.substring(1);
    if (p.startsWith('00213')) p = p.substring(2);
    if (p.startsWith('213')) p = '+$p';
    if (p.startsWith('0')) p = '+213${p.substring(1)}';
    final ok = RegExp(r'^\+213[567]\d{8}$').hasMatch(p);
    return ok ? p : null;
  }
}
