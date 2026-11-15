import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/food_estimate.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/product_search_hub/data/'
    'food_estimate_repository.dart';
import 'package:yamt/features/product_search_hub/domain/food_estimate.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_exceptions.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'recipe_food_guess_controller.dart';

const _estimate = FoodEstimate(
  name: 'Flour',
  portionGrams: 50,
  kcalLean: 170,
  kcalRich: 190,
  per100: GlobalFoodNutrition(
    qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
    per100Kcal: 350,
  ),
  ingredients: [],
);

class _FakeEstimates implements FoodEstimateRepository {
  new(this.result);

  final Completer<FoodEstimate> result;
  final descriptions = <String>[];
  final photoCounts = <int>[];

  @override
  Future<FoodEstimate> loadEstimate({
    required String description,
    required List<FoodEstimatePhoto> photos,
  }) {
    descriptions.add(description);
    photoCounts.add(photos.length);
    return result.future;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

({ProviderContainer container, List<AsyncValue<void>> states}) _setUp(
  _FakeEstimates estimates,
) {
  final container = ProviderContainer(
    overrides: [foodEstimateRepositoryProvider.overrideWithValue(estimates)],
  );
  addTearDown(container.dispose);
  final states = <AsyncValue<void>>[];
  container.listen(
    recipeFoodGuessControllerProvider,
    (_, next) => states.add(next),
  );
  return (container: container, states: states);
}

void main() {
  test('asks the estimate with the food name, loading then data', () async {
    final estimates = _FakeEstimates(Completer());
    final (:container, :states) = _setUp(estimates);

    final future = container
        .read(recipeFoodGuessControllerProvider.notifier)
        .guess('Mehl');
    expect(container.read(recipeFoodGuessControllerProvider).isLoading, isTrue);
    estimates.result.complete(_estimate);

    expect(await future, _estimate);
    expect(estimates.descriptions, ['Mehl']);
    expect(estimates.photoCounts, [0]);
    expect(states.map((state) => state.isLoading), [true, false]);
    expect(container.read(recipeFoodGuessControllerProvider).hasError, isFalse);
  });

  test('a failed estimate ends in an error and returns null', () async {
    final estimates = _FakeEstimates(Completer());
    final (:container, :states) = _setUp(estimates);

    final future = container
        .read(recipeFoodGuessControllerProvider.notifier)
        .guess('Mehl');
    estimates.result.completeError(const FoodEstimateUnclearException());

    expect(await future, isNull);
    final state = container.read(recipeFoodGuessControllerProvider);
    expect(state.hasError, isTrue);
    expect(state.error, isA<FoodEstimateUnclearException>());
  });

  test('a second guess while one runs is ignored', () async {
    final estimates = _FakeEstimates(Completer());
    final (:container, states: _) = _setUp(estimates);
    final notifier = container.read(recipeFoodGuessControllerProvider.notifier);

    final first = notifier.guess('Mehl');
    final second = await notifier.guess('Zucker');
    estimates.result.complete(_estimate);
    await first;

    expect(second, isNull);
    expect(estimates.descriptions, ['Mehl']);
  });
}
