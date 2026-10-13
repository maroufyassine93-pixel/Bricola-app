import 'package:cloud_firestore/cloud_firestore.dart';

/// Referral invite: "ادعُ أصدقاءك واربح ترقيات مجانية".
/// referrals/{referralId}: code, ownerId, invitedUserId, status, rewardGranted.
class Referral {
  static const String pending = 'pending';
  static const String completed = 'completed';

  final String id;
  final String code;
  final String ownerId;
  final String? invitedUserId;
  final String status;
  final bool rewardGranted;
  final DateTime createdAt;

  const Referral({
    required this.id,
    required this.code,
    required this.ownerId,
    this.invitedUserId,
    this.status = pending,
    this.rewardGranted = false,
    required this.createdAt,
  });

  factory Referral.fromMap(String id, Map<String, dynamic> m) => Referral(
        id: id,
        code: m['code'] as String? ?? '',
        ownerId: m['ownerId'] as String? ?? '',
        invitedUserId: m['invitedUserId'] as String?,
        status: m['status'] as String? ?? pending,
        rewardGranted: m['rewardGranted'] as bool? ?? false,
        createdAt:
            (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'code': code,
        'ownerId': ownerId,
        'invitedUserId': invitedUserId,
        'status': status,
        'rewardGranted': rewardGranted,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

/// Rewards ledger entry: points or free featured placement days.
/// rewards/{rewardId}: userId, kind (points|featuredDays), amount, reason…
class Reward {
  static const String points = 'points';
  static const String featuredDays = 'featuredDays';

  final String id;
  final String userId;
  final String kind;
  final int amount;
  final String reason;
  final bool used;
  final DateTime? expiresAt;
  final DateTime createdAt;

  const Reward({
    required this.id,
    required this.userId,
    required this.kind,
    required this.amount,
    required this.reason,
    this.used = false,
    this.expiresAt,
    required this.createdAt,
  });

  factory Reward.fromMap(String id, Map<String, dynamic> m) => Reward(
        id: id,
        userId: m['userId'] as String? ?? '',
        kind: m['kind'] as String? ?? points,
        amount: (m['amount'] as num? ?? 0).toInt(),
        reason: m['reason'] as String? ?? '',
        used: m['used'] as bool? ?? false,
        expiresAt: (m['expiresAt'] as Timestamp?)?.toDate(),
        createdAt:
            (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'kind': kind,
        'amount': amount,
        'reason': reason,
        'used': used,
        'expiresAt':
            expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
