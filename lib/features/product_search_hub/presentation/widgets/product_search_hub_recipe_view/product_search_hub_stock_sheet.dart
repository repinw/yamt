import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/presentation/widgets/stock_amount_text.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'product_search_hub_stock_foods.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_recipe_view/product_search_hub_recipe_rows.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _initialSheetSize = 0.85;

/// The grey line of a Vorrat food in the recipe food pick: its brand and
/// what the Vorrat holds, such as "Hausmarke · 750 g da".
String recipeStockLine(AppLocalizations l10n, InventoryItem item) {
  final stock = l10n.recipeFoodInStock(
    stockAmountText(
      l10n,
      amount: item.availableAmount,
      unit: item.amountUnit ?? InventoryAmountUnit.piece,
      scale: item.amountUnit == null ? 1 : item.amountScale,
    ),
  );
  final brand = item.brand?.trim() ?? '';
  return brand.isEmpty ? stock : l10n.recipeFoodBrandAndSize(brand, stock);
}

/// The whole Vorrat to pick one food from, for "Aus dem Vorrat nehmen",
/// without the foods that have nothing left for the line.
class RecipeStockSheet extends ConsumerWidget {
  const new _({required this.held});

  /// The ids of the foods that have nothing left for the line, joined by
  /// commas (`productSearchHubStockFoodsProvider`).
  final String held;

  /// Key of the sheet's list.
  static const listKey = Key('product_search_hub_recipe_stock_sheet_list');

  /// Shows the sheet without the [held] foods; returns the picked food, or
  /// null.
  static Future<InventoryItem?> show(
    BuildContext context, {
    required String held,
  }) => showModalBottomSheet<InventoryItem>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: FoodLabelColors.of(context).paper,
    builder: (_) => RecipeStockSheet._(held: held),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final foods = ref.watch(productSearchHubStockFoodsProvider('', held));
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: _initialSheetSize,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Text(
                l10n.recipeFoodStockSheetTitle,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(color: colors.ink, fontWeight: FontWeight.w800),
              ),
            ),
            Expanded(
              child: foods.when(
                data: (items) => items.isEmpty
                    ? RecipeListNote(text: l10n.recipeFoodStockEmpty)
                    : ListView.builder(
                        key: listKey,
                        controller: scrollController,
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return RecipeFoodRow(
                            key: ValueKey(item.id),
                            title: item.name,
                            subtitle: recipeStockLine(l10n, item),
                            imageUrl: item.imageUrl,
                            onTap: () => Navigator.of(context).pop(item),
                          );
                        },
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) =>
                    RecipeListNote(text: l10n.recipeFoodStockLoadFailed),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
