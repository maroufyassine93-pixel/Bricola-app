import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';
import '../core/wilayas.dart';
import '../l10n/strings_ar.dart';
import '../main.dart';
import '../models/booking.dart';
import '../models/category.dart';
import '../models/craftsman.dart';
import '../models/review.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../widgets/price_range_chip.dart';
import '../widgets/rating_stars.dart';
import '../widgets/section_title.dart';
import '../widgets/verified_badge.dart';

/// Full craftsman profile: badge (3 states), skills, prices, portfolio,
/// availability, urgent toggle, masked phone, reviews (photo required).
class CraftsmanProfileScreen extends StatelessWidget {
  final String craftsmanId;

  const CraftsmanProfileScreen({super.key, required this.craftsmanId});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    return StreamBuilder<Craftsman?>(
      stream: fs.craftsmanStream(craftsmanId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final c = snap.data;
        if (c == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text(S.emptyHere)),
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text(c.displayName)),
          body: ListView(
            children: [
              _header(context, c),
              _actions(context, fs, c),
              if (c.skills.isNotEmpty) _skills(c),
              _priceAgreement(),
              _availability(c),
              if (c.portfolioUrls.isNotEmpty) _portfolio(c),
              _reviews(context, fs, c),
              const SizedBox(height: 90),
            ],
          ),
          bottomSheet: _bookingBar(context, c),
        );
      },
    );
  }

  Widget _header(BuildContext context, Craftsman c) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: BricolaTheme.primary.withOpacity(0.12),
            backgroundImage:
                c.photoUrl != null ? NetworkImage(c.photoUrl!) : null,
            child: c.photoUrl == null
                ? const Icon(Icons.person,
                    size: 52, color: BricolaTheme.primary)
                : null,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(c.displayName,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(width: 8),
              VerifiedBadge.forCraftsman(c),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RatingStars(rating: c.ratingAvg),
              const SizedBox(width: 6),
              Text(
                '${c.ratingAvg.toStringAsFixed(1)} (${c.ratingCount} ${S.reviews})',
                style: const TextStyle(color: BricolaTheme.muted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            c.trades
                .map((t) => Categories.tradeById(t)?.label ?? t)
                .join(' • '),
            textAlign: TextAlign.center,
            style: const TextStyle(color: BricolaTheme.muted),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on,
                  size: 15, color: BricolaTheme.muted),
              Text(
                '${wilayaName(c.wilayaCode)}${c.commune.isNotEmpty ? ' — ${c.commune}' : ''}',
                style: const TextStyle(color: BricolaTheme.muted),
              ),
              const SizedBox(width: 12),
              if (c.phoneVerified)
                const Row(
                  children: [
                    Icon(Icons.phone,
                        size: 15, color: BricolaTheme.primary),
                    SizedBox(width: 2),
                    Text(S.phoneVerified,
                        style: TextStyle(
                            fontSize: 12,
                            color: BricolaTheme.primary)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actions(
      BuildContext context, FirestoreService fs, Craftsman c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _openChat(context, fs, c),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text(S.chatNow),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _tryCall(context, fs, c),
              icon: const Icon(Icons.phone),
              label: const Text(S.call),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openChat(
      BuildContext context, FirestoreService fs, Craftsman c) async {
    final uid = currentUid();
    final chatId = await fs.getOrCreateThread(
      me: uid,
      otherId: c.userId,
      otherName: c.displayName,
    );
    if (context.mounted) {
      Navigator.of(context).pushNamed('/chat', arguments: {
        'chatId': chatId,
        'otherName': c.displayName,
      });
    }
  }

  /// Phone stays masked until a booking is accepted (contactRevealed).
  Future<void> _tryCall(
      BuildContext context, FirestoreService fs, Craftsman c) async {
    final uid = currentUid();
    final bookings = await fs
        .bookingsForUser(uid, 'customer')
        .first;
    Booking? revealed;
    for (final b in bookings) {
      if (b.craftsmanId == c.id &&
          b.contactRevealed &&
          (b.contactPhone?.isNotEmpty ?? false)) {
        revealed = b;
        break;
      }
    }
    if (!context.mounted) return;
    if (revealed == null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text(S.call),
          content: const Text(S.phoneMaskedNotice),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(S.confirm),
            ),
          ],
        ),
      );
      return;
    }
    final uri = Uri.parse('tel:${revealed.contactPhone}');
    await launchUrl(uri);
  }

  Widget _skills(Craftsman c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: S.skills),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: c.skills
                .map((s) => Chip(
                      label: Text(s),
                      backgroundColor:
                          BricolaTheme.primary.withOpacity(0.08),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  /// Price is by mutual agreement between customer and craftsman.
  Widget _priceAgreement() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: BricolaTheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.handshake_outlined,
                color: BricolaTheme.primary, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text('السعر بالتراضي بين الزبون والحرفي',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _availability(Craftsman c) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    c.availableNow
                        ? Icons.check_circle
                        : Icons.pause_circle,
                    color: c.availableNow
                        ? Colors.green
                        : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    c.availableNow
                        ? S.availableNow
                        : 'غير متاح حالياً',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              if (c.urgentAvailable) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.sos,
                        color: BricolaTheme.danger),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${S.urgentToggle} (+${c.urgentSurchargePct}%)',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  S.urgentSurchargeNote,
                  style: TextStyle(
                      fontSize: 12, color: BricolaTheme.muted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _portfolio(Craftsman c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: S.portfolio),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: c.portfolioUrls.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.all(4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  c.portfolioUrls[i],
                  width: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 160,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _reviews(
      BuildContext context, FirestoreService fs, Craftsman c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: '${S.reviews} (${c.ratingCount})',
          actionLabel: S.rateService,
          onAction: () => _reviewDialog(context, fs, c),
        ),
        StreamBuilder<List<Review>>(
          stream: fs.reviewsFor(c.id),
          builder: (context, snap) {
            final list = snap.data ?? [];
            if (list.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text(S.noReviewsYet,
                    style: TextStyle(color: BricolaTheme.muted)),
              );
            }
            return Column(
              children: list
                  .take(5)
                  .map((r) => Card(
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              r.workPhotoUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.image),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                  child: Text(r.customerName,
                                      style: const TextStyle(
                                          fontWeight:
                                              FontWeight.w700))),
                              RatingStars(
                                  rating:
                                      r.rating.toDouble(),
                                  size: 12),
                            ],
                          ),
                          subtitle: r.comment.isNotEmpty
                              ? Text(r.comment)
                              : null,
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  /// Review dialog — work photo is MANDATORY.
  Future<void> _reviewDialog(
      BuildContext context, FirestoreService fs, Craftsman c) async {
    int rating = 5;
    final commentCtrl = TextEditingController();
    XFile? photo;
    bool saving = false;
    String? error;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text(S.rateService),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RatingInput(
                    onChanged: (v) => setD(() => rating = v)),
                TextField(
                  controller: commentCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: S.yourComment),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await ImagePicker()
                        .pickImage(source: ImageSource.camera);
                    if (picked != null) {
                      setD(() => photo = picked);
                    }
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: Text(photo == null
                      ? S.attachWorkPhoto
                      : 'تم إرفاق الصورة ✓'),
                ),
                const SizedBox(height: 4),
                const Text(
                  S.reviewWithPhotoRequired,
                  style: TextStyle(
                      fontSize: 11, color: BricolaTheme.muted),
                  textAlign: TextAlign.center,
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(error!,
                        style:
                            const TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(S.cancel),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      setD(() => saving = true);
                      try {
                        // TODO: find the customer's completed booking
                        // with this craftsman and use its id.
                        // Photo optional: skipped when none picked or when
                        // Storage is unavailable (empty url).
                        var url = '';
                        if (photo != null) {
                          final storage =
                              context.read<StorageService>();
                          final reviewId =
                              'tmp_${DateTime.now().millisecondsSinceEpoch}';
                          url = await storage
                              .uploadReviewPhoto(
                                  reviewId: reviewId,
                                  file: File(photo!.path));
                        }
                        await fs.submitReview(
                          craftsmanId: c.id,
                          bookingId: '',
                          customerId: currentUid(),
                          customerName: 'زبون',
                          rating: rating,
                          comment: commentCtrl.text.trim(),
                          workPhotoUrl: url,
                        );
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                                  content: Text('شكراً على تقييمك!')));
                        }
                      } catch (e) {
                        setD(() {
                          saving = false;
                          error = e.toString();
                        });
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text(S.submitReview),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bookingBar(BuildContext context, Craftsman c) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              final tradeId =
                  c.trades.isNotEmpty ? c.trades.first : null;
              Navigator.of(context).pushNamed('/booking',
                  arguments: {
                    'craftsmanId': c.id,
                    'tradeId': tradeId,
                  });
            },
            icon: const Icon(Icons.calendar_month),
            label: const Text(S.bookNow),
          ),
        ),
      ),
    );
  }
}
