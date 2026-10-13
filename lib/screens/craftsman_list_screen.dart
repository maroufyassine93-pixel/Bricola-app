import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/wilayas.dart';
import '../l10n/strings_ar.dart';
import '../models/category.dart';
import '../models/craftsman.dart';
import '../services/firestore_service.dart';
import '../widgets/craftsman_card.dart';

/// Craftsman results with filters: wilaya, verified only, available now,
/// plus free-text query (client-side name/trade match).
class CraftsmanListScreen extends StatefulWidget {
  final String? tradeId;
  final int? wilayaCode;
  final bool verifiedOnly;
  final bool availableNowOnly;
  final String? query;

  const CraftsmanListScreen({
    super.key,
    this.tradeId,
    this.wilayaCode,
    this.verifiedOnly = false,
    this.availableNowOnly = false,
    this.query,
  });

  @override
  State<CraftsmanListScreen> createState() =>
      _CraftsmanListScreenState();
}

class _CraftsmanListScreenState extends State<CraftsmanListScreen> {
  late int? _wilaya;
  late bool _verifiedOnly;
  late bool _availableNow;

  @override
  void initState() {
    super.initState();
    _wilaya = widget.wilayaCode;
    _verifiedOnly = widget.verifiedOnly;
    _availableNow = widget.availableNowOnly;
  }

  String get _title {
    if (widget.query != null) return 'نتائج: ${widget.query}';
    final tid = widget.tradeId;
    if (tid != null) {
      return Categories.tradeById(tid)?.ar ?? '';
    }
    return 'الحرفيون';
  }

  bool _matchesQuery(Craftsman c) {
    final q = widget.query;
    if (q == null || q.isEmpty) return true;
    final needle = q.toLowerCase();
    if (c.displayName.toLowerCase().contains(needle)) return true;
    return c.trades.any((t) {
      final trade = Categories.tradeById(t);
      return trade != null &&
          (trade.ar.contains(q) ||
              trade.fr.toLowerCase().contains(needle));
    });
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilters,
            tooltip: S.filters,
          ),
        ],
      ),
      body: StreamBuilder<List<Craftsman>>(
        stream: fs.craftsmenStream(
          tradeId: widget.tradeId,
          wilayaCode: _wilaya,
          verifiedOnly: _verifiedOnly,
          availableNowOnly: _availableNow,
        ),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text(S.errorGeneric));
          }
          final list =
              (snap.data ?? []).where(_matchesQuery).toList();
          if (list.isEmpty) {
            return const Center(child: Text(S.emptyHere));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            itemBuilder: (_, i) => CraftsmanCard(
              craftsman: list[i],
              onTap: () => Navigator.of(context).pushNamed(
                '/craftsman',
                arguments: list[i].id,
              ),
            ),
          );
        },
      ),
    );
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(S.filters,
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                value: _wilaya,
                decoration:
                    const InputDecoration(labelText: S.wilaya),
                items: [
                  const DropdownMenuItem<int?>(
                      value: null, child: Text('كل الولايات')),
                  ...wilayas.map((w) => DropdownMenuItem<int?>(
                      value: w.code,
                      child: Text('${w.code} - ${w.name}'))),
                ],
                onChanged: (v) => setSheet(() => _wilaya = v),
              ),
              SwitchListTile(
                title: const Text(S.verifiedOnly),
                value: _verifiedOnly,
                activeColor: BricolaTheme.primary,
                onChanged: (v) =>
                    setSheet(() => _verifiedOnly = v),
              ),
              SwitchListTile(
                title: const Text(S.availableNowOnly),
                value: _availableNow,
                activeColor: BricolaTheme.primary,
                onChanged: (v) =>
                    setSheet(() => _availableNow = v),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                  Navigator.of(ctx).pop();
                },
                child: const Text(S.apply),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
