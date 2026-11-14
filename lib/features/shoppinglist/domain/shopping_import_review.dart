import 'package:collection/collection.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_catalog.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_import_reading.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_shelf.dart';

/// One product of an import as the user checks it before it goes on the
/// list.
class ShoppingImportRow {
  /// Places [line] by the catalog, else by the shelf the reader guessed, and
  /// compares it with the [items] of the list. A product that is still to buy
  /// on the list starts unselected.
  factory of(ShoppingImportLine line, List<ShoppingListItem> items) {
    final known = lookUpShoppingCatalog(line.name);
    final normalizedName = line.name.toLowerCase();
    final listed = items.where(
      (item) => item.isOpen && item.normalizedName == normalizedName,
    );
    final listedQuantity = listed.isEmpty
        ? null
        : listed.map((item) => item.quantity).sum;
    final (shelf, icon) = known != null
        ? (known.shelf, known.icon)
        : (line.shelf, shoppingShelfIcon(line.shelf));
    return ShoppingImportRow._(
      line: line,
      shelf: shelf,
      icon: icon,
      isShelfKnown: shelf != ShoppingShelf.other,
      listedQuantity: listedQuantity,
      isSelected: listedQuantity == null,
    );
  }

  const new _({
    required this.line,
    required this.shelf,
    required this.icon,
    required this.isShelfKnown,
    required this.listedQuantity,
    required this.isSelected,
  });

  /// The product as read, with the name the user gave it.
  final ShoppingImportLine line;

  /// The shelf it is shown under.
  final ShoppingShelf shelf;

  /// Its picture.
  final ShoppingItemIcon icon;

  /// False when neither the catalog nor the reader knows a shelf; the
  /// product then goes under "Other".
  final bool isShelfKnown;

  /// How many of it are still to buy on the list, or null when it is not on
  /// the list. The import adds its quantity on top.
  final int? listedQuantity;

  /// Whether it goes on the list.
  final bool isSelected;

  ShoppingImportRow _toggled() => ShoppingImportRow._(
    line: line,
    shelf: shelf,
    icon: icon,
    isShelfKnown: isShelfKnown,
    listedQuantity: listedQuantity,
    isSelected: !isSelected,
  );
}

/// The products of an import before they go on the list, and the lines the
/// reader passed over.
class ShoppingImportReview {
  /// Checks every line of [reading] against the [items] of the list.
  factory of(ShoppingImportReading reading, List<ShoppingListItem> items) =>
      ShoppingImportReview._(
        rows: [
          for (final line in reading.lines) ShoppingImportRow.of(line, items),
        ],
        skipped: reading.skipped,
      );

  const new _({required this.rows, required this.skipped});

  /// The products, in the order of the list.
  final List<ShoppingImportRow> rows;

  /// The lines that are not a product, as written.
  final List<String> skipped;

  /// The lines that go on the list.
  List<ShoppingImportLine> get selectedLines => [
    for (final row in rows)
      if (row.isSelected) row.line,
  ];

  /// This review with the row at [index] selected or unselected.
  ShoppingImportReview toggled(int index) =>
      _withRow(index, rows[index]._toggled());

  /// This review with the product at [index] called [name]. The row is
  /// placed and compared with [items] again, as if it had been read so.
  ShoppingImportReview renamed(
    int index,
    String name,
    List<ShoppingListItem> items,
  ) => _withRow(
    index,
    ShoppingImportRow.of(rows[index].line.withName(name.trim()), items),
  );

  ShoppingImportReview _withRow(int index, ShoppingImportRow row) =>
      ShoppingImportReview._(
        rows: [...rows.sublist(0, index), row, ...rows.sublist(index + 1)],
        skipped: skipped,
      );
}
