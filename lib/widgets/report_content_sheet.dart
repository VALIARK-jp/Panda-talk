import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design_tokens.dart';
import '../infrastructure/moderation_repository.dart';
import '../presentation/providers/moderation_providers.dart';

Future<void> showReportContentSheet(
  BuildContext context, {
  required WidgetRef ref,
  required ReportTargetType targetType,
  required String targetId,
  String? subjectLabel,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return _ReportContentSheet(
        targetType: targetType,
        targetId: targetId,
        subjectLabel: subjectLabel,
      );
    },
  );
}

class _ReportContentSheet extends ConsumerStatefulWidget {
  const _ReportContentSheet({
    required this.targetType,
    required this.targetId,
    this.subjectLabel,
  });

  final ReportTargetType targetType;
  final String targetId;
  final String? subjectLabel;

  @override
  ConsumerState<_ReportContentSheet> createState() => _ReportContentSheetState();
}

class _ReportContentSheetState extends ConsumerState<_ReportContentSheet> {
  ContentReportReason _reason = ContentReportReason.inappropriate;
  final _detailController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await ref.read(moderationControllerProvider.notifier).reportContent(
        targetType: widget.targetType,
        targetId: widget.targetId,
        reason: _reason,
        detail: _detailController.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('通報を受け付けました。ご協力ありがとうございます。')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('通報に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final subject = widget.subjectLabel;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.lg + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '通報する',
            style: TextStyle(
              fontSize: AppFontSize.lg,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
          if (subject != null && subject.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subject,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: AppFontSize.sm,
                color: AppColors.textGray,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          ...ContentReportReason.values.map(
            (reason) => RadioListTile<ContentReportReason>(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: reason,
              groupValue: _reason,
              onChanged: _submitting
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() => _reason = value);
                    },
              title: Text(
                reason.label,
                style: const TextStyle(
                  fontSize: AppFontSize.md,
                  color: AppColors.black,
                ),
              ),
            ),
          ),
          TextField(
            controller: _detailController,
            enabled: !_submitting,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: '詳細（任意）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.black,
              foregroundColor: AppColors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    '通報する',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
          ),
        ],
      ),
    );
  }
}
