import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/features/calories/application/diary_today_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/'
    'diary_quick_entry_controller.dart';

import '../../../calories/support/fake_calories_repositories.dart';
import '../../../calories/support/fake_planned_entry_repository.dart';
import '../../support/diary_quick_entry_test_support.dart';

final _loggedAt = DateTime(2026, 9, 26, 8, 15);

void main() {
  late FakeCalorieLogRepository calorieLog;
  late FakePlannedEntryRepository plans;
  late ProviderContainer container;
  late List<DiaryQuickEntryState> states;
  final provider = diaryQuickEntryControllerProvider(
    initialLoggedAt: _loggedAt,
    initialMealType: MealType.lunch,
  );

  setUp(() {
    calorieLog = FakeCalorieLogRepository();
    plans = FakePlannedEntryRepository();
    container = ProviderContainer(
      overrides: quickEntryOverrides(calorieLog, plans: plans),
    );
    states = [];
    container.listen(
      provider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );
  });
  tearDown(() async {
    container.dispose();
    await calorieLog.dispose();
  });

  DiaryQuickEntryController controller() => container.read(provider.notifier);
  DiaryQuickEntryState state() => container.read(provider);

  test('starts empty on the given day and meal', () {
    expect(state().loggedAt, _loggedAt);
    expect(state().mealType, MealType.lunch);
    expect(state().today, dateOnly(quickEntryNow));
    expect(state().kcal, isNull);
    expect(state().isMissingMacros, isTrue);
    expect(state().canSave, isFalse);
  });

  test('a new day keeps the typed input and decides the plan again', () {
    var now = quickEntryNow;
    final tomorrow = DateTime(2026, 9, 29, 8);
    final dayContainer = ProviderContainer(
      overrides: quickEntryOverrides(calorieLog, clock: () => now),
    );
    addTearDown(dayContainer.dispose);
    final tomorrowProvider = diaryQuickEntryControllerProvider(
      initialLoggedAt: tomorrow,
      initialMealType: MealType.breakfast,
    );
    dayContainer.listen(tomorrowProvider, (_, _) {});
    dayContainer.read(tomorrowProvider.notifier)
      ..setName('Porridge')
      ..setValueText(DiaryQuickEntryValue.kcal, '350');
    expect(dayContainer.read(tomorrowProvider).isPlan, isTrue);

    now = DateTime(2026, 9, 29, 0, 1);
    dayContainer.read(diaryTodayProvider.notifier).refresh();

    final state = dayContainer.read(tomorrowProvider);
    expect(state.today, DateTime(2026, 9, 29));
    expect(state.isPlan, isFalse);
    expect(state.name, 'Porridge');
    expect(state.kcal, 350);
    expect(state.loggedAt, tomorrow);
  });

  test('can save once the calories are a number', () {
    controller().setValueText(DiaryQuickEntryValue.kcal, 'abc');
    expect(state().canSave, isFalse);

    controller().setValueText(DiaryQuickEntryValue.kcal, '12,5');
    expect(state().kcal, 12.5);
    expect(state().canSave, isTrue);
  });

  test('a macro is missing until all three are numbers', () {
    controller()
      ..setValueText(DiaryQuickEntryValue.fat, '1')
      ..setValueText(DiaryQuickEntryValue.carbs, '2');
    expect(state().isMissingMacros, isTrue);

    controller().setValueText(DiaryQuickEntryValue.protein, '0');
    expect(state().isMissingMacros, isFalse);
  });

  test('a picked day keeps the time of day of now', () {
    controller()
      ..setLoggedDay(DateTime(2026, 9, 27))
      ..setMealType(MealType.snack);

    expect(state().loggedAt, DateTime(2026, 9, 27, 12, 30));
    expect(state().mealType, MealType.snack);
  });

  test('save stores a quick entry and reports the saving', () async {
    controller()
      ..setName('  Kantine ')
      ..setValueText(DiaryQuickEntryValue.kcal, '650')
      ..setValueText(DiaryQuickEntryValue.fat, '22');
    states.clear();

    final entry = await controller().save(defaultName: 'Quick entry');

    expect(entry, isNotNull);
    expect(entry!.isQuickEntry, isTrue);
    expect(entry.name, 'Kantine');
    expect(entry.totalKcal, 650);
    expect(entry.totalFat, 22);
    expect(entry.totalProtein, 0);
    expect(entry.mealType, MealType.lunch);
    expect(entry.loggedAt, _loggedAt);
    expect(calorieLog.entries.single.id, entry.id);
    expect(states.map((state) => state.isSaving), [true, false]);
  });

  test('save on a future day stores a plan, not a calorie entry', () async {
    controller()
      ..setLoggedDay(DateTime(2026, 9, 29))
      ..setValueText(DiaryQuickEntryValue.kcal, '650');

    final entry = await controller().save(defaultName: 'Quick entry');

    expect(entry, isNotNull);
    expect(plans.plans.single.id, entry!.id);
    expect(calorieLog.entries, isEmpty);
  });

  test('save writes nothing without the calories', () async {
    final entry = await controller().save(defaultName: 'Quick entry');

    expect(entry, isNull);
    expect(calorieLog.entries, isEmpty);
  });

  test('a failed save returns null and allows another try', () async {
    calorieLog.saveShouldFail = true;
    controller().setValueText(DiaryQuickEntryValue.kcal, '120');

    final entry = await controller().save(defaultName: 'Quick entry');

    expect(entry, isNull);
    expect(state().isSaving, isFalse);
    expect(state().canSave, isTrue);
  });

  test('a second save waits for the first one', () async {
    final gate = Completer<void>();
    calorieLog.saveGate = gate.future;
    controller().setValueText(DiaryQuickEntryValue.kcal, '120');

    final first = controller().save(defaultName: 'Quick entry');
    final second = await controller().save(defaultName: 'Quick entry');
    gate.complete();

    expect(second, isNull);
    expect(await first, isNotNull);
    expect(calorieLog.entries, hasLength(1));
  });
}
