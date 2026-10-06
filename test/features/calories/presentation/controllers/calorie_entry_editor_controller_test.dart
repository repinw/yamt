import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/presentation/controllers/calorie_entries_controller.dart';
import 'package:yamt/features/calories/presentation/controllers/'
    'calorie_entry_editor_controller.dart';

class _FakeCalorieEntriesController extends CalorieEntriesController {
  final saved = <CalorieEntry>[];
  final deletedIds = <String>[];

  @override
  Future<List<CalorieEntry>> build() async => const [];

  @override
  Future<bool> saveEntry(CalorieEntry entry, {bool isNewEntry = false}) async {
    saved.add(entry);
    return true;
  }

  @override
  Future<bool> deleteEntry(String entryId) async {
    deletedIds.add(entryId);
    return true;
  }
}

CalorieEntry _oatmeal() {
  final now = DateTime(2026, 3, 1, 8);
  return CalorieEntry.create(
    id: 'entry-1',
    userId: 'user-1',
    name: 'Oatmeal',
    mealType: MealType.breakfast,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 389,
    per100Protein: 16.9,
    per100Carbs: 66.3,
    per100Fat: 6.9,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late ProviderContainer container;
  late _FakeCalorieEntriesController entries;

  setUp(() {
    entries = _FakeCalorieEntriesController();
    container = ProviderContainer(
      overrides: [calorieEntriesControllerProvider.overrideWith(() => entries)],
    );
    addTearDown(container.dispose);
  });

  test('saveEntry saves the entry through the entries controller', () async {
    final saved = await container
        .read(calorieEntryEditorControllerProvider.notifier)
        .saveEntry(entry: _oatmeal());

    expect(saved, isTrue);
    expect(entries.saved.single.id, 'entry-1');
  });

  test(
    'deleteEntry deletes the entry through the entries controller',
    () async {
      final deleted = await container
          .read(calorieEntryEditorControllerProvider.notifier)
          .deleteEntry(_oatmeal());

      expect(deleted, isTrue);
      expect(entries.deletedIds, ['entry-1']);
    },
  );
}
