import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_catalog.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_import_reading.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_import_review.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_shelf.dart';

ShoppingListItem _item(
  String name, {
  int quantity = 1,
  bool isDone = false,
  bool isArchived = false,
}) => ShoppingListItem(
  id: name,
  name: name,
  normalizedName: name.toLowerCase(),
  normalizedBrand: '',
  quantity: quantity,
  estimatedUnitPrice: 0,
  isDone: isDone,
  isArchived: isArchived,
);

ShoppingImportLine _line(
  String name, {
  ShoppingShelf shelf = ShoppingShelf.other,
  int quantity = 1,
  String? note,
}) => ShoppingImportLine(
  name: name,
  quantity: quantity,
  shelf: shelf,
  note: note,
);

ShoppingImportReview _review(
  List<ShoppingImportLine> lines, {
  List<ShoppingListItem> items = const [],
}) => ShoppingImportReview.of(
  ShoppingImportReading(lines: lines, skipped: const ['Hallo']),
  items,
);

void main() {
  group('ShoppingImportRow.of', () {
    test('the catalog shelf wins over the shelf the reader guessed', () {
      final known = lookUpShoppingCatalog('Milch')!;
      expect(known.shelf, isNot(ShoppingShelf.household));

      final row = ShoppingImportRow.of(
        _line('Milch', shelf: ShoppingShelf.household),
        const [],
      );

      expect(row.shelf, known.shelf);
      expect(row.icon, known.icon);
      expect(row.isShelfKnown, isTrue);
    });

    test('a product the catalog does not know takes the guessed shelf', () {
      final row = ShoppingImportRow.of(
        _line('Qwrtz', shelf: ShoppingShelf.produce),
        const [],
      );

      expect(row.shelf, ShoppingShelf.produce);
      expect(row.icon, shoppingShelfIcon(ShoppingShelf.produce));
      expect(row.isShelfKnown, isTrue);
    });

    test('a product neither knows goes under other, not known', () {
      final row = ShoppingImportRow.of(_line('Qwrtz'), const []);

      expect(row.shelf, ShoppingShelf.other);
      expect(row.isShelfKnown, isFalse);
    });

    test('a new product starts selected and not listed', () {
      final row = ShoppingImportRow.of(_line('Qwrtz'), [_item('Brot')]);

      expect(row.isSelected, isTrue);
      expect(row.listedQuantity, isNull);
    });

    test('a product still to buy, in any case, starts unselected', () {
      final row = ShoppingImportRow.of(_line('MILCH'), [
        _item('Milch', quantity: 2),
      ]);

      expect(row.isSelected, isFalse);
      expect(row.listedQuantity, 2);
    });

    test('a product in the cart or archived does not count as listed', () {
      final items = [
        _item('Milch', isDone: true),
        _item('Brot', isArchived: true),
      ];

      for (final name in ['Milch', 'Brot']) {
        final row = ShoppingImportRow.of(_line(name), items);
        expect(row.isSelected, isTrue, reason: name);
        expect(row.listedQuantity, isNull, reason: name);
      }
    });
  });

  group('ShoppingImportReview', () {
    test('keeps the skipped lines and selects the new products', () {
      final review = _review(
        [_line('Qwrtz', quantity: 2, note: '500 g'), _line('Milch')],
        items: [_item('Milch')],
      );

      expect(review.skipped, ['Hallo']);
      expect(review.selectedLines.map((line) => line.name), ['Qwrtz']);
      expect(review.selectedLines.single.note, '500 g');
      expect(review.selectedLines.single.quantity, 2);
    });

    test('toggled selects and unselects one row', () {
      final review = _review([_line('Qwrtz'), _line('Brot')]);

      final toggled = review.toggled(0);

      expect(toggled.selectedLines.map((line) => line.name), ['Brot']);
      expect(toggled.toggled(0).selectedLines.map((line) => line.name), [
        'Qwrtz',
        'Brot',
      ]);
    });

    test('renamed places and compares the row again', () {
      final items = [_item('Milch')];
      final review = _review([
        _line('Qwrtz', shelf: ShoppingShelf.household, quantity: 3),
      ], items: items);

      final renamed = review.renamed(0, ' Milch ', items);

      final row = renamed.rows.single;
      expect(row.line.name, 'Milch');
      expect(row.line.quantity, 3);
      expect(row.shelf, lookUpShoppingCatalog('Milch')!.shelf);
      expect(row.listedQuantity, 1);
      expect(row.isSelected, isFalse);
    });
  });
}
