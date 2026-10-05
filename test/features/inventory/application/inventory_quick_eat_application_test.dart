import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_application.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_calorie_log_bridge.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

class _FakePreparedMealRepository implements PreparedMealRepository {
  new(this._meals);

  List<PreparedMeal> _meals;
  int readAllCallCount = 0;

  List<PreparedMeal> get meals => _meals;

  @override
  Future<List<PreparedMeal>> readAll() async {
    readAllCallCount += 1;
    return List<PreparedMeal>.from(_meals);
  }

  @override
  Future<bool> saveAll(List<PreparedMeal> meals) async {
    _meals = List<PreparedMeal>.from(meals);
    return true;
  }

  @override
  Stream<List<PreparedMeal>> watchAll() => Stream.value(_meals);
}

PreparedMeal _meal({required String id}) {
  return PreparedMeal(
    id: id,
    name: 'Lunch box',
    totalPortions: 4,
    remainingPortions: 4,
    totalKcal: 400,
    totalProtein: 20,
    totalCarbs: 40,
    totalFat: 10,
    createdAt: DateTime(2026, 9, 2),
    updatedAt: DateTime(2026, 9, 2),
    components: const <PreparedMealComponent>[],
  );
}

InventoryQuickEatApplication _application({
  required _FakePreparedMealRepository repository,
  required List<CalorieEntry> savedEntries,
  bool atomic = true,
}) {
  Future<bool> saveEntry(CalorieEntry entry) async {
    savedEntries.add(entry);
    return true;
  }

  return InventoryQuickEatApplication(
    preparedMealRepository: repository,
    now: () => DateTime(2026, 9, 19, 12),
    calorieLogBridge: PreparedMealCalorieLogBridge(
      saveEntry: saveEntry,
      saveEntryAtomically: atomic ? saveEntry : null,
      now: () => DateTime(2026, 9, 19, 12),
      nextEntryId: () => 'entry-1',
    ),
  );
}

void main() {
  test('consumes a prepared meal without reading all meals', () async {
    final repository = _FakePreparedMealRepository(<PreparedMeal>[
      _meal(id: 'meal-1'),
    ]);
    final savedEntries = <CalorieEntry>[];
    final application = _application(
      repository: repository,
      savedEntries: savedEntries,
    );

    final saved = await application.consumePreparedMeal(
      meal: _meal(id: 'meal-1'),
      consumedPortions: 1,
      mealType: MealType.lunch,
      loggedDay: DateTime(2026, 9, 19),
    );

    expect(saved, isNotNull);
    expect(savedEntries.single.bundleSourcePreparedMealId, 'meal-1');
    expect(repository.readAllCallCount, 0);
  });

  test('fallback without atomic store only updates the eaten meal', () async {
    final repository = _FakePreparedMealRepository(<PreparedMeal>[
      _meal(id: 'meal-1'),
      _meal(id: 'meal-2'),
    ]);
    final application = _application(
      repository: repository,
      savedEntries: <CalorieEntry>[],
      atomic: false,
    );

    final saved = await application.consumePreparedMeal(
      meal: _meal(id: 'meal-1'),
      consumedPortions: 1,
      mealType: MealType.lunch,
      loggedDay: DateTime(2026, 9, 19),
    );

    expect(saved, isNotNull);
    expect(repository.meals.map((meal) => meal.id), <String>[
      'meal-1',
      'meal-2',
    ]);
    expect(repository.meals.first.remainingPortions, 3);
    expect(repository.meals.last.remainingPortions, 4);
  });
}
