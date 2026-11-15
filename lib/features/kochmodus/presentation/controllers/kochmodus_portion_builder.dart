import 'package:collection/collection.dart';
import 'package:yamt/core/domain/nutrition_facts.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/application/prepared_meal_inventory_math.dart';
import 'package:yamt/features/inventory/domain/eat_meal_nutrition.dart';
import 'package:yamt/features/kochmodus/application/cook_finish_check.dart';
import 'package:yamt/features/kochmodus/domain/cook_line_weight.dart';
import 'package:yamt/features/kochmodus/domain/cook_meal_name.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_line_view.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_portion_view.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

/// "Portion" of [run] cooked in [pots], from its [lines], the lines that
/// came in while cooking ([newLines]), the lines by meal ([linesByPot]),
/// the meals' names ([mealNames]) and why "In Vorrat" waits ([blocks]).
KochmodusPortionView kochmodusPortionView({
  required CookRun run,
  required List<CookPot> pots,
  required List<KochmodusLineView> lines,
  required List<KochmodusLineView> newLines,
  required Map<String, List<KochmodusLineView>> linesByPot,
  required Map<String, CookMealName> mealNames,
  required List<CookFinishBlock> blocks,
}) {
  final keys = linesByPot.keys.toList();
  final meals = [
    for (final (index, potId) in keys.indexed)
      _meal(
        run,
        potId,
        index + 1,
        pot: pots.where((pot) => pot.id == potId).firstOrNull,
        name: mealNames[potId] ?? CookMealNamePlain(run.name),
        lines: linesByPot[potId] ?? const [],
        single: keys.length == 1,
      ),
  ];
  final portionBlocks = [for (final block in blocks) ?_portionBlock(block)];
  final blockLineId = switch (portionBlocks.firstOrNull) {
    CookStockShort(:final lineId) ||
    CookEntryMissing(:final lineId) ||
    CookNutritionMissing(:final lineId) ||
    CookLineWithoutTake(:final lineId) => lineId,
    _ => null,
  };
  return KochmodusPortionView(
    meals: meals,
    potMeals: [
      for (final meal in meals)
        if (meal.pot != null) meal,
    ],
    lines: [
      for (final line in lines)
        if (line.settlement is! LineIgnored) line,
    ],
    ignoredLines: [
      for (final line in lines)
        if (line.settlement is LineIgnored) line,
    ],
    openNewLines: [
      for (final line in newLines)
        if (line.settlement is LineOpen || line.settlement is LineShopping)
          line,
    ],
    blocks: portionBlocks,
    blockLine: lines.firstWhereOrNull((line) => line.id == blockLineId),
    unweighedPots: portionBlocks.whereType<CookPotUnweighed>().length,
    potToWeigh: switch (portionBlocks.firstOrNull) {
      CookPotUnweighed(:final potId) => meals.firstWhereOrNull(
        (meal) => meal.potId == potId && meal.pot != null,
      ),
      _ => null,
    },
  );
}

// A meal without input: a pot waits for its weight, the counted meal gets
// its defaults on "In Vorrat".
CookFinishBlock? _portionBlock(CookFinishBlock block) => switch (block) {
  CookMealMissing(potId: countedMealPotId) => null,
  CookMealMissing(:final potId) => CookPotUnweighed(potId),
  _ => block,
};

KochmodusMealView _meal(
  CookRun run,
  String potId,
  int number, {
  required CookPot? pot,
  required CookMealName name,
  required List<KochmodusLineView> lines,
  required bool single,
}) {
  final draft = run.meals.where((meal) => meal.potId == potId).firstOrNull;
  return KochmodusMealView(
    potId: potId,
    pot: pot,
    number: number,
    name: name,
    draft: draft,
    count: draft?.count ?? (single ? run.portions : 1),
    inPieces: draft?.inPieces ?? pot == null,
    nutrition: _combine([
      for (final line in lines)
        for (final take in line.takes)
          if (take.amount > 0) take,
    ]),
    ingredientGrams: _grams(lines),
  );
}

// What [lines] weigh together; `null` when one has no weight yet.
int? _grams(List<KochmodusLineView> lines) {
  var sum = 0;
  for (final line in lines) {
    switch (line.weight) {
      case CookWeightExact(:final grams) ||
          CookWeightWeighed(:final grams) ||
          CookWeightEstimated(:final grams):
        sum += grams;
      case CookWeightNotCounted():
        break;
      case CookWeightMissing():
        return null;
    }
  }
  return sum;
}

// What [take] brings in; nothing known without the item or its nutrition.
NutritionFacts _eaten(KochmodusTake take) {
  final item = take.item;
  final nutrition = item?.nutrition;
  if (item == null || nutrition == null) return const NutritionFacts();
  return buildPreparedMealComponent(
    item: item,
    usedAmount: take.amount,
    usedUnit: resolveUsedUnit(item),
    nutrition: nutrition,
  ).nutritionFacts;
}

/// The nutrients of one portion of the meal from the takes of the
/// [assigned] lines of [run], for the label under "Alles bereit"; `null` when
/// a take has no item or no energy or macro, or nothing is taken. A nutrient
/// that a food does not list is a minimum (`EatMealNutrition.incomplete`).
EatMealNutrition? kochmodusPortionLabel(
  CookRun run,
  List<KochmodusLineView> assigned,
) {
  final takes = [
    for (final line in assigned)
      for (final take in line.takes)
        if (take.amount > 0) take,
  ];
  if (takes.isEmpty ||
      takes.any((take) => !hasCompleteNutrition(take.item?.nutrition))) {
    return null;
  }
  return _combine(takes).perPortion(run.portions);
}

/// The energy and the three macros of one [portion]
/// ([kochmodusPortionLabel]), each rounded, as "Alles bereit" says them.
/// Throws a [StateError] when [portion] lacks one of them.
KochmodusPortionNutrition kochmodusPortionMacros(
  EatMealNutrition portion,
) => switch (portion.total) {
  NutritionFacts(:final kcal?, :final protein?, :final carbs?, :final fat?) => (
    kcal: kcal.round(),
    protein: protein.round(),
    carbs: carbs.round(),
    fat: fat.round(),
  ),
  _ => throw StateError('A portion label lists energy and the macros.'),
};

// The meal of [takes]; the weights of the foods do not matter here.
EatMealNutrition _combine(Iterable<KochmodusTake> takes) =>
    EatMealNutrition.combine([
      for (final take in takes)
        (eaten: _eaten(take), amount: 0, unit: ConsumedUnit.grams),
    ]);
