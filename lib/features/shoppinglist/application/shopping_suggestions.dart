import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_suggestion.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';

part 'shopping_suggestions.g.dart';

/// Public injection point for recommendations from a data-owning feature.
@Riverpod(dependencies: [])
AsyncValue<List<ShoppingSuggestion>> shoppingSuggestionSource(Ref ref) =>
    const AsyncData([]);

/// Removes products already listed, independently of source loading.
@Riverpod(dependencies: [shoppingSuggestionSource])
AsyncValue<List<ShoppingSuggestion>> shoppingSuggestions(Ref ref) {
  final items = ref.watch(shoppingListControllerProvider).asData?.value ?? [];
  return ref
      .watch(shoppingSuggestionSourceProvider)
      .whenData(
        (suggestions) => suggestions
            .where((suggestion) => !_alreadyListed(items, suggestion))
            .take(6)
            .toList(growable: false),
      );
}

bool _alreadyListed(
  List<ShoppingListItem> items,
  ShoppingSuggestion suggestion,
) => items.any(
  (item) =>
      !item.isArchived &&
      item.name.trim().toLowerCase() == suggestion.name.trim().toLowerCase() &&
      ((item.brand?.trim().isEmpty ?? true) ||
          item.brand?.trim().toLowerCase() ==
              suggestion.brand?.trim().toLowerCase()),
);

/// Public refresh callback supplied alongside the recommendation source.
@Riverpod(dependencies: [])
void Function() shoppingSuggestionRetry(Ref ref) => () {};
