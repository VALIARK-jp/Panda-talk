import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_tokens.dart';
import '../../presentation/providers/profile_providers.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/panda_avatar.dart';
import '../../widgets/panda_button.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    final profileAsync = ref.read(profileControllerProvider);
    final profile = profileAsync.value;
    _nameController = TextEditingController(text: profile?.name ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

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
            AppTextField(label: '名前', controller: _nameController),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: '自己紹介',
              controller: _bioController,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.xl),
            PandaButton(
              label: '保存する',
              onTap: () async {
                await ref
                    .read(profileControllerProvider.notifier)
                    .updateProfile(
                      name: _nameController.text,
                      bio: _bioController.text,
                    );
                if (!context.mounted) return;
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
