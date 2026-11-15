import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/inventory/application/prepared_meal_from_items.dart';
import 'package:yamt/features/inventory/application/prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/application/template_ingredient_unit_mapper.dart';
import 'package:yamt/features/inventory/data/cooked_meal_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_template_copy.dart';
import 'package:yamt/features/kochmodus/application/cook_finish_check.dart';
import 'package:yamt/features/kochmodus/application/cook_recipe_line.dart';
import 'package:yamt/features/kochmodus/application/cook_run_discard_service.dart';
import 'package:yamt/features/kochmodus/domain/cook_pot_split.dart';
import 'package:yamt/features/recipes/data/cook_run_repository.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';
import 'package:yamt/features/recipes/domain/recipes_exceptions.dart';

part 'cook_run_finish_service.g.dart';

/// What "In den Vorrat legen" put into the Vorrat ("Guten Appetit!").
typedef CookFinishSummary = ({
  /// The meals, one per pot in the pots' order, with their count and whether
  /// they are served in pieces.
  List<PreparedMeal> meals,

  /// Whether the meals went into cans: their count is cans.
  bool inCans,

  /// Whether free cooking also became a Kochbuch recipe.
  bool inCookbook,
});

/// The end of the household's cook runs.
@riverpod
CookRunFinishService cookRunFinishService(Ref ref) => CookRunFinishService(
  runs: ref.watch(cookRunRepositoryProvider),
  inventory: ref.watch(inventoryItemRepositoryProvider),
  meals: ref.watch(cookedMealRepositoryProvider),
  templates: ref.watch(preparedMealTemplateRepositoryProvider),
  clock: ref.watch(clockProvider),
);

/// Ends a cook run with "In Vorrat": one meal per pot, the stock its lines
/// take, and the run deleted, in one batch.
class CookRunFinishService {
  /// Creates the service.
  const new({
    required this._runs,
    required this._inventory,
    required this._meals,
    required this._templates,
    required this._clock,
  });

  final CookRunRepository _runs;
  final InventoryItemRepository _inventory;
  final CookedMealRepository _meals;
  final PreparedMealTemplateRepository _templates;
  final DateTime Function() _clock;

  /// Puts the meals of the run [runId] into the Vorrat as the run and the
  /// Vorrat are now, after every change written so far.
  ///
  /// Each pot becomes the meal `<cookingId>-<potId>` ([CookRun.cookingId])
  /// with the name, count and weight the cook typed in, built from the items
  /// as they are before cooking. Each item takes what all pots take from
  /// it, once. Takes of 0 write nothing. An item the run added holds what the
  /// cook has at home, so it stays while a line holds it, also with a take of
  /// 0, and its rest stays in the Vorrat; one that no line and no other run
  /// holds any more is deleted again. Free cooking with "Ins
  /// Kochbuch" first saves the recipe `cookbook-<cookingId>` and deletes it
  /// again when the meals do not go in and the run is still there.
  ///
  /// Throws a [CookRunGoneException] when the run is gone, a [StateError]
  /// when the run has no pots chosen, "In Vorrat" has to wait
  /// ([cookFinishBlocks]) or a meal has no name, and a
  /// [PreparedMealBuildException] when an item holds too little. Nothing is
  /// written then.
  Future<CookFinishSummary> finish(String runId) async {
    await _runs.pending;
    final run = await _runs.load(runId);
    if (run == null) {
      throw CookRunGoneException(runId);
    }
    if (run.pots == null) {
      throw StateError('Cook run $runId has no pots chosen.');
    }
    final items = await _inventory.readAllForChange();
    final byId = {for (final item in items) item.id: item};
    final blocks = cookFinishBlocks(run, byId);
    if (blocks.isNotEmpty) {
      throw StateError('Cook run $runId cannot finish yet: $blocks');
    }
    final now = _clock();
    final totals = <String, int>{};
    final meals = <PreparedMeal>[];
    for (final MapEntry(key: potId, value: lines) in cookLinesByPot(
      run,
    ).entries) {
      final amounts = _amountsOf(lines);
      meals.add(_meal(run, potId, amounts, items, now));
      for (final MapEntry(:key, :value) in amounts.entries) {
        totals[key] = (totals[key] ?? 0) + value;
      }
    }
    final changes = [
      for (final MapEntry(:key, :value) in totals.entries)
        _stockChange(byId[key], value),
    ];
    final inCookbook = run.kind == CookRunKind.free && run.toCookbook;
    if (inCookbook) {
      await _saveRecipe(run, meals, totals, items, now);
    }
    try {
      await _meals.addCookedMeals(
        meals: meals,
        changes: changes,
        deleteItemIds: untouchedAddedItemIds(
          run,
          items,
          used: {
            for (final line in run.lines)
              if (line.settlement case LineAssigned(:final takes))
                for (final take in takes) take.itemId,
          },
          runs: await _runs.watchAll().first,
        ),
        happenedAt: now,
        endedRun: run,
      );
    } on Object {
      // A finish that went through meanwhile ended the run; its recipe stays.
      if (inCookbook && await _runs.load(run.id) != null) {
        await _templates.delete(_recipeId(run));
      }
      rethrow;
    }
    return (
      meals: meals,
      inCans: switch (run.pots) {
        CookPotsChosen(:final inCans) => inCans,
        _ => false,
      },
      inCookbook: inCookbook,
    );
  }

  // Free cooking as a Kochbuch recipe: its lines as this cooking used them
  // (cookRecipeLineText), with what all pots together took.
  Future<void> _saveRecipe(
    CookRun run,
    List<PreparedMeal> meals,
    Map<String, int> totals,
    List<InventoryItem> items,
    DateTime now,
  ) async {
    final id = _recipeId(run);
    final cooked = buildPreparedMealCreationResult(
      currentItems: items,
      preparedMealId: id,
      now: now,
      name: meals.first.name,
      imageAssetId: null,
      totalPortions: meals.fold(0, (sum, meal) => sum + meal.totalPortions),
      inputs: _inputsOf(totals),
    ).preparedMeal;
    final byId = {for (final item in items) item.id: item};
    final texts = {
      for (final line in run.lines)
        line.id: cookRecipeLineText(run, line, byId),
    };
    final template = cooked
        .copyWith(
          recipeIngredients: [for (final line in run.lines) texts[line.id]!],
          ignoredRecipeIngredients: [
            for (final line in run.lines)
              if (line.settlement is LineIgnored) texts[line.id]!,
          ],
          recipeIngredientAmountConversions: {
            for (final line in run.lines)
              if (line.conversion case final conversion?)
                texts[line.id]!: RecipeIngredientAmountConversion(
                  amountPerPiece: conversion.amountPerPiece,
                  unit: conversion.unit.toInventoryAmountUnit(),
                ),
          },
        )
        .asTemplate(id: id, now: now);
    if (!await _templates.save(template)) {
      throw StateError('The Kochbuch recipe $id was not saved.');
    }
  }
}

// The Kochbuch recipe that free cooking with "Ins Kochbuch" saves.
String _recipeId(CookRun run) => 'cookbook-${run.cookingId}';

// What [lines] take from each item; takes of 0 write nothing.
Map<String, int> _amountsOf(List<CookRunLine> lines) {
  final amounts = <String, int>{};
  for (final line in lines) {
    if (line.settlement case LineAssigned(:final takes)) {
      for (final take in takes) {
        if (take.amount > 0) {
          amounts[take.itemId] = (amounts[take.itemId] ?? 0) + take.amount;
        }
      }
    }
  }
  return amounts;
}

// An added item holds the cook's stock, so discarding the meal gives it back
// instead of deleting it.
List<PreparedMealItemInput> _inputsOf(Map<String, int> amounts) => [
  for (final MapEntry(:key, :value) in amounts.entries)
    PreparedMealItemInput(itemId: key, usedAmount: value),
];

// The meal of the pot [potId], built from the items before cooking, so a
// second pot does not see the first one's takes.
PreparedMeal _meal(
  CookRun run,
  String potId,
  Map<String, int> amounts,
  List<InventoryItem> items,
  DateTime now,
) {
  final draft = run.meals.where((meal) => meal.potId == potId).firstOrNull;
  if (draft == null) {
    // cookFinishBlocks names it first.
    throw StateError('Cook run ${run.id} has no meal for pot $potId.');
  }
  final typed = draft.name.trim();
  final name = typed.isEmpty ? run.name.trim() : typed;
  if (name.isEmpty) {
    // The page fills in the default name; free cooking has no run name.
    throw StateError('Cook run ${run.id} has no name for pot $potId.');
  }
  final meal = buildPreparedMealCreationResult(
    currentItems: items,
    preparedMealId: '${run.cookingId}-$potId',
    now: now,
    name: name,
    imageAssetId: run.imageAssetId,
    totalPortions: draft.count,
    inputs: _inputsOf(amounts),
  ).preparedMeal;
  final (emptyWeight, inCans) = switch (run.pots) {
    CookPotsChosen(:final pots, :final inCans) => (
      pots.where((pot) => pot.id == potId).firstOrNull?.emptyWeight,
      inCans,
    ),
    _ => (null, false),
  };
  final gross = draft.grossWeight;
  final net = emptyWeight == null || gross == null ? null : gross - emptyWeight;
  // Cans and pieces left the pot, so eating never weighs it again; pieces
  // have no weight at all (PreparedMealRules).
  final staysInPot = !inCans && !draft.inPieces;
  return meal.copyWith(
    imageUrl: run.imageUrl,
    potTareWeight: net != null && staysInPot ? emptyWeight : null,
    finalNetWeight: draft.inPieces ? null : net,
    servedInPieces: draft.inPieces ? true : null,
  );
}

// The item [before] after all pots took [total] from it.
CookedStockChange _stockChange(InventoryItem? before, int total) {
  if (before == null) {
    throw const PreparedMealBuildException(
      PreparedMealCreationFailureReason.itemUnavailable,
    );
  }
  final after = before.reducedBy(total);
  if (after == null) {
    throw const PreparedMealBuildException(
      PreparedMealCreationFailureReason.insufficientAmount,
    );
  }
  return (before: before, after: after);
}
