import 'package:flutter/material.dart';

import '../../l10n/strings_ar.dart';
import 'draft.dart';

/// Step 1 — personal info.
class BecomeStep1Personal extends StatefulWidget {
  const BecomeStep1Personal({super.key});

  @override
  State<BecomeStep1Personal> createState() =>
      _BecomeStep1PersonalState();
}

class _BecomeStep1PersonalState
    extends State<BecomeStep1Personal> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: BecomeFlow.draft.fullName);
    _phoneCtrl =
        TextEditingController(text: BecomeFlow.draft.contactPhone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(S.becomeCraftsman)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const BecomeStepsHeader(current: 1),
          const Text(S.bcStep1,
              style:
                  TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: S.fullName,
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'رقم هاتف للتواصل (اختياري)',
              hintText: 'يُكشف للزبون بعد قبول الحجز فقط',
              prefixIcon: Icon(Icons.phone),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (_nameCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(S.fullName)));
                return;
              }
              BecomeFlow.draft.fullName =
                  _nameCtrl.text.trim();
              BecomeFlow.draft.contactPhone =
                  _phoneCtrl.text.trim();
              Navigator.of(context)
                  .pushNamed('/become/step2');
            },
            child: const Text(S.next),
          ),
        ],
      ),
    );
  }
}
