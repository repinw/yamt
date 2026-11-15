import 'package:meta/meta.dart';
import 'package:yamt/core/domain/nutrition_facts.dart';
import 'package:yamt/features/inventory/domain/eat_meal_nutrition.dart';
import 'package:yamt/features/kochmodus/application/cook_finish_check.dart';
import 'package:yamt/features/kochmodus/domain/cook_meal_name.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_line_view.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_changes.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

/// One meal of "Portion": the meal of a pot, or the counted meal.
@immutable
class KochmodusMealView {
  /// Creates the meal.
  const new({
    required this.potId,
    required this.pot,
    required this.number,
    required this.name,
    required this.draft,
    required this.count,
    required this.inPieces,
    required this.nutrition,
    this.ingredientGrams,
  });

  /// The [CookPot.id], or [countedMealPotId].
  final String potId;

  /// The pot, `null` for the counted meal.
  final CookPot? pot;

  /// The pot's place among the pots, from 1, for a pot without a name.
  final int number;

  /// The name the meal gets until the cook types another one.
  final CookMealName name;

  /// What the cook typed in, `null` before the first input.
  final CookMealDraft? draft;

  /// The portions, cans or pieces: the draft's, else 1 per meal, or the
  /// run's portions when there is only one meal.
  final int count;

  /// Whether the meal is eaten in pieces: the draft's, else for the
  /// counted meal.
  final bool inPieces;

  /// The whole meal's nutrients from what its lines take.
  final EatMealNutrition nutrition;

  /// What its lines weigh together in grams, weighed or estimated; `null`
  /// when a line has no weight yet.
  final int? ingredientGrams;

  /// The pot with the food on the scale in grams, `null` until weighed.
  int? get grossWeight => draft?.grossWeight;

  /// The food without the pot in grams; `null` until the pot weighs more
  /// than empty, and for the counted meal.
  int? get netWeight {
    final emptyWeight = pot?.emptyWeight;
    final gross = grossWeight;
    if (emptyWeight == null || gross == null || gross <= emptyWeight) {
      return null;
    }
    return gross - emptyWeight;
  }

  /// Whether the pot was weighed at no more than its empty weight.
  bool get weighedTooLow {
    final emptyWeight = pot?.emptyWeight;
    final gross = grossWeight;
    return emptyWeight != null && gross != null && gross <= emptyWeight;
  }

  /// The nutrients per 100 g of the cooked food; `null` without its weight.
  NutritionFacts? get per100 {
    final net = netWeight;
    return net == null ? null : nutrition.total.scaled(100 / net);
  }

  /// The grams of one portion, can or piece; `null` without the weight.
  int? get gramsPerCount {
    final net = netWeight;
    return net == null ? null : (net / count).round();
  }
}

/// "Portion" as it is now, derived from the cooking page.
@immutable
class KochmodusPortionView {
  /// Creates the view.
  const new({
    required this.meals,
    required this.potMeals,
    required this.lines,
    required this.ignoredLines,
    required this.openNewLines,
    required this.blocks,
    required this.blockLine,
    required this.unweighedPots,
    required this.potToWeigh,
  });

  /// The meals in the pots' order.
  final List<KochmodusMealView> meals;

  /// The meals of a pot, without the counted meal.
  final List<KochmodusMealView> potMeals;

  /// The lines that go into a meal, in the run's order.
  final List<KochmodusLineView> lines;

  /// The lines the cook left out; each can be assigned again.
  final List<KochmodusLineView> ignoredLines;

  /// The lines that came in while cooking and are not settled yet
  /// ("N neue Zeilen").
  final List<KochmodusLineView> openNewLines;

  /// Why "In Vorrat" waits, in the order the page names them. A pot without
  /// input waits for its weight; a counted meal without input does not
  /// wait, "In Vorrat" types it in with its defaults
  /// ([kochmodusWithDefaultMeals]).
  final List<CookFinishBlock> blocks;

  /// The line the first of [blocks] names, `null` when it names none.
  final KochmodusLineView? blockLine;

  /// How many pots of [blocks] wait for their weight.
  final int unweighedPots;

  /// The meal whose pot waits for its weight when that is the first of
  /// [blocks]: the main button weighs it. `null` for any other first reason.
  final KochmodusMealView? potToWeigh;
}

/// The change that sets what the cook typed in for the meal of
/// [fallback]'s pot, on the freshest run: the other fields stay as stored,
/// or as [fallback] before the first input.
CookRun Function(CookRun run) kochmodusMealEdit(
  CookMealDraft fallback, {
  String? name,
  int? count,
  bool? inPieces,
  int? grossWeight,
}) => (run) {
  final current =
      run.meals.where((meal) => meal.potId == fallback.potId).firstOrNull ??
      fallback;
  return run.withMeal(
    CookMealDraft(
      potId: current.potId,
      name: name ?? current.name,
      count: count ?? current.count,
      inPieces: inPieces ?? current.inPieces,
      grossWeight: grossWeight ?? current.grossWeight,
    ),
  );
};

/// [run] with each of [defaults] as the meal of its pot when the cook typed
/// nothing in for it yet.
CookRun kochmodusWithDefaultMeals(CookRun run, List<CookMealDraft> defaults) {
  var typed = run;
  for (final draft in defaults) {
    if (typed.meals.every((meal) => meal.potId != draft.potId)) {
      typed = typed.withMeal(draft);
    }
  }
  return typed;
}
