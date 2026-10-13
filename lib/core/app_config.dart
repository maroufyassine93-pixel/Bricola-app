/// Global runtime flags.
class AppConfig {
  /// True once Firebase.initializeApp succeeded with real options.
  ///
  /// False in demo mode (no `flutterfire configure` yet): the app still
  /// opens and every Firebase-backed feature degrades to its error/empty
  /// state instead of crashing at startup.
  static bool firebaseReady = false;

  /// The ONE AND ONLY admin phone (E.164). The admin screen, the admin
  /// entry button, and the Firestore `isAdmin()` rule all key off this
  /// number — nobody else can ever become admin, not even via console.
  static const String adminPhone = '+213675404636';

  /// The ONE AND ONLY admin email (used while login is email-based).
  /// Admin checks pass when EITHER the email or the phone matches, so
  /// switching between email login (temporary) and phone login (Blaze)
  /// never locks the admin out.
  static const String adminEmail = 'maroufyassine93@gmail.com';

  /// True when this identity belongs to THE admin. Nobody else, ever.
  /// Email comparison is case-insensitive (Firebase may vary the case).
  static bool isAdminIdentity({String? email, String? phone}) {
    return (email != null &&
            email.isNotEmpty &&
            email.toLowerCase() == adminEmail) ||
        (phone != null && phone == adminPhone);
  }
}
