import 'package:flutter/material.dart';

import '../core/design_tokens.dart';
import '../core/dummy_data.dart';

/// Hero 用タグ（フィード ↔ コメント画面で共有）。
String answerRatioBarHeroTag(DummyQuestion question) =>
    'answer-ratio-${question.apiId ?? 'n${question.number}'}';

/// 二択ボタンと比率バーで共通の高さ（レイアウトのジャンプを防ぐ）。
const double kChoiceBlockHeight = 88;
const double kLabelStripHeight = 36;

class AnswerRatioBar extends StatefulWidget {
  final DummyQuestion question;
  final int percentA;
  final String? selectedOption;
  final ValueChanged<String>? onSelect;
  final bool interactive;

  const AnswerRatioBar({
    required this.question,
    required this.percentA,
    required this.selectedOption,
    this.onSelect,
    this.interactive = true,
  });

  @override
  State<AnswerRatioBar> createState() => AnswerRatioBarState();
}

class AnswerRatioBarState extends State<AnswerRatioBar>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _morph;
  int _targetPercentA = 50;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _morph = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    if (!widget.interactive) {
      _pulse.stop();
      if (widget.selectedOption != null) {
        _targetPercentA = widget.percentA;
        _morph.value = 1;
      }
      return;
    }
    _pulse.repeat(reverse: true);
    if (widget.selectedOption != null) {
      _targetPercentA = widget.percentA;
      _morph.value = 1;
      _pulse.stop();
    }
  }

  @override
  void didUpdateWidget(AnswerRatioBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.interactive) {
      _targetPercentA = widget.percentA;
      return;
    }
    if (oldWidget.selectedOption == null && widget.selectedOption != null) {
      _targetPercentA = widget.percentA;
      _pulse.stop();
      _morph.forward(from: 0);
    } else if (widget.selectedOption != null) {
      _targetPercentA = widget.percentA;
    } else if (widget.selectedOption == null && oldWidget.selectedOption != null) {
      _morph.reverse(from: 1);
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _morph.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasAnswered = widget.selectedOption != null;
    final selectedA = widget.selectedOption == widget.question.optionA;
    final selectedB = widget.selectedOption == widget.question.optionB;

    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _morph]),
      builder: (context, _) {
        final morphT = widget.interactive
            ? Curves.easeInOut.transform(_morph.value)
            : (widget.selectedOption != null ? 1.0 : 0.0);
        final pulseT = widget.interactive
            ? Curves.easeInOut.transform(_pulse.value)
            : 0.0;
        final leftPercent = hasAnswered
            ? (_targetPercentA + (50 - _targetPercentA) * (1 - morphT)).round()
            : 50;
        final rightPercent = 100 - leftPercent;
        final gap = AppSpacing.sm * (1 - morphT);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRect(
              child: SizedBox(
                height: kLabelStripHeight * morphT,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    height: kLabelStripHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: OptionLabelStrip(
                            label: widget.question.optionA,
                            opacity: morphT,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: OptionLabelStrip(
                            label: widget.question.optionB,
                            opacity: morphT,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ClipRect(
              child: SizedBox(
                height: kChoiceBlockHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MorphPercentSlot(
                      percent: leftPercent,
                      morphT: morphT,
                      align: TextAlign.end,
                      emphasized: selectedA,
                    ),
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        clipBehavior: Clip.hardEdge,
                        children: [
                          IgnorePointer(
                            ignoring: morphT < 0.85,
                            child: Opacity(
                              opacity: morphT,
                              child: RatioBarWithYourChoice(
                                leftPercent: leftPercent,
                                selectedA: selectedA,
                                showMarker: morphT > 0.75,
                              ),
                            ),
                          ),
                          IgnorePointer(
                            ignoring: morphT > 0.25,
                            child: Opacity(
                              opacity: (1 - morphT).clamp(0.0, 1.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: BinaryChoiceTile(
                                      label: widget.question.optionA,
                                      dark: false,
                                      pulseT: pulseT,
                                      labelOpacity: (1 - morphT).clamp(0.0, 1.0),
                                      onTap: () => widget.onSelect?.call(
                                        widget.question.optionA,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: gap),
                                  Expanded(
                                    child: BinaryChoiceTile(
                                      label: widget.question.optionB,
                                      dark: true,
                                      pulseT: pulseT,
                                      labelOpacity: (1 - morphT).clamp(0.0, 1.0),
                                      onTap: () => widget.onSelect?.call(
                                        widget.question.optionB,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    MorphPercentSlot(
                      percent: rightPercent,
                      morphT: morphT,
                      align: TextAlign.start,
                      emphasized: selectedB,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// モーフ中に幅が狭いときの % 表示オーバーフローを防ぐ。
class MorphPercentSlot extends StatelessWidget {
  final int percent;
  final double morphT;
  final TextAlign align;
  final bool emphasized;

  const MorphPercentSlot({
    required this.percent,
    required this.morphT,
    required this.align,
    required this.emphasized,
  });

  static const double _slotWidth = 44;

  @override
  Widget build(BuildContext context) {
    if (morphT <= 0.01) return const SizedBox.shrink();

    return ClipRect(
      child: SizedBox(
        width: _slotWidth * morphT,
        child: Align(
          alignment: align == TextAlign.end
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$percent%',
              textAlign: align,
              maxLines: 1,
              style: TextStyle(
                fontSize: AppFontSize.sm,
                fontWeight: FontWeight.w800,
                color: emphasized ? AppColors.black : AppColors.textGray,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OptionLabelStrip extends StatelessWidget {
  final String label;
  final double opacity;

  const OptionLabelStrip({
    required this.label,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: AppFontSize.sm,
          fontWeight: FontWeight.w700,
          color: AppColors.black,
          height: 1.2,
        ),
      ),
    );
  }
}

class RatioBarWithYourChoice extends StatelessWidget {
  final int leftPercent;
  final bool selectedA;
  final bool showMarker;

  const RatioBarWithYourChoice({
    required this.leftPercent,
    required this.selectedA,
    required this.showMarker,
  });

  @override
  Widget build(BuildContext context) {
    final onDarkSide = !selectedA;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final split = (w * leftPercent / 100).clamp(0.0, w);
            final markerCenterX =
                selectedA ? split / 2 : split + (w - split) / 2;
            final markerColor = onDarkSide ? AppColors.white : AppColors.black;
            final segmentWide = selectedA
                ? split >= 56
                : (w - split) >= 56;

            return Stack(
              clipBehavior: Clip.hardEdge,
              alignment: Alignment.center,
              children: [
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      width: split,
                      height: kChoiceBlockHeight,
                      color: AppColors.white,
                    ),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        height: kChoiceBlockHeight,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
                if (showMarker && segmentWide)
                  Positioned(
                    left: (markerCenterX - 30).clamp(2.0, w - 62),
                    top: 8,
                    bottom: 8,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '君の選択',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: markerColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 18,
                            color: markerColor,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class BinaryChoiceTile extends StatelessWidget {
  final String label;
  final bool dark;
  final double pulseT;
  final double labelOpacity;
  final VoidCallback onTap;

  const BinaryChoiceTile({
    required this.label,
    required this.dark,
    required this.pulseT,
    this.labelOpacity = 1,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = dark
        ? AppColors.white.withValues(alpha: 0.35 + pulseT * 0.55)
        : AppColors.black.withValues(alpha: 0.18 + pulseT * 0.35);
    final haloColor = dark
        ? AppColors.white.withValues(alpha: 0.12 + pulseT * 0.2)
        : AppColors.black.withValues(alpha: 0.06 + pulseT * 0.1);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        splashColor: dark
            ? AppColors.white.withValues(alpha: 0.22)
            : AppColors.black.withValues(alpha: 0.08),
        highlightColor: dark
            ? AppColors.white.withValues(alpha: 0.14)
            : AppColors.black.withValues(alpha: 0.05),
        child: Ink(
          decoration: BoxDecoration(
            color: dark ? AppColors.black : AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: haloColor,
                blurRadius: 3 + pulseT * 5,
                spreadRadius: 0,
              ),
            ],
          ),
          child: SizedBox(
            height: kChoiceBlockHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.md,
              ),
              child: Center(
                child: Opacity(
                  opacity: labelOpacity.clamp(0.0, 1.0),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppFontSize.md,
                      fontWeight: FontWeight.w800,
                      color: dark ? AppColors.white : AppColors.black,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
