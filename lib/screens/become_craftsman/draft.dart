import 'package:flutter/material.dart';

import '../../l10n/strings_ar.dart';

/// Shared draft for the multi-step "سجّل كحرفي" flow.
class CraftsmanDraft {
  String fullName = '';
  List<String> trades = [];
  int? wilayaCode;
  String commune = '';
  List<String> skills = [];
  String? verificationFilePath; // local path (photo or pdf)
  String? verificationFileType; // 'photo' | 'pdf'
  List<String> portfolioPaths = []; // local paths
  String contactPhone = ''; // optional: revealed to customer after booking

  bool get step1Done => fullName.trim().isNotEmpty;
  bool get step2Done =>
      trades.isNotEmpty && wilayaCode != null;

  /// Step 3 is fully optional now — verification doc and portfolio
  /// photos can be added later; the admin reviews anyway.
  bool get step3Done => true;
}

/// Flow holder — the draft survives across the 4 step screens.
class BecomeFlow {
  static CraftsmanDraft draft = CraftsmanDraft();
  static void reset() => draft = CraftsmanDraft();
}

/// Step indicator header shared by steps 1–4.
class BecomeStepsHeader extends StatelessWidget {
  final int current; // 1..4

  const BecomeStepsHeader({super.key, required this.current});

  static const _labels = [
    S.bcStep1,
    S.bcStep2,
    S.bcStep3,
    S.bcStep4,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(4, (i) {
          final n = i + 1;
          final active = n <= current;
          return Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: active
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                  child: Text('$n',
                      style: TextStyle(
                          color: active
                              ? Colors.white
                              : Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 4),
                if (n == current)
                  Expanded(
                    child: Text(_labels[i],
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                if (n < 4)
                  Expanded(
                      child: Container(
                          height: 2,
                          color: active
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade300)),
              ],
            ),
          );
        }),
      ),
    );
  }
}
