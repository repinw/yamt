import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Header row for the receipt review sheet with title and save action.
class InventoryReceiptReviewHeader extends StatelessWidget {
  const InventoryReceiptReviewHeader({
    super.key,
    required this.isSaving,
    required this.canSave,
    required this.onSaveTap,
  });

  final bool isSaving;
  final bool canSave;
  final VoidCallback onSaveTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            l10n.inventoryReceiptReviewTitle,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.onSurface,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        FilledButton(
          key: const Key('receipt_review_save_button'),
          onPressed: canSave ? onSaveTap : null,
          style: FilledButton.styleFrom(
            backgroundColor: colors.inverseSurface,
            foregroundColor: colors.onInverseSurface,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppReceiptReviewUi.headerButtonRadius,
              ),
            ),
          ),
          child: isSaving
              ? SizedBox.square(
                  dimension: AppSpacing.xl,
                  child: CircularProgressIndicator(
                    strokeWidth: AppSizes.progressStrokeWidth,
                    color: colors.onInverseSurface,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.save, size: 18),
                    const SizedBox(width: AppSpacing.xs),
                    Text(l10n.inventoryReceiptReviewSaveAction),
                  ],
                ),
        ),
      ],
    );
  }
}
