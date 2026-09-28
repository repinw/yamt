import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_bundle_component.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_entry_details_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_entry_details_state.dart';

import '../../../calories/support/fake_calories_repositories.dart';

final _now = DateTime(2026, 2, 26, 9, 30);

CalorieEntry _skyr({double amount = 200}) {
  return CalorieEntry.create(
    id: 'entry-1',
    userId: 'user-1',
    name: 'Skyr',
    mealType: MealType.breakfast,
    consumedAmount: amount,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 100,
    per100Protein: 10,
    per100Carbs: 5,
    per100Fat: 1,
    loggedAt: DateTime(2026, 2, 25, 8, 15),
    createdAt: DateTime(2026, 2, 25, 8, 15),
    updatedAt: DateTime(2026, 2, 25, 8, 15),
  );
}

CalorieEntry _preparedMeal() {
  return CalorieEntry.bundle(
    id: 'bundle-1',
    userId: 'user-1',
    name: 'Chili',
    mealType: MealType.lunch,
    totalKcal: 420,
    totalProtein: 28,
    totalCarbs: 35,
    totalFat: 18,
    bundleSourcePreparedMealId: 'prepared-1',
    bundleConsumedPortions: 1,
    bundleTotalPortions: 4,
    bundleComponents: const [
      CalorieEntryBundleComponent(
        name: 'Beans',
        amountLabel: '150 g',
        totalKcal: 120,
        totalProtein: 8,
        totalCarbs: 18,
        totalFat: 1,
      ),
    ],
    loggedAt: DateTime(2026, 2, 25, 12),
  );
}

class _CachingCalorieLogRepository extends FakeCalorieLogRepository {
  new({required List<CalorieEntry> super.initialEntries});

  @override
  CalorieEntry? cachedById(String entryId) {
    return entries.where((entry) => entry.id == entryId).firstOrNull;
  }
}

typedef _Harness = ({
  ProviderContainer container,
  DiaryEntryDetailsControllerProvider provider,
  List<AsyncValue<DiaryEntryDetailsState?>> states,
});

Future<_Harness> _open(
  FakeCalorieLogRepository repository, {
  String entryId = 'entry-1',
}) async {
  final container = ProviderContainer(
    overrides: [
      calorieLogRepositoryProvider.overrideWithValue(repository),
      clockProvider.overrideWithValue(() => _now),
    ],
  );
  addTearDown(container.dispose);
  final provider = diaryEntryDetailsControllerProvider(entryId);
  final states = <AsyncValue<DiaryEntryDetailsState?>>[];
  final subscription = container.listen(
    provider,
    (_, next) => states.add(next),
    fireImmediately: true,
  );
  addTearDown(subscription.close);
  await pumpEventQueue();
  return (container: container, provider: provider, states: states);
}

DiaryEntryDetailsState _state(_Harness harness) {
  return harness.container.read(harness.provider).requireValue!;
}

DiaryEntryDetailsController _controller(_Harness harness) {
  return harness.container.read(harness.provider.notifier);
}

void main() {
  test('loads the entry with its amount in the field', () async {
    final harness = await _open(
      FakeCalorieLogRepository(initialEntries: [_skyr()]),
    );

    expect(harness.states.first, isA<AsyncLoading<DiaryEntryDetailsState?>>());
    expect(harness.states.last, isA<AsyncData<DiaryEntryDetailsState?>>());
    final state = _state(harness);
    expect(state.entry.id, 'entry-1');
    expect(state.amountText, '200');
    expect(state.today, _now);
    expect(state.canEditAmount, isTrue);
    expect(state.changedAmount, isNull);
    expect(state.preview.totalKcal, 200);
  });

  test('shows a cached entry without a loading state', () async {
    final harness = await _open(
      _CachingCalorieLogRepository(initialEntries: [_skyr()]),
    );

    expect(harness.states, hasLength(1));
    expect(harness.states.single.value?.entry.name, 'Skyr');
  });

  test('is null for a missing entry', () async {
    final harness = await _open(FakeCalorieLogRepository(), entryId: 'missing');

    expect(harness.states.last, const AsyncData<DiaryEntryDetailsState?>(null));
  });

  test(
    'recomputes the totals from the per-100 values of the typed amount',
    () async {
      final harness = await _open(
        FakeCalorieLogRepository(initialEntries: [_skyr()]),
      );

      _controller(harness).setAmountText('150');

      final state = _state(harness);
      expect(state.changedAmount, 150);
      expect(state.preview.consumedAmount, 150);
      expect(state.preview.totalKcal, 150);
      expect(state.preview.totalProtein, 15);
      expect(state.preview.totalCarbs, 7.5);
      expect(state.preview.totalFat, 1.5);
      // The stored entry stays until the amount is saved.
      expect(state.entry.consumedAmount, 200);
    },
  );

  test('accepts a decimal comma', () async {
    final harness = await _open(
      FakeCalorieLogRepository(initialEntries: [_skyr()]),
    );

    _controller(harness).setAmountText('37,5');

    expect(_state(harness).changedAmount, 37.5);
    expect(_state(harness).preview.totalKcal, 37.5);
  });

  test('rejects an empty or zero amount', () async {
    final harness = await _open(
      FakeCalorieLogRepository(initialEntries: [_skyr()]),
    );

    _controller(harness).setAmountText('0');
    expect(_state(harness).hasAmountError, isTrue);
    expect(_state(harness).changedAmount, isNull);
    expect(_state(harness).preview.totalKcal, 200);

    _controller(harness).setAmountText('');
    expect(_state(harness).hasAmountError, isTrue);
  });

  test('keeps a rounded stored amount unchanged', () async {
    final harness = await _open(
      FakeCalorieLogRepository(initialEntries: [_skyr(amount: 33.333)]),
    );

    final state = _state(harness);
    expect(state.amountText, '33.33');
    expect(state.changedAmount, isNull);
  });

  test('takes a ruler amount as field text', () async {
    final harness = await _open(
      FakeCalorieLogRepository(initialEntries: [_skyr()]),
    );

    _controller(harness).pickAmount(250);

    expect(_state(harness).amountText, '250');
    expect(_state(harness).rulerValue, 250);
    expect(_state(harness).preview.totalKcal, 250);
  });

  test('sizes the ruler to at least twice the logged amount', () async {
    final small = await _open(
      FakeCalorieLogRepository(initialEntries: [_skyr()]),
    );
    expect(_state(small).rulerMax, 1000);
    expect(_state(small).rulerStep, 25);

    final large = await _open(
      FakeCalorieLogRepository(initialEntries: [_skyr(amount: 800)]),
    );
    expect(_state(large).rulerMax, 1600);
  });

  test('moves the entry to another meal', () async {
    final harness = await _open(
      FakeCalorieLogRepository(initialEntries: [_skyr()]),
    );

    final move = _controller(harness).moveToMeal(MealType.snack);

    expect(move?.previous.mealType, MealType.breakfast);
    expect(move?.updated.mealType, MealType.snack);
    expect(move?.updated.updatedAt, _now);
    expect(_state(harness).entry.mealType, MealType.snack);
    expect(_controller(harness).moveToMeal(MealType.snack), isNull);
  });

  test('moves the entry to another day at the same time', () async {
    final harness = await _open(
      FakeCalorieLogRepository(initialEntries: [_skyr()]),
    );

    final move = _controller(harness).moveToDay(DateTime(2026, 2, 23));

    expect(move?.updated.loggedAt, DateTime(2026, 2, 23, 8, 15));
    expect(_state(harness).entry.loggedAt, DateTime(2026, 2, 23, 8, 15));
    expect(_controller(harness).moveToDay(DateTime(2026, 2, 23)), isNull);

    _controller(harness).showEntry(move!.previous);
    expect(_state(harness).entry.loggedAt, DateTime(2026, 2, 25, 8, 15));
  });

  test('keeps the amount of a bundle fixed', () async {
    final harness = await _open(
      FakeCalorieLogRepository(initialEntries: [_preparedMeal()]),
      entryId: 'bundle-1',
    );

    _controller(harness).setAmountText('50');

    final state = _state(harness);
    expect(state.canEditAmount, isFalse);
    expect(state.hasAmountError, isFalse);
    expect(state.changedAmount, isNull);
    expect(state.preview.totalKcal, 420);
  });
}
