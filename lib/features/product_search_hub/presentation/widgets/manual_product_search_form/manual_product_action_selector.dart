import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_chip.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Chips that choose whether the product goes to the Vorrat or is eaten.
class ManualProductActionSelector extends StatelessWidget {
  /// Creates the chips.
  const new({required this.selectedAction, required this.onChanged, super.key});

  /// Selected action.
  final InventoryReceiptManualProductAction selectedAction;

  /// Called with the chosen action.
  final ValueChanged<InventoryReceiptManualProductAction> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        EatChip(
          key: const Key('receipt_review_manual_inventory_action_button'),
          label: l10n.inventoryManualAddResultActionInventory,
          isSelected:
              selectedAction ==
              InventoryReceiptManualProductAction.addToInventory,
          onPressed: () =>
              onChanged(InventoryReceiptManualProductAction.addToInventory),
        ),
        EatChip(
          key: const Key('receipt_review_manual_eat_action_button'),
          label: l10n.inventoryManualAddResultActionEat,
          isSelected:
              selectedAction == InventoryReceiptManualProductAction.eatNow,
          onPressed: () =>
              onChanged(InventoryReceiptManualProductAction.eatNow),
        ),
      ],
    );
  }
}
