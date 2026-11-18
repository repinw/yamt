import 'package:meta/meta.dart';
import 'package:yamt/features/inventory/domain/eat_meal_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/features/kochmodus/application/cook_takes.dart';
import 'package:yamt/features/kochmodus/domain/cook_line_weight.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_line_view.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_portion_view.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

/// The tabs of the cooking page, in their order. A recipe's lines are
/// assigned before, on their own page ("Was hast du da?").
enum KochmodusStep {
  /// Choosing the pots ("Töpfe").
  pots,

  /// Cooking with the guide or on the list ("Kochen").
  cook,

  /// Splitting into meals ("Portion").
  portion,
}

/// The nutrition of one portion: the energy in kcal and protein,
/// carbohydrates and fat in grams, each rounded.
typedef KochmodusPortionNutrition = ({
  int kcal,
  int protein,
  int carbs,
  int fat,
});

/// What one serving of a finished meal is.
enum KochmodusServing {
  /// A portion ("pro Portion").
  portion,

  /// A piece of a meal served in pieces ("pro Stück").
  piece,

  /// A can of meals that went into cans ("pro Dose").
  can,
}

/// One meal that "In den Vorrat legen" put into the Vorrat: its id, name,
/// how many servings of which kind, and the nutrition of one serving,
/// `null` when the meal has no energy.
typedef KochmodusDoneMeal = ({
  String id,
  String name,
  int count,
  KochmodusServing serving,
  KochmodusPortionNutrition? perServing,
});

/// What "Guten Appetit!" shows: the meals, one per pot in the pots' order,
/// and whether free cooking also became a Kochbuch recipe.
typedef KochmodusDone = ({List<KochmodusDoneMeal> meals, bool inCookbook});

/// One instruction of the guide ("Kochhelfer") with the timer choices of
/// each time it names (a span like "8–10 Min" gives each minute).
typedef KochmodusGuideLine = ({String text, List<List<Duration>> timerSteps});

/// Assigning or cooking as it is now: the run or its draft, the tab, and
/// every derived list the steps show. Built by `buildKochmodusView`.
@immutable
class KochmodusView {
  /// Creates the view.
  const new({
    required this.run,
    required this.saved,
    required this.ended,
    required this.busy,
    required this.reopened,
    required this.finished,
    required this.step,
    required this.locked,
    required this.utensils,
    required this.pots,
    required this.counted,
    required this.inCans,
    required this.lines,
    required this.toAnswer,
    required this.shopping,
    required this.ignored,
    required this.newLines,
    required this.perPortion,
    required this.portionLabel,
    required this.guide,
    required this.timers,
    required this.estimated,
    required this.portion,
    required this.items,
    required this.otherReservations,
    this.holders = const {},
    this.rejected = 0,
  });

  /// The run, or its draft before it is stored. After it ended it
  /// is the run as it was last seen. Name, portions, base portions,
  /// instructions, guide step, meals and "Ins Kochbuch" come from here.
  final CookRun run;

  /// Whether the run is stored; a recipe's draft is stored with its first
  /// change, free cooking's once its pots are chosen.
  final bool saved;

  /// Whether the stored run is gone: finished or discarded on another device.
  final bool ended;

  /// The writes the server rejected so far; when it grows, the page says so.
  final int rejected;

  /// Whether the run is being created, paused, finished or discarded; the
  /// buttons of those actions stay off meanwhile.
  final bool busy;

  /// Whether opening brought a paused run's shopping lines back to open and
  /// one is still open; the page shows "Zurück vom Einkauf".
  final bool reopened;

  /// What "In Vorrat" put into the Vorrat; the page shows "Guten Appetit!".
  final KochmodusDone? finished;

  /// The tab shown.
  final KochmodusStep step;

  /// The tabs that cannot open yet: a draft opens only Töpfe.
  final Set<KochmodusStep> locked;

  /// The household's kitchen utensils, which "Töpfe" offers.
  final List<KitchenUtensil> utensils;

  /// The chosen pots, in their order; empty while counting or unchosen.
  final List<CookPot> pots;

  /// Whether the cook counts pieces without a pot ("Ohne Topf").
  final bool counted;

  /// Whether the meals go into cans afterwards ("Danach in Dosen").
  final bool inCans;

  /// Every line in the run's order, the rest of a line on the shopping list
  /// (`cookRestLineId`) right under that line.
  final List<KochmodusLineView> lines;

  /// The lines the cook still answers on "Was hast du da?", in the order it
  /// asks them: the open ones, then those taken from the Vorrat that hold too
  /// little (`KochmodusLineView.shortBy`), guessed weights that take more than
  /// is left (`kochmodusGuessedTakeOnly`), or take nothing and that a weight
  /// cannot help (`KochmodusLineView.needsOtherFood`); each in the order of
  /// [lines].
  final List<KochmodusLineView> toAnswer;

  /// The lines waiting for the shopping ("im Einkauf").
  final List<KochmodusLineView> shopping;

  /// The lines left out of this cooking.
  final List<KochmodusLineView> ignored;

  /// The lines that came in while cooking.
  final List<KochmodusLineView> newLines;

  /// The nutrition of one portion once every line is settled and every take
  /// has its nutrition; `null` before or when nothing is taken.
  final KochmodusPortionNutrition? perPortion;

  /// The food label of one portion: the same energy and macros as [perPortion].
  final EatMealNutrition? portionLabel;

  /// The energy of one portion ([perPortion]).
  int? get kcalPerPortion => perPortion?.kcal;

  /// The instructions of the guide, empty for free cooking.
  final List<KochmodusGuideLine> guide;

  /// The running timers, the soonest first.
  final List<CookTimer> timers;

  /// The assigned lines with only an estimated weight or none, which
  /// "Ansehen" on "Fertig gekocht" offers to weigh; not a line that weighing
  /// cannot help (`KochmodusLineView.needsOtherFood`), nor one that does not
  /// count (`KochmodusLineView.notCounted`), nor one whose food left the
  /// Vorrat (`KochmodusLineView.entryMissing`).
  final List<KochmodusLineView> estimated;

  /// "Portion": the meals and what keeps "In Vorrat" waiting.
  final KochmodusPortionView portion;

  /// The Vorrat items by id.
  final Map<String, InventoryItem> items;

  /// What the other runs of the household take from each item, by id.
  final Map<String, int> otherReservations;

  /// The name of another run that takes something of each item, by id, for
  /// "für Pfannkuchen verplant".
  final Map<String, String> holders;

  /// The tab after [step], which "Weiter" opens; [step] on the last tab.
  KochmodusStep get nextStep {
    const steps = KochmodusStep.values;
    return step.index + 1 < steps.length ? steps[step.index + 1] : step;
  }

  /// What the Vorrat [item] still has for [line], in its unit and scale, as
  /// the row counts it: its stock less what the other runs and the run's other
  /// lines take (`cookAvailableFor`).
  int stockLeftOf(KochmodusLineView line, InventoryItem item) =>
      cookAvailableFor(run, line.line, item, otherReservations);

  /// Whether this is free cooking.
  bool get isFree => run.kind == CookRunKind.free;

  /// Whether the run waits for the shopping.
  bool get paused => run.step == CookRunStep.paused;

  /// How many lines the cook still answers ([toAnswer]).
  int get openCount => toAnswer.length;

  /// The lines of [estimated] without any weight, which "Ansehen" lists
  /// first, under "Noch zu wiegen".
  List<KochmodusLineView> get unweighed => [
    for (final line in estimated)
      if (line.weight is CookWeightMissing) line,
  ];

  /// The lines of [estimated] whose weight we estimated, which "Ansehen"
  /// lists under "Bei N Zutaten haben wir das Gewicht geschätzt".
  List<KochmodusLineView> get guessed => [
    for (final line in estimated)
      if (line.weight is CookWeightEstimated) line,
  ];

  /// How many lines carry an estimated weight ([guessed]): the N of "Bei N
  /// Zutaten haben wir das Gewicht geschätzt".
  int get estimatedCount => guessed.length;

  /// The lines "Noch zu wiegen" asks the cook to weigh: of [estimated], those
  /// whose weight is missing, and those in spoons, pieces, a measure or
  /// without an amount whose weight from a food kept in g or ml is only a
  /// guess (`CookWeightEstimated.toWeigh`). Not a line from a food kept in
  /// pieces with its own piece size, nor one that does not count (not in
  /// [estimated]); a weighed line drops off.
  List<KochmodusLineView> get toWeigh => [
    for (final line in estimated)
      if (switch (line.weight) {
        CookWeightMissing() => true,
        CookWeightEstimated(:final toWeigh) => toWeigh,
        _ => false,
      })
        line,
  ];

  /// Whether the switch "Mit Anleitung" shows: only when the recipe has
  /// instructions.
  bool get guideVisible => run.steps.isNotEmpty;

  /// Whether "Kochen" shows the guide ("Kochhelfer") instead of the list.
  bool get showGuide => run.withGuide && run.steps.isNotEmpty;
}

/// The tab that shows the run on [step]; a run that has not cooked yet
/// shows "Töpfe".
KochmodusStep kochmodusStepOf(CookRunStep step) => switch (step) {
  CookRunStep.pots ||
  CookRunStep.assign ||
  CookRunStep.paused => KochmodusStep.pots,
  CookRunStep.cook => KochmodusStep.cook,
  CookRunStep.portion => KochmodusStep.portion,
};

/// The step to store when the cook opens the tab [step] of the stored
/// [run]: Kochen or Portion past the run's step; `null` to store nothing,
/// also while the run is paused or not stored.
CookRunStep? kochmodusStepToStore(CookRun? run, KochmodusStep step) {
  final to = switch (step) {
    KochmodusStep.cook => CookRunStep.cook,
    KochmodusStep.portion => CookRunStep.portion,
    _ => null,
  };
  final ahead =
      run != null &&
      run.step != CookRunStep.paused &&
      step.index > kochmodusStepOf(run.step).index;
  return ahead ? to : null;
}
