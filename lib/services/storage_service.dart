import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../core/app_config.dart';

/// Firebase Storage uploads. All paths namespaced per user.
///
/// Resilience: every upload is guarded — if the bucket is not provisioned
/// (e.g. Blaze not enabled yet), offline, or denied, the upload is skipped
/// and '' is returned instead of throwing. Callers treat '' as "no photo
/// yet" so registration/booking flows keep working.
class StorageService {
  late final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Demo mode: uploads are skipped, empty URL returned.
  bool get _demo => !AppConfig.firebaseReady;

  /// Runs [op]; on any failure returns '' (photo skipped, not fatal).
  Future<String> _guarded(Future<String> Function() op) async {
    try {
      return await op().timeout(const Duration(seconds: 60));
    } catch (e) {
      debugPrint('Storage upload skipped: $e');
      return '';
    }
  }

  /// Chamber card / certificate → craftsmen/{uid}/verification/
  /// [fileType] is 'photo' or 'pdf' (drives the extension + content type).
  Future<String> uploadVerificationFile({
    required String uid,
    required File file,
    required String fileType,
  }) async {
    if (_demo) return '';
    return _guarded(() async {
      final ext = fileType == 'pdf' ? 'pdf' : 'jpg';
      final ref = _storage
          .ref()
          .child('craftsmen/$uid/verification/chamber_card.$ext');
      final metadata = SettableMetadata(
        contentType: fileType == 'pdf' ? 'application/pdf' : 'image/jpeg',
      );
      await ref.putFile(file, metadata);
      return ref.getDownloadURL();
    });
  }

  /// Portfolio work photos → craftsmen/{uid}/portfolio/{name}
  Future<String> uploadPortfolioPhoto({
    required String uid,
    required File file,
    required String name,
  }) async {
    if (_demo) return '';
    return _guarded(() async {
      final ref =
          _storage.ref().child('craftsmen/$uid/portfolio/$name.jpg');
      await ref.putFile(
          file, SettableMetadata(contentType: 'image/jpeg'));
      return ref.getDownloadURL();
    });
  }

  /// Booking problem photos → bookings/{bookingId}/{name}
  Future<String> uploadBookingPhoto({
    required String bookingId,
    required File file,
    required String name,
  }) async {
    if (_demo) return '';
    return _guarded(() async {
      final ref =
          _storage.ref().child('bookings/$bookingId/$name.jpg');
      await ref.putFile(
          file, SettableMetadata(contentType: 'image/jpeg'));
      return ref.getDownloadURL();
    });
  }

  /// Review work photo (REQUIRED for reviews) → reviews/{reviewId}.jpg
  Future<String> uploadReviewPhoto({
    required String reviewId,
    required File file,
  }) async {
    if (_demo) return '';
    return _guarded(() async {
      final ref = _storage.ref().child('reviews/$reviewId.jpg');
      await ref.putFile(
          file, SettableMetadata(contentType: 'image/jpeg'));
      return ref.getDownloadURL();
    });
  }

  /// Chat attachments → chats/{chatId}/{name}
  Future<String> uploadChatAttachment({
    required String chatId,
    required File file,
    required String name,
    String contentType = 'image/jpeg',
  }) async {
    if (_demo) return '';
    return _guarded(() async {
      final ref = _storage.ref().child('chats/$chatId/$name');
      await ref.putFile(file, SettableMetadata(contentType: contentType));
      return ref.getDownloadURL();
    });
  }

  /// Voice message → chats/{chatId}/voice/{name}.m4a
  Future<String> uploadVoiceMessage({
    required String chatId,
    required File file,
    required String name,
  }) {
    return uploadChatAttachment(
      chatId: chatId,
      file: file,
      name: 'voice/$name.m4a',
      contentType: 'audio/m4a',
    );
  }

  /// User avatar → users/{uid}/avatar.jpg
  Future<String> uploadAvatar({
    required String uid,
    required File file,
  }) async {
    if (_demo) return '';
    return _guarded(() async {
      final ref = _storage.ref().child('users/$uid/avatar.jpg');
      await ref.putFile(
          file, SettableMetadata(contentType: 'image/jpeg'));
      return ref.getDownloadURL();
    });
  }
}
