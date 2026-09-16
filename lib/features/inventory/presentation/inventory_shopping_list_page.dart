import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/inventory/application/inventory_shopping_suggestions.dart';
import 'package:yamt/features/shoppinglist/presentation/shopping_list_page.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_suggestions.dart';

/// Finished shopping surface with inventory-owned recommendation input.
class InventoryShoppingListPage extends ConsumerWidget {
  /// Creates the integrated page.
  const InventoryShoppingListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(inventoryShoppingSuggestionsProvider);
    return ShoppingListPage(
      suggestionsSection: ShoppingListSuggestions(
        key: const ValueKey('shopping-suggestions'),
        suggestions: suggestions,
        onRetry: () => ref.invalidate(inventoryShoppingStockProvider),
      ),
    );
  }
}
