import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/shoppinglist/application/shopping_suggestions.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_scope.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_plan_need.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_suggestion.dart';

ShoppingListItem _milk({
  bool isDone = false,
  bool isArchived = false,
  bool isPrivate = false,
}) => ShoppingListItem(
  id: 'milk',
  name: 'Milk',
  normalizedName: 'milk',
  normalizedBrand: '',
  quantity: isArchived ? 0 : 1,
  estimatedUnitPrice: 0,
  isFavorite: isArchived,
  isDone: isDone,
  isArchived: isArchived,
  isPrivate: isPrivate,
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

  test('visible suggestions leave out listed products and put pushed back '
      'ones last', () {
    const oats = ShoppingSuggestion(name: 'Oats');
    const butter = ShoppingSuggestion(name: 'Butter');

    final visible = visibleShoppingSuggestions(
      [_suggestion, oats, butter],
      items: [_milk()],
      scope: ShoppingListScope.household,
      pushedBack: const ['oats|'],
    );

    expect(
      [for (final suggestion in visible) suggestion.name],
      ['Butter', 'Oats'],
    );
  });

  test('only the list shown hides a suggestion', () {
    final privateMilk = _milk(isPrivate: true);
    List<String> names(ShoppingListScope scope) => [
      for (final suggestion in visibleShoppingSuggestions(
        [_suggestion],
        items: [privateMilk],
        scope: scope,
        pushedBack: const [],
      ))
        suggestion.name,
    ];

    expect(names(ShoppingListScope.household), [' milk ']);
    expect(names(ShoppingListScope.private), isEmpty);
    expect(names(ShoppingListScope.both), isEmpty);
  });

  group('shoppingSuggestionsWithPlan', () {
    final wednesday = DateTime(2026, 10, 7);
    final thursday = DateTime(2026, 10, 8);
    ShoppingPlanNeed need(String name, DateTime day) => ShoppingPlanNeed(
      name: name,
      day: day,
      mealType: MealType.breakfast,
      amount: 100,
      inMilliliters: false,
      isPartial: false,
    );

    test('puts plan needs first, once per food, for the first meal', () {
      final merged = shoppingSuggestionsWithPlan(
        [
          (
            day: wednesday,
            mealType: MealType.breakfast,
            needs: [need('Oats', wednesday)],
          ),
          (
            day: thursday,
            mealType: MealType.dinner,
            needs: [need('oats', thursday), need('Rice', thursday)],
          ),
        ],
        const [
          ShoppingSuggestion(name: 'Bread', purchaseCount: 3),
          ShoppingSuggestion(name: 'Oats', isOutOfStock: true),
        ],
      );

      expect(merged.map((s) => s.name), ['Oats', 'Rice', 'Bread']);
      expect(merged.first.plannedFor, (
        day: wednesday,
        mealType: MealType.breakfast,
      ));
      expect(merged.first.isOutOfStock, isTrue);
      expect(merged[1].plannedFor?.mealType, MealType.dinner);
      expect(merged.last.plannedFor, isNull);
    });

    test('without plans keeps the suggestions as they are', () {
      const bread = ShoppingSuggestion(name: 'Bread');
      expect(shoppingSuggestionsWithPlan(const [], const [bread]), [bread]);
    });
  });
}
