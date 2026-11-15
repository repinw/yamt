import 'package:collection/collection.dart';
import 'package:yamt/features/inventory/domain/cook_line_food.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/features/kochmodus/application/cook_finish_check.dart';
import 'package:yamt/features/kochmodus/application/cook_line_amount.dart';
import 'package:yamt/features/kochmodus/application/cook_line_parse.dart';
import 'package:yamt/features/kochmodus/application/cook_run_finish_service.dart';
import 'package:yamt/features/kochmodus/application/cook_takes.dart';
import 'package:yamt/features/kochmodus/domain/cook_duration.dart';
import 'package:yamt/features/kochmodus/domain/cook_food_words.dart';
import 'package:yamt/features/kochmodus/domain/cook_line_weight.dart';
import 'package:yamt/features/kochmodus/domain/cook_meal_name.dart';
import 'package:yamt/features/kochmodus/domain/cook_pot_split.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_line_view_builder.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_portion_builder.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_line_view.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_changes.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

/// The cooking page of [run] with the Vorrat [items], what the household's
/// other runs take from them ([otherReservations]) and their names
/// ([holders], see [kochmodusItemHolders]), and the [utensils]. [tab] is the
/// tab the cook opened, `null` to follow the run's step.
KochmodusView buildKochmodusView({
  required CookRun run,
  required bool saved,
  required bool ended,
  required bool busy,
  required bool reopened,
  required CookFinishSummary? finished,
  required KochmodusStep? tab,
  required List<InventoryItem> items,
  required Map<String, int> otherReservations,
  required List<KitchenUtensil> utensils,
  required TemplateIngredientParser parser,
  Map<String, String> holders = const {},
  int rejected = 0,
}) {
  final byId = {for (final item in items) item.id: item};
  final blocks = cookFinishBlocks(run, byId);
  final byPot = cookLinesByPot(run);
  final potOf = {
    for (final MapEntry(key: potId, value: potLines) in byPot.entries)
      for (final line in potLines) line.id: potId,
  };
  final lines = [
    for (final line in _restUnderOrigin(run.lines))
      kochmodusLineView(
        run,
        line,
        parser,
        byId,
        blocks,
        potOf[line.id],
        otherReservations,
      ),
  ];
  final viewOf = {for (final line in lines) line.id: line};
  List<KochmodusLineView> where(bool Function(KochmodusLineView) test) => [
    for (final line in lines)
      if (test(line)) line,
  ];
  final open = where((line) => line.settlement is LineOpen);
  final assigned = where((line) => line.settlement is LineAssigned);
  final shopping = where((line) => line.settlement is LineShopping);
  final newLines = where((line) => line.isNew);
  final settledAll = open.isEmpty && shopping.isEmpty;
  final pots = switch (run.pots) {
    CookPotsChosen(:final pots) => pots,
    CookCounted() || null => const <CookPot>[],
  };
  final linesByPot = {
    for (final MapEntry(key: potId, value: potLines) in byPot.entries)
      potId: [for (final line in potLines) viewOf[line.id]!],
  };
  final portionLabel = settledAll ? kochmodusPortionLabel(run, assigned) : null;
  final mealNames = {
    for (final potId in byPot.keys) potId: cookMealName(run, potId),
  };
  return KochmodusView(
    run: run,
    saved: saved,
    ended: ended,
    rejected: rejected,
    busy: busy,
    reopened: reopened && open.isNotEmpty,
    finished: finished == null ? null : _done(finished),
    step: tab ?? kochmodusStepOf(run.step),
    locked: {
      if (!saved) ...[KochmodusStep.cook, KochmodusStep.portion],
    },
    utensils: utensils,
    pots: pots,
    counted: run.pots is CookCounted,
    inCans: switch (run.pots) {
      CookPotsChosen(:final inCans) => inCans,
      CookCounted() || null => false,
    },
    lines: lines,
    toAnswer: [
      ...open,
      for (final line in assigned)
        if (line.shortBy != null ||
            line.needsOtherFood ||
            kochmodusGuessedTakeOnly(line) != null)
          line,
    ],
    shopping: shopping,
    ignored: where((line) => line.settlement is LineIgnored),
    newLines: newLines,
    perPortion: portionLabel == null
        ? null
        : kochmodusPortionMacros(portionLabel),
    portionLabel: portionLabel,
    guide: [for (final text in run.steps) _guideLine(text, lines)],
    timers: run.timers.sortedBy((timer) => timer.endsAt),
    estimated: [
      for (final line in assigned)
        if (!line.needsOtherFood &&
            !line.notCounted &&
            !line.entryMissing &&
            (line.weight is CookWeightEstimated ||
                line.weight is CookWeightMissing))
          line,
    ],
    portion: kochmodusPortionView(
      run: run,
      pots: pots,
      lines: lines,
      newLines: newLines,
      linesByPot: linesByPot,
      mealNames: mealNames,
      blocks: blocks,
    ),
    items: byId,
    otherReservations: otherReservations,
    holders: holders,
  );
}

// The instruction [text] with its timers and the [lines] it names: not one
// the cook left out, but one that does not count (a pinch of salt goes in).
KochmodusGuideLine _guideLine(String text, List<KochmodusLineView> lines) => (
  text: text,
  timerSteps: [
    for (final duration in cookDurationsIn(text)) cookTimerSteps(duration),
  ],
  foods: [
    for (final line in lines)
      if ((line.settlement is! LineIgnored || line.notCounted) &&
          cookStepNamesFood(text, cookLineFoodName(line.line.text)))
        switch (cookLineTextParts(line.text)) {
          (:final amount, :final food) => (
            lineId: line.id,
            amount: amount,
            food: food,
          ),
        },
  ],
);

// What "Guten Appetit!" shows of [finished]: each meal served in pieces, in
// cans or in portions, with the nutrition of one serving.
KochmodusDone _done(CookFinishSummary finished) => (
  meals: [
    for (final meal in finished.meals)
      (
        id: meal.id,
        name: meal.name,
        count: meal.totalPortions,
        serving: meal.isServedInPieces
            ? KochmodusServing.piece
            : finished.inCans
            ? KochmodusServing.can
            : KochmodusServing.portion,
        perServing: _perServing(meal),
      ),
  ],
  inCookbook: finished.inCookbook,
);

// The nutrition of one serving of [meal]; `null` when it has no energy.
KochmodusPortionNutrition? _perServing(PreparedMeal meal) {
  final count = meal.totalPortions;
  if (count <= 0) return null;
  final kcal = (meal.totalKcal / count).round();
  if (kcal <= 0) return null;
  return (
    kcal: kcal,
    protein: (meal.totalProtein / count).round(),
    carbs: (meal.totalCarbs / count).round(),
    fat: (meal.totalFat / count).round(),
  );
}

/// The name of a run of [runs] other than [runId] that takes something of
/// each item, by item id: the first such run with a name. Free cooking has
/// none until it is portioned.
Map<String, String> kochmodusItemHolders(List<CookRun> runs, String runId) => {
  for (final run in runs.reversed)
    if (run.id != runId && run.name.trim().isNotEmpty)
      for (final MapEntry(:key, :value) in run.reservations.entries)
        if (value > 0) key: run.name,
};

/// [run] with the line [lineId] taking from the Vorrat [items] with
/// [itemIds] in that order, as much as this cooking needs or the cook
/// weighed (`cookTakesFor`), next to what the household's other runs take
/// ([otherReservations]). An item missing from [items] keeps its take.
/// No items open the line again. Throws a
/// [StateError] when the line is gone.
///
/// [found] is the food the cook just found for the line, which [items] may
/// not hold yet. It takes over from an item missing from [items], so
/// "Eintrag fehlt" goes.
CookRun refillKochmodusTakes(
  CookRun run,
  String lineId,
  List<String> itemIds, {
  required List<InventoryItem> items,
  required Map<String, int> otherReservations,
  required TemplateIngredientParser parser,
  InventoryItem? found,
}) {
  final line = run.lineOf(lineId);
  if (line == null) throw StateError('Line $lineId is gone.');
  final byId = {
    for (final item in [...items, ?found]) item.id: item,
  };
  final chosen = [for (final id in itemIds) ?byId[id]];
  final refilled = {
    for (final take in cookTakesFor(
      run: run,
      line: line,
      need: cookLineNeed(
        run,
        line,
        parseKochmodusLine(parser, run, line),
        firstItem: chosen.firstOrNull,
      ),
      items: chosen,
      otherReservations: otherReservations,
    ))
      take.itemId: take,
  };
  // An item gone from the Vorrat keeps its take, so the line keeps showing
  // "Eintrag fehlt" instead of opening again.
  final kept = {
    if (line.settlement case LineAssigned(:final takes) when found == null)
      for (final take in takes) take.itemId: take,
  };
  return run.withTakes(lineId, [
    for (final id in itemIds)
      if (byId.containsKey(id)) ?refilled[id] else ?kept[id],
  ]);
}

// [lines] in their order, the rest of a line on the shopping list
// (`cookRestLineId`) right under that line instead of at the end.
List<CookRunLine> _restUnderOrigin(List<CookRunLine> lines) {
  final rests = {
    for (final line in lines)
      if (lines.any((origin) => cookRestLineId(origin.id) == line.id))
        line.id: line,
  };
  return [
    for (final line in lines)
      if (!rests.containsKey(line.id)) ...[
        line,
        ?rests[cookRestLineId(line.id)],
      ],
  ];
}
