import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../l10n/strings_ar.dart';
import '../models/category.dart';
import '../models/craftsman.dart';
import 'rating_stars.dart';
import 'verified_badge.dart';

/// Craftsman card used in list screens: photo, name, verification state,
/// rating, trades, wilaya, availability.
class CraftsmanCard extends StatelessWidget {
  final Craftsman craftsman;
  final VoidCallback onTap;

  const CraftsmanCard({
    super.key,
    required this.craftsman,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: BricolaTheme.primary.withOpacity(0.12),
                backgroundImage: craftsman.photoUrl != null
                    ? NetworkImage(craftsman.photoUrl!)
                    : null,
                child: craftsman.photoUrl == null
                    ? const Icon(Icons.person,
                        size: 34, color: BricolaTheme.primary)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            craftsman.displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        VerifiedBadge.forCraftsman(craftsman),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        RatingStars(rating: craftsman.ratingAvg, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          '${craftsman.ratingAvg.toStringAsFixed(1)} (${craftsman.ratingCount})',
                          style: const TextStyle(
                              fontSize: 12, color: BricolaTheme.muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      craftsman.trades
                          .map((t) =>
                              Categories.tradeById(t)?.ar ?? t)
                          .take(3)
                          .join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, color: BricolaTheme.muted),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 14, color: BricolaTheme.muted),
                        Text(
                          ' ولاية ${craftsman.wilayaCode}',
                          style: const TextStyle(
                              fontSize: 12, color: BricolaTheme.muted),
                        ),
                        const Spacer(),
                        if (craftsman.availableNow)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              S.availableNow,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
