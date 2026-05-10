import 'package:flutter/material.dart';
import '../../core/design_tokens.dart';
import '../../core/dummy_data.dart';
import '../../widgets/match_user_tile.dart';
import '../../widgets/panda_button.dart';
import '../../widgets/segmented_tabs.dart';
import 'user_detail_screen.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  int _tabIndex = 0;

  List<DummyUser> get _users {
    if (_tabIndex == 0) return similarUsers;
    if (_tabIndex == 1) return oppositeUsers;
    return middleUsers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              const Text('マッチ', style: TextStyle(fontSize: AppFontSize.xxl, fontWeight: FontWeight.w900, color: AppColors.black)),
              const SizedBox(height: AppSpacing.md),
              SegmentedTabs(
                tabs: const ['似ている人', '真逆な人', '50%付近'],
                selectedIndex: _tabIndex,
                onChanged: (i) => setState(() => _tabIndex = i),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, i) {
                    final u = _users[i];
                    return MatchUserTile(
                      rank: i + 1,
                      name: u.name,
                      matchRate: u.matchRate,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => UserDetailScreen(user: u)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PandaButton(label: 'もっと見る', onTap: () {}),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
