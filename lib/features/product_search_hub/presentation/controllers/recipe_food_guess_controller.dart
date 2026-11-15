import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/domain/food_estimate.dart';
import 'package:yamt/features/product_search_hub/data/'
    'food_estimate_repository.dart';

part 'recipe_food_guess_controller.g.dart';

/// Estimates a food by its name for a recipe line whose cook does not want
/// to pick one ("Egal, irgendeins"). The state is loading while the AI
/// works and holds the error of a failed estimate.
@riverpod
class RecipeFoodGuessController extends _$RecipeFoodGuessController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Estimates the food named [food].
  ///
  /// Returns the estimate, or null when it failed or another one runs.
  Future<FoodEstimate?> guess(String food) async {
    if (state.isLoading) return null;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(foodEstimateRepositoryProvider)
          .loadEstimate(description: food, photos: const []),
    );
    if (!ref.mounted) return null;
    state = result;
    return result.value;
  }
}
