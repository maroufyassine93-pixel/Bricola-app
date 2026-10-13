import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_config.dart';
import '../core/theme.dart';
import '../l10n/strings_ar.dart';
import '../models/booking.dart';
import '../models/category.dart';
import '../models/craftsman.dart';
import '../services/firestore_service.dart';

/// Admin panel — locked to ONE phone number (+213675404636):
/// 1. entry button is hidden unless the signed-in email/phone == admin's
/// 2. this screen re-checks the phone on open (route guard)
/// 3. a PIN (stored in the admin-only config/admin doc) gates the panel
/// 4. Firestore rules enforce the same phone check on the server.
/// Nobody else can ever become admin — not via the app, not via console.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

enum _Gate { loading, denied, networkError, pinCreate, pinEntry, unlocked }

class _AdminScreenState extends State<AdminScreen> {
  _Gate _gate = _Gate.loading;
  String? _gateError;
  String? _pinError;
  bool _busy = false;
  final _pinCtrl = TextEditingController();
  final _pinConfirmCtrl = TextEditingController();

  static final Map<String, String> _tradeLabels = {
    for (final g in Categories.groups)
      for (final t in g.trades) t.id: t.ar,
  };

  static const _bookingLabels = {
    Booking.pending: 'قيد الانتظار',
    Booking.accepted: 'مقبول',
    Booking.inProgress: 'قيد التنفيذ',
    Booking.completed: 'مكتمل',
    Booking.cancelled: 'ملغي',
    Booking.noShow: 'تخلّف الحرفي',
  };

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    _pinConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkAccess() async {
    // Admin = the admin email OR phone ONLY. Nobody else, ever.
    final user = AppConfig.firebaseReady
        ? FirebaseAuth.instance.currentUser
        : null;
    if (!AppConfig.isAdminIdentity(
        email: user?.email, phone: user?.phoneNumber)) {
      setState(() => _Gate.denied);
      return;
    }
    try {
      final hasPin =
          await context.read<FirestoreService>().hasAdminPin();
      if (mounted) {
        setState(
            () => _gate = hasPin ? _Gate.pinEntry : _Gate.pinCreate);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final code = e is FirebaseException ? e.code : '';
          _gate = (code == 'unavailable' ||
                  code == 'deadline-exceeded' ||
                  code == 'network-request-failed')
              ? _Gate.networkError
              : _Gate.denied;
          _gateError = '$e';
        });
      }
    }
  }

  void _retryAccess() {
    setState(() {
      _gate = _Gate.loading;
      _gateError = null;
    });
    _checkAccess();
  }

  Future<void> _submitPin() async {
    final fs = context.read<FirestoreService>();
    final ok = await fs.verifyAdminPin(_pinCtrl.text);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _gate = _Gate.unlocked;
        _pinError = null;
        _pinCtrl.clear();
      });
    } else {
      setState(() => _pinError = S.pinWrong);
    }
  }

  Future<void> _createPin() async {
    final pin = _pinCtrl.text.trim();
    final confirm = _pinConfirmCtrl.text.trim();
    if (pin.length < 4) {
      setState(() => _pinError = S.pinTooShort);
      return;
    }
    if (pin != confirm) {
      setState(() => _pinError = S.pinMismatch);
      return;
    }
    setState(() {
      _busy = true;
      _pinError = null;
    });
    try {
      await context.read<FirestoreService>().setAdminPin(pin);
      if (!mounted) return;
      setState(() {
        _gate = _Gate.unlocked;
        _busy = false;
        _pinCtrl.clear();
        _pinConfirmCtrl.clear();
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(S.pinSet)));
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _pinError = '$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(S.adminPanel)),
      body: switch (_gate) {
        _Gate.loading => const Center(child: CircularProgressIndicator()),
        _Gate.denied => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline,
                      size: 64, color: BricolaTheme.muted),
                  const SizedBox(height: 12),
                  const Text(S.notAuthorized,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  if (_gateError != null) ...[
                    const SizedBox(height: 8),
                    Text(_gateError!,
                        style: const TextStyle(
                            color: BricolaTheme.muted, fontSize: 12)),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _retryAccess,
                    child: const Text(S.retry),
                  ),
                ],
              ),
            ),
          ),
        _Gate.networkError => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_outlined,
                      size: 64, color: BricolaTheme.muted),
                  const SizedBox(height: 12),
                  const Text(S.noInternet,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text(S.noInternetHint,
                      style: TextStyle(
                          color: BricolaTheme.muted, fontSize: 14)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _retryAccess,
                    child: const Text(S.retry),
                  ),
                ],
              ),
            ),
          ),
        _Gate.pinCreate => _pinForm(
            title: S.createPinTitle,
            subtitle: S.createPinSubtitle,
            confirmField: true,
            onSubmit: _createPin,
          ),
        _Gate.pinEntry => _pinForm(
            title: S.pinTitle,
            subtitle: S.pinSubtitle,
            confirmField: false,
            onSubmit: _submitPin,
          ),
        _Gate.unlocked => _panel(),
      },
    );
  }

  Widget _pinForm({
    required String title,
    required String subtitle,
    required bool confirmField,
    required Future<void> Function() onSubmit,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.admin_panel_settings,
                    size: 48, color: BricolaTheme.primary),
                const SizedBox(height: 12),
                Text(title,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(subtitle,
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: BricolaTheme.muted)),
                const SizedBox(height: 16),
                TextField(
                  controller: _pinCtrl,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],
                  decoration:
                      const InputDecoration(labelText: S.pinLabel),
                  onSubmitted: (_) => onSubmit(),
                ),
                if (confirmField) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pinConfirmCtrl,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    decoration: const InputDecoration(
                        labelText: S.pinConfirmLabel),
                    onSubmitted: (_) => onSubmit(),
                  ),
                ],
                if (_pinError != null) ...[
                  const SizedBox(height: 8),
                  Text(_pinError!,
                      style:
                          const TextStyle(color: BricolaTheme.danger)),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _busy ? null : onSubmit,
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2))
                        : const Text(S.confirm),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Panel ──────────────────────────────────────────────────────────
  Widget _panel() {
    return DefaultTabController(
      length: 6,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: S.tabRequests),
              Tab(text: S.tabCraftsmen),
              Tab(text: S.tabBookings),
              Tab(text: S.tabUsers),
              Tab(text: S.tabStats),
              Tab(text: S.tabBroadcast),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _RequestsTab(),
                _CraftsmenTab(),
                _BookingsTab(),
                _UsersTab(),
                _StatsTab(),
                _BroadcastTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _date(DateTime d) => '${d.day}/${d.month}/${d.year}';

  static String _tradesLabel(Craftsman c) => c.trades
      .map((t) => _tradeLabels[t] ?? t)
      .join('، ');
}

// ── 1. Pending requests ──────────────────────────────────────────────
class _RequestsTab extends StatelessWidget {
  const _RequestsTab();

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    return StreamBuilder<List<Craftsman>>(
      stream: fs.pendingCraftsmenStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return const Center(child: Text(S.noPendingRequests));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          itemBuilder: (_, i) => _requestCard(context, fs, list[i]),
        );
      },
    );
  }

  Widget _requestCard(
      BuildContext context, FirestoreService fs, Craftsman c) {
    final v = c.verification;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: BricolaTheme.primary,
                  child: Text(
                    (c.displayName.isEmpty ? '؟' : c.displayName[0]),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.displayName.isEmpty
                            ? '(بدون اسم)'
                            : c.displayName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      Text(
                        '${_AdminScreenState._tradesLabel(c)} • ولاية ${c.wilayaCode}${c.commune.isEmpty ? '' : '، ${c.commune}'}',
                        style: const TextStyle(
                            color: BricolaTheme.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${S.verificationDoc}: ${v == null ? S.noDocUploaded : '${v.fileType == VerificationDoc.pdf ? 'PDF' : 'صورة'} • ${_AdminScreenState._date(v.submittedAt)}'}',
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              'طلب بتاريخ ${_AdminScreenState._date(c.createdAt)}',
              style: const TextStyle(
                  color: BricolaTheme.muted, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text(S.approve),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: BricolaTheme.primary),
                    onPressed: () => _approveDialog(context, fs, c),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close,
                        color: BricolaTheme.danger),
                    label: const Text(S.reject,
                        style:
                            TextStyle(color: BricolaTheme.danger)),
                    onPressed: () => _rejectDialog(context, fs, c),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveDialog(
      BuildContext context, FirestoreService fs, Craftsman c) async {
    var verified = true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text(S.confirmApprove),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.displayName.isEmpty ? '(بدون اسم)' : c.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(S.chamberDocVerified),
                value: verified,
                onChanged: (v) => setS(() => verified = v ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text(S.cancel)),
            ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(S.approve)),
          ],
        ),
      ),
    );
    if (ok == true && context.mounted) {
      await fs.setCraftsmanStatus(c.id, Craftsman.approved,
          chamberVerified: verified);
    }
  }

  Future<void> _rejectDialog(
      BuildContext context, FirestoreService fs, Craftsman c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.confirmReject),
        content: Text(
            c.displayName.isEmpty ? '(بدون اسم)' : c.displayName),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(S.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: BricolaTheme.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(S.reject),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await fs.setCraftsmanStatus(c.id, Craftsman.rejected);
    }
  }
}

// ── 2. Manage craftsmen ──────────────────────────────────────────────
class _CraftsmenTab extends StatelessWidget {
  const _CraftsmenTab();

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    return StreamBuilder<List<Craftsman>>(
      stream: fs.managedCraftsmenStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return const Center(child: Text(S.emptyHere));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final c = list[i];
            final suspended = c.status == Craftsman.suspended;
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: suspended
                      ? BricolaTheme.muted
                      : BricolaTheme.primary,
                  child: Text(
                    (c.displayName.isEmpty ? '؟' : c.displayName[0]),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  c.displayName.isEmpty ? '(بدون اسم)' : c.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                    '${_AdminScreenState._tradesLabel(c)}\n${suspended ? S.statusSuspended : S.statusApproved} • ⭐ ${c.ratingAvg.toStringAsFixed(1)} (${c.ratingCount})'),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'toggle') {
                      _toggleSuspend(context, fs, c, suspended);
                    } else if (v == 'delete') {
                      _deleteDialog(context, fs, c);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(suspended ? S.reactivate : S.suspend),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(S.delete,
                          style:
                              TextStyle(color: BricolaTheme.danger)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _toggleSuspend(BuildContext context, FirestoreService fs,
      Craftsman c, bool suspended) async {
    final ok = suspended
        ? true
        : await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text(S.confirmSuspend),
              content: Text(c.displayName.isEmpty
                  ? '(بدون اسم)'
                  : c.displayName),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text(S.cancel)),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: BricolaTheme.danger),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text(S.suspend),
                ),
              ],
            ),
          );
    if (ok == true && context.mounted) {
      await fs.setCraftsmanStatus(
          c.id, suspended ? Craftsman.approved : Craftsman.suspended);
    }
  }

  Future<void> _deleteDialog(
      BuildContext context, FirestoreService fs, Craftsman c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.confirmDeleteCraftsman),
        content: Text(
            c.displayName.isEmpty ? '(بدون اسم)' : c.displayName),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(S.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: BricolaTheme.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(S.delete),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await fs.deleteCraftsman(c.id);
    }
  }
}

// ── 3. All bookings ──────────────────────────────────────────────────
class _BookingsTab extends StatefulWidget {
  const _BookingsTab();

  @override
  State<_BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<_BookingsTab> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    const filters = [
      'all',
      Booking.pending,
      Booking.accepted,
      Booking.inProgress,
      Booking.completed,
      Booking.cancelled,
    ];
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: filters.map((f) {
              final selected = _filter == f;
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: ChoiceChip(
                  label: Text(f == 'all'
                      ? S.allFilter
                      : _AdminScreenState._bookingLabels[f] ?? f),
                  selected: selected,
                  onSelected: (_) => setState(() => _filter = f),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Booking>>(
            stream: fs.allBookingsStream(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator());
              }
              var list = snap.data ?? [];
              if (_filter != 'all') {
                list = list.where((b) => b.status == _filter).toList();
              }
              if (list.isEmpty) {
                return const Center(child: Text(S.emptyHere));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final b = list[i];
                  return Card(
                    child: ListTile(
                      title: Text(b.serviceLabel,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700)),
                      subtitle: Text(
                          '${_AdminScreenState._bookingLabels[b.status] ?? b.status}\n${_AdminScreenState._date(b.createdAt)}'),
                      isThreeLine: true,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── 4. Users (view-only — admin is the admin phone, nobody else) ──
class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    final me = AppConfig.firebaseReady
        ? FirebaseAuth.instance.currentUser
        : null;
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: fs.allUsersStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return const Center(child: Text(S.emptyHere));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final u = list[i];
            final uid = u['uid'] as String? ?? '';
            final name = (u['displayName'] as String?) ?? '';
            final phone = (u['phone'] as String?) ?? '';
            final email = (u['email'] as String?) ?? '';
            final isAdmin = AppConfig.isAdminIdentity(
                email: email, phone: phone);
            final isMe = uid.isNotEmpty &&
                me != null &&
                (uid == me.uid);
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isAdmin
                      ? BricolaTheme.accent
                      : BricolaTheme.muted,
                  child: Icon(
                      isAdmin
                          ? Icons.admin_panel_settings
                          : Icons.person,
                      color: Colors.white),
                ),
                title: Text(
                  name.isEmpty
                      ? (phone.isNotEmpty
                          ? phone
                          : (email.isNotEmpty ? email : uid))
                      : name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                    '${phone.isNotEmpty ? '$phone ' : email.isNotEmpty ? '$email ' : ''}${isAdmin ? '• ${S.roleAdmin}' : ''}${isMe ? ' • (أنت)' : ''}'
                        .trim()),
              ),
            );
          },
        );
      },
    );
  }
}

// ── 5. Stats ─────────────────────────────────────────────────────────
class _StatsTab extends StatelessWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    return FutureBuilder<List<int>>(
      future: Future.wait([
        fs.countCollection('craftsmen',
            field: 'status', isEqualTo: Craftsman.approved),
        fs.countCollection('craftsmen',
            field: 'status', isEqualTo: Craftsman.pending),
        fs.countCollection('bookings'),
        fs.countCollection('users'),
      ]),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final v = snap.data ?? [0, 0, 0, 0];
        final cards = [
          (S.statCraftsmen, v[0], Icons.handyman, BricolaTheme.primary),
          (S.statPending, v[1], Icons.pending_actions,
              BricolaTheme.accent),
          (S.statBookings, v[2], Icons.calendar_month,
              const Color(0xFF2563EB)),
          (S.statUsers, v[3], Icons.people,
              const Color(0xFF7C3AED)),
        ];
        return GridView.count(
          crossAxisCount: 2,
          padding: const EdgeInsets.all(16),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: cards.map((c) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(c.$3, size: 36, color: c.$4),
                    const SizedBox(height: 8),
                    Text('${c.$2}',
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w800)),
                    Text(c.$1,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: BricolaTheme.muted, fontSize: 13)),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ── 6. Broadcast ─────────────────────────────────────────────────────
class _BroadcastTab extends StatefulWidget {
  const _BroadcastTab();

  @override
  State<_BroadcastTab> createState() => _BroadcastTabState();
}

class _BroadcastTabState extends State<_BroadcastTab> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.confirmBroadcast),
        content: Text('$title\n$body'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(S.cancel)),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(S.sendBroadcast)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final n = await context
          .read<FirestoreService>()
          .sendBroadcastNotification(title: title, body: body);
      if (!mounted) return;
      setState(() => _busy = false);
      _titleCtrl.clear();
      _bodyCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${S.broadcastDone} ($n)')));
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
                labelText: S.broadcastTitleLabel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyCtrl,
            maxLines: 4,
            decoration:
                const InputDecoration(labelText: S.broadcastBodyLabel),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: Text(_busy ? '…' : S.sendBroadcast),
              onPressed: _busy ? null : _send,
            ),
          ),
        ],
      ),
    );
  }
}
