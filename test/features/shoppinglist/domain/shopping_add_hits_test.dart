import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_add_hits.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_catalog.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_suggestion.dart';

ShoppingListItem _item(
  String name, {
  bool isFavorite = false,
  bool isArchived = false,
  bool isDone = false,
}) => ShoppingListItem(
  id: name,
  name: name,
  normalizedName: name.toLowerCase(),
  normalizedBrand: '',
  quantity: isArchived ? 0 : 1,
  estimatedUnitPrice: 0,
  isFavorite: isFavorite,
  isArchived: isArchived,
  isDone: isDone,
);

List<String> _names(List<ShoppingAddHit> hits) => [
  for (final hit in hits) hit.name,
];

void main() {
  test('an empty query offers the saved products that are not to buy', () {
    final hits = shoppingAddHits(
      '',
      items: [
        _item('Bread', isFavorite: true, isArchived: true),
        _item('Milk', isFavorite: true),
        _item('Eggs', isFavorite: true, isDone: true),
        _item('Salt'),
      ],
      suggestions: const [ShoppingSuggestion(name: 'Butter', purchaseCount: 3)],
    );

    expect(_names(hits), ['Bread', 'Eggs']);
    expect(hits.first.source, ShoppingAddHitSource.saved);
  });

  test('a suggestion keeps the planned meal it is for', () {
    final dinner = (day: DateTime(2026, 11, 17), mealType: MealType.dinner);
    final hits = shoppingAddHits(
      'pete',
      items: const [],
      suggestions: [ShoppingSuggestion(name: 'Petersilie', plannedFor: dinner)],
    );

    expect(hits.single.plannedFor, dinner);
  });

  test('a query matches at the start of a word, the name start first, '
      'shorter names first', () {
    final hits = shoppingAddHits(
      ' mi',
      items: [_item('Hafermilch', isFavorite: true, isArchived: true)],
      suggestions: const [
        ShoppingSuggestion(name: 'Mini Mix Nesquick', isOutOfStock: true),
        ShoppingSuggestion(name: 'Minze', isLowStock: true),
        ShoppingSuggestion(name: 'Miso', purchaseCount: 4),
        ShoppingSuggestion(name: 'Yunmi Nuggets', purchaseCount: 2),
        ShoppingSuggestion(name: 'Paprika mix', purchaseCount: 2),
      ],
    );

    expect(_names(hits), ['Miso', 'Minze', 'Mini Mix Nesquick', 'Paprika mix']);
    expect(hits.first.source, ShoppingAddHitSource.purchased);
    expect(hits.first.purchaseCount, 4);
  });

  test('from three letters a query also matches inside a word, saved '
      'products first', () {
    final hits = shoppingAddHits(
      'milch',
      items: [_item('Hafermilch', isFavorite: true, isArchived: true)],
      suggestions: const [
        ShoppingSuggestion(name: 'Vollmilch', isOutOfStock: true),
        ShoppingSuggestion(name: 'Milchreis', purchaseCount: 2),
      ],
    );

    expect(_names(hits), ['Milchreis', 'Hafermilch', 'Vollmilch']);
    expect(hits[1].source, ShoppingAddHitSource.saved);
  });

  test('a typo of four letters or more still finds the product, a short '
      'one finds nothing', () {
    List<String> hitsFor(String query) => _names(
      shoppingAddHits(
        query,
        items: const [],
        suggestions: const [],
        catalog: shoppingCatalogIn('de'),
      ),
    );

    expect(hitsFor('Mlich'), contains('Milch'));
    expect(hitsFor('Joghrut'), contains('Joghurt'));
    // A typo in the start of a longer name, while still typing.
    expect(hitsFor('Banna'), contains('Bananen'));
    expect(hitsFor('Mlc'), isEmpty);
    expect(hitsFor('Glühlampe'), isEmpty);
  });

  test('a product that is to buy is not offered, a saved one wins over its '
      'suggestion', () {
    final hits = shoppingAddHits(
      'm',
      items: [_item('Milk'), _item('Miso', isFavorite: true, isArchived: true)],
      suggestions: const [
        ShoppingSuggestion(name: 'milk', isOutOfStock: true),
        ShoppingSuggestion(name: 'Miso', isOutOfStock: true),
      ],
    );

    expect(_names(hits), ['Miso']);
    expect(hits.single.source, ShoppingAddHitSource.saved);
  });

  test('brands tell two products with one name apart', () {
    final hits = shoppingAddHits(
      'milk',
      items: const [],
      suggestions: const [
        ShoppingSuggestion(name: 'Milk', brand: 'Farm', isLowStock: true),
        ShoppingSuggestion(name: 'Milk', brand: 'Alp', isLowStock: true),
      ],
    );

    expect([for (final hit in hits) hit.brand], ['Farm', 'Alp']);
  });

  test('an entry to buy without a brand keeps every brand of its name out', () {
    final hits = shoppingAddHits(
      'milk',
      items: [_item('Milk')],
      suggestions: const [
        ShoppingSuggestion(name: 'Milk', brand: 'Farm', isLowStock: true),
      ],
    );

    expect(hits, isEmpty);
  });

  test('a product without a brand named as typed is not offered twice', () {
    final hits = shoppingAddHits(
      'Milk ',
      items: [_item('milk', isFavorite: true, isArchived: true)],
      suggestions: const [
        ShoppingSuggestion(name: 'Milk', brand: 'Farm', isLowStock: true),
      ],
    );

    expect([for (final hit in hits) hit.brand], ['Farm']);
  });
}
