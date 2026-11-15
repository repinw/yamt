import 'package:meta/meta.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_plan_pack.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';

/// What a line of a cook run brings into the pot, in grams or ml (1:1).
@immutable
sealed class CookLineWeight {
  /// Creates the weight.
  const new();
}

/// What a line in grams or ml takes from items kept in grams or ml.
final class CookWeightExact extends CookLineWeight {
  /// Creates the weight.
  const new(this.grams);

  /// The grams or ml.
  final int grams;

  @override
  bool operator ==(Object other) =>
      other is CookWeightExact && other.grams == grams;

  @override
  int get hashCode => Object.hash(CookWeightExact, grams);
}

/// What the cook weighed.
final class CookWeightWeighed extends CookLineWeight {
  /// Creates the weight.
  const new(this.grams);

  /// The grams or ml.
  final int grams;

  @override
  bool operator ==(Object other) =>
      other is CookWeightWeighed && other.grams == grams;

  @override
  int get hashCode => Object.hash(CookWeightWeighed, grams);
}

/// Pieces times the weight of one piece from the item's serving size, or
/// what a line in spoons, pieces, a measure or without an amount takes from
/// an item kept in grams or ml, the guess of its weight ("≈ geschätzt").
final class CookWeightEstimated extends CookLineWeight {
  /// Creates the weight.
  const new(this.grams, {this.toWeigh = false});

  /// The grams or ml.
  final int grams;

  /// Whether the weight is the guess for a line in spoons, pieces, a measure
  /// or without an amount from an item kept in grams or ml, which "Noch zu
  /// wiegen" asks the cook to weigh.
  final bool toWeigh;

  @override
  bool operator ==(Object other) =>
      other is CookWeightEstimated &&
      other.grams == grams &&
      other.toWeigh == toWeigh;

  @override
  int get hashCode => Object.hash(CookWeightEstimated, grams, toWeigh);
}

/// Not known ("Gewicht fehlt"): the line is not assigned, an item is gone,
/// counts in pieces without a serving size or in whole packs, or the line
/// takes nothing. Never a silent 0 g.
final class CookWeightMissing extends CookLineWeight {
  /// Creates the weight.
  const new();

  @override
  bool operator ==(Object other) => other is CookWeightMissing;

  @override
  int get hashCode => (CookWeightMissing).hashCode;
}

/// An ignored line, such as salt: it has no weight that counts.
final class CookWeightNotCounted extends CookLineWeight {
  /// Creates the weight.
  const new();

  @override
  bool operator ==(Object other) => other is CookWeightNotCounted;

  @override
  int get hashCode => (CookWeightNotCounted).hashCode;
}

/// What the amount of a line's text, or the cook's own amount, counts in.
enum CookLineAmountKind {
  /// Grams or ml.
  weight,

  /// Spoons (EL, TL).
  spoons,

  /// Pieces, a measure such as "Zehe" or "Bund", or no amount.
  other,
}

/// The weight of [line] with the Vorrat [items] by id: what the cook
/// weighed, else what its takes hold. A weight is exact only when the line's
/// amount is a weight ([kind]) and its items are kept in grams or ml. What a
/// line in spoons, pieces, a measure or without an amount takes from an item
/// kept in grams or ml is only a guess the cook weighs while cooking
/// ([CookWeightEstimated.toWeigh]): a spoon is never a weight. From an item
/// kept in pieces it goes by the item's piece size.
CookLineWeight cookLineWeight(
  CookRunLine line,
  Map<String, InventoryItem> items, {
  required CookLineAmountKind kind,
}) {
  if (line.settlement is LineIgnored) return const CookWeightNotCounted();
  if (line.weighed case final grams?) return CookWeightWeighed(grams);
  final takes = switch (line.settlement) {
    LineAssigned(:final takes) => takes,
    _ => const <ItemTake>[],
  };
  var total = 0.0;
  var perPiece = false;
  var guessed = false;
  for (final take in takes) {
    // A take of 0 only keeps its item with the line.
    if (take.amount <= 0) continue;
    final item = items[take.itemId];
    if (item == null) return const CookWeightMissing();
    final held = inventoryStockInConsumedUnit(item, take.amount);
    if (held == null) return const CookWeightMissing();
    total += held.amount;
    if (item.amountUnit == InventoryAmountUnit.piece) {
      perPiece = true;
    } else {
      guessed = guessed || kind != CookLineAmountKind.weight;
    }
  }
  final grams = total.round();
  if (grams <= 0) return const CookWeightMissing();
  if (guessed) return CookWeightEstimated(grams, toWeigh: true);
  return perPiece ? CookWeightEstimated(grams) : CookWeightExact(grams);
}

/// The grams or ml of one piece of [item] when it is kept in parts of pieces
/// with a piece weight, else `null`.
double? cookPieceWeightOf(InventoryItem item) =>
    item.usesAmountProgress &&
        item.amountScale > 1 &&
        item.amountUnit == InventoryAmountUnit.piece
    ? inventoryStockInConsumedUnit(item, item.amountScale)?.amount
    : null;
