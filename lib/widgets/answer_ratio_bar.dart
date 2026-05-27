import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../core/design_tokens.dart';
import '../core/dummy_data.dart';

/// Hero 用タグ（フィード ↔ コメント画面で共有）。
String answerRatioBarHeroTag(DummyQuestion question) =>
    'answer-ratio-${question.apiId ?? 'n${question.number}'}';

/// 二択ボタンと比率バーで共通の高さ（レイアウトのジャンプを防ぐ）。
const double kChoiceBlockHeight = 88;
const double kLabelStripHeight = 36;
const double kLabelStripWithPercentHeight = 54;

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
    } else if (widget.selectedOption == null &&
        oldWidget.selectedOption != null) {
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
        // 外側の高さと内側コンテンツを同期（内側だけ大きいと一瞬 OVERFLOW する）
        final labelAreaHeight = hasAnswered
            ? lerpDouble(0, kLabelStripWithPercentHeight, morphT)!
            : 0.0;
        final showPercents =
            hasAnswered && labelAreaHeight >= kLabelStripWithPercentHeight - 4;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (labelAreaHeight > 0.5)
              ClipRect(
                child: SizedBox(
                  height: labelAreaHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: OptionLabelStrip(
                          label: widget.question.optionA,
                          opacity: morphT,
                          percent: showPercents ? leftPercent : null,
                          emphasized: selectedA,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: OptionLabelStrip(
                          label: widget.question.optionB,
                          opacity: morphT,
                          percent: showPercents ? rightPercent : null,
                          emphasized: selectedB,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ClipRect(
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                height: kChoiceBlockHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                                leftLabel: widget.question.optionA,
                                rightLabel: widget.question.optionB,
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
                                      labelOpacity: (1 - morphT).clamp(
                                        0.0,
                                        1.0,
                                      ),
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
                                      labelOpacity: (1 - morphT).clamp(
                                        0.0,
                                        1.0,
                                      ),
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

class OptionLabelStrip extends StatelessWidget {
  final String label;
  final double opacity;
  final int? percent;
  final bool emphasized;

  const OptionLabelStrip({
    required this.label,
    required this.opacity,
    this.percent,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final o = opacity.clamp(0.0, 1.0);

    return Opacity(
      opacity: o,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
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
            if (percent != null) ...[
              const SizedBox(height: 2),
              Text(
                '$percent%',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppFontSize.md,
                  fontWeight: FontWeight.w900,
                  color: emphasized ? AppColors.black : AppColors.textGray,
                  height: 1.1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class RatioBarWithYourChoice extends StatelessWidget {
  final int leftPercent;
  final bool selectedA;
  final String leftLabel;
  final String rightLabel;
  final bool showMarker;

  const RatioBarWithYourChoice({
    required this.leftPercent,
    required this.selectedA,
    required this.leftLabel,
    required this.rightLabel,
    required this.showMarker,
  });

  @override
  Widget build(BuildContext context) {
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
            final selectedWidth = selectedA ? split : w - split;
            final selectedLeft = selectedA ? 0.0 : split;
            final selectedPercent = selectedA ? leftPercent : 100 - leftPercent;
            final selectedLabel = selectedA ? leftLabel : rightLabel;
            final selectedOnDark = !selectedA;
            final selectedIsMajority = selectedPercent >= 50;
            final showSelectedCallout = showMarker && selectedWidth >= 96;

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
                if (showSelectedCallout)
                  Positioned(
                    left: selectedLeft,
                    width: selectedWidth,
                    top: 8,
                    bottom: 8,
                    child: _SelectedResultCallout(
                      label: selectedLabel,
                      percent: selectedPercent,
                      isMajority: selectedIsMajority,
                      onDark: selectedOnDark,
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

class _SelectedResultCallout extends StatelessWidget {
  final String label;
  final int percent;
  final bool isMajority;
  final bool onDark;

  const _SelectedResultCallout({
    required this.label,
    required this.percent,
    required this.isMajority,
    required this.onDark,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = onDark ? AppColors.white : AppColors.black;
    final mutedColor = primaryColor.withValues(alpha: 0.78);
    final chipColor = onDark ? AppColors.white : AppColors.black;
    final chipTextColor = onDark ? AppColors.black : AppColors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: chipColor,
                borderRadius: BorderRadius.circular(AppRadius.full),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '✓ あなた',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: chipTextColor,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$percent%',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppFontSize.xxl,
                fontWeight: FontWeight.w900,
                color: primaryColor,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: AppFontSize.sm,
                fontWeight: FontWeight.w900,
                color: primaryColor,
                height: 1.1,
              ),
            ),
            Text(
              isMajority ? '多数派' : '少数派',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: mutedColor,
                height: 1.15,
              ),
            ),
          ],
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
