import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/features/kochmodus/application/cook_refill.dart';
import 'package:yamt/features/kochmodus/application/cook_said_weight.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_controller.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_run_edits.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_portion_view.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_changes.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

/// What a line said or typed while cooking did (`KochmodusActions.takeSaid`),
/// for "nein" (`KochmodusSaidController.undoLast`): the new line `lineId`, or
/// with `before` a weight on the assigned line `lineId`, as it was until then;
/// `after` is the line as the change left it.
typedef KochmodusSaid = ({
  String lineId,
  CookRunLine? before,
  CookRunLine after,
});

/// A line that "Portion" took out (`KochmodusActions.removeFromPortion`), for
/// `KochmodusActions.undoRemove`: as it was until then, and its place among
/// the lines.
typedef KochmodusRemoved = ({CookRunLine line, int index});

/// The editing actions of the cooking page. Each is one change of the run
/// (`KochmodusController.change`) and returns whether it worked.
extension KochmodusActions on KochmodusController {
  /// Cooks in [utensils] ("Weiter" on "Töpfe"), into cans afterwards when
  /// [inCans]. A draft of free cooking is created now; then "Kochen" opens.
  Future<bool> choosePots(
    List<KitchenUtensil> utensils, {
    required bool inCans,
  }) => change(
    (run) => run
        .withPots([
          for (final utensil in utensils)
            CookPot(
              id: utensil.id,
              name: utensil.name,
              emptyWeight: utensil.weightGrams,
              imageStoragePath: utensil.imageStoragePath,
            ),
        ], inCans: inCans)
        .toStep(kochmodusAfterPots(run)),
    next: true,
  );

  /// Cooks without a pot and counts pieces ("Ohne Topf"), like [choosePots].
  Future<bool> chooseCounted() => change(
    (run) => run.withCounted().toStep(kochmodusAfterPots(run)),
    next: true,
  );

  /// Settles the line [lineId] as [settlement]: shopping, left out, or open.
  Future<bool> settle(String lineId, LineSettlement settlement) =>
      change((run) => run.settle(lineId, settlement));

  /// Takes the line [lineId] from the Vorrat items [itemIds] in that order,
  /// after its amount [own] and with [rest] on the shopping list
  /// ([kochmodusWithRest]) in the same change; without items it opens again.
  /// Fails when all of them left the Vorrat since the cook picked them.
  Future<bool> assignItems(
    String lineId,
    List<String> itemIds, {
    ({int? amount, TemplateIngredientUnit? unit})? own,
    String? rest,
  }) => change((run) {
    final amounted = own == null
        ? run
        : run.withAmount(lineId, own.amount, unit: own.unit);
    final rested = rest == null
        ? amounted
        : kochmodusWithRest(amounted, lineId, rest);
    final refilled = refillTakes(rested, lineId, itemIds);
    if (itemIds.isNotEmpty && refilled.lineOf(lineId)?.settlement is LineOpen) {
      throw StateError('The items picked for $lineId are gone.');
    }
    return refilled;
  });

  /// Takes the food [found] that search, barcode or AI just put into the
  /// Vorrat for the line [lineId], after its amount [own] in the same change:
  /// the line names it first and takes from it what it needs, at most what the
  /// cook has (see `cookTakesFor`); its other items give only what is still
  /// missing, or leave the line when it takes the found food [alone]
  /// ("Anderes nehmen"). Discard deletes the food again, and so does finish
  /// once no line holds it. What the cook weighed is the total, so a weighed
  /// line splits it over its items again, the new first.
  Future<bool> assignFound(
    String lineId,
    InventoryItem found, {
    ({int? amount, TemplateIngredientUnit? unit})? own,
    bool alone = false,
  }) => change((run) {
    final amounted = own == null
        ? run
        : run.withAmount(lineId, own.amount, unit: own.unit);
    final others = switch (amounted.lineOf(lineId)?.settlement) {
      LineAssigned(:final takes) when !alone => [
        for (final take in takes)
          if (take.itemId != found.id) take.itemId,
      ],
      _ => const <String>[],
    };
    return refillTakes(amounted.addedItem(lineId, found.id), lineId, [
      found.id,
      ...others,
    ], found: found);
  });

  /// Sets the amount of the line [lineId] for this cooking, in the line's
  /// unit, or in [unit] when its text names none; `null` goes back to the
  /// recipe's. An assigned line takes again from the same items, at most what
  /// they have (see `cookTakesFor`).
  Future<bool> setAmount(
    String lineId,
    int? amount, {
    TemplateIngredientUnit? unit,
  }) => change(
    (run) => _refillLine(run.withAmount(lineId, amount, unit: unit), lineId),
  );

  /// "N kaufen" of a line whose items hold too little: the line [lineId]
  /// takes [own], what they have, like [setAmount], and [rest], such as
  /// "200 ml Milch", goes on the shopping list as a line of its own
  /// (`cookRestLineId`) in place of an earlier one.
  Future<bool> buyRest(
    String lineId, {
    required int? own,
    required String rest,
    TemplateIngredientUnit? unit,
  }) => change(
    (run) => _refillLine(
      kochmodusWithRest(run, lineId, rest).withAmount(lineId, own, unit: unit),
      lineId,
    ),
  );

  /// Sets what the line [lineId] weighed in grams; `null` clears it. An
  /// assigned line takes again from the same items: what it weighed when
  /// they are kept in grams or ml (`cookWeighedTake`), else as before.
  Future<bool> weigh(String lineId, int? grams) =>
      change((run) => _refillLine(run.weigh(lineId, grams), lineId));

  /// Adds the open line [text] from [origin]; its id, `null` when it failed.
  Future<String?> addLine(String text, CookLineOrigin origin) async {
    final line = kochmodusNewLine(text, origin);
    return await change((run) => run.addLine(line)) ? line.id : null;
  }

  /// Takes the line [said] while cooking: a weight that names an assigned
  /// line ("30 g Öl", see `parseCookSaidWeight`, `cookLineForFood`) adds to
  /// what that line weighed, because it went in in several goes; anything
  /// else becomes a new line. [items] is the Vorrat by id; names match in
  /// the language [localeCode]. Returns what it did, for "nein"; `null` when
  /// it failed.
  Future<KochmodusSaid?> takeSaid(
    String said, {
    required Map<String, InventoryItem> items,
    required String localeCode,
  }) async {
    final weight = parseCookSaidWeight(said);
    final added = kochmodusNewLine(said, CookLineOrigin.cooking);
    KochmodusSaid? taken;
    final done = await change((run) {
      final line = weight == null
          ? null
          : cookLineForFood(
              weight.name,
              lines: run.lines,
              items: items,
              localeCode: localeCode,
            );
      final changed = weight == null || line == null
          ? run.addLine(added)
          : _refillLine(
              run.weigh(line.id, (line.weighed ?? 0) + weight.grams),
              line.id,
            );
      final id = line?.id ?? added.id;
      taken = (lineId: id, before: line, after: changed.lineOf(id)!);
      return changed;
    });
    return done ? taken : null;
  }

  /// Removes the line [lineId]; a line that is gone already, as after a
  /// second tap, changes nothing.
  Future<bool> removeLine(String lineId) => change(
    (run) => run.lineOf(lineId) == null ? run : run.removeLine(lineId),
  );

  /// Takes the line [lineId] out on "Portion": a line that came in while
  /// cooking goes, any other stays ignored. `null` when it failed.
  Future<KochmodusRemoved?> removeFromPortion(String lineId) async {
    KochmodusRemoved? removed;
    final done = await change((run) {
      final line = run.lineOf(lineId);
      if (line == null) throw StateError('Line $lineId is gone.');
      removed = (line: line, index: run.lines.indexOf(line));
      return line.origin == CookLineOrigin.cooking
          ? run.removeLine(lineId)
          : run.settle(lineId, const LineIgnored());
    });
    return done ? removed : null;
  }

  /// Takes back what [removeFromPortion] did: the line is as it was, with its
  /// weight and its items, which take again for the run as it is now.
  Future<bool> undoRemove(KochmodusRemoved removed) => change(
    (run) => _refillLine(
      run.restoreLine(removed.line, index: removed.index),
      removed.line.id,
    ),
  );

  /// Cooks with the guide ("Mit Anleitung") or on the list.
  Future<bool> setGuide({required bool on}) =>
      change((run) => run.useGuide(on: on));

  /// Leaves "Zuweisen" for the cooking page ("Kochen"), which opens on
  /// "Töpfe", with cut takes filled up (`cookRefillCut`); a run that
  /// cooked already stays on its step. A draft is created now.
  Future<bool> toPots() => change(
    (run) => switch (run.step) {
      CookRunStep.assign || CookRunStep.paused => cookRefillCut(
        run,
        refillTakes,
      ).toStep(CookRunStep.pots),
      _ => run,
    },
  );

  /// Shows the instruction [index] in the guide.
  Future<bool> guideTo(int index) => change((run) => run.guideTo(index));

  /// Puts the line [lineId] into the pot [potId].
  Future<bool> setPot(String lineId, String potId) =>
      change((run) => run.setPot(lineId, potId));

  /// Sets what the cook typed in for the meal of [fallback]'s pot; the
  /// other fields stay as stored, or as [fallback] before the first input
  /// (see `kochmodusMealEdit`).
  Future<bool> editMeal(
    CookMealDraft fallback, {
    String? name,
    int? count,
    bool? inPieces,
    int? grossWeight,
  }) => change(
    kochmodusMealEdit(
      fallback,
      name: name,
      count: count,
      inPieces: inPieces,
      grossWeight: grossWeight,
    ),
  );

  /// Gives each meal of [defaults] its defaults when the cook typed nothing
  /// in for it yet ("In Vorrat", see `kochmodusWithDefaultMeals`).
  Future<bool> addDefaultMeals(List<CookMealDraft> defaults) =>
      change((run) => kochmodusWithDefaultMeals(run, defaults));

  /// Lets free cooking end with a Kochbuch recipe ("Ins Kochbuch").
  Future<bool> setToCookbook({required bool on}) =>
      change((run) => run.withToCookbook(on: on));

  // [run] with the assigned line [id] taking again from its items.
  CookRun _refillLine(CookRun run, String id) =>
      cookRefillLine(run, id, refillTakes);

  /// Goes on to portioning ("Fertig · Portionieren").
  Future<bool> toPortion() =>
      change((run) => run.toStep(CookRunStep.portion), next: true);
}
