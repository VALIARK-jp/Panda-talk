import 'package:flutter/material.dart';
import '../../core/design_tokens.dart';
import '../../core/share_utils.dart';
import '../../widgets/panda_avatar.dart';
import '../../widgets/panda_button.dart';

class AnswerResultScreen extends StatefulWidget {
  final String selected;
  final int percentA;
  final String optionA;
  final String optionB;
  final int answeredCount; // この回答後の累計回答数
  final int minorityCount; // この回答後の累計少数派回答数

  const AnswerResultScreen({
    super.key,
    required this.selected,
    required this.percentA,
    required this.optionA,
    required this.optionB,
    required this.answeredCount,
    required this.minorityCount,
  });

  @override
  State<AnswerResultScreen> createState() => _AnswerResultScreenState();
}

class _AnswerResultScreenState extends State<AnswerResultScreen> {
  bool _animated = false;
  bool _scoreVisible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _animated = true);
    });
    // 比率アニメ後にスコアを表示
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _scoreVisible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pA = widget.percentA;
    final pB = 100 - pA;

    // 少数派判定
    final selectedA = widget.selected == widget.optionA;
    final selectedPercent = selectedA ? pA : pB;
    final isMinority = selectedPercent < 50;

    // 異端児スコア
    final score = widget.answeredCount > 0
        ? (widget.minorityCount / widget.answeredCount * 100).round()
        : 0;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),
              // あなたは〇〇派
              const Text(
                'あなたは…',
                style: TextStyle(
                  fontSize: AppFontSize.lg,
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.selected}！',
                style: const TextStyle(
                  fontSize: AppFontSize.xxxl,
                  fontWeight: FontWeight.w900,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // 少数派 / 多数派バッジ
              AnimatedOpacity(
                opacity: _animated ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isMinority ? AppColors.black : AppColors.softGray,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    isMinority
                        ? '少数派 $selectedPercent%'
                        : '多数派 $selectedPercent%',
                    style: TextStyle(
                      fontSize: AppFontSize.sm,
                      fontWeight: FontWeight.w700,
                      color: isMinority ? AppColors.white : AppColors.textGray,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PandaMascot(
                size: 96,
                expression: isMinority ? 'default' : 'happy',
              ),
              const SizedBox(height: AppSpacing.lg),
              // みんなの比率バー
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.softGray,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'みんなの回答',
                      style: TextStyle(
                        fontSize: AppFontSize.md,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: SizedBox(
                        height: 56,
                        child: LayoutBuilder(
                          builder: (ctx, constraints) {
                            final totalW = constraints.maxWidth;
                            return Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 1500),
                                  curve: Curves.easeOut,
                                  width: _animated
                                      ? totalW * pA / 100
                                      : totalW * 0.5,
                                  color: AppColors.white,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${widget.optionA} $pA%',
                                    style: const TextStyle(
                                      fontSize: AppFontSize.sm,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.black,
                                    ),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 1500),
                                  curve: Curves.easeOut,
                                  width: _animated
                                      ? totalW * pB / 100
                                      : totalW * 0.5,
                                  color: AppColors.black,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${widget.optionB} $pB%',
                                    style: const TextStyle(
                                      fontSize: AppFontSize.sm,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // 異端児スコア
              AnimatedOpacity(
                opacity: _scoreVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.softGray,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'あなたの異端児スコア',
                            style: TextStyle(
                              fontSize: AppFontSize.md,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                          ),
                          Row(
                            children: [
                              if (isMinority)
                                const Text(
                                  '+1 ',
                                  style: TextStyle(
                                    fontSize: AppFontSize.md,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.black,
                                  ),
                                ),
                              Text(
                                '$score%',
                                style: const TextStyle(
                                  fontSize: AppFontSize.lg,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // スコアバー
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        child: SizedBox(
                          height: 12,
                          child: LayoutBuilder(
                            builder: (ctx, constraints) {
                              return Stack(
                                children: [
                                  Container(
                                    color: AppColors.borderGray,
                                    width: constraints.maxWidth,
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 800),
                                    curve: Curves.easeOut,
                                    width: _scoreVisible
                                        ? constraints.maxWidth * score / 100
                                        : 0,
                                    color: AppColors.black,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '凡人',
                            style: TextStyle(
                              fontSize: AppFontSize.sm,
                              color: AppColors.textGray,
                            ),
                          ),
                          Text(
                            '${widget.answeredCount}問中${widget.minorityCount}問で少数派',
                            style: const TextStyle(
                              fontSize: AppFontSize.sm,
                              color: AppColors.textGray,
                            ),
                          ),
                          const Text(
                            '異端児',
                            style: TextStyle(
                              fontSize: AppFontSize.sm,
                              color: AppColors.textGray,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              PandaButton(
                label: 'シェアする',
                onTap: () {
                  final minority = isMinority ? '少数派' : '多数派';
                  AppShare.text(
                    context,
                    '私は${widget.selected}派！（$minority $selectedPercent%）\nあなたはどっち？\n#パンダトーク',
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              PandaOutlinedButton(
                label: '次の質問へ →',
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
