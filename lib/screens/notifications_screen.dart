import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../l10n/strings_ar.dart';
import '../main.dart';
import '../models/app_notification.dart';
import '../services/firestore_service.dart';

/// Push / in-app notifications.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    return Scaffold(
      appBar: AppBar(title: const Text(S.notifications)),
      body: StreamBuilder<List<AppNotification>>(
        stream: fs.notifications(currentUid()),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(S.noNotifications,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) {
              final n = list[i];
              return Card(
                color: n.read ? null : Colors.green.shade50,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: BricolaTheme.primary
                        .withOpacity(0.12),
                    child: Icon(_iconFor(n.type),
                        color: BricolaTheme.primary),
                  ),
                  title: Text(n.title,
                      style: TextStyle(
                          fontWeight: n.read
                              ? FontWeight.normal
                              : FontWeight.w800)),
                  subtitle: Text(n.body),
                  onTap: () {
                    if (!n.read) {
                      fs.markNotificationRead(n.id);
                    }
                    // TODO: deep-link via n.data['route'].
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'booking':
        return Icons.calendar_month;
      case 'message':
        return Icons.chat_bubble_outline;
      case 'review':
        return Icons.star_outline;
      case 'reward':
        return Icons.card_giftcard;
      default:
        return Icons.notifications;
    }
  }
}
