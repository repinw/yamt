import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_action_picker_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines high-level inventory item removal choices.
enum InventoryItemRemovalChoice {
  /// The item was thrown away and should count as waste.
  discarded,

  /// The item was used elsewhere and should only reduce stock.
  consumedElsewhere,

  /// The item should be removed completely without stock tracking.
  deleteCompletely,
}

/// Shows the inventory item removal dialog.
Future<InventoryItemRemovalChoice?> showInventoryItemRemoveDialog(
  BuildContext context, {
  required String itemName,
  required bool canReduceAmount,
  bool useRootNavigator = true,
}) {
  return showInventoryActionPickerSheet<InventoryItemRemovalChoice>(
    context,
    useRootNavigator: useRootNavigator,
    builder: (dialogContext) {
      return _InventoryItemRemoveDialog(
        itemName: itemName,
        canReduceAmount: canReduceAmount,
        useRootNavigator: useRootNavigator,
      );
    },
  );
}

class _InventoryItemRemoveDialog extends StatelessWidget {
  const _InventoryItemRemoveDialog({
    required this.itemName,
    required this.canReduceAmount,
    required this.useRootNavigator,
  });

  final String itemName;
  final bool canReduceAmount;
  final bool useRootNavigator;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return InventoryActionPickerSheet(
      title: l10n.inventoryItemRemoveDialogTitle,
      subtitle: l10n.inventoryItemRemoveDialogMessage(itemName),
      onClose: () => Navigator.of(
        context,
        rootNavigator: useRootNavigator,
      ).pop(),
      footer: Center(
        child: TextButton(
          onPressed: () => Navigator.of(
            context,
            rootNavigator: useRootNavigator,
          ).pop(),
          child: Text(l10n.inventoryReceiptReviewCancelAction),
        ),
      ),
      children: [
        if (canReduceAmount) ...[
          _InventoryItemRemoveOption(
            icon: Icons.delete_outline_rounded,
            title: l10n.inventoryItemRemoveDiscardAction,
            subtitle: l10n.inventoryItemRemoveDiscardSubtitle,
            foregroundColor: colors.error,
            backgroundColor: colors.errorContainer.withValues(alpha: 0.5),
            onPressed: () =>
                _close(context, InventoryItemRemovalChoice.discarded),
          ),
          const SizedBox(height: AppSpacing.sm),
          _InventoryItemRemoveOption(
            icon: Icons.restaurant_rounded,
            title: l10n.inventoryItemRemoveConsumeElsewhereAction,
            subtitle: l10n.inventoryItemRemoveConsumeElsewhereSubtitle,
            foregroundColor: colors.primary,
            backgroundColor: colors.primaryContainer.withValues(alpha: 0.45),
            onPressed: () => _close(
              context,
              InventoryItemRemovalChoice.consumedElsewhere,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        _InventoryItemRemoveOption(
          icon: Icons.close_rounded,
          title: l10n.inventoryItemRemoveDeleteAction,
          subtitle: l10n.inventoryItemRemoveDeleteSubtitle,
          foregroundColor: colors.onSurfaceVariant,
          backgroundColor: colors.surfaceContainerHigh,
          onPressed: () => _close(
            context,
            InventoryItemRemovalChoice.deleteCompletely,
          ),
        ),
      ],
    );
  }

  void _close(BuildContext context, InventoryItemRemovalChoice choice) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context, rootNavigator: useRootNavigator).pop(choice);
  }
}

class _InventoryItemRemoveOption extends StatelessWidget {
  const _InventoryItemRemoveOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color foregroundColor;
  final Color backgroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              InventoryActionPickerOptionIcon(
                icon: icon,
                foregroundColor: foregroundColor,
                backgroundColor: backgroundColor,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: foregroundColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: foregroundColor.withValues(alpha: 0.78),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
