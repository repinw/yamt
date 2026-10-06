import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/application/calorie_entry_day_change.dart';
import 'package:yamt/features/calories/application/calorie_entry_saver.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/diary/presentation/controllers/'
    'diary_entry_change_controller.dart';

CalorieEntry _entry(DateTime loggedAt) => CalorieEntry.create(
  id: 'entry-1',
  userId: 'user-1',
  name: 'Skyr',
  mealType: MealType.breakfast,
  consumedAmount: 200,
  consumedUnit: ConsumedUnit.grams,
  per100Kcal: 60,
  per100Protein: 11,
  per100Carbs: 4,
  per100Fat: 0.2,
  loggedAt: loggedAt,
  createdAt: loggedAt,
  updatedAt: loggedAt,
);

void main() {
  final monday = DateTime(2026, 3, 23, 8);
  final wednesday = DateTime(2026, 3, 25, 8);

  Future<List<DateTime>> save(DateTime loggedAt, DateTime previousDay) async {
    final changedDays = <DateTime>[];
    final container = ProviderContainer(
      overrides: [
        calorieEntrySaverProvider.overrideWithValue(
          (entry, {scannedSourceRef, persistEntry}) async => true,
        ),
        calorieEntryDayChangeProvider.overrideWithValue(
          (day) async => changedDays.add(day),
        ),
      ],
    );
    addTearDown(container.dispose);

    final saved = await container
        .read(diaryEntryChangeControllerProvider.notifier)
        .save(_entry(loggedAt), previousDay: previousDay);

    expect(saved, isTrue);
    return changedDays;
  }

  test('an entry moved to a later day changes its old day too', () async {
    expect(await save(wednesday, monday), [monday]);
  });

  test('an entry moved to an earlier day needs no extra change', () async {
    expect(await save(monday, wednesday), isEmpty);
  });
}
