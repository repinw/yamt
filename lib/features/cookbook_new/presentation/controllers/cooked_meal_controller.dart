import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_cooking_service.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

part 'cooked_meal_controller.g.dart';

/// Saves the "Gekocht" step of the meal [mealId].
@riverpod
class CookedMealController extends _$CookedMealController {
  @override
  FutureOr<void> build(String mealId) {}

  /// Marks the meal as cooked with [totalPortions], counted in pieces when
  /// [servedInPieces], and with the pot's
  /// [potTareWeight] and the food's [netWeight] when it was weighed. Returns
  /// the cooked meal, or `null` when it failed.
  Future<PreparedMeal?> save({
    required int totalPortions,
    required bool servedInPieces,
    required int? potTareWeight,
    required int? netWeight,
  }) async {
    final link = ref.keepAlive();
    state = const AsyncLoading();
    try {
      final result = await AsyncValue.guard(
        () => ref
            .read(preparedMealCookingServiceProvider)
            .finishCooking(
              mealId: mealId,
              totalPortions: totalPortions,
              servedInPieces: servedInPieces,
              potTareWeight: netWeight == null ? null : potTareWeight,
              finalNetWeight: netWeight,
            ),
      );
      if (result case AsyncError(:final error, :final stackTrace)) {
        log(
          'Failed to mark the meal as cooked.',
          name: 'CookedMealController',
          error: error,
          stackTrace: stackTrace,
        );
      }
      if (ref.mounted) {
        state = result;
      }
      return result.value;
    } finally {
      link.close();
    }
  }
}
