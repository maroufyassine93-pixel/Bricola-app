import 'package:cloud_firestore/cloud_firestore.dart';

/// Indicative price range for one trade (سعر استرشادي), in DZD.
class PriceRange {
  final String tradeId;
  final int minDzd;
  final int maxDzd;

  const PriceRange({
    required this.tradeId,
    required this.minDzd,
    required this.maxDzd,
  });

  String get label => '$minDzd–$maxDzd دج';

  factory PriceRange.fromMap(Map<String, dynamic> m) => PriceRange(
        tradeId: m['tradeId'] as String? ?? '',
        minDzd: (m['minDzd'] as num? ?? 0).toInt(),
        maxDzd: (m['maxDzd'] as num? ?? 0).toInt(),
      );

  Map<String, dynamic> toMap() => {
        'tradeId': tradeId,
        'minDzd': minDzd,
        'maxDzd': maxDzd,
      };
}

/// Chamber verification document (بطاقة الحرفي / شهادة).
/// The file itself lives in Firebase Storage under
/// `craftsmen/{uid}/verification/` and may be a photo OR a PDF.
class VerificationDoc {
  static const String photo = 'photo';
  static const String pdf = 'pdf';

  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';

  final String fileUrl;
  final String fileType; // photo | pdf
  final String status; // pending | approved | rejected
  final DateTime submittedAt;

  const VerificationDoc({
    required this.fileUrl,
    required this.fileType,
    this.status = pending,
    required this.submittedAt,
  });

  factory VerificationDoc.fromMap(Map<String, dynamic> m) => VerificationDoc(
        fileUrl: m['fileUrl'] as String? ?? '',
        fileType: m['fileType'] as String? ?? photo,
        status: m['status'] as String? ?? pending,
        submittedAt:
            (m['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'fileUrl': fileUrl,
        'fileType': fileType,
        'status': status,
        'submittedAt': Timestamp.fromDate(submittedAt),
      };
}

/// A craftsman profile. Lives in `craftsmen/{craftsmanId}`.
/// NOTE: the raw phone number is NOT stored here. It lives in
/// `users/{uid}.phonePrivate` and is revealed to the customer only after a
/// booking is accepted (see FirestoreService.revealPhoneAfterAccept).
class Craftsman {
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
  static const String suspended = 'suspended';

  final String id;
  final String userId;
  final String displayName;
  final String? photoUrl;
  final List<String> trades;
  final int wilayaCode;
  final String commune;
  final bool phoneVerified;
  final bool chamberVerified; // "حرفي موثّق" badge
  final VerificationDoc? verification; // chamber card / certificate upload
  final double ratingAvg;
  final int ratingCount;
  final List<String> skills;
  final List<String> portfolioUrls;
  final List<PriceRange> priceRanges;
  final bool availableNow;
  final bool urgentAvailable; // تدخل مستعجل 🚨
  final int urgentSurchargePct; // 30
  final double? lat;
  final double? lng;
  final DateTime? featuredUntil; // paid/free featured placement
  final String status; // pending | approved | rejected | suspended
  final DateTime createdAt;

  const Craftsman({
    required this.id,
    required this.userId,
    required this.displayName,
    this.photoUrl,
    this.trades = const [],
    required this.wilayaCode,
    this.commune = '',
    this.phoneVerified = false,
    this.chamberVerified = false,
    this.verification,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.skills = const [],
    this.portfolioUrls = const [],
    this.priceRanges = const [],
    this.availableNow = false,
    this.urgentAvailable = false,
    this.urgentSurchargePct = 30,
    this.lat,
    this.lng,
    this.featuredUntil,
    this.status = 'pending',
    required this.createdAt,
  });

  bool get isFeatured =>
      featuredUntil != null && featuredUntil!.isAfter(DateTime.now());

  PriceRange? priceFor(String tradeId) {
    for (final p in priceRanges) {
      if (p.tradeId == tradeId) return p;
    }
    return null;
  }

  factory Craftsman.fromMap(String id, Map<String, dynamic> m) {
    return Craftsman(
      id: id,
      userId: m['userId'] as String? ?? '',
      displayName: m['displayName'] as String? ?? '',
      photoUrl: m['photoUrl'] as String?,
      trades: List<String>.from(m['trades'] ?? const []),
      wilayaCode: (m['wilayaCode'] as num? ?? 0).toInt(),
      commune: m['commune'] as String? ?? '',
      phoneVerified: m['phoneVerified'] as bool? ?? false,
      chamberVerified: m['chamberVerified'] as bool? ?? false,
      verification: m['verification'] != null
          ? VerificationDoc.fromMap(
              Map<String, dynamic>.from(m['verification']))
          : null,
      ratingAvg: (m['ratingAvg'] as num? ?? 0).toDouble(),
      ratingCount: (m['ratingCount'] as num? ?? 0).toInt(),
      skills: List<String>.from(m['skills'] ?? const []),
      portfolioUrls: List<String>.from(m['portfolioUrls'] ?? const []),
      priceRanges: (m['priceRanges'] as List? ?? const [])
          .map((e) => PriceRange.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      availableNow: m['availableNow'] as bool? ?? false,
      urgentAvailable: m['urgentAvailable'] as bool? ?? false,
      urgentSurchargePct: (m['urgentSurchargePct'] as num? ?? 30).toInt(),
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
      featuredUntil:
          (m['featuredUntil'] as Timestamp?)?.toDate(),
      status: m['status'] as String? ?? 'pending',
      createdAt:
          (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'trades': trades,
        'wilayaCode': wilayaCode,
        'commune': commune,
        'phoneVerified': phoneVerified,
        'chamberVerified': chamberVerified,
        'verification': verification?.toMap(),
        'ratingAvg': ratingAvg,
        'ratingCount': ratingCount,
        'skills': skills,
        'portfolioUrls': portfolioUrls,
        'priceRanges': priceRanges.map((p) => p.toMap()).toList(),
        'availableNow': availableNow,
        'urgentAvailable': urgentAvailable,
        'urgentSurchargePct': urgentSurchargePct,
        'lat': lat,
        'lng': lng,
        'featuredUntil':
            featuredUntil != null ? Timestamp.fromDate(featuredUntil!) : null,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
