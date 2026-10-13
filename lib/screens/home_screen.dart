import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../l10n/strings_ar.dart';
import '../models/category.dart';
import '../services/firestore_service.dart';
import '../widgets/craftsman_card.dart';
import '../widgets/image_category_button.dart';
import '../widgets/section_title.dart';
import 'account_screen.dart';
import 'chat_list_screen.dart';
import 'notifications_screen.dart';
import 'rewards_screen.dart';

/// Home with bottom navigation: home | chats | notifications | rewards | account.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [
          _HomeTab(),
          ChatListScreen(),
          NotificationsScreen(),
          RewardsScreen(),
          AccountScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: BricolaTheme.primary,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: S.chats),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications_none),
              label: S.notifications),
          BottomNavigationBarItem(
              icon: Icon(Icons.card_giftcard), label: S.rewards),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: S.account),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    S.homeGreeting,
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    textInputAction: TextInputAction.search,
                    onSubmitted: (q) {
                      if (q.trim().isEmpty) return;
                      Navigator.of(context).pushNamed(
                        '/craftsmen',
                        arguments: {'query': q.trim()},
                      );
                    },
                    decoration: const InputDecoration(
                      hintText: S.searchHint,
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Urgent banner 🚨
                  Material(
                    color: BricolaTheme.danger,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.of(context).pushNamed(
                        '/craftsmen',
                        arguments: {'availableNowOnly': true},
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Icon(Icons.sos,
                                color: Colors.white, size: 30),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(S.urgentBanner,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight:
                                              FontWeight.w800,
                                          fontSize: 15)),
                                  Text(S.urgentBannerSub,
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_back_ios,
                                color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 3 big image category buttons
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final group = Categories.groups[i];
                  return ImageCategoryButton(
                    group: group,
                    onTap: () => Navigator.of(context).pushNamed(
                      '/category',
                      arguments: group.id,
                    ),
                  );
                },
                childCount: Categories.groups.length,
              ),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.72,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SectionTitle(
              title: S.topRated,
              actionLabel: S.seeAll,
              onAction: () =>
                  Navigator.of(context).pushNamed('/craftsmen'),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 210,
              child: StreamBuilder(
                stream: fs.craftsmenStream(),
                builder: (context, snap) {
                  if (snap.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }
                  final list =
                      (snap.data ?? []).take(8).toList();
                  if (list.isEmpty) {
                    return const Center(
                        child: Text(S.emptyHere));
                  }
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: list.length,
                    itemBuilder: (_, i) => SizedBox(
                      width: 300,
                      child: CraftsmanCard(
                        craftsman: list[i],
                        onTap: () =>
                            Navigator.of(context).pushNamed(
                          '/craftsman',
                          arguments: list[i].id,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
