import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme.dart';
import '../../l10n/strings_ar.dart';
import '../../models/craftsman.dart';
import 'draft.dart';

/// Step 3 — chamber card / certificate (photo via camera OR PDF file)
/// + portfolio photos (min 3).
class BecomeStep3Documents extends StatefulWidget {
  const BecomeStep3Documents({super.key});

  @override
  State<BecomeStep3Documents> createState() =>
      _BecomeStep3DocumentsState();
}

class _BecomeStep3DocumentsState
    extends State<BecomeStep3Documents> {
  /// Offer both upload methods in one sheet.
  Future<void> _pickVerification() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(S.chooseUploadType,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt,
                  color: BricolaTheme.primary),
              title: const Text(S.uploadPhoto),
              onTap: () =>
                  Navigator.of(ctx).pop('photo'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf,
                  color: BricolaTheme.danger),
              title: const Text(S.uploadPdf),
              onTap: () => Navigator.of(ctx).pop('pdf'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null) return;
    final draft = BecomeFlow.draft;
    if (choice == 'photo') {
      final picked = await ImagePicker()
          .pickImage(source: ImageSource.camera, imageQuality: 80);
      if (picked != null) {
        setState(() {
          draft.verificationFilePath = picked.path;
          draft.verificationFileType = VerificationDoc.photo;
        });
      }
    } else {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      final path = result?.files.single.path;
      if (path != null) {
        setState(() {
          draft.verificationFilePath = path;
          draft.verificationFileType = VerificationDoc.pdf;
        });
      }
    }
  }

  Future<void> _pickPortfolio() async {
    final picked = await ImagePicker()
        .pickMultiImage(imageQuality: 70);
    if (picked.isNotEmpty) {
      setState(() {
        BecomeFlow.draft.portfolioPaths =
            picked.map((p) => p.path).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = BecomeFlow.draft;
    final hasVerification = draft.verificationFilePath != null;
    return Scaffold(
      appBar: AppBar(title: const Text(S.becomeCraftsman)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const BecomeStepsHeader(current: 3),
          const Text('وثيقة التحقق (اختياري)',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('بطاقة حرفي أو شهادة — تُسرّع قبول ملفك',
              style: TextStyle(
                  color: BricolaTheme.muted, fontSize: 13)),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickVerification,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(
                    color: hasVerification
                        ? Colors.green
                        : BricolaTheme.primary,
                    width: 1.5),
                borderRadius: BorderRadius.circular(14),
                color: hasVerification
                    ? Colors.green.shade50
                    : Colors.white,
              ),
              child: Center(
                child: hasVerification
                    ? Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            draft.verificationFileType ==
                                    VerificationDoc.pdf
                                ? Icons.picture_as_pdf
                                : Icons.check_circle,
                            color: Colors.green,
                            size: 32,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            draft.verificationFileType ==
                                    VerificationDoc.pdf
                                ? 'PDF ✓'
                                : 'صورة ✓',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      )
                    : const Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_file,
                              size: 36,
                              color: BricolaTheme.primary),
                          SizedBox(height: 4),
                          Text(S.chooseUploadType),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${S.uploadPortfolio} (اختياري — ${draft.portfolioPaths.length})',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...draft.portfolioPaths.map((p) => ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(File(p),
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover),
                  )),
              InkWell(
                onTap: _pickPortfolio,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: BricolaTheme.primary),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_a_photo,
                      color: BricolaTheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            // Step 3 is fully optional — just continue.
            onPressed: () {
              Navigator.of(context)
                  .pushNamed('/become/step4');
            },
            child: const Text(S.next),
          ),
        ],
      ),
    );
  }
}
