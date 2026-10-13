import 'package:cloud_firestore/cloud_firestore.dart';

/// A single chat message. Types: text | voice | image.
/// Voice messages are a first-class citizen (many craftsmen prefer voice).
class ChatMessage {
  static const String text = 'text';
  static const String voice = 'voice';
  static const String image = 'image';

  final String id;
  final String senderId;
  final String type;
  final String textContent;
  final String? mediaUrl; // voice .m4a or image
  final int durationSec; // voice length
  final DateTime createdAt;
  final List<String> readBy;

  const ChatMessage({
    required this.id,
    required this.senderId,
    this.type = text,
    this.textContent = '',
    this.mediaUrl,
    this.durationSec = 0,
    required this.createdAt,
    this.readBy = const [],
  });

  bool get isVoice => type == voice;
  bool get isImage => type == image;

  factory ChatMessage.fromMap(String id, Map<String, dynamic> m) =>
      ChatMessage(
        id: id,
        senderId: m['senderId'] as String? ?? '',
        type: m['type'] as String? ?? text,
        textContent: m['text'] as String? ?? '',
        mediaUrl: m['mediaUrl'] as String?,
        durationSec: (m['durationSec'] as num? ?? 0).toInt(),
        createdAt:
            (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        readBy: List<String>.from(m['readBy'] ?? const []),
      );

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'type': type,
        'text': textContent,
        'mediaUrl': mediaUrl,
        'durationSec': durationSec,
        'createdAt': Timestamp.fromDate(createdAt),
        'readBy': readBy,
      };
}

/// Chat thread header (chats/{chatId}).
class ChatThread {
  final String id;
  final List<String> participants;
  final String? bookingId;
  final String otherName;
  final String? otherPhotoUrl;
  final String lastMessage;
  final DateTime lastMessageAt;

  const ChatThread({
    required this.id,
    required this.participants,
    this.bookingId,
    required this.otherName,
    this.otherPhotoUrl,
    this.lastMessage = '',
    required this.lastMessageAt,
  });

  factory ChatThread.fromMap(String id, Map<String, dynamic> m) =>
      ChatThread(
        id: id,
        participants: List<String>.from(m['participants'] ?? const []),
        bookingId: m['bookingId'] as String?,
        otherName: m['otherName'] as String? ?? '',
        otherPhotoUrl: m['otherPhotoUrl'] as String?,
        lastMessage: m['lastMessage'] as String? ?? '',
        lastMessageAt:
            (m['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}
