import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_eat_calculator.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meal_eat_sheet_controller.dart';

import '../../../../support/prepared_meal_test_data.dart';

final _now = DateTime(2026, 5, 13, 19, 5);

({ProviderContainer container, PreparedMealEatSheetControllerProvider provider})
_setUp(PreparedMeal meal) {
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(() => _now),
      inventoryQuickEatMealsProvider.overrideWith(
        (ref) => Stream.value(const <PreparedMeal>[]),
      ),
    ],
  );
  addTearDown(container.dispose);
  final provider = preparedMealEatSheetControllerProvider(
    meal: meal,
    localeName: 'en',
  );
  container.listen(provider, (_, _) {});
  return (container: container, provider: provider);
}

Future<
  ({
    ProviderContainer container,
    PreparedMealEatSheetControllerProvider provider,
  })
>
_setUpFollowing(PreparedMeal opened, List<PreparedMeal> stored) async {
  final meals = StreamController<List<PreparedMeal>>();
  addTearDown(meals.close);
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(() => _now),
      inventoryQuickEatMealsProvider.overrideWith((ref) => meals.stream),
    ],
  );
  addTearDown(container.dispose);
  final provider = preparedMealEatSheetControllerProvider(
    meal: opened,
    localeName: 'en',
  );
  container.listen(provider, (_, _) {});
  meals.add(stored);
  await pumpEventQueue();
  _emit = (next) async {
    meals.add(next);
    await pumpEventQueue();
  };
  return (container: container, provider: provider);
}

late Future<void> Function(List<PreparedMeal> meals) _emit;

PreparedMeal _meal() {
  return preparedMealTestData(totalPortions: 4).copyWith(finalNetWeight: 800);
}

void main() {
  test('starts with one portion at the clock time', () {
    final (:container, :provider) = _setUp(_meal());

    final state = container.read(provider);

    expect(state.amountText, '1');
    expect(state.loggedAt, _now);
    expect(state.nutrition?.eaten.kcal, 100);
    expect(state.amountMax, state.calculator.meal.remainingPortions);
    expect(state.amountStep, 0.25);
  });

  test('switching the unit converts the entered amount both ways', () {
    final (:container, :provider) = _setUp(_meal());
    final controller = container.read(provider.notifier)..switchMode();

    final grams = container.read(provider);
    expect(grams.mode, PreparedMealEatAmountMode.grams);
    expect(grams.amountText, '200');
    expect(grams.amountMax, grams.calculator.meal.remainingNetWeight);

    controller.switchMode();

    final portions = container.read(provider);
    expect(portions.mode, PreparedMealEatAmountMode.portions);
    expect(portions.amountText, '1');
  });

  test('submit returns portions for a valid amount', () {
    final (:container, :provider) = _setUp(_meal());
    final controller = container.read(provider.notifier)..pickAmount(2);

    final request = controller.submit();

    expect(request?.portions, 2);
    expect(request?.loggedDay, _now);
  });

  test('a plan day goes into the request but not into the page', () {
    final (:container, :provider) = _setUp(_meal());
    final tomorrow = _now.add(const Duration(days: 1));

    final request = container
        .read(provider.notifier)
        .submit(asPlan: true, planDay: tomorrow);

    expect(request?.loggedDay.day, tomorrow.day);
    expect(request?.isPlan, isTrue);
    expect(container.read(provider).loggedAt, _now);
  });

  test('following the Vorrat keeps the input and logs the new meal', () async {
    final opened = _meal().copyWith(pendingRecipeIngredients: ['Salt']);
    final filled = _meal().copyWith(totalKcal: 800);
    final (:container, :provider) = await _setUpFollowing(opened, [opened]);
    final controller = container.read(provider.notifier)..pickAmount(2);

    await _emit([filled]);

    final state = container.read(provider);
    expect(state.amountText, '2');
    expect(state.nutrition?.eaten.kcal, 400);
    expect(controller.submit()?.meal, filled);
  });

  test('following the Vorrat starts from the meal it holds now', () async {
    final opened = _meal().copyWith(pendingRecipeIngredients: ['Salt']);
    final filled = _meal().copyWith(totalKcal: 800);
    final (:container, :provider) = await _setUpFollowing(opened, [filled]);

    expect(container.read(provider).calculator.meal, filled);
  });

  test('a meal the Vorrat does not hold keeps the opened copy', () {
    final opened = _meal();
    final (:container, :provider) = _setUp(opened);

    expect(container.read(provider.notifier).submit()?.meal, opened);
  });

  test('submit rejects more than what is left', () {
    final (:container, :provider) = _setUp(_meal());
    final controller = container.read(provider.notifier)..setAmountText('3');

    expect(controller.submit(), isNull);
    expect(container.read(provider).hasAmountError, isTrue);
  });
}
