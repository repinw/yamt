import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_add_hits.dart';
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

  test('a query matches saved products and suggestions by part of the name, '
      'starts first', () {
    final hits = shoppingAddHits(
      ' mi',
      items: [_item('Hafermilch', isFavorite: true, isArchived: true)],
      suggestions: const [
        ShoppingSuggestion(name: 'Vollmilch', isOutOfStock: true),
        ShoppingSuggestion(name: 'Minze', isLowStock: true),
        ShoppingSuggestion(name: 'Miso', purchaseCount: 4),
        ShoppingSuggestion(name: 'Butter', purchaseCount: 2),
      ],
    );

    expect(_names(hits), ['Minze', 'Miso', 'Hafermilch', 'Vollmilch']);
    expect(
      [for (final hit in hits) hit.source],
      [
        ShoppingAddHitSource.lowStock,
        ShoppingAddHitSource.purchased,
        ShoppingAddHitSource.saved,
        ShoppingAddHitSource.outOfStock,
      ],
    );
    expect(hits[1].purchaseCount, 4);
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
