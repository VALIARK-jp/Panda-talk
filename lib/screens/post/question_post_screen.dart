import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_tokens.dart';
import '../../core/dummy_data.dart';
import '../../presentation/providers/post_providers.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/panda_button.dart';
import 'question_search_screen.dart';

class QuestionPostScreen extends ConsumerStatefulWidget {
  const QuestionPostScreen({super.key});

  @override
  ConsumerState<QuestionPostScreen> createState() => _QuestionPostScreenState();
}

class _QuestionPostScreenState extends ConsumerState<QuestionPostScreen> {
  final _questionController = TextEditingController(text: '恋愛は追う派？追われる派？');
  final _optionAController = TextEditingController(text: '追う派');
  final _optionBController = TextEditingController(text: '追われる派');
  String _category = '恋愛';
  final _categories = ['恋愛', '生活', '性格', '旅行', '仕事', '食べ物'];

  @override
  void dispose() {
    _questionController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    super.dispose();
  }

  Future<void> _postQuestion() async {
    await ref
        .read(questionPostControllerProvider.notifier)
        .postQuestion(
          text: _questionController.text,
          optionA: _optionAController.text,
          optionB: _optionBController.text,
          category: _category,
        );
    _questionController.clear();
    _optionAController.clear();
    _optionBController.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('質問を投稿しました')));
  }

  @override
  Widget build(BuildContext context) {
    final myQuestions = ref.watch(questionPostControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '質問を投稿',
                    style: TextStyle(
                      fontSize: AppFontSize.xxl,
                      fontWeight: FontWeight.w900,
                      color: AppColors.black,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const QuestionSearchScreen(),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: AppColors.textGray, size: 20),
                        SizedBox(width: 4),
                        Text(
                          '検索',
                          style: TextStyle(
                            fontSize: AppFontSize.md,
                            color: AppColors.textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: '質問文',
                controller: _questionController,
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(label: '選択肢A', controller: _optionAController),
              const SizedBox(height: AppSpacing.md),
              AppTextField(label: '選択肢B', controller: _optionBController),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'カテゴリ',
                style: TextStyle(
                  fontSize: AppFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 8),
              _CategoryDropdown(
                value: _category,
                categories: _categories,
                onChanged: (value) => setState(() => _category = value),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _SimilarQuestionNotice(),
              const SizedBox(height: AppSpacing.xl),
              PandaButton(label: '投稿する', onTap: _postQuestion),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                '自分の投稿',
                style: TextStyle(
                  fontSize: AppFontSize.md,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...myQuestions.map(
                (question) => _MyQuestionCard(
                  question: question,
                  onEdit: _showEditSheet,
                  onDelete: (number) => ref
                      .read(questionPostControllerProvider.notifier)
                      .deleteQuestion(number),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditSheet(DummyQuestion question) {
    final questionController = TextEditingController(text: question.text);
    final optionAController = TextEditingController(text: question.optionA);
    final optionBController = TextEditingController(text: question.optionB);
    var category = question.category;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '質問を編集',
                    style: TextStyle(
                      fontSize: AppFontSize.xl,
                      fontWeight: FontWeight.w800,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: '質問文',
                    controller: questionController,
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(label: '選択肢A', controller: optionAController),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(label: '選択肢B', controller: optionBController),
                  const SizedBox(height: AppSpacing.md),
                  _CategoryDropdown(
                    value: category,
                    categories: _categories,
                    onChanged: (value) => setSheetState(() => category = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PandaButton(
                    label: '保存する',
                    onTap: () async {
                      await ref
                          .read(questionPostControllerProvider.notifier)
                          .editQuestion(
                            number: question.number,
                            text: questionController.text,
                            optionA: optionAController.text,
                            optionB: optionBController.text,
                            category: category,
                          );
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final String value;
  final List<String> categories;
  final ValueChanged<String> onChanged;

  const _CategoryDropdown({
    required this.value,
    required this.categories,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.softGray,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: categories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _SimilarQuestionNotice extends StatelessWidget {
  const _SimilarQuestionNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.softGray,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.textGray),
              SizedBox(width: 6),
              Text(
                '類似する質問があります',
                style: TextStyle(
                  fontSize: AppFontSize.sm,
                  color: AppColors.textGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.borderGray),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    '恋愛は追う派？待つ派？',
                    style: TextStyle(
                      fontSize: AppFontSize.md,
                      color: AppColors.black,
                    ),
                  ),
                ),
                Text(
                  'Q.0987',
                  style: TextStyle(
                    fontSize: AppFontSize.sm,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MyQuestionCard extends StatelessWidget {
  final DummyQuestion question;
  final ValueChanged<DummyQuestion> onEdit;
  final ValueChanged<int> onDelete;

  const _MyQuestionCard({
    required this.question,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(AppSpacing.md),
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
                Text(
                  'Q.${question.number} / ${question.category}',
                  style: const TextStyle(
                    fontSize: AppFontSize.sm,
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  question.text,
                  style: const TextStyle(
                    fontSize: AppFontSize.md,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => onEdit(question),
            icon: const Icon(Icons.edit_outlined, color: AppColors.black),
          ),
          IconButton(
            onPressed: () => onDelete(question.number),
            icon: const Icon(Icons.delete_outline, color: AppColors.textGray),
          ),
        ],
      ),
    );
  }
}
