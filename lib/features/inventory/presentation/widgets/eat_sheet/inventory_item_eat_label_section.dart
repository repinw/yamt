import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/nutrition_facts_rows.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_state.dart';
import 'package:yamt/features/inventory/presentation/formatters/inventory_nutrition_format.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_label_table.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_page_header.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet_l10n.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Head of the item eat page: the item header and its nutrition label.
class InventoryItemEatLabelSection extends StatelessWidget {
  /// Creates the section for [item] in [state].
  const new({required this.item, required this.state, super.key});

  /// The eaten item.
  final InventoryItem item;

  /// The eat page state.
  final InventoryItemEatSheetState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final calculator = state.calculator;
    final nutrition = state.nutrition;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.xxl,
      children: [
        EatPageHeader(
          title: item.name,
          brand: item.brand,
          caption: calculator.hasOpenStock
              ? null
              : l10n.eatPageInStock(state.stockLabel(l10n)),
          imageUrl: item.imageUrl,
          fallbackKey: const Key('inventory_item_eat_sheet_hero_fallback'),
        ),
        if (nutrition != null)
          EatLabelTable(
            key: const Key('inventory_item_nutrition_table'),
            rows: nutritionFactsRows(
              context,
              eaten: nutrition.eaten,
              per100: nutrition.per100,
              unknownEaten: l10n.eatPageAmountUnknown,
            ),
            per100Header: l10n.caloriesEntryPer100Label(
              state.nutritionUnit(l10n),
            ),
            eatenHeader: switch (nutrition.amount) {
              final amount? => l10n.inventoryEatSheetAmountWithUnit(
                formatInventoryNutritionValue(amount),
                state.nutritionUnit(l10n),
              ),
              null => l10n.eatPageAmountUnknown,
            },
          ),
      ],
    );
  }
}
