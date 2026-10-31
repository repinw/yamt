import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/inventory/application/inventory_plan_demand_provider.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_entry.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_entry_row.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Key of the button that eats without taking stock.
const inventoryPackChoiceSkipKey = Key('inventory_pack_choice_skip');

/// Key of the row of the pack [itemId].
Key inventoryPackChoiceRowKey(String itemId) =>
    ValueKey<String>('inventory_pack_choice_$itemId');

/// The answer to [showInventoryPackChoiceSheet].
sealed class InventoryPackChoice {
  const new();
}

/// The stock comes from [item].
final class InventoryPackChosen extends InventoryPackChoice {
  /// Creates the choice of [item].
  const new(this.item);

  /// The pack to take the stock from.
  final InventoryItem item;
}

/// The food is eaten without taking stock.
final class InventoryPackSkipped extends InventoryPackChoice {
  /// Creates the choice to take no stock.
  const new();
}

/// Asks from which of [packs], packs of the food being eaten, the stock
/// comes, or whether none gives it. Each pack shows as its Vorrat row, with
/// what open plans keep of it. Returns null when the sheet is dismissed.
Future<InventoryPackChoice?> showInventoryPackChoiceSheet(
  BuildContext context, {
  required List<InventoryItem> packs,
}) {
  return showModalBottomSheet<InventoryPackChoice>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: FoodLabelColors.of(context).card,
    showDragHandle: true,
    builder: (sheetContext) => _PackChoiceSheet(
      packs: packs,
      onChoice: (choice) => Navigator.of(sheetContext).pop(choice),
    ),
  );
}

class _PackChoiceSheet extends ConsumerWidget {
  const new({required this.packs, required this.onChoice});

  final List<InventoryItem> packs;
  final ValueChanged<InventoryPackChoice> onChoice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demand = ref.watch(openPlanDemandProvider).value;
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.inventoryPackChoiceTitle,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(color: colors.ink, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.md),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (index, pack) in packs.indexed)
                    InventoryEntryRow(
                      key: inventoryPackChoiceRowKey(pack.id),
                      entry: InventoryFoodEntry(pack),
                      tiltLeft: index.isEven,
                      planned: demand?.plannedByItemId[pack.id] ?? 0,
                      missing: demand?.missingByItemId[pack.id] ?? 0,
                      onTap: () => onChoice(InventoryPackChosen(pack)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.tonal(
            key: inventoryPackChoiceSkipKey,
            onPressed: () => onChoice(const InventoryPackSkipped()),
            child: Text(l10n.inventoryPackChoiceSkip),
          ),
        ],
      ),
    );
  }
}
