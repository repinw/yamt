import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_line_split.dart';

void main() {
  test('the amount in front of the product becomes the note', () {
    expect(splitShoppingLine('1 mittlere Zwiebel'), (
      name: 'Zwiebel',
      note: '1 mittlere',
      quantity: 1,
    ));
    expect(splitShoppingLine('600 g Karotten'), (
      name: 'Karotten',
      note: '600 g',
      quantity: 1,
    ));
    expect(splitShoppingLine('2 EL Olivenöl'), (
      name: 'Olivenöl',
      note: '2 EL',
      quantity: 1,
    ));
    expect(splitShoppingLine('½ Bund Petersilie'), (
      name: 'Petersilie',
      note: '½ Bund',
      quantity: 1,
    ));
    expect(splitShoppingLine('1,5 l Milch'), (
      name: 'Milch',
      note: '1,5 l',
      quantity: 1,
    ));
  });

  test('a bare count becomes the quantity', () {
    expect(splitShoppingLine('2 Zwiebeln'), (
      name: 'Zwiebeln',
      note: null,
      quantity: 2,
    ));
    expect(splitShoppingLine('1 Zwiebel'), (
      name: 'Zwiebel',
      note: null,
      quantity: 1,
    ));
  });

  test('a written-out unit stays in the note, not in the name', () {
    expect(splitShoppingLine('2 Esslöffel Olivenöl'), (
      name: 'Olivenöl',
      note: '2 Esslöffel',
      quantity: 1,
    ));
    expect(splitShoppingLine('100 Gramm Mehl'), (
      name: 'Mehl',
      note: '100 Gramm',
      quantity: 1,
    ));
  });

  test('a line without an amount, or only an amount, stays whole', () {
    const salt = (name: 'Salz', note: null, quantity: 1);
    expect(splitShoppingLine(' Salz '), salt);
    expect(splitShoppingLine('Milch 3,5 %'), (
      name: 'Milch 3,5 %',
      note: null,
      quantity: 1,
    ));
    expect(splitShoppingLine('500 g'), (
      name: '500 g',
      note: null,
      quantity: 1,
    ));
  });
}
