import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/wilayas.dart';
import '../../l10n/strings_ar.dart';
import '../../main.dart';
import '../../models/category.dart';
import '../../models/craftsman.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import 'draft.dart';

/// Step 4 — review, skills, indicative prices → submit application.
class BecomeStep4Review extends StatefulWidget {
  const BecomeStep4Review({super.key});

  @override
  State<BecomeStep4Review> createState() =>
      _BecomeStep4ReviewState();
}

class _BecomeStep4ReviewState
    extends State<BecomeStep4Review> {
  final _skillCtrl = TextEditingController();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final draft = BecomeFlow.draft;
    return Scaffold(
      appBar: AppBar(title: const Text(S.becomeCraftsman)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const BecomeStepsHeader(current: 4),
          _summaryCard(draft),
          const SizedBox(height: 16),
          _skillsEditor(draft),
          const SizedBox(height: 16),
          // Price is by mutual agreement — no indicative prices collected.
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.handshake_outlined,
                      color: BricolaTheme.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'السعر بالتراضي بينك وبين الزبون',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed:
                _saving ? null : () => _submit(draft),
            child: _saving
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2))
                : const Text(S.submitApplication),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(CraftsmanDraft draft) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(draft.fullName,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              draft.trades
                  .map((t) =>
                      Categories.tradeById(t)?.ar ?? t)
                  .join(' • '),
              style:
                  const TextStyle(color: BricolaTheme.muted),
            ),
            const SizedBox(height: 4),
            Text(
              '${wilayaName(draft.wilayaCode ?? 0)}${draft.commune.isNotEmpty ? ' — ${draft.commune}' : ''}',
              style:
                  const TextStyle(color: BricolaTheme.muted),
            ),
            const SizedBox(height: 4),
            Text(
              draft.verificationFilePath == null
                  ? 'وثيقة التحقق: لم تُرفق (اختياري)'
                  : draft.verificationFileType ==
                          VerificationDoc.pdf
                      ? 'وثيقة التحقق: ملف PDF ✓'
                      : 'وثيقة التحقق: صورة ✓',
              style: TextStyle(
                  color: draft.verificationFilePath == null
                      ? BricolaTheme.muted
                      : Colors.green,
                  fontWeight: FontWeight.w700),
            ),
            Text(
              'صور الأعمال: ${draft.portfolioPaths.length}',
              style:
                  const TextStyle(color: BricolaTheme.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skillsEditor(CraftsmanDraft draft) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(S.skills,
            style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: draft.skills
              .map((s) => Chip(
                    label: Text(s),
                    onDeleted: () =>
                        setState(() => draft.skills.remove(s)),
                  ))
              .toList(),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _skillCtrl,
                decoration: const InputDecoration(
                    hintText: 'مثال: تركيب مكيفات سبليت'),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle,
                  color: BricolaTheme.primary, size: 32),
              onPressed: () {
                final v = _skillCtrl.text.trim();
                if (v.isNotEmpty) {
                  setState(() {
                    draft.skills.add(v);
                    _skillCtrl.clear();
                  });
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _submit(CraftsmanDraft draft) async {
    setState(() => _saving = true);
    try {
      final uid = currentUid();
      final storage = context.read<StorageService>();
      final fs = context.read<FirestoreService>();

      // 1. Verification file → craftsmen/{uid}/verification/
      // (optional — skipped when the user didn't attach one)
      VerificationDoc? verification;
      if (draft.verificationFilePath != null) {
        final verificationUrl =
            await storage.uploadVerificationFile(
          uid: uid,
          file: File(draft.verificationFilePath!),
          fileType:
              draft.verificationFileType ?? VerificationDoc.photo,
        );
        verification = VerificationDoc(
          fileUrl: verificationUrl,
          fileType:
              draft.verificationFileType ?? VerificationDoc.photo,
          status: VerificationDoc.pending,
          submittedAt: DateTime.now(),
        );
      }

      // 2. Portfolio photos → craftsmen/{uid}/portfolio/
      // (empty URLs = Storage unavailable; filtered out, added later)
      final portfolioUrls = <String>[];
      for (var i = 0; i < draft.portfolioPaths.length; i++) {
        final url = await storage.uploadPortfolioPhoto(
          uid: uid,
          file: File(draft.portfolioPaths[i]),
          name: 'work_$i',
        );
        if (url.isNotEmpty) portfolioUrls.add(url);
      }

      // 2b. Optional contact phone → users/{uid}.phonePrivate so the
      // existing reveal-after-booking flow keeps working.
      if (draft.contactPhone.isNotEmpty) {
        await fs.ensureUserDoc(
          uid: uid,
          phone: draft.contactPhone,
        );
      }

      // 3. Create the craftsman doc in `pending` status.
      // Price is by mutual agreement — no indicative prices collected.
      await fs.submitCraftsmanApplication(
        uid: uid,
        displayName: draft.fullName,
        trades: draft.trades,
        wilayaCode: draft.wilayaCode!,
        commune: draft.commune,
        skills: draft.skills,
        portfolioUrls: portfolioUrls,
        priceRanges: const [],
        verification: verification,
      );

      BecomeFlow.reset();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
            '/become/success', (_) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
