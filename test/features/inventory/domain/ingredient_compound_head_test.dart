import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/ingredient_compound_head.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

InventoryItem _item({required String id, required String name}) =>
    InventoryItem.create(
      id: id,
      name: name,
      entryDate: DateTime.utc(2026, 10),
      storeName: 'Store',
      quantity: 1,
    );

void main() {
  test('a food only at the start of a compound matches weakly (#842)', () {
    bool weak(String ingredient, String name) => isWeakIngredientMatch(
      ingredient: ingredient,
      item: _item(id: name, name: name),
    );

    // The item names another food after it, or the line after the item.
    expect(weak('100 g Reis', 'Reiswaffeln'), isTrue);
    expect(weak('100 g Reis', 'Reis-Waffeln'), isTrue);
    expect(weak('2 Eier', 'Eiernudeln'), isTrue);
    expect(weak('1 Ei', 'Eiernudeln'), isTrue);
    expect(weak('300 ml Milch', 'Milchschokolade'), isTrue);
    expect(weak('200 g Milchreis', 'Milch'), isTrue);
    expect(weak('500 g Kartoffeln', 'Kartoffelpüree'), isTrue);
    expect(weak('100 g Mais', 'Maisöl'), isTrue);
    // A cut is weak too: the cook picks it once.
    expect(weak('200 g Hering', 'Heringsfilet'), isTrue);
    expect(weak('50 g Hafer', 'Haferflocken'), isTrue);
    expect(weak('200 g Hähnchen', 'Hähnchenbrust'), isTrue);
    // The food as the last part, an ending, an amount word, a number, or
    // several words are not.
    expect(weak('2 Knoblauchzehen', 'Knoblauch'), isFalse);
    expect(weak('1 Knoblauch', 'Knoblauchzehen'), isFalse);
    expect(weak('400 g Tomaten', 'Tomatenstücke'), isFalse);
    expect(weak('2 EL Reis', 'Reiswaffeln'), isTrue);
    expect(weak('200 g Milchreis', 'Bio Milch'), isTrue);
    expect(weak('100 g Reis', 'Basmatireis'), isFalse);
    expect(weak('300 ml Milch', 'Milch3,5%'), isFalse);
    expect(weak('2 Karotte', 'Karotten'), isFalse);
    expect(weak('100 g Reis', 'Reis'), isFalse);
    expect(weak('100 g Test Reis', 'Testreis'), isFalse);
    // Known limit (#891): the last part fits, so these are no weak match.
    expect(weak('300 ml Milch', 'Buttermilch'), isFalse);
    expect(weak('100 g Reis', 'Milchreis'), isFalse);
  });
}
