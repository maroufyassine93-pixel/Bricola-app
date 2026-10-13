import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/category.dart';

/// Sub-trades of one category group, as image buttons.
class CategoryDetailScreen extends StatelessWidget {
  final String groupId;

  const CategoryDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final group = Categories.groupById(groupId);
    if (group == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('غير موجود')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(group.titleAr)),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.35,
        ),
        itemCount: group.trades.length,
        itemBuilder: (_, i) {
          final trade = group.trades[i];
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            elevation: 1,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.of(context).pushNamed(
                '/craftsmen',
                arguments: {'tradeId': trade.id},
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: group.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(trade.icon,
                          size: 32, color: group.color),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      trade.ar,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    Text(
                      trade.fr,
                      style: const TextStyle(
                          fontSize: 12, color: BricolaTheme.muted),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
