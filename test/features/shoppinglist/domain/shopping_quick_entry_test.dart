import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_quick_entry.dart';

void main() {
  test('plain text asks for one', () {
    expect(parseShoppingQuickEntry('  Milch '), (quantity: 1, text: 'Milch'));
  });

  test('a leading count is the quantity', () {
    expect(parseShoppingQuickEntry('2 mi'), (quantity: 2, text: 'mi'));
    expect(parseShoppingQuickEntry('3x Eier'), (quantity: 3, text: 'Eier'));
    expect(parseShoppingQuickEntry('12 × Wasser'), (
      quantity: 12,
      text: 'Wasser',
    ));
  });

  test('a number in front of a unit stays in the text', () {
    expect(parseShoppingQuickEntry('500 g Hackfleisch'), (
      quantity: 1,
      text: '500 g Hackfleisch',
    ));
    expect(parseShoppingQuickEntry('2 kg Kartoffeln'), (
      quantity: 1,
      text: '2 kg Kartoffeln',
    ));
    expect(parseShoppingQuickEntry('1 L Milch'), (
      quantity: 1,
      text: '1 L Milch',
    ));
  });

  test('a word that only starts like a unit is a product', () {
    expect(parseShoppingQuickEntry('2 Gurken'), (quantity: 2, text: 'Gurken'));
    expect(parseShoppingQuickEntry('2 Limetten'), (
      quantity: 2,
      text: 'Limetten',
    ));
  });

  test('a number alone, zero, or a product that starts with digits stays '
      'text', () {
    expect(parseShoppingQuickEntry('2'), (quantity: 1, text: '2'));
    expect(parseShoppingQuickEntry('0 Milch'), (quantity: 1, text: '0 Milch'));
    expect(parseShoppingQuickEntry('7up'), (quantity: 1, text: '7up'));
    expect(parseShoppingQuickEntry('100 Blatt'), (
      quantity: 1,
      text: '100 Blatt',
    ));
  });

  test('a unit word ends at a space, also before umlauts', () {
    expect(parseShoppingQuickEntry('2 l Öl'), (quantity: 1, text: '2 l Öl'));
    expect(parseShoppingQuickEntry('2 Liter Milch'), (
      quantity: 1,
      text: '2 Liter Milch',
    ));
    expect(parseShoppingQuickEntry('2 Lüftchen'), (
      quantity: 2,
      text: 'Lüftchen',
    ));
    expect(parseShoppingQuickEntry('3 Gläser'), (quantity: 3, text: 'Gläser'));
  });
}
