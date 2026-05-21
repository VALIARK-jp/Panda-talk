import 'package:flutter/material.dart';

import '../core/category_poster_copy.dart';
import '../core/design_tokens.dart';
import 'panda_avatar.dart';

/// 回答直後の「中毒」演出（大％ → 多数派/少数派 → 異端児バンプ）。
class AnswerRevealOverlay extends StatefulWidget {
  final int selectedPercent;
  final bool isMinority;
  final int prevOddballScore;
  final int newOddballScore;
  final String? oddballBumpLabel;
  final String? mascotAssetPath;
  final VoidCallback onFinished;

  const AnswerRevealOverlay({
    super.key,
    required this.selectedPercent,
    required this.isMinority,
    required this.prevOddballScore,
    required this.newOddballScore,
    this.oddballBumpLabel,
    this.mascotAssetPath,
    required this.onFinished,
  });

  @override
  State<AnswerRevealOverlay> createState() => _AnswerRevealOverlayState();
}

class _AnswerRevealOverlayState extends State<AnswerRevealOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _percentScale;
  late final Animation<double> _badgeOpacity;
  late final Animation<double> _oddballOpacity;
  late final Animation<double> _backdropOpacity;

  static const _totalMs = 2200;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalMs),
    );

    _percentScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.12)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.12, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
    ]).animate(_controller);

    _badgeOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 22),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 12,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 38),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 8,
      ),
    ]).animate(_controller);

    _oddballOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 55),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 15),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 10,
      ),
    ]).animate(_controller);

    _backdropOpacity = Tween<double>(begin: 0.92, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.82, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward().then((_) {
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showOddball = widget.oddballBumpLabel != null ||
        (widget.isMinority && widget.newOddballScore > 0);
    final minorityLine = widget.isMinority
        ? minorityFlavorCopy(widget.selectedPercent)
        : null;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return IgnorePointer(
          child: Container(
            color: AppColors.white.withValues(
              alpha: _backdropOpacity.value.clamp(0.0, 1.0),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(
                      scale: _percentScale.value,
                      child: Text(
                        '${widget.selectedPercent}%',
                        style: TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.w900,
                          color: AppColors.black,
                          height: 1,
                          letterSpacing: -2,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Opacity(
                      opacity: _badgeOpacity.value.clamp(0.0, 1.0),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: widget.isMinority
                                  ? AppColors.black
                                  : AppColors.softGray,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                              border: widget.isMinority
                                  ? null
                                  : Border.all(color: AppColors.borderGray),
                            ),
                            child: Text(
                              widget.isMinority
                                  ? '君は 少数派'
                                  : '君は 多数派',
                              style: TextStyle(
                                fontSize: AppFontSize.xl,
                                fontWeight: FontWeight.w900,
                                color: widget.isMinority
                                    ? AppColors.white
                                    : AppColors.black,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (minorityLine != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              minorityLine,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: AppFontSize.md,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textGray,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (showOddball) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Opacity(
                        opacity: _oddballOpacity.value.clamp(0.0, 1.0),
                        child: _OddballBumpCard(
                          label: widget.oddballBumpLabel,
                          prevScore: widget.prevOddballScore,
                          newScore: widget.newOddballScore,
                          isMinority: widget.isMinority,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Opacity(
                      opacity: _badgeOpacity.value.clamp(0.0, 1.0) * 0.9,
                      child: PandaMascot(
                        size: 64,
                        expression:
                            widget.isMinority ? 'minority' : 'majority',
                        assetPath: widget.mascotAssetPath,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OddballBumpCard extends StatelessWidget {
  final String? label;
  final int prevScore;
  final int newScore;
  final bool isMinority;

  const _OddballBumpCard({
    this.label,
    required this.prevScore,
    required this.newScore,
    required this.isMinority,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isMinority ? AppColors.black : AppColors.softGray,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: isMinority
            ? null
            : Border.all(color: AppColors.borderGray),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label ?? 'あなたの異端児スコア',
              style: TextStyle(
                fontSize: AppFontSize.md,
                fontWeight: FontWeight.w800,
                color: isMinority ? AppColors.white : AppColors.black,
              ),
            ),
          ),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: prevScore, end: newScore),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return Text(
                '$value%',
                style: TextStyle(
                  fontSize: AppFontSize.xxl,
                  fontWeight: FontWeight.w900,
                  color: isMinority ? AppColors.white : AppColors.black,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
