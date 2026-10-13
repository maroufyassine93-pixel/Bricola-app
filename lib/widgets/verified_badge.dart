import 'package:flutter/material.dart';

import '../l10n/strings_ar.dart';
import '../models/craftsman.dart';

/// Verification badge with THREE states:
/// - verified  → green "حرفي موثّق ✓"
/// - pending   → amber "قيد المراجعة ⏳" (verification doc submitted)
/// - unverified→ grey outline "غير موثّق بعد"
class VerifiedBadge extends StatelessWidget {
  final _BadgeState state;
  final bool compact;

  const VerifiedBadge._(this.state, {this.compact = false});

  /// Badge driven by a craftsman: verified > pending > unverified.
  factory VerifiedBadge.forCraftsman(Craftsman c, {bool compact = false}) {
    if (c.chamberVerified) {
      return VerifiedBadge._(_BadgeState.verified, compact: compact);
    }
    final v = c.verification;
    // Pending review → amber badge (file uploaded, not yet approved).
    if (v != null && v.status == VerificationDoc.pending) {
      return VerifiedBadge._(_BadgeState.pending, compact: compact);
    }
    return VerifiedBadge._(_BadgeState.unverified, compact: compact);
  }

  const VerifiedBadge.verified({super.key, this.compact = false})
      : state = _BadgeState.verified;
  const VerifiedBadge.pending({super.key, this.compact = false})
      : state = _BadgeState.pending;
  const VerifiedBadge.unverified({super.key, this.compact = false})
      : state = _BadgeState.unverified;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    late final String label;
    late final IconData icon;
    switch (state) {
      case _BadgeState.verified:
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        label = S.verifiedCraftsman;
        icon = Icons.verified;
        break;
      case _BadgeState.pending:
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        label = S.pendingReview;
        icon = Icons.hourglass_top;
        break;
      case _BadgeState.unverified:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
        label = S.notVerifiedYet;
        icon = Icons.help_outline;
        break;
    }
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 10, vertical: compact ? 2 : 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 15, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

enum _BadgeState { verified, pending, unverified }
