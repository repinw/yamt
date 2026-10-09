import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// Keeps the household's meals in memory and records each write.
class FakePreparedMealRepository implements PreparedMealRepository {
  /// Starts with [meals]. `writeResults` decides the outcome of the writes in
  /// order; the last one repeats.
  new({
    List<PreparedMeal> meals = const <PreparedMeal>[],
    this._writeResults = const <bool>[true],
  }) : meals = List<PreparedMeal>.from(meals);

  /// The stored meals.
  List<PreparedMeal> meals;
  final List<bool> _writeResults;

  /// How often the meals were read.
  int readCount = 0;

  /// How often a meal was saved or deleted.
  int writeCount = 0;

  @override
  Stream<List<PreparedMeal>> watchAll() => Stream.value(meals);

  @override
  Future<List<PreparedMeal>> readAll() async {
    readCount += 1;
    return List<PreparedMeal>.from(meals);
  }

  @override
  Future<bool> save(PreparedMeal meal) async {
    if (!_nextWrite()) {
      return false;
    }
    final isNew = meals.every((stored) => stored.id != meal.id);
    meals = [
      for (final stored in meals)
        if (stored.id == meal.id) meal else stored,
      if (isNew) meal,
    ];
    return true;
  }

  @override
  Future<bool> delete(String mealId) async {
    if (!_nextWrite()) {
      return false;
    }
    meals = [
      for (final stored in meals)
        if (stored.id != mealId) stored,
    ];
    return true;
  }

  bool _nextWrite() {
    writeCount += 1;
    return _writeResults[(writeCount - 1).clamp(0, _writeResults.length - 1)];
  }

  @override
  Future<List<PreparedMeal>> readAllForChange() => readAll();
}
