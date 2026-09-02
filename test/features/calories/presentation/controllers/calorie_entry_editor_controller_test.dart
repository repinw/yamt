import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/application/calorie_entry_delete_flow.dart';
import 'package:yamt/features/calories/application/'
    'calorie_inventory_entry_save_handler.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/presentation/controllers/'
    'calorie_entry_editor_controller.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';

class _FakeCalorieEntriesController extends CalorieEntriesController {
  _FakeCalorieEntriesController({
    Future<bool> Function(
      CalorieEntry entry,
      Future<bool> Function(CalorieEntry)? persistEntry,
    )?
    onSaveEntry,
  }) : _onSaveEntry = onSaveEntry;

  final Future<bool> Function(
    CalorieEntry entry,
    Future<bool> Function(CalorieEntry)? persistEntry,
  )?
  _onSaveEntry;

  @override
  Future<List<CalorieEntry>> build() async => const [];

  @override
  Future<bool> saveEntry(
    CalorieEntry entry, {
    dynamic inventoryContext,
    dynamic scannedSourceRef,
    Future<bool> Function(CalorieEntry)? persistEntry,
  }) async {
    if (_onSaveEntry != null) {
      return _onSaveEntry(entry, persistEntry);
    }
    if (persistEntry != null) {
      return persistEntry(entry);
    }
    return true;
  }
}

class _FakeCalorieEntryDeleteFlow implements CalorieEntryDeleteFlow {
  bool canRestore = true;
  bool deleteSuccess = true;
  CalorieEntry? deletedEntry;

  @override
  Future<bool> canRestoreSource(CalorieEntry entry) async => canRestore;

  @override
  Future<CalorieEntryDeleteResult> deleteEntry({
    required CalorieEntry entry,
    required bool restoreToInventory,
  }) async {
    deletedEntry = entry;
    return deleteSuccess
        ? const CalorieEntryDeleteResult.success(restoredToInventory: true)
        : const CalorieEntryDeleteResult.failure(
            CalorieEntryDeleteFailureReason.deleteFailed,
          );
  }
}

void main() {
  group('CalorieEntryEditorController', () {
    late ProviderContainer container;
    late _FakeCalorieEntriesController entriesController;
    late _FakeCalorieEntryDeleteFlow deleteFlow;
    CalorieEntry? savedEntry;

    setUp(() {
      savedEntry = null;
      entriesController = _FakeCalorieEntriesController(
        onSaveEntry: (entry, persist) async {
          savedEntry = entry;
          if (persist != null) {
            return persist(entry);
          }
          return true;
        },
      );
      deleteFlow = _FakeCalorieEntryDeleteFlow();
      container = ProviderContainer(
        overrides: [
          calorieEntriesControllerProvider.overrideWith(
            () => entriesController,
          ),
          calorieEntryDeleteFlowProvider.overrideWithValue(deleteFlow),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is not saving', () {
      final state = container.read(calorieEntryEditorControllerProvider);
      expect(state, isFalse);
    });

    test('saveEntry saves entry via entries controller', () async {
      final now = DateTime.now();
      final entry = CalorieEntry.create(
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

      final controller = container.read(
        calorieEntryEditorControllerProvider.notifier,
      );
      final result = await controller.saveEntry(entry: entry);

      expect(result, isTrue);
      expect(savedEntry?.id, 'entry-1');
      expect(
        container.read(calorieEntryEditorControllerProvider),
        isFalse,
      );
    });

    test('saveEntry delegates to saveHandler when pending exists', () async {
      var saveHandlerCalled = false;
      final customContainer = ProviderContainer(
        overrides: [
          calorieEntriesControllerProvider.overrideWith(
            () => entriesController,
          ),
          calorieInventoryEntrySaveHandlerProvider.overrideWithValue(
            ({required entry, required pendingConsumptionId}) async {
              saveHandlerCalled = true;
              return true;
            },
          ),
        ],
      );
      addTearDown(customContainer.dispose);

      final now = DateTime.now();
      final entry = CalorieEntry.create(
        id: 'entry-2',
        userId: 'user-1',
        name: 'Apple',
        mealType: MealType.snack,
        consumedAmount: 150,
        consumedUnit: ConsumedUnit.grams,
        per100Kcal: 52,
        per100Protein: 0.3,
        per100Carbs: 14,
        per100Fat: 0.2,
        createdAt: now,
        updatedAt: now,
      );

      final controller = customContainer.read(
        calorieEntryEditorControllerProvider.notifier,
      );
      final result = await controller.saveEntry(
        entry: entry,
        pendingConsumptionId: 'pending-123',
      );

      expect(result, isTrue);
      expect(saveHandlerCalled, isTrue);
    });

    test('canRestoreSource queries delete flow', () async {
      final now = DateTime.now();
      final entry = CalorieEntry.create(
        id: 'entry-3',
        userId: 'user-1',
        name: 'Banana',
        mealType: MealType.snack,
        consumedAmount: 120,
        consumedUnit: ConsumedUnit.grams,
        per100Kcal: 89,
        per100Protein: 1.1,
        per100Carbs: 23,
        per100Fat: 0.3,
        createdAt: now,
        updatedAt: now,
      );

      deleteFlow.canRestore = true;
      final controller = container.read(
        calorieEntryEditorControllerProvider.notifier,
      );
      expect(await controller.canRestoreSource(entry), isTrue);

      deleteFlow.canRestore = false;
      expect(await controller.canRestoreSource(entry), isFalse);
    });

    test('deleteEntry calls delete flow and returns result', () async {
      final now = DateTime.now();
      final entry = CalorieEntry.create(
        id: 'entry-4',
        userId: 'user-1',
        name: 'Rice',
        mealType: MealType.dinner,
        consumedAmount: 200,
        consumedUnit: ConsumedUnit.grams,
        per100Kcal: 130,
        per100Protein: 2.7,
        per100Carbs: 28,
        per100Fat: 0.3,
        createdAt: now,
        updatedAt: now,
      );

      final controller = container.read(
        calorieEntryEditorControllerProvider.notifier,
      );
      final result = await controller.deleteEntry(
        entry: entry,
        restoreToInventory: true,
      );

      expect(result.isSuccess, isTrue);
      expect(deleteFlow.deletedEntry?.id, 'entry-4');
    });

    test('discardPendingInventory invokes discarder', () async {
      var discardedId = '';
      final customContainer = ProviderContainer(
        overrides: [
          calorieInventoryPendingConsumptionDiscarderProvider.overrideWithValue(
            (id) async {
              discardedId = id;
            },
          ),
        ],
      );
      addTearDown(customContainer.dispose);

      final controller = customContainer.read(
        calorieEntryEditorControllerProvider.notifier,
      );
      await controller.discardPendingInventory('pending-456');

      expect(discardedId, 'pending-456');
    });
  });
}
