import 'package:yamt/features/shoppinglist/domain/shopping_shelf.dart';

/// One product read from an imported list.
class ShoppingImportLine {
  /// Creates a line.
  const new({
    required this.name,
    required this.quantity,
    required this.shelf,
    this.note,
  });

  /// The product name, trimmed and never empty.
  final String name;

  /// How many to buy, at least one.
  final int quantity;

  /// An amount or remark that is not a count, such as "500 g".
  final String? note;

  /// The shelf the reader guessed; [ShoppingShelf.other] when it knows none.
  final ShoppingShelf shelf;

  /// This line with [name].
  ShoppingImportLine withName(String name) => ShoppingImportLine(
    name: name,
    quantity: quantity,
    note: note,
    shelf: shelf,
  );
}

/// What the reader found in an imported list: the products and the lines
/// that are not a product.
class ShoppingImportReading {
  /// Creates a reading.
  const new({required this.lines, required this.skipped});

  /// Reads the answer of the import template:
  /// `{"items": [{"name", "quantity", "note"?, "shelf"}], "skipped": [...]}`.
  /// Throws a [FormatException] on any other shape.
  factory fromJson(Object? json) {
    if (json case {
      'items': final List<Object?> items,
      'skipped': final List<Object?> skipped,
    }) {
      return ShoppingImportReading(
        lines: [for (final item in items) _lineFromJson(item)],
        skipped: [
          for (final line in skipped)
            if (line is String) line else throw _wrongShape('skipped', line),
        ],
      );
    }
    throw _wrongShape('reading', json);
  }

  /// The products, in the order of the list.
  final List<ShoppingImportLine> lines;

  /// The lines that are not a product, as written.
  final List<String> skipped;
}

/// How many lines of a pasted list hold something.
int shoppingImportLineCount(String text) =>
    text.split('\n').where((line) => line.trim().isNotEmpty).length;

final Map<String, ShoppingShelf> _shelvesByName = {
  for (final shelf in ShoppingShelf.values) shelf.name: shelf,
};

ShoppingImportLine _lineFromJson(Object? json) {
  if (json
      case {
        'name': final String name,
        'quantity': final int quantity,
        'shelf': final String shelfName,
      }
      when name.trim().isNotEmpty && quantity >= 1) {
    final shelf = _shelvesByName[shelfName];
    if (shelf == null) throw _wrongShape('shelf', shelfName);
    // The template marks the note optional, so it may be left out.
    final note = json['note'];
    if (note is! String?) throw _wrongShape('note', note);
    final trimmedNote = note?.trim();
    return ShoppingImportLine(
      name: name.trim(),
      quantity: quantity,
      note: trimmedNote == null || trimmedNote.isEmpty ? null : trimmedNote,
      shelf: shelf,
    );
  }
  throw _wrongShape('item', json);
}

FormatException _wrongShape(String what, Object? value) =>
    FormatException('Unexpected shopping import $what: $value');
