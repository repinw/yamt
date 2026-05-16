import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_models.dart'
    as models;
import 'package:yamt/l10n/app_localizations.dart';

/// Action selector for manual product completion.
class ManualProductActionSelector extends StatelessWidget {
  /// Creates an action selector.
  const ManualProductActionSelector({
    required this.selectedAction,
    this.onChanged,
    super.key,
  });

  /// Selected action.
  final models.InventoryReceiptManualProductAction selectedAction;

  /// Called when selected action changes.
  final ValueChanged<models.InventoryReceiptManualProductAction>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            key: const Key('receipt_review_manual_inventory_action_button'),
            onPressed: onChanged == null
                ? null
                : () => onChanged!(
                    models.InventoryReceiptManualProductAction.addToInventory,
                  ),
            style: _buttonStyle(
              context: context,
              isSelected:
                  selectedAction ==
                  models.InventoryReceiptManualProductAction.addToInventory,
            ),
            child: Text(l10n.inventoryManualAddResultActionInventory),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: OutlinedButton(
            key: const Key('receipt_review_manual_eat_action_button'),
            onPressed: onChanged == null
                ? null
                : () => onChanged!(
                    models.InventoryReceiptManualProductAction.eatNow,
                  ),
            style: _buttonStyle(
              context: context,
              isSelected:
                  selectedAction ==
                  models.InventoryReceiptManualProductAction.eatNow,
            ),
            child: Text(l10n.inventoryManualAddResultActionEat),
          ),
        ),
      ],
    );
  }

  ButtonStyle _buttonStyle({
    required BuildContext context,
    required bool isSelected,
  }) {
    final colors = Theme.of(context).colorScheme;
    return OutlinedButton.styleFrom(
      backgroundColor: isSelected ? colors.secondaryContainer : null,
      foregroundColor: isSelected ? colors.onSecondaryContainer : null,
      side: BorderSide(
        color: isSelected ? colors.secondary : colors.outlineVariant,
      ),
    );
  }
}
