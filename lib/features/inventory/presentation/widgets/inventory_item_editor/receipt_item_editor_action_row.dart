import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines receipt item editor action row.
class ReceiptItemEditorActionRow extends StatelessWidget {
  /// The receipt item editor action row.
  const ReceiptItemEditorActionRow({
    required this.onCancelTap,
    required this.onApplyTap,
    super.key,
  });

  /// The on cancel tap.
  final VoidCallback onCancelTap;

  /// The on apply tap.
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
