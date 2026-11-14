import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_import_reading.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_shelf.dart';

Map<String, Object?> _item({
  Object? name = 'Milch',
  Object? quantity = 2,
  Object? shelf = 'chilled',
}) => {'name': name, 'quantity': quantity, 'shelf': shelf};

void main() {
  group('ShoppingImportReading.fromJson', () {
    test('reads items, notes and skipped lines', () {
      final reading = ShoppingImportReading.fromJson({
        'items': [
          {..._item(name: ' Hackfleisch '), 'note': ' 500 g ', 'quantity': 1},
          {..._item(), 'note': null},
          _item(name: 'Brot', shelf: 'bakery', quantity: 1),
        ],
        'skipped': ['Einkauf Samstag'],
      });

      expect(reading.lines, hasLength(3));
      expect(reading.lines[0].name, 'Hackfleisch');
      expect(reading.lines[0].note, '500 g');
      expect(reading.lines[1].quantity, 2);
      expect(reading.lines[1].note, isNull);
      expect(reading.lines[1].shelf, ShoppingShelf.chilled);
      expect(reading.lines[2].note, isNull);
      expect(reading.lines[2].shelf, ShoppingShelf.bakery);
      expect(reading.skipped, ['Einkauf Samstag']);
    });

    test('an empty note counts as none', () {
      final reading = ShoppingImportReading.fromJson({
        'items': [
          {..._item(), 'note': '  '},
        ],
        'skipped': <Object?>[],
      });

      expect(reading.lines.single.note, isNull);
    });

    final wrongShapes = <String, Object?>{
      'not a map': ['Milch'],
      'items missing': {'skipped': <Object?>[]},
      'skipped missing': {'items': <Object?>[]},
      'item not a map': {
        'items': ['Milch'],
        'skipped': <Object?>[],
      },
      'name missing': {
        'items': [
          {'quantity': 1, 'shelf': 'chilled'},
        ],
        'skipped': <Object?>[],
      },
      'blank name': {
        'items': [_item(name: '  ')],
        'skipped': <Object?>[],
      },
      'quantity as a double': {
        'items': [_item(quantity: 2.0)],
        'skipped': <Object?>[],
      },
      'quantity as a string': {
        'items': [_item(quantity: '2')],
        'skipped': <Object?>[],
      },
      'quantity zero': {
        'items': [_item(quantity: 0)],
        'skipped': <Object?>[],
      },
      'unknown shelf': {
        'items': [_item(shelf: 'garden')],
        'skipped': <Object?>[],
      },
      'note as a number': {
        'items': [
          {..._item(), 'note': 500},
        ],
        'skipped': <Object?>[],
      },
      'skipped line not a string': {
        'items': <Object?>[],
        'skipped': [3],
      },
    };
    for (final MapEntry(key: name, value: json) in wrongShapes.entries) {
      test('throws a FormatException for $name', () {
        expect(
          () => ShoppingImportReading.fromJson(json),
          throwsFormatException,
        );
      });
    }
  });

  test('shoppingImportLineCount counts the lines that hold something', () {
    expect(shoppingImportLineCount(''), 0);
    expect(shoppingImportLineCount('Milch\n\n  \n2 Brot\nEier'), 3);
  });
}
