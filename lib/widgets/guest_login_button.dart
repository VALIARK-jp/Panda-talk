import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/design_tokens.dart';
import '../presentation/providers/auth_providers.dart';
import '../features/auth/screens/auth/login_screen.dart';

class GuestLoginButton extends ConsumerWidget {
  const GuestLoginButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authUserProvider).valueOrNull;
    if (authUser != null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      ),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.black,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        alignment: Alignment.center,
        child: const Text(
          'ログイン',
          style: TextStyle(
            color: AppColors.white,
            fontSize: AppFontSize.sm,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
