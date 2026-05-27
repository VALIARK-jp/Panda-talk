import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/category_poster_copy.dart';
import '../../core/design_tokens.dart';
import '../../presentation/providers/question_providers.dart';
import '../../widgets/tag_chip.dart';
import '../../widgets/user_avatar.dart';

class QuestionSearchScreen extends ConsumerStatefulWidget {
  const QuestionSearchScreen({super.key});

  @override
  ConsumerState<QuestionSearchScreen> createState() =>
      _QuestionSearchScreenState();
}

class _QuestionSearchScreenState extends ConsumerState<QuestionSearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = _query.trim();
    final searchAsync = trimmed.isEmpty
        ? null
        : ref.watch(questionSearchProvider(trimmed));

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
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onChanged: _onQueryChanged,
                      onSubmitted: (value) {
                        _debounce?.cancel();
                        setState(() => _query = value.trim());
                      },
                      style: const TextStyle(
                        fontSize: AppFontSize.md,
                        color: AppColors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: '質問を検索',
                        hintStyle: const TextStyle(
                          fontSize: AppFontSize.md,
                          color: AppColors.textGray,
                        ),
                        filled: true,
                        fillColor: AppColors.softGray,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.textGray,
                          size: 20,
                        ),
                        suffixIcon: trimmed.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: AppColors.textGray,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _controller.clear();
                                  _debounce?.cancel();
                                  setState(() => _query = '');
                                },
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: trimmed.isEmpty
                  ? const Center(
                      child: Text(
                        'キーワードを入力して検索',
                        style: TextStyle(
                          fontSize: AppFontSize.md,
                          color: AppColors.textGray,
                        ),
                      ),
                    )
                  : searchAsync!.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text(
                            '検索に失敗しました\n$e',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: AppFontSize.md,
                              color: AppColors.textGray,
                            ),
                          ),
                        ),
                      ),
                      data: (results) {
                        if (results.isEmpty) {
                          return const Center(
                            child: Text(
                              '該当する質問がありません',
                              style: TextStyle(
                                fontSize: AppFontSize.md,
                                color: AppColors.textGray,
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          itemCount: results.length,
                          itemBuilder: (context, i) {
                            final q = results[i];
                            final categoryColor = categoryAccentColor(
                              q.category,
                            );
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                                border: Border.all(
                                  color: categoryColor.withValues(alpha: 0.22),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            UserAvatar(
                                              size: 20,
                                              imageUrl: q.authorAvatarUrl,
                                            ),
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
                                  TagChip(
                                    label: q.category,
                                    color: categoryColor,
                                  ),
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
