import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:yamt/features/inventory/application/prepared_meal_inventory_math.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/application/cook_line_amount.dart';
import 'package:yamt/features/kochmodus/application/cook_takes.dart';
import 'package:yamt/features/kochmodus/domain/cook_pot_split.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

/// Why "In Vorrat" waits. The view words each one.
@immutable
sealed class CookFinishBlock {
  /// Creates the reason.
  const new();
}

/// The line [lineId] takes more of the item [itemId] than it holds next to
/// the run's other lines ("nur N da").
final class CookStockShort extends CookFinishBlock {
  /// Creates the reason.
  const new({
    required this.lineId,
    required this.itemId,
    required this.available,
  });

  /// The line.
  final String lineId;

  /// The item.
  final String itemId;

  /// What the item still holds for the line, in its unit and scale; for a line
  /// whose takes follow a weight, what all its items hold.
  final int available;

  @override
  bool operator ==(Object other) =>
      other is CookStockShort &&
      other.lineId == lineId &&
      other.itemId == itemId &&
      other.available == available;

  @override
  int get hashCode => Object.hash(lineId, itemId, available);
}

/// The line [lineId] takes from the item [itemId], which is no longer in
/// the Vorrat ("Eintrag fehlt").
final class CookEntryMissing extends CookFinishBlock {
  /// Creates the reason.
  const new({required this.lineId, required this.itemId});

  /// The line.
  final String lineId;

  /// The item.
  final String itemId;

  @override
  bool operator ==(Object other) =>
      other is CookEntryMissing &&
      other.lineId == lineId &&
      other.itemId == itemId;

  @override
  int get hashCode => Object.hash(CookEntryMissing, lineId, itemId);
}

/// The line [lineId] takes from the item [itemId], which lacks energy or
/// a macro ("Nährwerte fehlen").
final class CookNutritionMissing extends CookFinishBlock {
  /// Creates the reason.
  const new({required this.lineId, required this.itemId});

  /// The line.
  final String lineId;

  /// The item.
  final String itemId;

  @override
  bool operator ==(Object other) =>
      other is CookNutritionMissing &&
      other.lineId == lineId &&
      other.itemId == itemId;

  @override
  int get hashCode => Object.hash(CookNutritionMissing, lineId, itemId);
}

/// The line [lineId] names an amount but takes nothing
/// ([cookLineTakesNothing]): "erst wiegen oder entfernen" when [canWeigh],
/// else "anderes Lebensmittel wählen oder entfernen".
final class CookLineWithoutTake extends CookFinishBlock {
  /// Creates the reason.
  const new(this.lineId, {required this.canWeigh});

  /// The line.
  final String lineId;

  /// Whether a weight would help ([cookLineCanFollowWeight]).
  final bool canWeigh;

  @override
  bool operator ==(Object other) =>
      other is CookLineWithoutTake &&
      other.lineId == lineId &&
      other.canWeigh == canWeigh;

  @override
  int get hashCode => Object.hash(CookLineWithoutTake, lineId, canWeigh);
}

/// The pot [potId] holds lines but no weight above its empty weight yet
/// ("Erst den Topf wiegen"); never for a meal served in pieces.
final class CookPotUnweighed extends CookFinishBlock {
  /// Creates the reason.
  const new(this.potId);

  /// The pot.
  final String potId;

  @override
  bool operator ==(Object other) =>
      other is CookPotUnweighed && other.potId == potId;

  @override
  int get hashCode => Object.hash(CookPotUnweighed, potId);
}

/// The pot [potId], or the counted meal, holds no line that takes
/// something from the Vorrat ("Topf ohne Zutaten").
final class CookPotEmpty extends CookFinishBlock {
  /// Creates the reason.
  const new(this.potId);

  /// The pot.
  final String potId;

  @override
  bool operator ==(Object other) =>
      other is CookPotEmpty && other.potId == potId;

  @override
  int get hashCode => Object.hash(CookPotEmpty, potId);
}

/// The meal of the pot [potId], or of the counted meal, has no name and
/// count typed in yet.
final class CookMealMissing extends CookFinishBlock {
  /// Creates the reason.
  const new(this.potId);

  /// The pot, or [countedMealPotId].
  final String potId;

  @override
  bool operator ==(Object other) =>
      other is CookMealMissing && other.potId == potId;

  @override
  int get hashCode => Object.hash(CookMealMissing, potId);
}

/// [count] lines are neither assigned nor ignored, such as lines spoken in
/// while cooking ("Erst neue Zeilen klären").
final class CookLinesOpen extends CookFinishBlock {
  /// Creates the reason.
  const new(this.count);

  /// How many lines.
  final int count;

  @override
  bool operator ==(Object other) =>
      other is CookLinesOpen && other.count == count;

  @override
  int get hashCode => Object.hash(CookLinesOpen, count);
}

/// Why [run] cannot go into the Vorrat yet with the Vorrat [items] by id,
/// in the order the view names them; empty when it can. A single take of 0
/// checks nothing, because it writes nothing. Only the stock counts, not what
/// other runs reserve: a forgotten run must not block this one.
List<CookFinishBlock> cookFinishBlocks(
  CookRun run,
  Map<String, InventoryItem> items,
) {
  final short = <CookFinishBlock>[];
  final gone = <CookFinishBlock>[];
  final noNutrition = <CookFinishBlock>[];
  for (final line in run.lines) {
    if (line.settlement case LineAssigned(:final takes)) {
      final lineItems = [for (final take in takes) ?items[take.itemId]];
      // A weight splits over all items of the line, so "nur N da" counts them
      // all; the part beyond them sits on the last one.
      final held = cookWeighedTake(line, lineItems) == null
          ? null
          : [
              for (final item in lineItems)
                cookAvailableFor(run, line, item, const {}),
            ].sum;
      for (final take in takes) {
        if (take.amount <= 0) continue;
        final item = items[take.itemId];
        if (item == null) {
          gone.add(CookEntryMissing(lineId: line.id, itemId: take.itemId));
          continue;
        }
        final available = cookAvailableFor(run, line, item, const {});
        if (take.amount > available) {
          short.add(
            CookStockShort(
              lineId: line.id,
              itemId: item.id,
              available: held ?? available,
            ),
          );
        }
        if (!hasCompleteNutrition(item.nutrition)) {
          noNutrition.add(
            CookNutritionMissing(lineId: line.id, itemId: item.id),
          );
        }
      }
    }
  }
  final open = run.lines
      .where(
        (line) =>
            line.settlement is LineOpen || line.settlement is LineShopping,
      )
      .length;
  return [
    ...short,
    ...gone,
    ...noNutrition,
    for (final line in run.lines)
      if (cookLineTakesNothing(run, line))
        CookLineWithoutTake(
          line.id,
          canWeigh: cookLineCanFollowWeight(line, items),
        ),
    ..._potBlocks(run),
    if (open > 0) CookLinesOpen(open),
  ];
}

// Each meal needs a line that takes something and a typed-in meal; a pot
// also needs its weight above the empty weight, unless its meal is served in
// pieces.
List<CookFinishBlock> _potBlocks(CookRun run) {
  final emptyWeights = switch (run.pots) {
    CookPotsChosen(:final pots) => {
      for (final pot in pots) pot.id: pot.emptyWeight,
    },
    CookCounted() || null => const <String, int>{},
  };
  final unweighed = <CookFinishBlock>[];
  final empty = <CookFinishBlock>[];
  final noMeal = <CookFinishBlock>[];
  for (final MapEntry(key: potId, value: lines) in cookLinesByPot(
    run,
  ).entries) {
    if (!lines.any(_takesSomething)) {
      empty.add(CookPotEmpty(potId));
      continue;
    }
    final draft = run.meals.where((meal) => meal.potId == potId).firstOrNull;
    if (draft == null) {
      noMeal.add(CookMealMissing(potId));
      continue;
    }
    final emptyWeight = emptyWeights[potId];
    final gross = draft.grossWeight;
    // Pieces leave the pot without a weight, so they never wait for it.
    if (!draft.inPieces &&
        emptyWeight != null &&
        (gross == null || gross <= emptyWeight)) {
      unweighed.add(CookPotUnweighed(potId));
    }
  }
  return [...unweighed, ...empty, ...noMeal];
}

bool _takesSomething(CookRunLine line) => switch (line.settlement) {
  LineAssigned(:final takes) => takes.any((take) => take.amount > 0),
  _ => false,
};
