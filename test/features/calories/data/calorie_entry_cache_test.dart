import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/data/calorie_entry_cache.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';

CalorieEntry _createEntry(String id) {
  final now = DateTime.utc(2026, 3, 20, 12);
  return CalorieEntry.create(
    id: id,
    userId: 'user-1',
    name: 'Apple',
    mealType: MealType.breakfast,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 52,
    per100Protein: 0.3,
    per100Carbs: 14,
    per100Fat: 0.2,
    loggedAt: now,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('CalorieEntryCache', () {
    late CalorieEntryCache cache;

    setUp(() {
      cache = CalorieEntryCache();
    });

    test('returns null for uncached entry', () {
      expect(cache.get('unknown'), isNull);
    });

    test('stores and retrieves an entry with put', () {
      final entry = _createEntry('entry-1');
      cache.put(entry);

      expect(cache.get('entry-1'), entry);
    });

    test(
      'stores multiple entries and returns same list with rememberAll',
      () {
      final entry1 = _createEntry('entry-1');
      final entry2 = _createEntry('entry-2');
      final list = [entry1, entry2];

      final result = cache.rememberAll(list);

      expect(result, same(list));
      expect(cache.get('entry-1'), entry1);
      expect(cache.get('entry-2'), entry2);
    });

    test('removes entry by id', () {
      final entry = _createEntry('entry-1');
      cache.put(entry);
      expect(cache.get('entry-1'), entry);

      cache.remove('entry-1');
      expect(cache.get('entry-1'), isNull);
    });

    test('clears all entries', () {
      cache.rememberAll([_createEntry('entry-1'), _createEntry('entry-2')]);
      expect(cache.get('entry-1'), isNotNull);
      expect(cache.get('entry-2'), isNotNull);

      cache.clear();
      expect(cache.get('entry-1'), isNull);
      expect(cache.get('entry-2'), isNull);
    });
  });
}
