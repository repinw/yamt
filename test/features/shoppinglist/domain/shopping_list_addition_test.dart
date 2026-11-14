import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_addition.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_planned_meal.dart';

const _addition = ShoppingListAddition();

ShoppingListItem _milk({
  required int quantity,
  bool isDone = false,
  bool isArchived = false,
}) => ShoppingListItem(
  id: 'milk',
  name: 'Milk',
  normalizedName: 'milk',
  normalizedBrand: '',
  quantity: quantity,
  estimatedUnitPrice: 0,
  isFavorite: isArchived,
  isDone: isDone,
  isArchived: isArchived,
);

ShoppingListItem _addTwoTo(ShoppingListItem current) => _addition
    .mergeAddedItem(
      previousItems: [current],
      input: _addition.parseAddItemInput(
        name: ' milk ',
        quantity: 2,
        estimatedUnitPrice: 0,
      )!,
      generatedId: 'new',
    )
    .single;

void main() {
  test('adding to an entry that is still to buy puts the quantity on top', () {
    final merged = _addTwoTo(_milk(quantity: 3));

    expect((merged.id, merged.quantity, merged.isDone), ('milk', 5, false));
  });

  test('adding to an entry in the cart brings it back with the new '
      'quantity alone', () {
    final merged = _addTwoTo(_milk(quantity: 3, isDone: true));

    expect((merged.id, merged.quantity, merged.isDone), ('milk', 2, false));
  });

  test('adding to an archived saved product puts it back on the list', () {
    final merged = _addTwoTo(_milk(quantity: 0, isArchived: true));

    expect(
      (merged.quantity, merged.isArchived, merged.isFavorite),
      (2, false, true),
    );
  });

  test('an entry in the cart comes back without its old note', () {
    final merged = _addTwoTo(
      _milk(quantity: 3, isDone: true).copyWith(note: 'laktosefrei'),
    );

    expect(merged.note, isNull);
  });

  test('an entry still to buy keeps its note when more is added', () {
    final merged = _addTwoTo(_milk(quantity: 3).copyWith(note: 'laktosefrei'));

    expect(merged.note, 'laktosefrei');
  });

  test('an entry in the cart comes back without its old planned meal', () {
    final merged = _addTwoTo(
      _milk(quantity: 3, isDone: true).copyWith(plannedFor: _thursdayBreakfast),
    );

    expect(merged.plannedFor, isNull);
  });

  test('a planned meal of the addition replaces the old one', () {
    final merged = _addition
        .mergeAddedItem(
          previousItems: [
            _milk(quantity: 1).copyWith(plannedFor: _thursdayBreakfast),
          ],
          input: _addition.parseAddItemInput(
            name: 'Milk',
            quantity: 1,
            estimatedUnitPrice: 0,
            plannedFor: (day: DateTime(2026, 11, 20), mealType: MealType.lunch),
          )!,
          generatedId: 'new',
        )
        .single;

    expect(merged.plannedFor, (
      day: DateTime(2026, 11, 20),
      mealType: MealType.lunch,
    ));
  });
}

final ShoppingPlannedMeal _thursdayBreakfast = (
  day: DateTime(2026, 11, 19),
  mealType: MealType.breakfast,
);
