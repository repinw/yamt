import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/application/inventory_plan_demand_provider.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/application/inventory_shopping_suggestions.dart';
import 'package:yamt/features/shoppinglist/presentation/shopping_list_page.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_plan_needs.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_suggestions.dart';

/// Finished shopping surface with inventory-owned recommendation input.
class InventoryShoppingListPage extends ConsumerWidget {
  /// Creates the integrated page.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(inventoryShoppingSuggestionsProvider);
    return ShoppingListPage(
      suggestionsSection: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShoppingListPlanNeeds(
            groups: ref.watch(inventoryShoppingPlanNeedGroupsProvider),
            onRetry: () => ref
              ..invalidate(openPlansProvider)
              ..invalidate(inventoryQuickEatItemsProvider),
          ),
          ShoppingListSuggestions(
            key: const ValueKey('shopping-suggestions'),
            suggestions: suggestions,
            onRetry: () => ref.invalidate(inventoryShoppingStockProvider),
          ),
        ],
      ),
    );
  }
}
