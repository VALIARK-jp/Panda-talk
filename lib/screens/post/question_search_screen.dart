import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_tokens.dart';
import '../../presentation/providers/question_providers.dart';
import '../../widgets/panda_avatar.dart';
import '../../widgets/tag_chip.dart';

class QuestionSearchScreen extends ConsumerStatefulWidget {
  const QuestionSearchScreen({super.key});

  @override
  ConsumerState<QuestionSearchScreen> createState() =>
      _QuestionSearchScreenState();
}

class _QuestionSearchScreenState extends ConsumerState<QuestionSearchScreen> {
  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(questionSearchProvider('恋愛'));
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.softGray,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: AppColors.textGray,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '恋愛',
                            style: TextStyle(
                              fontSize: AppFontSize.md,
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: searchAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('エラー: $e')),
                data: (searchResults) => ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  itemCount: searchResults.length,
                  itemBuilder: (context, i) {
                    final q = searchResults[i];
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
                          const SizedBox(width: 8),
                          TagChip(label: q.category),
                          const SizedBox(width: 8),
                          Text(
                            'Q.${q.number}',
                            style: const TextStyle(
                              fontSize: AppFontSize.sm,
                              color: AppColors.textGray,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
