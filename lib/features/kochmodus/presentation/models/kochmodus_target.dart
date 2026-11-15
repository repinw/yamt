import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:yamt/features/kochmodus/application/cook_run_start_service.dart';

part 'kochmodus_target.freezed.dart';

/// What the cooking page opens: a recipe of the Kochbuch, a cook run of the
/// household, or new free cooking.
@freezed
sealed class KochmodusTarget with _$KochmodusTarget {
  /// The recipe [recipeId], for [portions] portions or the recipe's own.
  /// Opens the household's run of the recipe when it has one.
  const factory recipe({required String recipeId, int? portions}) =
      KochmodusRecipeTarget;

  /// The cook run [runId] of the household.
  const factory run(String runId) = KochmodusRunTarget;

  /// New free cooking that will be stored as the run [runId].
  const factory free(String runId) = KochmodusFreeTarget;

  const new _();

  /// The id of the cook run the page shows or will store; for a recipe
  /// [cookRecipeRunId], as the start service names it.
  String get cookRunId => switch (this) {
    KochmodusRecipeTarget(:final recipeId) => cookRecipeRunId(recipeId),
    KochmodusRunTarget(:final runId) ||
    KochmodusFreeTarget(:final runId) => runId,
  };
}
