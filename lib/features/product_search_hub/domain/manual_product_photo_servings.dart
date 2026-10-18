import 'package:meta/meta.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_unit_aliases.dart';
import 'package:yamt/features/product_search_hub/domain/manual_product_piece_weight.dart';
import 'package:yamt/features/product_search_hub/domain/manual_product_search_value_utils.dart';

/// The servings that the package photos read: one piece from the front, and
/// the per-portion heading of the nutrition table.
@immutable
class ManualProductPhotoServings {
  /// Creates the servings.
  const new({this.front, this.table, this.prefersFront = false});

  /// One piece of a multipack, read from the front.
  final ManualProductServing? front;

  /// The serving of the nutrition table's per-portion column.
  final ManualProductServing? table;

  /// Whether the user picked [front] over [table].
  final bool prefersFront;

  /// The serving to save: the table's, unless the user picked the front.
  /// For the same amount, the one with a name.
  ManualProductServing? get chosen {
    if (!differ) return table?.size != null ? table : front ?? table;
    return prefersFront ? front : table;
  }

  /// The serving to save for a package: one counted in pieces takes only
  /// the front's piece, since a table's portion is no piece.
  ManualProductServing? savedFor({required bool countedInPieces}) =>
      countedInPieces ? front : chosen;

  /// Whether the user picks between the two servings: they differ, and the
  /// package is not counted in pieces.
  bool offersChoice({required bool countedInPieces}) =>
      differ && !countedInPieces;

  /// Whether both photos read a serving of a different amount, so the user
  /// picks.
  bool get differ =>
      front != null &&
      table != null &&
      (front!.quantity != table!.quantity ||
          front!.quantityUnit != table!.quantityUnit);

  /// These servings after a new front photo, which replaces the old read.
  ManualProductPhotoServings withFront(ManualProductServing? front) =>
      ManualProductPhotoServings(
        front: front,
        table: table,
        prefersFront: prefersFront,
      );

  /// These servings after a new nutrition table photo.
  ManualProductPhotoServings withTable(ManualProductServing? table) =>
      ManualProductPhotoServings(
        front: front,
        table: table,
        prefersFront: prefersFront,
      );

  /// These servings with the user's pick.
  ManualProductPhotoServings picking({required bool front}) =>
      ManualProductPhotoServings(
        front: this.front,
        table: table,
        prefersFront: front,
      );

  @override
  bool operator ==(Object other) =>
      other is ManualProductPhotoServings &&
      other.front == front &&
      other.table == table &&
      other.prefersFront == prefersFront;

  @override
  int get hashCode => Object.hash(front, table, prefersFront);
}

final _multipack = RegExp(
  r'^(\d+)\s*[x×]\s*(\d+(?:[.,]\d+)?\s*[a-zäöüß]+)$',
  caseSensitive: false,
);
final _amountInParentheses = RegExp(
  r'\([^)]*?(\d+(?:[.,]\d+)?\s*[a-zäöüß]+)\)',
  caseSensitive: false,
);
final _amount = RegExp(
  r'(\d+(?:[.,]\d+)?\s*[a-zäöüß]+)\b',
  caseSensitive: false,
);
final _servingWord = RegExp(
  r'^(?:pro|je|per|1)\s+([a-zäöüß]+)',
  caseSensitive: false,
);

/// The serving of one piece from the front of a package: the AI's piece
/// weight, or else a multipack label such as "6 x 25 g". Null without one.
ManualProductServing? manualProductFrontServing({
  double? weight,
  String? unit,
  String? name,
  String? quantityLabel,
}) {
  if (weight != null) {
    return _serving(weight, unit, name);
  }
  final match = _multipack.firstMatch(quantityLabel?.trim() ?? '');
  return match == null ? null : _servingOf(match.group(2)!, name);
}

/// The serving of a nutrition table's per-portion heading: the AI's serving
/// weight, or else a label such as "pro Riegel (25 g)". Null without one.
///
/// A bare 100 g or 100 ml names the per-100 column, not a serving.
ManualProductServing? manualProductTableServing({
  double? quantity,
  String? unit,
  String? name,
  String? label,
}) {
  if (quantity != null) {
    return _serving(quantity, unit, name);
  }
  final text = label?.trim() ?? '';
  final word = name?.trim().isNotEmpty ?? false
      ? name
      : _servingWord.firstMatch(text)?.group(1);
  // An amount in parentheses first, such as "pro Becher (100 g)", then the
  // others, skipping a bare 100 g or 100 ml: that names the per-100 column.
  for (final amount in _amountInParentheses.allMatches(text)) {
    final serving = _servingOf(amount.group(1)!, word);
    if (serving != null) return serving;
  }
  for (final amount in _amount.allMatches(text)) {
    final serving = _servingOf(amount.group(1)!, word);
    if (serving != null && serving.quantity != 100) return serving;
  }
  return null;
}

final _amountParts = RegExp(r'^(\d+(?:[.,]\d+)?)\s*([a-zäöüß]+)$');

/// The serving of [amount], such as "25 g" or "0,25 l".
ManualProductServing? _servingOf(String amount, String? name) {
  final parts = _amountParts.firstMatch(amount.trim().toLowerCase());
  final quantity = parseManualProductDouble(parts?.group(1) ?? '');
  return quantity == null ? null : _serving(quantity, parts!.group(2), name);
}

/// One [name] of [amount] in [unit], in grams or milliliters, labeled
/// "1 Riegel (25 g)" for the eat page. Without a name, the amount alone
/// names it there. The amount keeps its fraction, such as 12.5 g.
ManualProductServing? _serving(double amount, String? unit, String? name) {
  final base = servingInBaseUnit(amount, unit);
  final code = switch (base?.unit) {
    InventoryAmountUnit.gram => 'g',
    InventoryAmountUnit.milliliter => 'ml',
    _ => null,
  };
  if (base == null || code == null || base.amount <= 0) return null;
  // Round away float noise such as 0.33 l = 330.00000000000006 ml.
  final quantity = (base.amount * 1000).roundToDouble() / 1000;
  final word = name?.trim();
  return (
    size: word == null || word.isEmpty
        ? null
        : '1 $word (${formatManualProductDouble(quantity)} $code)',
    quantity: quantity,
    quantityUnit: code,
  );
}
