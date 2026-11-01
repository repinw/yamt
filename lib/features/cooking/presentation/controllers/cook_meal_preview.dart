import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/cooking/application/cook_finish_service.dart';
import 'package:yamt/features/cooking/domain/cook_session.dart';
import 'package:yamt/features/cooking/presentation/controllers/cook_view_builder.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/domain/eat_meal_nutrition.dart';

part 'cook_meal_preview.g.dart';

/// The nutrients of the whole meal that [portioning] would put into the
/// Vorrat now. It fails like "In Vorrat" would, for example when a food
/// lacks nutrition.
@riverpod
AsyncValue<EatMealNutrition> cookMealPreview(
  Ref ref,
  String recipeId,
  String localeCode,
  CookPortioning portioning,
) {
  final view = ref.watch(cookViewProvider(recipeId, localeCode));
  final items = ref.watch(inventoryQuickEatItemsProvider);
  final now = ref.watch(clockProvider)();
  return switch ((view, items)) {
    (AsyncError(:final error, :final stackTrace), _) ||
    (
      _,
      AsyncError(:final error, :final stackTrace),
    ) => AsyncError(error, stackTrace),
    (AsyncData(value: final view?), AsyncData(value: final items)) => _preview(
      () {
        final meal = buildCookedMeal(
          items: items,
          recipe: view.recipe,
          session: view.session,
          portioning: portioning,
          id: 'preview',
          now: now,
        ).preparedMeal;
        return EatMealNutrition.ofPreparedMeal(meal, 1, withWeight: true);
      },
    ),
    _ => const AsyncLoading(),
  };
}

// The nutrients [build] returns, or its failure.
AsyncValue<EatMealNutrition> _preview(EatMealNutrition Function() build) {
  try {
    return AsyncData(build());
  } on Object catch (error, stackTrace) {
    return AsyncError(error, stackTrace);
  }
}
