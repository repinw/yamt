import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_eat_calculator.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meal_eat_sheet_controller.dart';

import '../../../../support/prepared_meal_test_data.dart';

final _now = DateTime(2026, 5, 13, 19, 5);

({ProviderContainer container, PreparedMealEatSheetControllerProvider provider})
_setUp(PreparedMeal meal) {
  final container = ProviderContainer(
    overrides: [clockProvider.overrideWithValue(() => _now)],
  );
  addTearDown(container.dispose);
  final provider = preparedMealEatSheetControllerProvider(
    meal: meal,
    localeName: 'en',
  );
  container.listen(provider, (_, _) {});
  return (container: container, provider: provider);
}

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

  test('submit rejects more than what is left', () {
    final (:container, :provider) = _setUp(_meal());
    final controller = container.read(provider.notifier)..setAmountText('3');

    expect(controller.submit(), isNull);
    expect(container.read(provider).hasAmountError, isTrue);
  });
}
