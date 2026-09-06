import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_mutation.dart';
import 'package:yamt/features/diary/domain/diary_food_log_session.dart';

void main() {
  CalorieEntry entry(String id, int day) => CalorieEntry.create(
    id: id,
    userId: 'user',
    name: id,
    mealType: MealType.lunch,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 184,
    per100Protein: 25,
    per100Carbs: 12,
    per100Fat: 4,
    loggedAt: DateTime(2026, 9, day),
  );
  void record(
    DiaryFoodLogSession session,
    CalorieEntry entry,
    CalorieEntryMutationKind kind,
  ) => session.record(
    CalorieEntryMutation(kind: kind, entryId: entry.id, entry: entry),
  );

  test('groups new foods by actual day and ignores edits to older foods', () {
    final session = DiaryFoodLogSession();
    record(session, entry('old', 5), CalorieEntryMutationKind.updated);
    record(session, entry('a', 6), CalorieEntryMutationKind.created);
    record(session, entry('b', 5), CalorieEntryMutationKind.created);
    record(session, entry('c', 5), CalorieEntryMutationKind.created);
    expect(session.dayGroups.map((group) => group.map((e) => e.id).toList()), [
      ['b', 'c'],
      ['a'],
    ]);
  });

  test(
    'deduplicates commits and reflects edits and removal during a batch',
    () {
      final session = DiaryFoodLogSession();
      final a = entry('a', 5);
      record(session, a, CalorieEntryMutationKind.created);
      record(session, a, CalorieEntryMutationKind.created);
      record(
        session,
        a.copyWith(loggedAt: DateTime(2026, 9, 6)),
        CalorieEntryMutationKind.updated,
      );
      expect(session.dayGroups.single.single.loggedAt.day, 6);
      session.record(
        const CalorieEntryMutation(
          kind: CalorieEntryMutationKind.deleted,
          entryId: 'a',
        ),
      );
      expect(session.dayGroups, isEmpty);
    },
  );
}
