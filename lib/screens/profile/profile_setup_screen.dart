import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/design_tokens.dart';
import '../../infrastructure/profile_onboarding_store.dart';
import '../../infrastructure/post_login_onboarding_store.dart';
import '../../infrastructure/supabase/avatar_upload_service.dart';
import '../../infrastructure/providers/repositories.dart';
import '../../presentation/providers/auth_providers.dart';
import '../../presentation/providers/profile_providers.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/panda_button.dart';
import '../../widgets/profile_avatar_picker.dart';

/// 初回ログイン後のプロフィール入力（名前・ユーザーコード・アイコン・一言）。
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key, required this.onComplete});

  final Future<void> Function() onComplete;

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  File? _pickedAvatar;
  String? _remoteAvatarUrl;
  bool _submitting = false;
  String? _errorMessage;

  static final _usernamePattern = RegExp(r'^[a-zA-Z0-9_]{3,30}$');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefill());
  }

  Future<void> _prefill() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    await Supabase.instance.client.auth.refreshSession();
    final refreshed = Supabase.instance.client.auth.currentUser ?? user;
    final metadata = refreshed.userMetadata ?? const <String, dynamic>{};
    final provider = refreshed.appMetadata['provider'] as String? ?? 'email';

    final displayName = metadata['displayName'] as String? ??
        metadata['name'] as String? ??
        '';

    if (displayName.isNotEmpty && _nameController.text.isEmpty) {
      _nameController.text = displayName;
    }

    final photoUrl = metadata['photoURL'] as String?;
    if (photoUrl != null &&
        photoUrl.trim().isNotEmpty &&
        _pickedAvatar == null &&
        (_remoteAvatarUrl == null || _remoteAvatarUrl!.isEmpty)) {
      setState(() => _remoteAvatarUrl = photoUrl.trim());
    }

    try {
      await ref.read(authServiceProvider).ensureBackendProfile(
        provider: provider,
        displayName: displayName.isEmpty ? null : displayName,
      );
      final profile = await ref.read(profileRepositoryProvider).getProfile();
      if (!mounted) return;
      if (_nameController.text.isEmpty && profile.name.isNotEmpty) {
        _nameController.text = profile.name;
      }
      if (_bioController.text.isEmpty && profile.bio.isNotEmpty) {
        _bioController.text = profile.bio;
      }
      final avatar = profile.avatarUrl;
      if (_pickedAvatar == null &&
          avatar != null &&
          avatar.isNotEmpty &&
          (_remoteAvatarUrl == null || _remoteAvatarUrl!.isEmpty)) {
        setState(() => _remoteAvatarUrl = avatar);
      }
    } catch (_) {
      // プロフィール行がまだ無くてもフォームは続行
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final file = await ProfileAvatarPicker.pick(context);
    if (file == null || !mounted) return;
    setState(() {
      _pickedAvatar = file;
      _remoteAvatarUrl = null;
    });
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim().toLowerCase();
    final bio = _bioController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'ユーザー名を入力してください');
      return;
    }
    if (!_usernamePattern.hasMatch(username)) {
      setState(() => _errorMessage = 'ユーザーコードは英数字と_のみ、3〜30文字です');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final available =
          await ref.read(profileControllerProvider.notifier).isUsernameAvailable(
            username,
          );
      if (!available) {
        setState(() {
          _submitting = false;
          _errorMessage = 'このユーザーコードは既に使われています';
        });
        return;
      }

      String? avatarUrl = _remoteAvatarUrl;
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (_pickedAvatar != null && userId != null) {
        avatarUrl = await AvatarUploadService().upload(_pickedAvatar!, userId);
      }

      await ref.read(profileControllerProvider.notifier).completeProfileSetup(
        name: name,
        username: username,
        bio: bio,
        avatarUrl: avatarUrl,
      );

      if (userId != null) {
        await ProfileOnboardingStore.setCompleted(userId);
        await PostLoginOnboardingStore.setWelcomeCompleted();
      }

      if (!mounted) return;
      await widget.onComplete();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('ProfileSetup submit failed: $e\n$st');
      }
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = _messageForSubmitError(e);
      });
    }
  }

  String _messageForSubmitError(Object error) {
    final text = error.toString();
    if (text.contains('SocketException') ||
        text.contains('Connection refused') ||
        text.contains('Failed host lookup')) {
      return 'API に接続できません。'
          'シミュレータなら backend を `npm run dev:db` で起動するか、'
          '.env の PANDA_TALK_API_BASE_URL を deploy 済み HTTPS にしてください。';
    }
    if (text.contains('StorageException') ||
        text.contains('Bucket not found') ||
        text.contains('row-level security')) {
      return profileAvatarErrorMessage(error);
    }
    if (text.contains('CONFLICT') ||
        text.contains('duplicate key') ||
        text.contains('unique constraint')) {
      return 'このユーザーコードは既に使われています';
    }
    if (text.contains('NOT_FOUND') || text.contains('User not found')) {
      return 'プロフィール行がありません。一度ログアウトしてから再度ログインしてください。';
    }
    return '保存に失敗しました。もう一度お試しください';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'プロフィールをつくろう',
              style: TextStyle(
                fontSize: AppFontSize.xxl,
                fontWeight: FontWeight.w900,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'あとから変更できます。まずはあなたらしいプロフィールを登録しましょう。',
              style: TextStyle(
                fontSize: AppFontSize.md,
                color: AppColors.textGray,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ProfileAvatarEditor(
              size: 88,
              imageUrl: _pickedAvatar == null ? _remoteAvatarUrl : null,
              localFile: _pickedAvatar,
              enabled: !_submitting,
              onTap: _pickAvatar,
              hint: 'タップしてアイコンを選ぶ',
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(label: 'ユーザー名', controller: _nameController),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'ユーザーコード',
              controller: _usernameController,
            ),
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                '@ユーザーコード として表示されます（英数字と _ のみ）',
                style: TextStyle(fontSize: AppFontSize.sm, color: AppColors.textGray),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: '一言',
              controller: _bioController,
              maxLines: 3,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: AppFontSize.md),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            PandaButton(
              label: _submitting ? '保存中…' : 'はじめる',
              onTap: _submitting ? null : _submit,
            ),
            SizedBox(height: MediaQuery.paddingOf(context).bottom + 16),
          ],
        ),
      ),
    );
  }

}
