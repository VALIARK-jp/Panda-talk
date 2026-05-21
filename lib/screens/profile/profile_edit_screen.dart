import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/design_tokens.dart';
import '../../core/dummy_data.dart';
import '../../infrastructure/supabase/avatar_upload_service.dart';
import '../../presentation/providers/profile_providers.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/panda_button.dart';
import '../../widgets/profile_avatar_picker.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();

  File? _pickedAvatar;
  String? _avatarUrl;
  String _initialUsername = '';
  bool _saving = false;
  bool _fieldsInitialized = false;
  String? _errorMessage;

  static final _usernamePattern = RegExp(r'^[a-zA-Z0-9_]{3,30}$');

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _initFields(DummyProfile profile) {
    if (_fieldsInitialized) return;
    _fieldsInitialized = true;
    _nameController.text = profile.name;
    _usernameController.text = profile.username;
    _initialUsername = profile.username;
    _bioController.text = profile.bio;
    _avatarUrl = profile.avatarUrl;
  }

  Future<void> _pickAvatar() async {
    final file = await ProfileAvatarPicker.pick(context);
    if (file == null || !mounted) return;
    setState(() {
      _pickedAvatar = file;
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim().toLowerCase();
    final bio = _bioController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'ユーザー名を入力してください');
      return;
    }
    if (!_usernamePattern.hasMatch(username)) {
      setState(
        () => _errorMessage = 'ユーザーコードは英数字と_のみ、3〜30文字です',
      );
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      if (username != _initialUsername) {
        final available = await ref
            .read(profileControllerProvider.notifier)
            .isUsernameAvailable(username);
        if (!available) {
          if (!mounted) return;
          setState(() {
            _saving = false;
            _errorMessage = 'このユーザーコードは既に使われています';
          });
          return;
        }
      }

      String? avatarUrl = _avatarUrl;
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (_pickedAvatar != null && userId != null) {
        avatarUrl = await AvatarUploadService().upload(_pickedAvatar!, userId);
      }

      await ref.read(profileControllerProvider.notifier).updateProfile(
            name: name,
            bio: bio,
            avatarUrl: avatarUrl,
            username: username,
          );
      if (!mounted) return;
      ref.invalidate(profileControllerProvider);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _messageForSaveError(e);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageForSaveError(e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _messageForSaveError(Object error) {
    final text = error.toString();
    if (text.contains('duplicate key') ||
        text.contains('unique constraint') ||
        text.contains('CONFLICT')) {
      return 'このユーザーコードは既に使われています';
    }
    return profileAvatarErrorMessage(error);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileControllerProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.white,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.white,
        body: Center(child: Text('プロフィールを読み込めませんでした: $error')),
      ),
      data: (profile) {
        _initFields(profile);
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
                ProfileAvatarEditor(
                  size: 88,
                  imageUrl: _pickedAvatar == null ? _avatarUrl : null,
                  localFile: _pickedAvatar,
                  enabled: !_saving,
                  onTap: _pickAvatar,
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
                    style: TextStyle(
                      fontSize: AppFontSize.sm,
                      color: AppColors.textGray,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: '自己紹介',
                  controller: _bioController,
                  maxLines: 3,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: AppFontSize.md,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                PandaButton(
                  label: _saving ? '保存中…' : '保存する',
                  onTap: _saving ? null : _save,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
