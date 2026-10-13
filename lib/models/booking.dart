import 'package:cloud_firestore/cloud_firestore.dart';

/// Booking lifecycle:
/// pending → accepted → inProgress → completed (→ paidConfirmed)
/// pending/accepted → cancelled | noShow (triggers ضمان بريكولا)
class Booking {
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String inProgress = 'inProgress';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
  static const String noShow = 'noShow';

  final String id;
  final String customerId;
  final String craftsmanId;
  final String tradeId;
  final String serviceLabel;
  final String description;
  final List<String> photoUrls;
  final DateTime? preferredTime;
  final bool urgent;
  final String status;
  final int? priceAgreedDzd;
  final bool paidConfirmed; // "تم الدفع" — cash on completion
  final bool contactRevealed; // phone unmasked after accept
  final String? contactPhone; // written by backend on reveal (never client)
  final DateTime createdAt;
  final DateTime updatedAt;

  const Booking({
    required this.id,
    required this.customerId,
    required this.craftsmanId,
    required this.tradeId,
    required this.serviceLabel,
    this.description = '',
    this.photoUrls = const [],
    this.preferredTime,
    this.urgent = false,
    this.status = pending,
    this.priceAgreedDzd,
    this.paidConfirmed = false,
    this.contactRevealed = false,
    this.contactPhone,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive =>
      status == pending || status == accepted || status == inProgress;

  factory Booking.fromMap(String id, Map<String, dynamic> m) => Booking(
        id: id,
        customerId: m['customerId'] as String? ?? '',
        craftsmanId: m['craftsmanId'] as String? ?? '',
        tradeId: m['tradeId'] as String? ?? '',
        serviceLabel: m['serviceLabel'] as String? ?? '',
        description: m['description'] as String? ?? '',
        photoUrls: List<String>.from(m['photoUrls'] ?? const []),
        preferredTime: (m['preferredTime'] as Timestamp?)?.toDate(),
        urgent: m['urgent'] as bool? ?? false,
        status: m['status'] as String? ?? pending,
        priceAgreedDzd: (m['priceAgreedDzd'] as num?)?.toInt(),
        paidConfirmed: m['paidConfirmed'] as bool? ?? false,
        contactRevealed: m['contactRevealed'] as bool? ?? false,
        contactPhone: m['contactPhone'] as String?,
        createdAt:
            (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt:
            (m['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'customerId': customerId,
        'craftsmanId': craftsmanId,
        'tradeId': tradeId,
        'serviceLabel': serviceLabel,
        'description': description,
        'photoUrls': photoUrls,
        'preferredTime': preferredTime != null
            ? Timestamp.fromDate(preferredTime!)
            : null,
        'urgent': urgent,
        'status': status,
        'priceAgreedDzd': priceAgreedDzd,
        'paidConfirmed': paidConfirmed,
        'contactRevealed': contactRevealed,
        'contactPhone': contactPhone,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}
