import 'dart:async';
import 'dart:developer' show log;

import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/cookbook_new/data/recipe_estimate_repository.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_ingredient_lines.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

part 'recipe_estimate_service.g.dart';

/// Recipe estimate service.
@riverpod
RecipeEstimateService recipeEstimateService(Ref ref) => RecipeEstimateService(
  templates: ref.watch(preparedMealTemplateRepositoryProvider),
  estimates: ref.watch(recipeEstimateRepositoryProvider),
  clock: ref.watch(clockProvider),
  runs: ref.watch(recipeEstimateRunsProvider),
);

/// Recipe estimate runs.
@Riverpod(keepAlive: true)
RecipeEstimateRuns recipeEstimateRuns(Ref ref) => RecipeEstimateRuns();

/// What this app run knows about recipe estimates, by recipe, portions, and
/// lines. It outlives the short-lived [RecipeEstimateService], so all its
/// callers share it. Nothing of it is stored.
class RecipeEstimateRuns {
  /// The estimates running now, which a caller for the same key joins.
  final running = <String, Future<bool>>{};

  /// The keys whose AI answer could not be used, which are not asked again
  /// in this app run. A changed line or portion count is a new key.
  final unusable = <String>{};
}

/// Gives a saved recipe the AI's rough nutrition per portion and a weight
/// per ingredient line, so the cook can plan before any Vorrat food is
/// assigned.
class RecipeEstimateService {
  /// Creates the service.
  const new({
    required this._templates,
    required this._estimates,
    required this._clock,
    required this._runs,
  });

  final PreparedMealTemplateRepository _templates;
  final RecipeEstimateRepository _estimates;
  final DateTime Function() _clock;
  final RecipeEstimateRuns _runs;

  /// Estimates the saved recipe [recipeId] unless its estimate already fits
  /// its ingredient lines and portions
  /// ([RecipeIngredientLines.needsRecipeEstimate]) or this app run got an
  /// answer for them that could not be used. A caller while the same lines
  /// and portions are being estimated joins that estimate, so they cost one
  /// AI call.
  ///
  /// The answer goes onto the recipe as it is saved then, in a transaction,
  /// keeping the weights the cook typed. It is dropped when the recipe is
  /// gone, when the lines or portions changed meanwhile, since that change
  /// estimates again, or when a fitting estimate came first.
  ///
  /// Returns whether the saved recipe holds an estimate that fits it: one
  /// that was there, came first, or was saved now. It is `false` when the
  /// recipe is gone, its lines or portions changed meanwhile, or the AI's
  /// answer for them could not be used.
  /// Throws when reading, estimating, or saving fails.
  Future<bool> estimate(String recipeId) async {
    final recipe = await _load(recipeId);
    if (recipe == null) {
      return false;
    }
    if (!recipe.needsRecipeEstimate) {
      return true;
    }
    final key = recipe.recipeEstimateKey;
    if (_runs.unusable.contains(key)) {
      return false;
    }
    return await (_runs.running[key] ??= _askAndSave(recipe, key).whenComplete(
      () {
        // Not returned: whenComplete would wait for it, and it is this
        // future.
        unawaited(_runs.running.remove(key));
      },
    ));
  }

  Future<bool> _askAndSave(PreparedMeal recipe, String key) async {
    final RecipeEstimateAnswer answer;
    try {
      answer = await _estimates.loadEstimate(
        name: recipe.name,
        portions: recipe.totalPortions,
        lines: recipe.recipeIngredients,
        now: _clock(),
      );
    } on FormatException {
      _runs.unusable.add(key);
      rethrow;
    }
    // Set on each try of the transaction, which may run the change again.
    var fits = false;
    await _templates.update(recipe.id, (latest) {
      fits = latest.recipeEstimateKey == key;
      return !fits || latest.fittingRecipeEstimate != null
          ? null
          : latest.withRecipeEstimate(answer.estimate, answer.weights);
    });
    return fits;
  }

  /// Starts [estimate] without waiting for it. A failure is logged and
  /// leaves the recipe without an estimate; the cook is not told.
  void estimateInBackground(String recipeId) => unawaited(
    estimate(recipeId).then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) => log(
        'Estimating the recipe $recipeId failed.',
        name: 'RecipeEstimateService',
        error: error,
        stackTrace: stackTrace,
      ),
    ),
  );

  Future<PreparedMeal?> _load(String recipeId) async =>
      (await _templates.readAll()).firstWhereOrNull((t) => t.id == recipeId);
}
