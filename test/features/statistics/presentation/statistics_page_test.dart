import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_discard_event_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/inventory/provider/prepared_meals_controller.dart';
import 'package:yamt/features/statistics/presentation/statistics_page.dart';
import 'package:yamt/features/statistics/presentation/widgets/'
    'statistics_error_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../calories/support/fake_calories_repositories.dart';

class _FakeInventoryDiscardEventRepository
    implements InventoryDiscardEventRepository {
  const _FakeInventoryDiscardEventRepository(this.events);

  final List<InventoryDiscardEvent> events;

  @override
  Future<List<InventoryDiscardEvent>> readAll() async {
    return events;
  }

  @override
  Future<bool> saveEvent(InventoryDiscardEvent event) async {
    return true;
  }
}

void main() {
  testWidgets('switches between spending waste and calories tabs', (
    tester,
  ) async {
    final inventoryController = _InventoryItemsDataController([
      InventoryItem.create(
        id: 'rice',
        name: 'Rice',
        entryDate: DateTime.now(),
        storeName: 'REWE',
        quantity: 2,
        initialQuantity: 2,
        unitPrice: 2,
        receiptDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ]);
    final mealsController = _PreparedMealsDataController(
      const <PreparedMeal>[],
    );
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry('breakfast', loggedAt: DateTime.now()),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2000,
        calculatorProfile: null,
        effectiveDate: DateTime.now().subtract(const Duration(days: 6)),
      ),
    );
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        inventoryController: inventoryController,
        mealsController: mealsController,
        logRepository: logRepository,
        settingsRepository: settingsRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tracked spending'), findsOneWidget);

    await tester.tap(find.text('Food Waste'));
    await tester.pumpAndSettle();
    expect(find.text('Food waste overview'), findsOneWidget);

    await tester.tap(find.text('Calories'));
    await tester.pumpAndSettle();
    expect(find.text('Calories overview'), findsOneWidget);
  });

  testWidgets('shows loading state while inventory data is pending', (
    tester,
  ) async {
    final inventoryController = _InventoryItemsLoadingController();
    final mealsController = _PreparedMealsDataController(
      const <PreparedMeal>[],
    );
    final logRepository = FakeCalorieLogRepository();
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        inventoryController: inventoryController,
        mealsController: mealsController,
        logRepository: logRepository,
        settingsRepository: settingsRepository,
      ),
    );
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error card and retry action for household data errors', (
    tester,
  ) async {
    final inventoryController = _InventoryItemsErrorController();
    final mealsController = _PreparedMealsDataController(
      const <PreparedMeal>[],
    );
    final logRepository = FakeCalorieLogRepository();
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        inventoryController: inventoryController,
        mealsController: mealsController,
        logRepository: logRepository,
        settingsRepository: settingsRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(StatisticsErrorCard), findsOneWidget);

    await tester.ensureVisible(find.text('Retry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(inventoryController.refreshCount, 1);
  });

  testWidgets('shows error card when calorie statistics provider fails', (
    tester,
  ) async {
    final inventoryController = _InventoryItemsDataController(
      const <InventoryItem>[],
    );
    final mealsController = _PreparedMealsDataController(
      const <PreparedMeal>[],
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2000,
        calculatorProfile: null,
        effectiveDate: DateTime.now().subtract(const Duration(days: 6)),
      ),
    );
    final logRepository = _ThrowingCalorieLogRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        inventoryController: inventoryController,
        mealsController: mealsController,
        logRepository: logRepository,
        settingsRepository: settingsRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Calories'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(StatisticsErrorCard), findsOneWidget);
  });
}

Widget _buildHarness({
  required InventoryItemsController inventoryController,
  required PreparedMealsController mealsController,
  required CalorieLogRepositoryContract logRepository,
  required CalorieSettingsRepository settingsRepository,
}) {
  return ProviderScope(
    overrides: [
      inventoryItemsControllerProvider.overrideWith(() => inventoryController),
      preparedMealsControllerProvider.overrideWith(() => mealsController),
      calorieLogRepositoryProvider.overrideWithValue(logRepository),
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      inventoryDiscardEventRepositoryProvider.overrideWithValue(
        const _FakeInventoryDiscardEventRepository(
          <InventoryDiscardEvent>[],
        ),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: StatisticsPage()),
    ),
  );
}

CalorieEntry _entry(String id, {required DateTime loggedAt}) {
  return CalorieEntry.create(
    id: id,
    userId: 'user-1',
    name: 'Entry $id',
    mealType: MealType.breakfast,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 100,
    per100Protein: 10,
    per100Carbs: 5,
    per100Fat: 1,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

class _InventoryItemsDataController extends InventoryItemsController {
  _InventoryItemsDataController(this.items);

  final List<InventoryItem> items;
  int refreshCount = 0;

  @override
  FutureOr<List<InventoryItem>> build() => items;

  @override
  Future<void> refresh() async {
    refreshCount += 1;
    state = AsyncData(items);
  }
}

class _InventoryItemsLoadingController extends InventoryItemsController {
  final _pending = Completer<List<InventoryItem>>();

  @override
  FutureOr<List<InventoryItem>> build() => _pending.future;
}

class _InventoryItemsErrorController extends InventoryItemsController {
  int refreshCount = 0;

  @override
  FutureOr<List<InventoryItem>> build() {
    throw StateError('inventory failed');
  }

  @override
  Future<void> refresh() async {
    refreshCount += 1;
  }
}

class _PreparedMealsDataController extends PreparedMealsController {
  _PreparedMealsDataController(this.meals);

  final List<PreparedMeal> meals;
  int refreshCount = 0;

  @override
  FutureOr<List<PreparedMeal>> build() => meals;

  @override
  Future<void> refresh() async {
    refreshCount += 1;
    state = AsyncData(meals);
  }
}

class _ThrowingCalorieLogRepository extends FakeCalorieLogRepository {
  @override
  Future<DateTime?> readFirstEntryDate() async {
    throw StateError('statistics failed');
  }
}
