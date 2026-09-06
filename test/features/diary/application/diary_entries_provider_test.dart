import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/features/diary/application/diary_balance_provider.dart';
import 'package:yamt/features/diary/application/diary_entries_provider.dart';

import '../../calories/support/fake_calories_repositories.dart';
import '../support/diary_dashboard_test_support.dart';

void main() {
  final selectedDay = DateTime(2026, 4, 27);

  test('shares one entries fetch across diary day consumers', () async {
    final entriesCompleter = Completer<List<CalorieEntry>>();
    var readCount = 0;
    final repository = FakeCalorieLogRepository()
      ..onReadEntriesForDay = (day) {
        readCount += 1;
        expect(day, selectedDay);
        return entriesCompleter.future;
      };
    final container = ProviderContainer(
      overrides: [
        calorieLogRepositoryProvider.overrideWithValue(repository),
        calorieWeekOverviewForWindowProvider(
          selectedDay,
        ).overrideWith(
          (ref) => diaryWeekOverviewForTest(selectedDay: selectedDay),
        ),
        burnWeekRunControllerProvider.overrideWith(
          _FakeBurnWeekRunController.new,
        ),
      ],
    );
    addTearDown(repository.dispose);
    addTearDown(container.dispose);

    final entriesSubscription = container.listen(
      diaryEntriesForDayProvider(selectedDay),
      (_, _) {},
    );
    final balanceSubscription = container.listen(
      diaryBalanceSourceProvider(selectedDay),
      (_, _) {},
    );
    final secondEntriesSubscription = container.listen(
      diaryEntriesForDayProvider(selectedDay),
      (_, _) {},
    );
    addTearDown(entriesSubscription.close);
    addTearDown(balanceSubscription.close);
    addTearDown(secondEntriesSubscription.close);

    await container.pump();
    expect(readCount, 1);

    entriesCompleter.complete([
      _entry(id: 'breakfast', day: selectedDay, mealType: MealType.breakfast),
    ]);

    final entries = await container.read(
      diaryEntriesForDayProvider(selectedDay).future,
    );
    final balance = await container.read(
      diaryBalanceSourceProvider(selectedDay).future,
    );

    expect(entries, hasLength(1));
    expect(balance.selectedDayEntries, hasLength(1));
    expect(readCount, 1);
  });

  test('autoDispose clears entries cache after last listener closes', () async {
    var readCount = 0;
    final repository = FakeCalorieLogRepository()
      ..onReadEntriesForDay = (_) async {
        readCount += 1;
        return const <CalorieEntry>[];
      };
    final container = ProviderContainer(
      overrides: [calorieLogRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(repository.dispose);
    addTearDown(container.dispose);

    final provider = diaryEntriesForDayProvider(selectedDay);
    final subscription = container.listen(provider, (_, _) {});
    await container.read(provider.future);
    expect(readCount, 1);

    subscription.close();
    await container.pump();

    final nextSubscription = container.listen(provider, (_, _) {});
    addTearDown(nextSubscription.close);
    await container.read(provider.future);
    expect(readCount, 2);
  });
}

class _FakeBurnWeekRunController extends BurnWeekRunController {
  @override
  Future<BurnWeekRunState> build() async => const BurnWeekRunState.initial();
}

CalorieEntry _entry({
  required String id,
  required DateTime day,
  required MealType mealType,
}) {
  final loggedAt = day.add(const Duration(hours: 8));
  return CalorieEntry(
    id: id,
    userId: 'user-1',
    name: id,
    mealType: mealType,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 100,
    per100Protein: 5,
    per100Carbs: 10,
    per100Fat: 2,
    totalKcal: 100,
    totalProtein: 5,
    totalCarbs: 10,
    totalFat: 2,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}
