import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_product_candidate_widgets.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Recent manual product list.
class ManualProductRecentItems extends StatelessWidget {
  /// Creates recent item list.
  const ManualProductRecentItems({
    required this.items,
    required this.onSelect,
    super.key,
    this.onStoreSelect,
    this.onEatSelect,
  });

  /// Recent items.
  final List<InventoryItem> items;

  /// Called when an item is selected.
  final ValueChanged<InventoryItem> onSelect;

  /// Called when an item should be stored.
  final ValueChanged<InventoryItem>? onStoreSelect;

  /// Called when an item should be eaten now.
  final ValueChanged<InventoryItem>? onEatSelect;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.inventoryReceiptReviewRecentProductsTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Column(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              Builder(
                builder: (context) {
                  final item = items[index];
                  final inventoryButtonKey = Key(
                    'receipt_review_manual_recent_item_store_button_'
                    '${item.id}',
                  );
                  final eatButtonKey = Key(
                    'receipt_review_manual_recent_item_eat_button_'
                    '${item.id}',
                  );
                  return InventoryProductCandidateTile(
                    key: Key('receipt_review_manual_recent_item_${item.id}'),
                    name: item.name,
                    brand: item.brand,
                    imageUrl: item.imageUrl,
                    packageWeight: item.weight,
                    nutrition: item.nutrition,
                    onTap: () => onSelect(item),
                    trailing: onEatSelect != null
                        ? InventoryProductCandidateActions(
                            inventoryLabel:
                                l10n.inventoryManualAddResultActionInventory,
                            eatLabel: l10n.inventoryManualAddResultActionEat,
                            inventoryButtonKey: inventoryButtonKey,
                            eatButtonKey: eatButtonKey,
                            showInventoryAction: onStoreSelect != null,
                            onInventory: () => onStoreSelect?.call(item),
                            onEat: () => onEatSelect!(item),
                          )
                        : null,
                  );
                },
              ),
              if (index != items.length - 1)
                const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ],
    );
  }
}
