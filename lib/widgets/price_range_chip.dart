import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../l10n/strings_ar.dart';
import '../models/category.dart';
import '../models/craftsman.dart';

/// "3000–5000 دج" indicative price chip for a trade.
class PriceRangeChip extends StatelessWidget {
  final PriceRange range;
  final String? tradeLabel;

  const PriceRangeChip({super.key, required this.range, this.tradeLabel});

  @override
  Widget build(BuildContext context) {
    final trade = Categories.tradeById(range.tradeId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: BricolaTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: BricolaTheme.primary.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tradeLabel ?? trade?.ar ?? range.tradeId,
            style: const TextStyle(
                fontSize: 12, color: BricolaTheme.muted),
          ),
          Text(
            '${range.label} ${S.dzd}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: BricolaTheme.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
