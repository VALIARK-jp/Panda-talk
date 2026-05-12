import 'package:flutter/material.dart';
import '../../core/design_tokens.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/panda_avatar.dart';
import '../../widgets/panda_button.dart';

class ProfileEditScreen extends StatelessWidget {
  const ProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: AppColors.black),
                ),
                const SizedBox(width: 12),
                const Text(
                  'プロフィール編集',
                  style: TextStyle(
                    fontSize: AppFontSize.xl,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  PandaAvatar(size: 88),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.black,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.photo_camera_outlined,
                      color: AppColors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const AppTextField(label: '名前', initialValue: 'ぱんだちゃん'),
            const SizedBox(height: AppSpacing.md),
            const AppTextField(
              label: '自己紹介',
              initialValue: 'パンダが大好きです',
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.xl),
            PandaButton(label: '保存する', onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}
