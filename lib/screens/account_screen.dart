import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_config.dart';
import '../core/theme.dart';
import '../l10n/strings_ar.dart';
import '../main.dart';
import '../models/booking.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

/// Account: profile, my bookings (with "تم الدفع"), become-craftsman entry,
/// legal (law 18-07), logout.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  static const _statusLabels = {
    Booking.pending: S.bookingPending,
    Booking.accepted: S.bookingAccepted,
    Booking.inProgress: 'قيد التنفيذ',
    Booking.completed: S.bookingCompleted,
    Booking.cancelled: S.bookingCancelled,
    Booking.noShow: 'تخلّف الحرفي',
  };

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    final uid = currentUid();
    final user = AppConfig.firebaseReady
        ? FirebaseAuth.instance.currentUser
        : null;
    final phone = user?.phoneNumber ?? '';
    final email = user?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text(S.account)),
      body: ListView(
        children: [
          StreamBuilder<Map<String, dynamic>?>(
            stream: fs.userStream(uid),
            builder: (context, snap) {
              final data = snap.data;
              final name =
                  (data?['displayName'] as String?) ?? '';
              final role =
                  (data?['role'] as String?) ?? 'customer';
              // Admin = the admin email OR phone ONLY. Nobody else.
              final isAdmin = AppConfig.isAdminIdentity(
                  email: email, phone: phone);
              return Column(
                children: [
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: BricolaTheme.primary,
                        child: Icon(Icons.person,
                            color: Colors.white),
                      ),
                      title: Text(
                          name.isEmpty
                              ? (phone.isNotEmpty ? phone : email)
                              : name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800)),
                      subtitle: Text(
                          '${phone.isNotEmpty ? phone : email}\n${isAdmin ? S.roleAdmin : role == 'craftsman' ? S.becomeCraftsman : S.roleCustomer}'),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () =>
                            _editName(context, fs, uid, name),
                        tooltip: S.editProfile,
                      ),
                    ),
                  ),
                  // Admin entry — visible ONLY to admins.
                  if (isAdmin)
                    Card(
                      color: BricolaTheme.primary.withOpacity(0.08),
                      child: ListTile(
                        leading: const Icon(
                            Icons.admin_panel_settings,
                            color: BricolaTheme.primary),
                        title: const Text(S.adminPanel,
                            style: TextStyle(
                                fontWeight: FontWeight.w700)),
                        subtitle: const Text(S.adminOnly),
                        trailing: const Icon(Icons.arrow_back_ios,
                            size: 16),
                        onTap: () => Navigator.of(context)
                            .pushNamed('/admin'),
                      ),
                    ),
                ],
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(S.myBookings,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          _bookingsList(context, fs, uid),
          // Received bookings — visible only to approved craftsmen,
          // with accept (reveals phone) / decline actions.
          if (role == 'craftsman' &&
              (data?['craftsmanId'] as String?)?.isNotEmpty == true)
            _receivedBookings(
                context, fs, data!['craftsmanId'] as String),
          Card(
            child: ListTile(
              leading: const Icon(Icons.handyman,
                  color: BricolaTheme.primary),
              title: const Text(S.becomeCraftsman,
                  style:
                      TextStyle(fontWeight: FontWeight.w700)),
              subtitle:
                  const Text('اعرض خدماتك لآلاف الزبائن'),
              trailing:
                  const Icon(Icons.arrow_back_ios, size: 16),
              onTap: () =>
                  Navigator.of(context).pushNamed('/become/step1'),
            ),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text(S.about),
                  onTap: () => _infoDialog(
                      context, S.about, S.appDescription),
                ),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text(S.terms),
                  onTap: () => _infoDialog(context, S.terms,
                      '${S.guaranteeBody}\n\n${S.cashPaymentNote}'),
                ),
                ListTile(
                  leading:
                      const Icon(Icons.privacy_tip_outlined),
                  title: const Text(S.privacy),
                  onTap: () => _infoDialog(
                      context, S.privacy, S.legalNotice),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () async {
                await context
                    .read<AuthService>()
                    .signOut();
                if (context.mounted) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(
                          '/login', (_) => false);
                }
              },
              icon: const Icon(Icons.logout,
                  color: BricolaTheme.danger),
              label: const Text(S.logout,
                  style:
                      TextStyle(color: BricolaTheme.danger)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bookingsList(
      BuildContext context, FirestoreService fs, String uid) {
    return StreamBuilder<List<Booking>>(
      stream: fs.bookingsForUser(uid, 'customer'),
      builder: (context, snap) {
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(S.emptyHere,
                style: TextStyle(color: BricolaTheme.muted)),
          );
        }
        return Column(
          children: list.map((b) {
            final canPay =
                b.status == Booking.completed && !b.paidConfirmed;
            return Card(
              child: ListTile(
                title: Text(b.serviceLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700)),
                subtitle: Text(
                    _statusLabels[b.status] ?? b.status),
                trailing: canPay
                    ? ElevatedButton(
                        onPressed: () =>
                            fs.confirmPayment(b.id),
                        child:
                            const Text(S.confirmPayment),
                      )
                    : (b.status == Booking.completed
                        ? TextButton(
                            onPressed: () =>
                                Navigator.of(context)
                                    .pushNamed('/craftsman',
                                        arguments:
                                            b.craftsmanId),
                            child: Text(S.rateService),
                          )
                        : null),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// Bookings received by the craftsman — accept reveals their phone
  /// to the customer (rules enforce it equals their own phonePrivate).
  Widget _receivedBookings(
      BuildContext context, FirestoreService fs, String craftsmanId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text('الحجوزات المستلمة',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ),
        StreamBuilder<List<Booking>>(
          stream: fs.bookingsForUser(craftsmanId, 'craftsman'),
          builder: (context, snap) {
            if (snap.hasError) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('تعذّر تحميل الحجوزات',
                    style: TextStyle(color: BricolaTheme.muted)),
              );
            }
            final list = snap.data ?? [];
            if (list.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('لا توجد حجوزات بعد',
                    style: TextStyle(color: BricolaTheme.muted)),
              );
            }
            return Column(
              children: list.map((b) {
                final pending = b.status == Booking.pending;
                return Card(
                  child: ListTile(
                    title: Text(b.serviceLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700)),
                    subtitle: Text(
                        '${_statusLabels[b.status] ?? b.status}\n${b.description}'),
                    isThreeLine: true,
                    trailing: pending
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check_circle,
                                    color: Colors.green),
                                tooltip: 'قبول وكشف الهاتف',
                                onPressed: () =>
                                    fs.acceptBooking(b.id),
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel,
                                    color: BricolaTheme.danger),
                                tooltip: 'رفض',
                                onPressed: () =>
                                    fs.declineBooking(b.id),
                              ),
                            ],
                          )
                        : null,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Future<void> _editName(BuildContext context,
      FirestoreService fs, String uid, String current) async {
    final ctrl = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.editProfile),
        content: TextField(
          controller: ctrl,
          decoration:
              const InputDecoration(labelText: S.fullName),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(S.cancel)),
          ElevatedButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(ctrl.text.trim()),
              child: const Text(S.save)),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await fs.updateDisplayName(uid, name);
    }
  }

  void _infoDialog(
      BuildContext context, String title, String body) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body, style: const TextStyle(height: 1.7)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(S.confirm),
          ),
        ],
      ),
    );
  }
}
