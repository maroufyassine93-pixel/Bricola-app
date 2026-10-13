import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/theme.dart';
import '../l10n/strings_ar.dart';
import '../main.dart';
import '../services/referral_service.dart';

/// Rewards: referral code, invite friends → points → free featured placement.
class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final referrals = context.read<ReferralService>();
    final uid = currentUid();
    return Scaffold(
      appBar: AppBar(title: const Text(S.rewards)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [BricolaTheme.primary, BricolaTheme.primaryDark],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              children: [
                Icon(Icons.card_giftcard,
                    size: 48, color: Colors.white),
                SizedBox(height: 8),
                Text(S.rewardsTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 8),
                Text(S.rewardsBody,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white70,
                        height: 1.6)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<String>(
            future: referrals.getOrCreateCode(uid),
            builder: (context, snap) {
              final code = snap.data ?? '…';
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(S.yourCode,
                          style:
                              TextStyle(color: BricolaTheme.muted)),
                      const SizedBox(height: 8),
                      Text(
                        code,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: code));
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                        content:
                                            Text(S.codeCopied)));
                              },
                              icon:
                                  const Icon(Icons.copy),
                              label: const Text(S.copyCode),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Share.share(
                                'حمّل تطبيق بريكولا واستعمل رمز الدعوة $code — حرفيون موثوقون في ولايتك!',
                              ),
                              icon:
                                  const Icon(Icons.share),
                              label:
                                  const Text(S.shareInvite),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        FutureBuilder<int>(
                          future:
                              referrals.pointsBalance(uid),
                          builder: (context, snap) => Text(
                            '${snap.data ?? 0}',
                            style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: BricolaTheme.primary),
                          ),
                        ),
                        const Text(S.myPoints),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        StreamBuilder<int>(
                          stream:
                              referrals.inviteCount(uid),
                          builder: (context, snap) => Text(
                            '${snap.data ?? 0}',
                            style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: BricolaTheme.primary),
                          ),
                        ),
                        const Text(S.inviteHistory),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.star,
                  color: BricolaTheme.accent, size: 36),
              title: Text(
                  '${S.rewardFeatured}\n(${ReferralService.featuredDaysCost} ${S.myPoints})'),
              trailing: ElevatedButton(
                onPressed: () async {
                  final ok = await referrals
                      .redeemFeatured(uid);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(
                            content: Text(ok
                                ? 'تم تفعيل إبراز ملفك لـ 7 أيام 🎉'
                                : S.notEnoughPoints)));
                  }
                },
                child: const Text(S.redeem),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
