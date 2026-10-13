import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

import '../core/app_config.dart';
import '../models/app_notification.dart';
import '../models/booking.dart';
import '../models/chat_message.dart';
import '../models/craftsman.dart';
import '../models/review.dart';

/// All Firestore access. Screens consume the Streams below and handle
/// loading / empty / error states themselves.
class FirestoreService {
  late final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// True when Firebase was never configured (`flutterfire configure` not
  /// run): every stream yields empty demo data and every write is a no-op,
  /// so the app stays fully navigable without a backend.
  bool get _demo => !AppConfig.firebaseReady;

  // ── Users ────────────────────────────────────────────────────────────
  /// Creates the user doc on first login. NEVER overwrites an existing
  /// role (e.g. 'admin' granted via console) on subsequent logins.
  /// Works for both email and phone sign-in: whichever identifier is
  /// provided gets stored; the other is left untouched.
  Future<void> ensureUserDoc({
    required String uid,
    String? phone,
    String? email,
    String? displayName,
  }) async {
    if (_demo) return;
    final ref = _db.collection('users').doc(uid);
    final existing = await ref.get();
    final data = <String, dynamic>{
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (phone != null && phone.isNotEmpty) 'phonePrivate': phone,
      if (email != null && email.isNotEmpty) 'email': email,
      if (displayName != null) 'displayName': displayName,
    };
    if (existing.exists) {
      await ref.set(data, SetOptions(merge: true));
      return;
    }
    data['displayName'] = displayName ?? '';
    data['role'] = 'customer';
    data['createdAt'] = FieldValue.serverTimestamp();
    await ref.set(data, SetOptions(merge: true));
  }

  Future<void> saveFcmToken(String uid, String token) {
    if (_demo) return Future.value();
    return _db.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  Future<void> updateDisplayName(String uid, String name) {
    if (_demo) return Future.value();
    return _db.collection('users').doc(uid).set(
        {'displayName': name}, SetOptions(merge: true));
  }

  Stream<Map<String, dynamic>?> userStream(String uid) {
    if (_demo) return Stream.value(null);
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((d) => d.data());
  }

  // ── Craftsmen ────────────────────────────────────────────────────────
  /// Approved craftsmen, optionally filtered. Featured-first ordering is done
  /// client-side (featured flag, then rating).
  Stream<List<Craftsman>> craftsmenStream({
    String? tradeId,
    int? wilayaCode,
    bool verifiedOnly = false,
    bool availableNowOnly = false,
  }) {
    if (_demo) return Stream.value(<Craftsman>[]);
    Query<Map<String, dynamic>> q =
        _db.collection('craftsmen').where('status', isEqualTo: 'approved');
    if (tradeId != null) {
      q = q.where('trades', arrayContains: tradeId);
    }
    if (wilayaCode != null) {
      q = q.where('wilayaCode', isEqualTo: wilayaCode);
    }
    if (verifiedOnly) {
      q = q.where('chamberVerified', isEqualTo: true);
    }
    if (availableNowOnly) {
      q = q.where('availableNow', isEqualTo: true);
    }
    return q.snapshots().map((s) {
      final list = s.docs
          .map((d) => Craftsman.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) {
        if (a.isFeatured != b.isFeatured) {
          return a.isFeatured ? -1 : 1;
        }
        return b.ratingAvg.compareTo(a.ratingAvg);
      });
      return list;
    });
  }

  Stream<Craftsman?> craftsmanStream(String id) {
    if (_demo) return Stream.value(null);
    return _db.collection('craftsmen').doc(id).snapshots().map(
        (d) => d.exists ? Craftsman.fromMap(d.id, d.data()!) : null);
  }

  // ── Admin ──────────────────────────────────────────────────────────
  /// Whether the signed-in user is THE admin — the admin email OR the
  /// admin phone number. Both are checked so the app keeps working when
  /// login switches between email (temporary) and phone (Blaze).
  /// Nobody else, ever.
  Stream<bool> isAdminStream(String uid) {
    if (_demo) return Stream.value(false);
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = user?.email == AppConfig.adminEmail ||
        user?.phoneNumber == AppConfig.adminPhone;
    return Stream.value(isAdmin);
  }

  /// Pending craftsman applications, newest first (client-side sort —
  /// no composite index needed).
  Stream<List<Craftsman>> pendingCraftsmenStream() {
    if (_demo) return Stream.value(<Craftsman>[]);
    return _db
        .collection('craftsmen')
        .where('status', isEqualTo: Craftsman.pending)
        .snapshots()
        .map((s) {
      final list = s.docs
          .map((d) => Craftsman.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Admin: approve / reject / suspend a craftsman. Rules allow this
  /// only for admins; owners cannot flip their own status.
  Future<void> setCraftsmanStatus(String id, String status,
      {bool? chamberVerified}) async {
    if (_demo) return;
    final data = <String, dynamic>{'status': status};
    if (chamberVerified != null) {
      data['chamberVerified'] = chamberVerified;
    }
    await _db.collection('craftsmen').doc(id).update(data);
    // On approval, link the user doc to their craftsman file.
    // (Admin-only write — users cannot self-assign role/craftsmanId.)
    if (status == Craftsman.approved) {
      final doc = await _db.collection('craftsmen').doc(id).get();
      final userId = doc.data()?['userId'] as String?;
      if (userId != null && userId.isNotEmpty) {
        await _db.collection('users').doc(userId).set(
          {'role': 'craftsman', 'craftsmanId': id},
          SetOptions(merge: true),
        );
      }
    }
  }

  /// Admin: delete a craftsman profile entirely.
  Future<void> deleteCraftsman(String id) {
    if (_demo) return Future.value();
    return _db.collection('craftsmen').doc(id).delete();
  }

  /// Admin: approved + suspended craftsmen (manage tab).
  Stream<List<Craftsman>> managedCraftsmenStream() {
    if (_demo) return Stream.value(<Craftsman>[]);
    return _db
        .collection('craftsmen')
        .where('status',
            whereIn: [Craftsman.approved, Craftsman.suspended])
        .snapshots()
        .map((s) {
      final list = s.docs
          .map((d) => Craftsman.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => b.ratingAvg.compareTo(a.ratingAvg));
      return list;
    });
  }

  /// Admin: every booking on the platform, newest first.
  Stream<List<Booking>> allBookingsStream() {
    if (_demo) return Stream.value(<Booking>[]);
    return _db.collection('bookings').snapshots().map((s) {
      final list =
          s.docs.map((d) => Booking.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Admin: every user, with their uid attached.
  Stream<List<Map<String, dynamic>>> allUsersStream() {
    if (_demo) return Stream.value(<Map<String, dynamic>>[]);
    return _db.collection('users').snapshots().map(
        (s) => s.docs.map((d) => {'uid': d.id, ...d.data()}).toList());
  }

  /// Admin PIN — stored as SHA-256, NEVER plaintext.
  /// [hasAdminPin] reports existence; [verifyAdminPin] checks a candidate.
  /// A legacy plaintext PIN (pre-hash versions) is auto-upgraded on first
  /// successful verify.
  Future<bool> hasAdminPin() async {
    if (_demo) return false;
    final d = await _db.collection('config').doc('admin').get();
    final pin = d.data()?['pin'] as String?;
    return pin != null && pin.isNotEmpty;
  }

  String _pinHash(String pin) =>
      sha256.convert(utf8.encode(pin)).toString();

  bool _looksHashed(String v) =>
      v.length == 64 && RegExp(r'^[0-9a-f]{64}$').hasMatch(v);

  Future<bool> verifyAdminPin(String input) async {
    if (_demo) return false;
    final ref = _db.collection('config').doc('admin');
    final d = await ref.get();
    final stored = d.data()?['pin'] as String?;
    if (stored == null || stored.isEmpty) return false;
    if (_looksHashed(stored)) {
      return _pinHash(input) == stored;
    }
    // Legacy plaintext PIN: verify, then upgrade to hash.
    if (input == stored) {
      await ref.set({'pin': _pinHash(input)}, SetOptions(merge: true));
      return true;
    }
    return false;
  }

  Future<void> setAdminPin(String pin) {
    if (_demo) return Future.value();
    return _db
        .collection('config')
        .doc('admin')
        .set({'pin': _pinHash(pin)}, SetOptions(merge: true));
  }

  /// Admin: document counts for the stats tab.
  Future<int> countCollection(String collection,
      {String? field, Object? isEqualTo}) async {
    if (_demo) return 0;
    Query<Map<String, dynamic>> q = _db.collection(collection);
    if (field != null) q = q.where(field, isEqualTo: isEqualTo);
    final snap = await q.count().get();
    return snap.count ?? 0;
  }

  /// Admin: one `system` notification per user (batched).
  /// Returns the number of users notified.
  Future<int> sendBroadcastNotification(
      {required String title, required String body}) async {
    if (_demo) return 0;
    final users = await _db.collection('users').get();
    if (users.docs.isEmpty) return 0;
    final batch = _db.batch();
    for (final u in users.docs) {
      batch.set(_db.collection('notifications').doc(), {
        'userId': u.id,
        'title': title,
        'body': body,
        'type': 'system',
        'data': <String, dynamic>{},
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    return users.docs.length;
  }

  Future<Craftsman?> getCraftsman(String id) async {
    if (_demo) return null;
    final d = await _db.collection('craftsmen').doc(id).get();
    return d.exists ? Craftsman.fromMap(d.id, d.data()!) : null;
  }

  /// Craftsman toggles his own availability / urgent flag.
  Future<void> setAvailability({
    required String craftsmanId,
    bool? availableNow,
    bool? urgentAvailable,
  }) {
    if (_demo) return Future.value();
    final data = <String, dynamic>{};
    if (availableNow != null) data['availableNow'] = availableNow;
    if (urgentAvailable != null) data['urgentAvailable'] = urgentAvailable;
    return _db.collection('craftsmen').doc(craftsmanId).update(data);
  }

  // ── Become craftsman ─────────────────────────────────────────────────
  /// Creates the craftsman file in `pending` status with the verification
  /// document (photo or PDF) attached → profile shows "قيد المراجعة".
  Future<String> submitCraftsmanApplication({
    required String uid,
    required String displayName,
    required List<String> trades,
    required int wilayaCode,
    required String commune,
    required List<String> skills,
    required List<String> portfolioUrls,
    required List<PriceRange> priceRanges,
    VerificationDoc? verification,
  }) async {
    if (_demo) return 'demo-id';
    final now = DateTime.now();
    final doc = await _db.collection('craftsmen').add(Craftsman(
          id: '',
          userId: uid,
          displayName: displayName,
          trades: trades,
          wilayaCode: wilayaCode,
          commune: commune,
          phoneVerified: false, // no OTP login in email mode
          chamberVerified: false,
          verification: verification,
          skills: skills,
          portfolioUrls: portfolioUrls,
          priceRanges: priceRanges,
          status: 'pending',
          createdAt: now,
        ).toMap());
    return doc.id;
  }

  // ── Bookings ─────────────────────────────────────────────────────────
  Future<String> createBooking({
    required String customerId,
    required String craftsmanId,
    required String tradeId,
    required String serviceLabel,
    required String description,
    required List<String> photoUrls,
    DateTime? preferredTime,
    required bool urgent,
  }) async {
    if (_demo) return 'demo-booking-id';
    final now = DateTime.now();
    final doc = await _db.collection('bookings').add(Booking(
          id: '',
          customerId: customerId,
          craftsmanId: craftsmanId,
          tradeId: tradeId,
          serviceLabel: serviceLabel,
          description: description,
          photoUrls: photoUrls,
          preferredTime: preferredTime,
          urgent: urgent,
          createdAt: now,
          updatedAt: now,
        ).toMap());
    return doc.id;
  }

  Stream<List<Booking>> bookingsForUser(String uid, String role) {
    if (_demo) return Stream.value(<Booking>[]);
    final field = role == 'craftsman' ? 'craftsmanId' : 'customerId';
    // NOTE: for craftsmen, craftsmanId stores the craftsmen-doc id.
    return _db
        .collection('bookings')
        .where(field, isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => Booking.fromMap(d.id, d.data())).toList());
  }

  Stream<Booking?> bookingStream(String id) {
    if (_demo) return Stream.value(null);
    return _db.collection('bookings').doc(id).snapshots().map(
        (d) => d.exists ? Booking.fromMap(d.id, d.data()!) : null);
  }

  Future<void> updateBookingStatus(String id, String status) {
    if (_demo) return Future.value();
    return _db.collection('bookings').doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// "تم الدفع" — customer confirms cash was paid on completion.
  Future<void> confirmPayment(String id) {
    if (_demo) return Future.value();
    return _db.collection('bookings').doc(id).update({
      'paidConfirmed': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Craftsman accepts a booking → status='accepted' + reveal own phone.
  /// Firestore rules (isReveal) enforce that contactPhone equals the
  /// caller's own phonePrivate — no arbitrary numbers possible.
  Future<void> acceptBooking(String id) async {
    if (_demo) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = await _db.collection('users').doc(uid).get();
    final phone = userDoc.data()?['phonePrivate'] as String? ?? '';
    await _db.collection('bookings').doc(id).update({
      'status': Booking.accepted,
      'contactRevealed': true,
      'contactPhone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Craftsman declines a booking.
  Future<void> declineBooking(String id) async {
    if (_demo) return;
    await _db.collection('bookings').doc(id).update({
      'status': Booking.cancelled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Reviews (photo REQUIRED) ─────────────────────────────────────────
  Stream<List<Review>> reviewsFor(String craftsmanId) {
    if (_demo) return Stream.value(<Review>[]);
    return _db
        .collection('reviews')
        .where('craftsmanId', isEqualTo: craftsmanId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => Review.fromMap(d.id, d.data())).toList());
  }

  /// Throws [StateError] when [workPhotoUrl] is empty — a review without a
  /// photo of the completed work is rejected (UI + rules enforce too).
  Future<void> submitReview({
    required String craftsmanId,
    required String bookingId,
    required String customerId,
    required String customerName,
    required int rating,
    required String comment,
    required String workPhotoUrl,
  }) async {
    if (workPhotoUrl.isEmpty) {
      throw StateError('صورة العمل المنجز إلزامية للتقييم');
    }
    if (_demo) return;
    final batch = _db.batch();
    final reviewRef = _db.collection('reviews').doc();
    batch.set(
        reviewRef,
        Review(
          id: reviewRef.id,
          craftsmanId: craftsmanId,
          bookingId: bookingId,
          customerId: customerId,
          customerName: customerName,
          rating: rating,
          comment: comment,
          workPhotoUrl: workPhotoUrl,
          createdAt: DateTime.now(),
        ).toMap());
    // Recompute the craftsman's average (transaction-safe enough for MVP;
    // move to a Cloud Function trigger at scale).
    final craftRef = _db.collection('craftsmen').doc(craftsmanId);
    final snap = await craftRef.get();
    if (snap.exists) {
      final data = snap.data()!;
      final count = (data['ratingCount'] as num? ?? 0).toInt();
      final avg = (data['ratingAvg'] as num? ?? 0).toDouble();
      final newAvg = ((avg * count) + rating) / (count + 1);
      batch.update(craftRef, {
        'ratingAvg': newAvg,
        'ratingCount': count + 1,
      });
    }
    await batch.commit();
  }

  // ── Chat ─────────────────────────────────────────────────────────────
  Stream<List<ChatThread>> chatThreads(String uid) {
    if (_demo) return Stream.value(<ChatThread>[]);
    return _db
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ChatThread.fromMap(d.id, d.data()))
            .toList());
  }

  Stream<List<ChatMessage>> messages(String chatId) {
    if (_demo) return Stream.value(<ChatMessage>[]);
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs
            .map((d) => ChatMessage.fromMap(d.id, d.data()))
            .toList());
  }

  /// Finds or creates a 1:1 thread WITHOUT sending a message
  /// (used by the "دردشة" button on a craftsman profile).
  Future<String> getOrCreateThread({
    String? bookingId,
    required String me,
    required String otherId,
    required String otherName,
  }) async {
    if (_demo) return 'demo-thread';
    final chats = _db.collection('chats');
    if (bookingId != null) {
      final existing = await chats
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) return existing.docs.first.id;
    }
    final doc = await chats.add({
      'participants': [me, otherId],
      'bookingId': bookingId,
      'otherName': otherName,
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Finds or creates the 1:1 thread for a booking, then appends the message.
  /// When [chatId] is given (thread already open on screen), the message is
  /// written straight into it — no bookingId lookup, no duplicate threads.
  Future<void> sendMessage({
    required String bookingId,
    String? chatId,
    required String senderId,
    required String receiverId,
    required String receiverName,
    String type = ChatMessage.text,
    String text = '',
    String? mediaUrl,
    int durationSec = 0,
  }) async {
    if (_demo) return;
    final chats = _db.collection('chats');
    final DocumentReference<Map<String, dynamic>> threadRef;
    if (chatId != null && chatId.isNotEmpty) {
      threadRef = chats.doc(chatId);
    } else {
      final existing = await chats
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();
      if (existing.docs.isEmpty) {
        threadRef = await chats.add({
          'participants': [senderId, receiverId],
          'bookingId': bookingId,
          'otherName': receiverName,
          'lastMessage': _preview(type, text),
          'lastMessageAt': FieldValue.serverTimestamp(),
        });
      } else {
        threadRef = existing.docs.first.reference;
      }
    }
    await threadRef.collection('messages').add(ChatMessage(
          id: '',
          senderId: senderId,
          type: type,
          textContent: text,
          mediaUrl: mediaUrl,
          durationSec: durationSec,
          createdAt: DateTime.now(),
          readBy: [senderId],
        ).toMap());
    await threadRef.update({
      'lastMessage': _preview(type, text),
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
  }

  String _preview(String type, String text) {
    if (type == ChatMessage.voice) return '🎙️ رسالة صوتية';
    if (type == ChatMessage.image) return '📷 صورة';
    return text;
  }

  // ── Notifications ────────────────────────────────────────────────────
  Stream<List<AppNotification>> notifications(String uid) {
    if (_demo) return Stream.value(<AppNotification>[]);
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs
            .map((d) => AppNotification.fromMap(d.id, d.data()))
            .toList());
  }

  Future<void> markNotificationRead(String id) {
    if (_demo) return Future.value();
    return _db.collection('notifications').doc(id).update({'read': true});
  }
}
