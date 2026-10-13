import 'package:firebase_messaging/firebase_messaging.dart';

/// FCM: permission, token registration, foreground/background handlers.
class MessagingService {
  late final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  /// Call once at startup (after Firebase.initializeApp).
  Future<void> init({
    required Future<void> Function(String token) onToken,
  }) async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
    final token = await _fcm.getToken();
    if (token != null) await onToken(token);
    _fcm.onTokenRefresh.listen(onToken);

    // Foreground messages → show via local in-app banner (screens listen).
    FirebaseMessaging.onMessage.listen((msg) {
      // TODO: surface with a local notification / overlay.
    });

    // Tapped notification while backgrounded/terminated.
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      // TODO: deep-link using msg.data['route'].
    });
  }

  /// Subscribe to wilaya topic for local campaigns, e.g. "wilaya_31".
  Future<void> subscribeWilaya(int wilayaCode) =>
      _fcm.subscribeToTopic('wilaya_$wilayaCode');

  Future<void> unsubscribeWilaya(int wilayaCode) =>
      _fcm.unsubscribeFromTopic('wilaya_$wilayaCode');
}
