import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/shoppinglist/application/shopping_suggestions.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_suggestion.dart';

ShoppingListItem _milk({bool isDone = false, bool isArchived = false}) =>
    ShoppingListItem(
      id: 'milk',
      name: 'Milk',
      normalizedName: 'milk',
      normalizedBrand: '',
      quantity: isArchived ? 0 : 1,
      estimatedUnitPrice: 0,
      isFavorite: isArchived,
      isDone: isDone,
      isArchived: isArchived,
    );

const _suggestion = ShoppingSuggestion(
  name: ' milk ',
  purchaseCount: 2,
  isOutOfStock: true,
);

void main() {
  test('a suggestion is listed while its entry is still to buy', () {
    expect(isSuggestionAlreadyListed([_milk()], _suggestion), isTrue);
  });

  test('a suggestion comes back once its entry is in the cart or archived', () {
    expect(
      isSuggestionAlreadyListed([_milk(isDone: true)], _suggestion),
      isFalse,
    );
    expect(
      isSuggestionAlreadyListed([_milk(isArchived: true)], _suggestion),
      isFalse,
    );
  });
}
