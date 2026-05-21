import 'dart:io';

import 'package:flutter/material.dart';

import 'panda_avatar.dart';

/// プロフィール画像（URL / 端末ファイル）またはデフォルトパンダ。
class UserAvatar extends StatelessWidget {
  final double size;
  final String? imageUrl;
  final File? localFile;

  const UserAvatar({
    super.key,
    this.size = 96,
    this.imageUrl,
    this.localFile,
  });

  @override
  Widget build(BuildContext context) {
    if (localFile != null) {
      return ClipOval(
        child: Image.file(
          localFile!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    final url = imageUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    }

    return _fallback();
  }

  Widget _fallback() => PandaAvatar(size: size);
}
