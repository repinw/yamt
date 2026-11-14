import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_suggestion.dart';

ShoppingSuggestion _eggs() => ShoppingSuggestion(
  name: 'Eier',
  purchaseCount: 2,
  plannedFor: (day: DateTime(2026, 11, 16), mealType: MealType.breakfast),
);

void main() {
  test('lists of the same suggestions are equal, so they key one provider', () {
    expect(
      ShoppingSuggestionList([_eggs()]),
      ShoppingSuggestionList([_eggs()]),
    );
    expect(
      ShoppingSuggestionList([_eggs()]).hashCode,
      ShoppingSuggestionList([_eggs()]).hashCode,
    );
    expect(
      ShoppingSuggestionList([_eggs()]),
      isNot(ShoppingSuggestionList(const [ShoppingSuggestion(name: 'Eier')])),
    );
  });
}
