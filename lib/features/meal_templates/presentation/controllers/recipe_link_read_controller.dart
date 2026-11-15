import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/data/prepared_meal_recipe_importer.dart';

part 'recipe_link_read_controller.g.dart';

/// Reads recipe pages for the link flow.
@riverpod
class RecipeLinkReadController extends _$RecipeLinkReadController {
  @override
  FutureOr<void> build() {}

  /// The recipe at [recipeUrl], or `null` when its page cannot be read. Stays
  /// alive until the reading ends, since the flow that asks does not listen.
  Future<PreparedMealRecipeImport?> read(
    String recipeUrl, {
    required String localeName,
  }) async {
    final link = ref.keepAlive();
    try {
      return await ref
          .read(preparedMealRecipeImporterProvider)
          .importRecipe(recipeUrl, localeName: localeName);
    } on Object catch (error, stackTrace) {
      log(
        'Failed to import recipe from $recipeUrl',
        name: 'RecipeLinkReadController',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    } finally {
      link.close();
    }
  }
}
