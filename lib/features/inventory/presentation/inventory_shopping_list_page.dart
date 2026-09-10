import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/inventory/application/inventory_shopping_suggestions.dart';
import 'package:yamt/features/shoppinglist/application/shopping_suggestions.dart';
import 'package:yamt/features/shoppinglist/presentation/shopping_list_page.dart';

/// Finished shopping surface with inventory-owned recommendation input.
@Dependencies([inventoryShoppingSuggestions])
class InventoryShoppingListPage extends ConsumerWidget {
  /// Creates the integrated page.
  const InventoryShoppingListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(inventoryShoppingSuggestionsProvider);
    return ProviderScope(
      overrides: [
        shoppingSuggestionSourceProvider.overrideWithValue(suggestions),
        shoppingSuggestionRetryProvider.overrideWithValue(
          () => ref.invalidate(inventoryShoppingStockProvider),
        ),
      ],
      child: const ShoppingListPage(),
    );
  }
}
