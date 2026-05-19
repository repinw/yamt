import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_carryover_history.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

void main() {
  group('buildCalorieCarryoverDateRange', () {
    test('normalizes inclusive start and exclusive end', () {
      final days = buildCalorieCarryoverDateRange(
        startInclusive: DateTime(2026, 4, 1, 12),
        endExclusive: DateTime(2026, 4, 4, 23),
      );

      expect(
        days,
        <DateTime>[
          DateTime(2026, 4),
          DateTime(2026, 4, 2),
          DateTime(2026, 4, 3),
        ],
      );
    });

    test('returns empty list when range is not forward', () {
      final days = buildCalorieCarryoverDateRange(
        startInclusive: DateTime(2026, 4, 4),
        endExclusive: DateTime(2026, 4, 4),
      );

      expect(days, isEmpty);
    });
  });

  group('buildCalorieCarryoverDays', () {
    test('maps goals and day entries to consumed carryover snapshots', () {
      final dayOne = DateTime(2026, 4);
      final dayTwo = DateTime(2026, 4, 2);

      final carryoverDays = buildCalorieCarryoverDays(
        days: <DateTime>[dayOne, dayTwo],
        goalKcals: const <double>[2000, 2100],
        entriesByDay: <String, List<CalorieEntry>>{
          diaryDayKey(dayOne): <CalorieEntry>[
            _entry(id: 'one', day: dayOne, kcal: 300),
            _entry(id: 'two', day: dayOne, kcal: 450),
          ],
        },
      );

      expect(carryoverDays, hasLength(2));
      expect(carryoverDays[0].goalKcal, 2000);
      expect(carryoverDays[0].consumedKcal, 750);
      expect(carryoverDays[1].goalKcal, 2100);
      expect(carryoverDays[1].consumedKcal, 0);
    });
  });
}

CalorieEntry _entry({
  required String id,
  required DateTime day,
  required double kcal,
}) {
  return CalorieEntry.create(
    id: id,
    userId: 'user',
    name: 'Food',
    mealType: MealType.lunch,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: kcal,
    per100Protein: 0,
    per100Carbs: 0,
    per100Fat: 0,
    loggedAt: day,
    createdAt: day,
    updatedAt: day,
  );
}
