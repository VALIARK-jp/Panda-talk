import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/design_tokens.dart';
import 'user_avatar.dart';

/// ギャラリー / カメラからプロフィール画像を選ぶ。
class ProfileAvatarPicker {
  ProfileAvatarPicker._();

  static final _picker = ImagePicker();

  static Future<File?> pick(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('フォトライブラリから選ぶ'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('カメラで撮影'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return null;

    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null) return null;
    return File(file.path);
  }
}

/// タップで画像を選べるプロフィールアイコン（編集画面・初回設定用）。
class ProfileAvatarEditor extends StatelessWidget {
  const ProfileAvatarEditor({
    super.key,
    required this.size,
    required this.imageUrl,
    required this.localFile,
    required this.enabled,
    required this.onTap,
    this.hint = 'タップしてアイコンを変更',
  });

  final double size;
  final String? imageUrl;
  final File? localFile;
  final bool enabled;
  final VoidCallback onTap;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: GestureDetector(
            onTap: enabled ? onTap : null,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                UserAvatar(
                  size: size,
                  imageUrl: imageUrl,
                  localFile: localFile,
                ),
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
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Text(
            hint,
            style: const TextStyle(
              fontSize: AppFontSize.sm,
              color: AppColors.textGray,
            ),
          ),
        ),
      ],
    );
  }
}

String profileAvatarErrorMessage(Object error) {
  final text = error.toString();
  if (text.contains('StorageException') ||
      text.contains('Bucket not found') ||
      text.contains('row-level security')) {
    return 'アイコンの保存に失敗しました。'
        'Supabase の avatars バケット（マイグレーション 20260518120000）が適用されているか確認してください。';
  }
  if (text.contains('PlatformException') ||
      text.contains('photo_access') ||
      text.contains('Permission')) {
    return '写真へのアクセスが拒否されました。設定アプリから許可してください。';
  }
  return '保存に失敗しました。もう一度お試しください。';
}
