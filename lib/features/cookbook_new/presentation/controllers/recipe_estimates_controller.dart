import 'dart:async';
import 'dart:collection';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/cookbook_new/application/recipe_estimate_service.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_ingredient_lines.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/cookbook_controller.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

part 'recipe_estimates_controller.g.dart';

const _maxRunning = 3;

/// Estimates every saved recipe of the Kochbuch whose estimate does not fit
/// its lines, at most [_maxRunning] at once, and holds the ids of the recipes
/// running or waiting for their turn, so their cards can show that a value
/// is coming.
///
/// Each recipe is tried once while this controller lives, which in the home
/// shell is until the next app start; a failure leaves it without an
/// estimate. Only opening its recipe page tries again, and not when the AI's
/// answer could not be used.
@riverpod
class RecipeEstimatesController extends _$RecipeEstimatesController {
  final Set<String> _tried = {};
  final Queue<String> _waiting = Queue();
  int _running = 0;

  @override
  Set<String> build() {
    ref.listen(cookbookTemplatesProvider, (_, next) {
      if (next.value case final templates?) {
        // State may not change while the listened provider builds.
        scheduleMicrotask(() => _enqueue(templates));
      }
    }, fireImmediately: true);
    return const {};
  }

  void _enqueue(List<PreparedMeal> templates) {
    if (!ref.mounted) return;
    final missing = [
      for (final recipe in templates)
        if (recipe.needsRecipeEstimate && _tried.add(recipe.id)) recipe.id,
    ];
    if (missing.isEmpty) return;
    state = {...state, ...missing};
    _waiting.addAll(missing);
    _startWaiting();
  }

  void _startWaiting() {
    while (_running < _maxRunning && _waiting.isNotEmpty) {
      _running += 1;
      _estimate(_waiting.removeFirst());
    }
  }

  void _estimate(String recipeId) {
    unawaited(
      // Inside the future, so a service that cannot be built fails like an
      // estimate.
      Future<void>(
            () => ref.read(recipeEstimateServiceProvider).estimate(recipeId),
          )
          .catchError(
            (Object error, StackTrace stackTrace) => log(
              'Estimating the recipe $recipeId failed.',
              name: 'RecipeEstimatesController',
              error: error,
              stackTrace: stackTrace,
            ),
          )
          .whenComplete(() {
            if (!ref.mounted) return;
            _running -= 1;
            state = state.difference({recipeId});
            _startWaiting();
          }),
    );
  }
}
