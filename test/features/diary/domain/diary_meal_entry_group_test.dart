import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/diary/domain/diary_meal_entry_group.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';

DiaryMealEntry _entry(
  String id, {
  String name = 'Oats',
  double kcal = 75,
  double? amount = 20,
  String? imageUrl,
}) {
  return DiaryMealEntry(
    id: id,
    mealType: MealType.lunch,
    name: name,
    imageUrl: imageUrl,
    totalKcal: kcal,
    totalProtein: 2.8,
    totalCarbs: 11.8,
    totalFat: 1.4,
    consumedAmount: amount,
    consumedUnit: amount == null ? null : ConsumedUnit.grams,
  );
}

void main() {
  test('merges identical foods and keeps first-logged order', () {
    final groups = groupDiaryMealEntries([
      _entry('oats-1'),
      _entry('nuts', name: 'Peanuts', kcal: 182),
      _entry('oats-2'),
    ]);

    expect(groups, hasLength(2));
    expect(groups.first.entries.map((e) => e.id), ['oats-1', 'oats-2']);
    expect(groups.first.isMerged, isTrue);
    expect(groups.last.isMerged, isFalse);
  });

  test('combined entry sums kcal, macros, and amount', () {
    final group = groupDiaryMealEntries([
      _entry('oats-1'),
      _entry('oats-2'),
      _entry('oats-3'),
    ]).single;

    final combined = group.combined;
    expect(combined.id, 'oats-1');
    expect(combined.totalKcal, 225);
    expect(combined.totalProtein, closeTo(8.4, 0.001));
    expect(combined.consumedAmount, 60);
    expect(combined.consumedUnit, ConsumedUnit.grams);
  });

  test('keeps foods apart when image or unit differ', () {
    final groups = groupDiaryMealEntries([
      _entry('oats-1'),
      _entry('oats-2', imageUrl: 'https://example.com/other.png'),
      _entry('oats-3', amount: null),
    ]);

    expect(groups, hasLength(3));
  });

  test('section computes its groups once from its entries', () {
    final section = DiaryMealSection(
      mealType: MealType.lunch,
      entries: [_entry('oats-1'), _entry('oats-2')],
      totalKcal: 150,
    );

    expect(section.entryGroups, hasLength(1));
    expect(identical(section.entryGroups, section.entryGroups), isTrue);
  });
}
