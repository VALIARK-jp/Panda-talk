import 'package:flutter/material.dart';
import '../core/design_tokens.dart';

class PandaButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final double? width;

  const PandaButton({super.key, required this.label, this.onTap, this.width});

  @override
  State<PandaButton> createState() => _PandaButtonState();
}

class _PandaButtonState extends State<PandaButton>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.width ?? double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.black,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: AppFontSize.lg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class PandaOutlinedButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final double? width;

  const PandaOutlinedButton({
    super.key,
    required this.label,
    this.onTap,
    this.width,
  });

  @override
  State<PandaOutlinedButton> createState() => _PandaOutlinedButtonState();
}

class _PandaOutlinedButtonState extends State<PandaOutlinedButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.width ?? double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: AppColors.borderGray),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: const TextStyle(
              color: AppColors.black,
              fontSize: AppFontSize.lg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
