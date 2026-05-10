import 'package:flutter/material.dart';
import '../../core/design_tokens.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/panda_button.dart';
import 'question_search_screen.dart';

class QuestionPostScreen extends StatefulWidget {
  const QuestionPostScreen({super.key});

  @override
  State<QuestionPostScreen> createState() => _QuestionPostScreenState();
}

class _QuestionPostScreenState extends State<QuestionPostScreen> {
  String _category = '恋愛';
  final _categories = ['恋愛', '生活', '性格', '旅行', '仕事', '食べ物'];

  @override
  Widget build(BuildContext context) {
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
                  const Text('質問を投稿', style: TextStyle(fontSize: AppFontSize.xxl, fontWeight: FontWeight.w900, color: AppColors.black)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuestionSearchScreen())),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: AppColors.textGray, size: 20),
                        SizedBox(width: 4),
                        Text('検索', style: TextStyle(fontSize: AppFontSize.md, color: AppColors.textGray)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const AppTextField(label: '質問文', initialValue: '恋愛は追う派？追われる派？', maxLines: 2),
              const SizedBox(height: AppSpacing.md),
              const AppTextField(label: '選択肢A', initialValue: '追う派'),
              const SizedBox(height: AppSpacing.md),
              const AppTextField(label: '選択肢B', initialValue: '追われる派'),
              const SizedBox(height: AppSpacing.md),
              const Text('カテゴリ', style: TextStyle(fontSize: AppFontSize.md, fontWeight: FontWeight.w600, color: AppColors.black)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.softGray,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _category,
                    isExpanded: true,
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // 類似質問警告
              Container(
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
                        Text('類似する質問があります', style: TextStyle(fontSize: AppFontSize.sm, color: AppColors.textGray)),
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
                          Expanded(child: Text('恋愛は追う派？待つ派？', style: TextStyle(fontSize: AppFontSize.md, color: AppColors.black))),
                          Text('Q.0987', style: TextStyle(fontSize: AppFontSize.sm, color: AppColors.textGray)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PandaButton(label: '投稿する', onTap: () => Navigator.pop(context)),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
