import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/features/shoppinglist/application/shopping_list_operations.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_addition.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';

part 'shopping_list_names_service.g.dart';

/// Puts products on the shopping list by name for later features.
class ShoppingListNamesService {
  /// Creates the service that writes through the shopping list repository.
  const new(this._repository);

  final ShoppingListRepository _repository;

  static const _addition = ShoppingListAddition();
  static const _uuid = Uuid();

  /// Adds the [names] that are not on the list yet, one of each, in one
  /// write. Throws when the list cannot be read or written, so a failed
  /// read never replaces the list.
  Future<void> addMissing(Iterable<String> names) async {
    final items = await _repository.readAll();
    final listed = computeActiveShoppingListItemKeys(items);
    final inputs = [
      for (final name in names)
        if (!isSourceItemInActiveShoppingList(
          item: (name: name, brand: null, initialQuantity: 1, unitPrice: 0),
          activeItemKeys: listed,
        ))
          ?_addition.parseAddItemInput(
            name: name,
            quantity: 1,
            estimatedUnitPrice: 0,
          ),
    ];
    if (inputs.isEmpty) {
      return;
    }
    final saved = await _repository.saveAll(
      inputs.fold<List<ShoppingListItem>>(
        items,
        (list, input) => _addition.mergeAddedItem(
          previousItems: list,
          input: input,
          generatedId: _uuid.v4(),
        ),
      ),
    );
    if (!saved) {
      throw StateError('The shopping list could not be saved.');
    }
  }
}

/// The service on the household's shopping list.
@riverpod
ShoppingListNamesService shoppingListNamesService(Ref ref) =>
    ShoppingListNamesService(ref.watch(shoppingListRepositoryProvider));
