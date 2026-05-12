import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_tokens.dart';
import '../../presentation/providers/question_providers.dart';
import '../../widgets/panda_avatar.dart';
import '../../widgets/tag_chip.dart';

class QuestionHistoryScreen extends ConsumerStatefulWidget {
  const QuestionHistoryScreen({super.key});

  @override
  ConsumerState<QuestionHistoryScreen> createState() =>
      _QuestionHistoryScreenState();
}

class _QuestionHistoryScreenState extends ConsumerState<QuestionHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(questionHistoryProvider);
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: AppColors.black),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'あなたの履歴',
                    style: TextStyle(
                      fontSize: AppFontSize.xl,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: historyAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('エラー: $e')),
                data: (historyQuestions) {
                  final filtered = historyQuestions
                      .where((q) => q.myAnswer != null)
                      .toList();

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final q = filtered[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.borderGray),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      PandaAvatar(size: 20),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '@${q.authorUsername}',
                                          style: const TextStyle(
                                            fontSize: AppFontSize.sm,
                                            color: AppColors.textGray,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Q.${q.number}',
                                    style: const TextStyle(
                                      fontSize: AppFontSize.sm,
                                      color: AppColors.textGray,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    q.text,
                                    style: const TextStyle(
                                      fontSize: AppFontSize.md,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (q.myAnswer != null)
                              TagChip(label: q.myAnswer!, filled: true),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
