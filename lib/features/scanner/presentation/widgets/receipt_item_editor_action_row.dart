import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

class ReceiptItemEditorActionRow extends StatelessWidget {
  const ReceiptItemEditorActionRow({
    super.key,
    required this.onCancelTap,
    required this.onApplyTap,
  });

  final VoidCallback onCancelTap;
  final VoidCallback onApplyTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancelTap,
            child: Text(l10n.inventoryReceiptReviewCancelAction),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: FilledButton(
            key: const Key('receipt_review_apply_item_button'),
            onPressed: onApplyTap,
            child: Text(l10n.inventoryReceiptReviewApplyItemAction),
          ),
        ),
      ],
    );
  }
}
