import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../l10n/strings_ar.dart';
import '../main.dart';
import '../models/chat_message.dart';
import '../services/firestore_service.dart';

/// List of chat threads for the current user.
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    final uid = currentUid();
    return Scaffold(
      appBar: AppBar(title: const Text(S.chats)),
      body: StreamBuilder<List<ChatThread>>(
        stream: fs.chatThreads(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final threads = snap.data ?? [];
          if (threads.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(S.noChats,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text(S.noChatsSub,
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: BricolaTheme.muted)),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: threads.length,
            itemBuilder: (_, i) {
              final t = threads[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: BricolaTheme.primary
                        .withOpacity(0.12),
                    backgroundImage:
                        t.otherPhotoUrl != null
                            ? NetworkImage(t.otherPhotoUrl!)
                            : null,
                    child: t.otherPhotoUrl == null
                        ? const Icon(Icons.person,
                            color: BricolaTheme.primary)
                        : null,
                  ),
                  title: Text(t.otherName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    t.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () =>
                      Navigator.of(context).pushNamed(
                    '/chat',
                    arguments: {
                      'chatId': t.id,
                      'otherName': t.otherName,
                      'bookingId': t.bookingId,
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
