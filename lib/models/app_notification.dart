import 'package:cloud_firestore/cloud_firestore.dart';

/// Push/in-app notification (notifications/{notifId}).
class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // booking | message | review | reward | system
  final Map<String, dynamic> data;
  final bool read;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.type = 'system',
    this.data = const {},
    this.read = false,
    required this.createdAt,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> m) =>
      AppNotification(
        id: id,
        userId: m['userId'] as String? ?? '',
        title: m['title'] as String? ?? '',
        body: m['body'] as String? ?? '',
        type: m['type'] as String? ?? 'system',
        data: Map<String, dynamic>.from(m['data'] ?? const {}),
        read: m['read'] as bool? ?? false,
        createdAt:
            (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'data': data,
        'read': read,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
