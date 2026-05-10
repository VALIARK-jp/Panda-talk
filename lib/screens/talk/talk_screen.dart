import 'package:flutter/material.dart';
import '../../core/design_tokens.dart';
import '../../core/dummy_data.dart';
import '../../widgets/group_card.dart';
import 'group_chat_screen.dart';

class TalkScreen extends StatelessWidget {
  const TalkScreen({super.key});

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
              const Text('トーク', style: TextStyle(fontSize: AppFontSize.xxl, fontWeight: FontWeight.w900, color: AppColors.black)),
              const SizedBox(height: AppSpacing.sm),
              const Text('おすすめグループ', style: TextStyle(fontSize: AppFontSize.md, color: AppColors.textGray)),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ListView.builder(
                  itemCount: groups.length,
                  itemBuilder: (context, i) {
                    final g = groups[i];
                    return GroupCard(
                      name: g.name,
                      avgMatchRate: g.avgMatchRate,
                      members: g.members,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => GroupChatScreen(group: g)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
