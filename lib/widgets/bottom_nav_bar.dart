import 'package:flutter/material.dart';

import '../config/feature_flags.dart';
import '../core/design_tokens.dart';
import 'panda_avatar.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.borderGray)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              label: '診断',
              index: 0,
              current: currentIndex,
              onTap: onTap,
            ),
            _PandaNavItem(index: 1, current: currentIndex, onTap: onTap),
            _NavItem(
              icon: Icons.add_circle_outline,
              label: '投稿',
              index: 2,
              current: currentIndex,
              onTap: onTap,
            ),
            if (kTalkNavTabEnabled)
              _NavItem(
                icon: Icons.chat_bubble_outline,
                label: 'トーク',
                index: 3,
                current: currentIndex,
                onTap: onTap,
              ),
            _NavItem(
              icon: Icons.person_outline,
              label: 'プロフィール',
              index: kTalkNavTabEnabled ? 4 : 3,
              current: currentIndex,
              onTap: onTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? AppColors.black : AppColors.textGray,
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: selected ? AppColors.black : AppColors.textGray,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PandaNavItem extends StatelessWidget {
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _PandaNavItem({
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: selected ? 1.0 : 0.4,
                child: PandaAvatar(size: 24),
              ),
              const SizedBox(height: 2),
              Text(
                'マッチ',
                style: TextStyle(
                  fontSize: 10,
                  color: selected ? AppColors.black : AppColors.textGray,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
