import 'package:flutter/material.dart';
import '../../core/design_tokens.dart';
import '../../core/dummy_data.dart';
import '../../widgets/segmented_tabs.dart';
import '../../widgets/tag_chip.dart';

class QuestionHistoryScreen extends StatefulWidget {
  const QuestionHistoryScreen({super.key});

  @override
  State<QuestionHistoryScreen> createState() => _QuestionHistoryScreenState();
}

class _QuestionHistoryScreenState extends State<QuestionHistoryScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final filtered = _tabIndex == 0
        ? historyQuestions
        : _tabIndex == 1
            ? historyQuestions.where((q) => q.myAnswer != null).toList()
            : historyQuestions.where((q) => q.myAnswer == null).toList();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back, color: AppColors.black)),
                  const SizedBox(width: 12),
                  const Text('あなたの履歴', style: TextStyle(fontSize: AppFontSize.xl, fontWeight: FontWeight.w700, color: AppColors.black)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SegmentedTabs(
                tabs: const ['すべて', '回答済み', '未回答'],
                selectedIndex: _tabIndex,
                onChanged: (i) => setState(() => _tabIndex = i),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final q = filtered[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                              Text('Q.${q.number}', style: const TextStyle(fontSize: AppFontSize.sm, color: AppColors.textGray)),
                              const SizedBox(height: 4),
                              Text(q.text, style: const TextStyle(fontSize: AppFontSize.md, fontWeight: FontWeight.w600, color: AppColors.black)),
                            ],
                          ),
                        ),
                        if (q.myAnswer != null) TagChip(label: q.myAnswer!, filled: true),
                      ],
                    ),
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
