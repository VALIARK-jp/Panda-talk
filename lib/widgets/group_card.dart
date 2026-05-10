import 'package:flutter/material.dart';
import '../core/design_tokens.dart';
import 'panda_avatar.dart';
import 'panda_button.dart';

class GroupCard extends StatelessWidget {
  final String name;
  final int avgMatchRate;
  final List<String> members;
  final VoidCallback? onTap;

  const GroupCard({
    super.key,
    required this.name,
    required this.avgMatchRate,
    required this.members,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontSize: AppFontSize.lg, fontWeight: FontWeight.w700, color: AppColors.black)),
          const SizedBox(height: 4),
          Text('平均合致度：$avgMatchRate%', style: const TextStyle(fontSize: AppFontSize.md, color: AppColors.textGray)),
          const SizedBox(height: 8),
          Row(
            children: [
              ...members.map((m) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: PandaAvatar(size: 32),
              )),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  members.join('、'),
                  style: const TextStyle(fontSize: AppFontSize.sm, color: AppColors.textGray),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PandaButton(label: '参加する', onTap: onTap),
        ],
      ),
    );
  }
}
