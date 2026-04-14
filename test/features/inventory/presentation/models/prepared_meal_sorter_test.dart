import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_view_preferences.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'prepared_meal_sorter.dart';

PreparedMeal _preparedMeal({
  required String id,
  required String name,
  required String createdAt,
  String? updatedAt,
  int totalPortions = 2,
  int remainingPortions = 1,
}) {
  return PreparedMeal(
    id: id,
    name: name,
    totalPortions: totalPortions,
    remainingPortions: remainingPortions,
    totalKcal: 500,
    totalProtein: 20,
    totalCarbs: 50,
    totalFat: 15,
    createdAt: DateTime.parse(createdAt),
    updatedAt: DateTime.parse(updatedAt ?? createdAt),
    components: const [],
  );
}

void main() {
  const sorter = PreparedMealSorter();

  test('mode helpers round-trip all prepared meal sort modes', () {
    for (final sortMode in PreparedMealSortMode.values) {
      final criterion = sorter.criterionFor(sortMode);
      final ascending = sorter.isAscending(sortMode);

      expect(sorter.modeFor(criterion, ascending: ascending), sortMode);
    }
  });

  test('added sort supports descending and ascending', () {
    final descending = sorter.sort(<PreparedMeal>[
      _preparedMeal(
        id: 'older',
        name: 'Apple',
        createdAt: '2026-02-20T08:00:00Z',
      ),
      _preparedMeal(
        id: 'newer',
        name: 'Banana',
        createdAt: '2026-02-22T08:00:00Z',
      ),
    ], sortMode: PreparedMealSortMode.addedDescending);
    final ascending = sorter.sort(<PreparedMeal>[
      _preparedMeal(
        id: 'older',
        name: 'Apple',
        createdAt: '2026-02-20T08:00:00Z',
      ),
      _preparedMeal(
        id: 'newer',
        name: 'Banana',
        createdAt: '2026-02-22T08:00:00Z',
      ),
    ], sortMode: PreparedMealSortMode.addedAscending);

    expect(descending.map((meal) => meal.id), <String>['newer', 'older']);
    expect(ascending.map((meal) => meal.id), <String>['older', 'newer']);
  });

  test('eaten and alphabetical sorts work as expected', () {
    final eaten = sorter.sort(<PreparedMeal>[
      _preparedMeal(
        id: 'old',
        name: 'Soup',
        createdAt: '2026-02-20T08:00:00Z',
        updatedAt: '2026-02-21T08:00:00Z',
      ),
      _preparedMeal(
        id: 'recent',
        name: 'Salad',
        createdAt: '2026-02-21T08:00:00Z',
        updatedAt: '2026-02-22T08:00:00Z',
      ),
    ], sortMode: PreparedMealSortMode.eatenDescending);
    final alphabetical = sorter.sort(<PreparedMeal>[
      _preparedMeal(
        id: 'b',
        name: 'Banana Bowl',
        createdAt: '2026-02-22T08:00:00Z',
      ),
      _preparedMeal(
        id: 'a',
        name: 'Apple Pie',
        createdAt: '2026-02-20T08:00:00Z',
      ),
    ], sortMode: PreparedMealSortMode.alphabeticalAscending);

    expect(eaten.map((meal) => meal.id), <String>['recent', 'old']);
    expect(alphabetical.map((meal) => meal.id), <String>['a', 'b']);
  });

  test('quantity sort uses remaining ratio and portions as tie-breaker', () {
    final ascending = sorter.sort(<PreparedMeal>[
      _preparedMeal(
        id: 'half-many',
        name: 'Half Many',
        createdAt: '2026-02-20T08:00:00Z',
        totalPortions: 8,
        remainingPortions: 4,
      ),
      _preparedMeal(
        id: 'half-few',
        name: 'Half Few',
        createdAt: '2026-02-21T08:00:00Z',
        totalPortions: 2,
        remainingPortions: 1,
      ),
      _preparedMeal(
        id: 'empty',
        name: 'Empty',
        createdAt: '2026-02-22T08:00:00Z',
        totalPortions: 4,
        remainingPortions: 0,
      ),
    ], sortMode: PreparedMealSortMode.quantityAscending);

    expect(ascending.map((meal) => meal.id), <String>[
      'empty',
      'half-few',
      'half-many',
    ]);
  });
}
