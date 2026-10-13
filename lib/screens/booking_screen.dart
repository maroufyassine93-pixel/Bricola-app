import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../l10n/strings_ar.dart';
import '../main.dart';
import '../models/category.dart';
import '../models/craftsman.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

/// Booking request form: service, description, photos, preferred time,
/// urgent flag → confirmation sheet showing ضمان بريكولا.
class BookingScreen extends StatefulWidget {
  final String craftsmanId;
  final String? tradeId;

  const BookingScreen({
    super.key,
    required this.craftsmanId,
    this.tradeId,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _descCtrl = TextEditingController();
  String? _tradeId;
  List<XFile> _photos = [];
  bool _urgent = false;
  int _dayOffset = 0; // 0 today, 1 tomorrow
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tradeId = widget.tradeId;
  }

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    return FutureBuilder<Craftsman?>(
      future: fs.getCraftsman(widget.craftsmanId),
      builder: (context, snap) {
        final c = snap.data;
        return Scaffold(
          appBar: AppBar(title: const Text(S.bookingTitle)),
          body: c == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _tradePicker(c),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: S.problemDescription,
                        hintText: S.problemHint,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _photoPicker(),
                    const SizedBox(height: 12),
                    _timePicker(),
                    const SizedBox(height: 12),
                    if (c.urgentAvailable)
                      SwitchListTile(
                        title: Text(
                            '${S.urgentRequest} (+${c.urgentSurchargePct}%)'),
                        value: _urgent,
                        activeColor: BricolaTheme.danger,
                        onChanged: (v) =>
                            setState(() => _urgent = v),
                      ),
                    const SizedBox(height: 8),
                    _priceHint(c),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saving
                          ? null
                          : () => _submit(fs, c),
                      child: _saving
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2))
                          : const Text(S.sendRequest),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _tradePicker(Craftsman c) {
    if (c.trades.length <= 1) {
      final t = c.trades.isNotEmpty
          ? Categories.tradeById(c.trades.first)
          : null;
      return ListTile(
        title: Text(t?.label ?? S.service),
        leading: const Icon(Icons.build),
      );
    }
    return DropdownButtonFormField<String>(
      value: _tradeId,
      decoration:
          const InputDecoration(labelText: S.service),
      items: c.trades.map((id) {
        final t = Categories.tradeById(id);
        return DropdownMenuItem(
            value: id, child: Text(t?.label ?? id));
      }).toList(),
      onChanged: (v) => setState(() => _tradeId = v),
    );
  }

  Widget _photoPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(S.addPhotos,
            style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ..._photos.map((p) => ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(File(p.path),
                      width: 80, height: 80, fit: BoxFit.cover),
                )),
            InkWell(
              onTap: () async {
                final picked = await ImagePicker()
                    .pickMultiImage(imageQuality: 70);
                setState(() => _photos = picked);
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: BricolaTheme.primary, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_a_photo,
                    color: BricolaTheme.primary),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _timePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(S.preferredTime,
            style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text(S.today)),
            ButtonSegment(value: 1, label: Text(S.tomorrow)),
          ],
          selected: {_dayOffset},
          onSelectionChanged: (s) =>
              setState(() => _dayOffset = s.first),
        ),
      ],
    );
  }

  /// Price is by mutual agreement between customer and craftsman.
  Widget _priceHint(Craftsman c) {
    return Container(
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
            child: Text('السعر بالتراضي بينك وبين الحرفي',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(
      FirestoreService fs, Craftsman c) async {
    if (_tradeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(S.service)));
      return;
    }
    setState(() => _saving = true);
    try {
      final bookingId =
          'b_${DateTime.now().millisecondsSinceEpoch}';
      final storage = context.read<StorageService>();
      final urls = <String>[];
      for (var i = 0; i < _photos.length; i++) {
        urls.add(await storage.uploadBookingPhoto(
          bookingId: bookingId,
          file: File(_photos[i].path),
          name: 'p$i',
        ));
      }
      final trade = Categories.tradeById(_tradeId!);
      final preferred = DateTime.now()
          .add(Duration(days: _dayOffset));
      await fs.createBooking(
        customerId: currentUid(),
        craftsmanId: c.id,
        tradeId: _tradeId!,
        serviceLabel: trade?.label ?? _tradeId!,
        description: _descCtrl.text.trim(),
        photoUrls: urls,
        preferredTime: preferred,
        urgent: _urgent,
      );
      if (mounted) _showConfirmation();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Confirmation sheet — prominently shows ضمان بريكولا.
  void _showConfirmation() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle,
                size: 64, color: Colors.green),
            const SizedBox(height: 12),
            const Text(S.bookingSent,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text(S.bookingPending,
                style: TextStyle(color: BricolaTheme.muted)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: BricolaTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield,
                          color: BricolaTheme.primary),
                      SizedBox(width: 8),
                      Text(S.guaranteeTitle,
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(S.guaranteeBody,
                      style: TextStyle(height: 1.6)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        '/home', (_) => false),
                child: const Text(S.backToHome),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
