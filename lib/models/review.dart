import 'package:cloud_firestore/cloud_firestore.dart';

/// A customer review. Business rule: a review can ONLY be submitted with a
/// photo of the completed work (workPhotoUrl is required, non-empty).
class Review {
  final String id;
  final String craftsmanId;
  final String bookingId;
  final String customerId;
  final String customerName;
  final int rating; // 1..5
  final String comment;
  final String workPhotoUrl; // REQUIRED — enforced in UI + Firestore rules
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.craftsmanId,
    required this.bookingId,
    required this.customerId,
    required this.customerName,
    required this.rating,
    this.comment = '',
    required this.workPhotoUrl,
    required this.createdAt,
  });

  bool get hasPhoto => workPhotoUrl.isNotEmpty;

  factory Review.fromMap(String id, Map<String, dynamic> m) => Review(
        id: id,
        craftsmanId: m['craftsmanId'] as String? ?? '',
        bookingId: m['bookingId'] as String? ?? '',
        customerId: m['customerId'] as String? ?? '',
        customerName: m['customerName'] as String? ?? '',
        rating: (m['rating'] as num? ?? 5).toInt().clamp(1, 5),
        comment: m['comment'] as String? ?? '',
        workPhotoUrl: m['workPhotoUrl'] as String? ?? '',
        createdAt:
            (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'craftsmanId': craftsmanId,
        'bookingId': bookingId,
        'customerId': customerId,
        'customerName': customerName,
        'rating': rating,
        'comment': comment,
        'workPhotoUrl': workPhotoUrl,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
