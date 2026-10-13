import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Firebase configuration for Bricola.
///
/// Values come from the Firebase console (Project settings → General).
/// `google-services.json` (Android) must also sit at
/// `android/app/google-services.json` — the Google Services Gradle plugin
/// reads it at build time.
///
/// SECURITY: the Android `apiKey` below is a public client identifier
/// (it ships inside every APK). Real protection comes from the Firestore
/// rules (`firebase/firestore.rules`) + App Check, not from hiding this key.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // ── Filled from the Firebase console (project bricola-6a682) ──────
    const opts = FirebaseOptions(
      apiKey: 'AIzaSyA_DFtX3zkHEEFga7U65PTWj03yrR1CJTE',
      appId: '1:474049867857:android:f9f78f540c3c66ba838870',
      messagingSenderId: '474049867857',
      projectId: 'bricola-6a682',
      storageBucket: 'bricola-6a682.firebasestorage.app',
    );
    // ────────────────────────────────────────────────────────────────
    return opts;
  }
}
