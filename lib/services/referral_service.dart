import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/app_config.dart';

/// Referral program: "ادعُ أصدقاءك واربح ترقيات مجانية".
/// Each user owns a short code; when an invited friend completes their first
/// booking, both sides earn points redeemable for free featured placement.
class ReferralService {
  late final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _rand = Random.secure();

  static const int pointsPerInvite = 100;
  static const int featuredDaysCost = 300; // points for 7 featured days

  /// Demo mode: every backend call short-circuits (see FirestoreService).
  bool get _demo => !AppConfig.firebaseReady;

  /// Get the user's code, creating it on first use.
  Future<String> getOrCreateCode(String uid) async {
    if (_demo) return 'DEMO01';
    final userRef = _db.collection('users').doc(uid);
    final snap = await userRef.get();
    final existing = snap.data()?['referralCode'] as String?;
    if (existing != null && existing.isNotEmpty) return existing;
    final code = _newCode();
    await userRef.set({'referralCode': code}, SetOptions(merge: true));
    return code;
  }

  /// Record that [invitedUid] signed up with [code].
  /// Returns false when the code is invalid or belongs to the same user.
  Future<bool> applyCode(String code, String invitedUid) async {
    if (_demo) return false;
    final clean = code.trim().toUpperCase();
    final ownerSnap = await _db
        .collection('users')
        .where('referralCode', isEqualTo: clean)
        .limit(1)
        .get();
    if (ownerSnap.docs.isEmpty) return false;
    final ownerId = ownerSnap.docs.first.id;
    if (ownerId == invitedUid) return false;

    final dup = await _db
        .collection('referrals')
        .where('invitedUserId', isEqualTo: invitedUid)
        .limit(1)
        .get();
    if (dup.docs.isNotEmpty) return false; // one referral per user

    await _db.collection('referrals').add({
      'code': clean,
      'ownerId': ownerId,
      'invitedUserId': invitedUid,
      'status': 'pending',
      'rewardGranted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return true;
  }

  /// Called (by a Cloud Function in production) when the invited user
  /// completes their first booking → grant points to the owner.
  Future<void> grantInviteReward(String referralId) async {
    if (_demo) return;
    final ref = _db.collection('referrals').doc(referralId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data()!;
      if (data['rewardGranted'] == true) return;
      final ownerId = data['ownerId'] as String;
      tx.update(ref, {'status': 'completed', 'rewardGranted': true});
      tx.set(_db.collection('rewards').doc(), {
        'userId': ownerId,
        'kind': 'points',
        'amount': pointsPerInvite,
        'reason': 'دعوة صديق',
        'used': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Redeem points for 7 days of featured placement on the craftsman's file.
  Future<bool> redeemFeatured(String uid) async {
    if (_demo) return false;
    final balance = await pointsBalance(uid);
    if (balance < featuredDaysCost) return false;
    final batch = _db.batch();
    // Mark oldest unused point rewards as used until cost is covered.
    final rewards = await _db
        .collection('rewards')
        .where('userId', isEqualTo: uid)
        .where('kind', isEqualTo: 'points')
        .where('used', isEqualTo: false)
        .orderBy('createdAt')
        .get();
    var remaining = featuredDaysCost;
    for (final doc in rewards.docs) {
      if (remaining <= 0) break;
      final amount = (doc.data()['amount'] as num).toInt();
      final take = min(amount, remaining);
      remaining -= take;
      if (take >= amount) {
        batch.update(doc.reference, {'used': true});
      } else {
        batch.update(doc.reference, {'amount': amount - take});
        batch.set(_db.collection('rewards').doc(), {
          'userId': uid,
          'kind': 'points',
          'amount': take,
          'reason': 'استبدال: إبراز الملف',
          'used': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
    if (remaining > 0) return false;
    batch.set(_db.collection('rewards').doc(), {
      'userId': uid,
      'kind': 'featuredDays',
      'amount': 7,
      'reason': 'إبراز الملف 7 أيام',
      'used': false,
      'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7))),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return true;
  }

  Future<int> pointsBalance(String uid) async {
    if (_demo) return 0;
    final snap = await _db
        .collection('rewards')
        .where('userId', isEqualTo: uid)
        .where('kind', isEqualTo: 'points')
        .where('used', isEqualTo: false)
        .get();
    var total = 0;
    for (final d in snap.docs) {
      total += (d.data()['amount'] as num).toInt();
    }
    return total;
  }

  Stream<int> inviteCount(String uid) {
    if (_demo) return Stream.value(0);
    return _db
        .collection('referrals')
        .where('ownerId', isEqualTo: uid)
        .snapshots()
        .map((s) => s.docs.length);
  }

  String get currentUid =>
      AppConfig.firebaseReady ? FirebaseAuth.instance.currentUser!.uid : '';

  String _newCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(
        6, (_) => chars[_rand.nextInt(chars.length)]).join();
  }
}
