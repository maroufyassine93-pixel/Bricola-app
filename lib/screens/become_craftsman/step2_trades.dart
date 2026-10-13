import 'package:flutter/material.dart';

import '../../core/wilayas.dart';
import '../../l10n/strings_ar.dart';
import '../../models/category.dart';
import 'draft.dart';

/// Step 2 — trades + wilaya + commune.
class BecomeStep2Trades extends StatefulWidget {
  const BecomeStep2Trades({super.key});

  @override
  State<BecomeStep2Trades> createState() =>
      _BecomeStep2TradesState();
}

class _BecomeStep2TradesState
    extends State<BecomeStep2Trades> {
  late final TextEditingController _communeCtrl;

  @override
  void initState() {
    super.initState();
    _communeCtrl =
        TextEditingController(text: BecomeFlow.draft.commune);
  }

  @override
  Widget build(BuildContext context) {
    final draft = BecomeFlow.draft;
    return Scaffold(
      appBar: AppBar(title: const Text(S.becomeCraftsman)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const BecomeStepsHeader(current: 2),
          const Text(S.chooseTrades,
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...Categories.groups.map((g) => Card(
                child: ExpansionTile(
                  leading:
                      Icon(g.icon, color: g.color),
                  title: Text(g.titleAr,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700)),
                  children: g.trades.map((t) {
                    final selected =
                        draft.trades.contains(t.id);
                    return CheckboxListTile(
                      title: Text(t.ar),
                      subtitle: Text(t.fr),
                      value: selected,
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          draft.trades.add(t.id);
                        } else {
                          draft.trades.remove(t.id);
                        }
                      }),
                    );
                  }).toList(),
                ),
              )),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: draft.wilayaCode,
            decoration:
                const InputDecoration(labelText: S.wilaya),
            items: wilayas
                .map((w) => DropdownMenuItem(
                    value: w.code,
                    child: Text('${w.code} - ${w.name}')))
                .toList(),
            onChanged: (v) =>
                setState(() => draft.wilayaCode = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _communeCtrl,
            decoration: const InputDecoration(
              labelText: S.commune,
              prefixIcon: Icon(Icons.location_city),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (!draft.step2Done) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'اختر مهنتك والولاية أولاً')));
                return;
              }
              draft.commune = _communeCtrl.text.trim();
              Navigator.of(context)
                  .pushNamed('/become/step3');
            },
            child: const Text(S.next),
          ),
        ],
      ),
    );
  }
}
