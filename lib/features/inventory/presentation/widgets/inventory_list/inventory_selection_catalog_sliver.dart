import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meal_selection_controller.dart';
import 'package:yamt/features/inventory/presentation/inventory_selection_catalog_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Catalog part of the Vorrat selection mode (#654): the foods found in the
/// catalog for the meal, each with a remove button, and a row that searches
/// the catalog for the text of the Vorrat search field.
class InventorySelectionCatalogSliver extends ConsumerWidget {
  /// Creates the sliver for the search text [query].
  const new({required this.query, super.key});

  /// Key of the row that opens the catalog search.
  static const searchKey = Key('inventory_selection_catalog_search');

  /// Key of the row of the catalog food at [index].
  static Key foodKey(int index) => Key('inventory_selection_catalog_$index');

  /// Text of the Vorrat search field; the catalog search starts with it.
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final foods = ref.watch(
      preparedMealSelectionControllerProvider.select(
        (state) => state.catalogFoods,
      ),
    );
    final text = query.trim();
    return SliverPadding(
      padding: responsivePagePadding(context, top: 0, bottom: 0),
      sliver: SliverList.list(
        children: [
          for (final (index, food) in foods.indexed)
            ListTile(
              key: foodKey(index),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_rounded),
              title: Text(food.result.item.name),
              trailing: IconButton(
                tooltip: l10n.inventorySelectionCatalogFoodRemove,
                icon: const Icon(Icons.close_rounded),
                onPressed: () => ref
                    .read(preparedMealSelectionControllerProvider.notifier)
                    .removeCatalogFoodAt(index, food),
              ),
            ),
          ListTile(
            key: searchKey,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.travel_explore_rounded),
            title: Text(
              text.isEmpty
                  ? l10n.inventorySelectionCatalogSearch
                  : l10n.inventorySelectionCatalogSearchQuery(text),
            ),
            onTap: () => InventorySelectionCatalogFlow.search(
              context: context,
              ref: ref,
              query: text,
            ),
          ),
        ],
      ),
    );
  }
}
