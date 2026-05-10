import 'package:flutter/material.dart';
import '../../core/design_tokens.dart';
import '../../core/dummy_data.dart';
import '../../widgets/panda_avatar.dart';
import '../../widgets/panda_button.dart';
import '../../widgets/segmented_tabs.dart';
import '../../widgets/tag_chip.dart';
import 'answer_result_screen.dart';
import 'question_history_screen.dart';

class QuestionFeedScreen extends StatefulWidget {
  const QuestionFeedScreen({super.key});

  @override
  State<QuestionFeedScreen> createState() => _QuestionFeedScreenState();
}

class _QuestionFeedScreenState extends State<QuestionFeedScreen> {
  int _tabIndex = 0;            // 0=診断 1=Hot
  int _answeredCount = 0;       // ゲスト回答カウント（ダミー）
  int _minorityCount = 0;       // 少数派回答カウント
  final bool _isGuest = true;   // ゲストモードフラグ（ダミー）

  static const _nudgeMessages = {
    10: '10問答えたね！\n登録すると合致度が見られるよ。',
    20: 'あなたと合う人、\nもう見つかってるかも。',
    30: '異端児スコアが本格的になってきた。\n記録しておこう。',
  };

  void _onAnswer(String selected, int percentA) {
    final selectedA = selected == currentQuestion.optionA;
    final selectedPercent = selectedA ? percentA : (100 - percentA);
    final isMinority = selectedPercent < 50;

    setState(() {
      _answeredCount++;
      if (isMinority) _minorityCount++;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnswerResultScreen(
          selected: selected,
          percentA: percentA,
          optionA: currentQuestion.optionA,
          optionB: currentQuestion.optionB,
          answeredCount: _answeredCount,
          minorityCount: _minorityCount,
        ),
      ),
    ).then((_) {
      if (_isGuest && _nudgeMessages.containsKey(_answeredCount)) {
        _showNudgeModal(_answeredCount);
      }
    });
  }

  void _showNudgeModal(int count) {
    final message = _nudgeMessages[count]!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _NudgeCard(message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = currentQuestion;
    return Scaffold(
      backgroundColor: AppColors.softGray,
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedTabs(
                      tabs: const ['診断', 'Hot'],
                      selectedIndex: _tabIndex,
                      onChanged: (i) => setState(() => _tabIndex = i),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuestionHistoryScreen())),
                    child: PandaAvatar(size: 36),
                  ),
                ],
              ),
            ),
            // 質問カード
            Expanded(
              child: GestureDetector(
                onVerticalDragEnd: (d) {
                  if (d.primaryVelocity != null && d.primaryVelocity! < -200) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const QuestionHistoryScreen()));
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          // 番号 + カテゴリ
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Q.${q.number}', style: const TextStyle(fontSize: AppFontSize.sm, color: AppColors.textGray)),
                              TagChip(label: q.category),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          // パンダ2体
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              PandaAvatar(size: 48),
                              const SizedBox(width: AppSpacing.xl),
                              PandaAvatar(size: 48),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          // 質問文
                          Text(
                            q.text,
                            style: const TextStyle(fontSize: AppFontSize.xl, fontWeight: FontWeight.w700, color: AppColors.black),
                            textAlign: TextAlign.center,
                          ),
                          const Spacer(),
                          // 選択肢ボタン
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _onAnswer(q.optionA, q.percentA),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                      border: Border.all(color: AppColors.black, width: 1.5),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(q.optionA, style: const TextStyle(fontSize: AppFontSize.lg, fontWeight: FontWeight.w700, color: AppColors.black)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _onAnswer(q.optionB, q.percentA),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    decoration: BoxDecoration(
                                      color: AppColors.black,
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(q.optionB, style: const TextStyle(fontSize: AppFontSize.lg, fontWeight: FontWeight.w700, color: AppColors.white)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NudgeCard extends StatelessWidget {
  final String message;
  const _NudgeCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ハンドル
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PandaMascot(size: 72, expression: 'default'),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: const TextStyle(fontSize: AppFontSize.lg, fontWeight: FontWeight.w700, color: AppColors.black, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          PandaButton(
            label: '登録する',
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          PandaOutlinedButton(
            label: '続ける',
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
