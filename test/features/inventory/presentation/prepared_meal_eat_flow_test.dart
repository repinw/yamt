import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_delete_result.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_application.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_calorie_log_bridge.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_calorie_entry_commit_store.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meals_controller.dart';
import 'package:yamt/features/inventory/presentation/models/prepared_meal_actions.dart';
import 'package:yamt/features/inventory/presentation/prepared_meal_eat_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../support/prepared_meal_test_data.dart';
import '../../calories/support/fake_calories_repositories.dart';
import '../../calories/support/fake_planned_entry_repository.dart';

class _FakeQuickEatActions implements InventoryQuickEatActions {
  new({this.fail = false, this.plan = false});

  final bool fail;
  final bool plan;
  PreparedMeal? consumedMeal;
  num? consumedPortions;

  @override
  Future<PreparedMealEatResult?> consumePreparedMeal({
    required PreparedMeal meal,
    required num consumedPortions,
    required MealType mealType,
    required DateTime loggedDay,
  }) async {
    consumedMeal = meal;
    this.consumedPortions = consumedPortions;
    if (fail) {
      return null;
    }
    final entry = buildConsumedPreparedMealCalorieEntry(
      meal: meal,
      consumedPortions: consumedPortions,
      mealType: mealType,
      now: () => loggedDay,
      nextEntryId: () => 'entry-1',
    );
    return entry == null ? null : (entry: entry, isPlan: plan);
  }
}

class _FakePreparedMealRepository implements PreparedMealRepository {
  new(this._meals);

  final _changes = StreamController<List<PreparedMeal>>.broadcast();
  List<PreparedMeal> _meals;

  @override
  Stream<List<PreparedMeal>> watchAll() {
    return Stream<List<PreparedMeal>>.multi((controller) {
      controller.add(_meals);
      final subscription = _changes.stream.listen(controller.add);
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Future<List<PreparedMeal>> readAll() async => _meals;

  @override
  Future<bool> saveAll(List<PreparedMeal> meals) async {
    emit(meals);
    return true;
  }

  /// Replaces the stored meals, as another device or a fill would.
  void emit(List<PreparedMeal> meals) {
    _meals = meals;
    _changes.add(meals);
  }

  Future<void> dispose() => _changes.close();
}

PreparedMealActions _detailActions() {
  return PreparedMealActions(
    throwAway: (_, _, _) async => true,
    fillPendingIngredient: (_, _, _) async => true,
    fillPendingIngredientWithItem: (_, _, _, _) async => true,
    ignorePendingIngredient: (_, _) async => true,
    unbundle: (_) async => true,
    edit: (_, _, _) async => true,
    saveTemplate: (_, _) async => true,
  );
}

final _restoredPortions = <({String mealId, num portions})>[];

/// Gives the portions of a deleted entry back and records them.
class _MealStore implements PreparedMealCalorieEntryCommitStore {
  const new();

  @override
  Future<CalorieEntryDeleteResult> deleteEntryAndRestorePreparedMeal({
    required CalorieEntry entry,
  }) async {
    _restoredPortions.add((
      mealId: entry.bundleSourcePreparedMealId!,
      portions: entry.bundleConsumedPortions!,
    ));
    return const CalorieEntryDeleteResult.success(restoredToInventory: true);
  }

  @override
  Future<bool> commitEntryAndPreparedMeal({required CalorieEntry entry}) =>
      throw UnimplementedError();
}

Future<void> _pumpHarness(
  WidgetTester tester, {
  required _FakeQuickEatActions actions,
  required ValueChanged<CalorieEntry?> onResult,
  FakePlannedEntryRepository? plans,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        inventoryQuickEatActionsProvider.overrideWithValue(actions),
        firebaseFirestoreProvider.overrideWith((ref) => null),
        calorieSettingsRepositoryProvider.overrideWithValue(
          FakeCalorieSettingsRepository(),
        ),
        preparedMealCalorieEntryCommitStoreProvider.overrideWithValue(
          const _MealStore(),
        ),
        plannedEntryRepositoryProvider.overrideWithValue(
          plans ?? FakePlannedEntryRepository(),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                onResult(
                  await PreparedMealEatFlow.eat(
                    context: context,
                    meal: preparedMealTestData(),
                  ),
                );
              },
              child: const Text('eat'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('eat'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('prepared_meal_eat_confirm_button')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('logs the entered portions and returns the entry', (
    tester,
  ) async {
    final actions = _FakeQuickEatActions();
    CalorieEntry? result;

    await _pumpHarness(
      tester,
      actions: actions,
      onResult: (entry) => result = entry,
    );

    expect(actions.consumedPortions, 1);
    expect(result?.bundleSourcePreparedMealId, 'meal-1');
  });

  testWidgets('the detail page logs the meal as the Vorrat holds it now', (
    tester,
  ) async {
    final opened = preparedMealTestData().copyWith(
      pendingRecipeIngredients: ['Salt'],
    );
    final filled = preparedMealTestData().copyWith(totalKcal: 600);
    final repository = _FakePreparedMealRepository([opened]);
    addTearDown(repository.dispose);
    final actions = _FakeQuickEatActions();
    const confirm = Key('prepared_meal_eat_confirm_button');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryQuickEatActionsProvider.overrideWithValue(actions),
          preparedMealRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => PreparedMealEatFlow.eat(
                  context: context,
                  meal: opened,
                  actions: _detailActions(),
                ),
                child: const Text('eat'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('eat'));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.byKey(confirm)).onPressed, isNull);

    repository.emit([filled]);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(confirm));
    await tester.pumpAndSettle();

    expect(actions.consumedMeal, filled);
    expect(find.text('Added to diary'), findsOneWidget);
  });

  testWidgets('the detail page logs the newer Vorrat meal from the start', (
    tester,
  ) async {
    final opened = preparedMealTestData().copyWith(
      pendingRecipeIngredients: ['Salt'],
    );
    final filled = preparedMealTestData().copyWith(totalKcal: 600);
    final repository = _FakePreparedMealRepository([filled]);
    addTearDown(repository.dispose);
    final actions = _FakeQuickEatActions();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryQuickEatActionsProvider.overrideWithValue(actions),
          preparedMealRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            // The Vorrat page keeps the meals loaded before a detail opens.
            body: Consumer(
              builder: (context, ref, _) {
                ref.watch(preparedMealsControllerProvider);
                return TextButton(
                  onPressed: () => PreparedMealEatFlow.eat(
                    context: context,
                    meal: opened,
                    actions: _detailActions(),
                  ),
                  child: const Text('eat'),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('eat'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('prepared_meal_eat_confirm_button')));
    await tester.pumpAndSettle();

    expect(actions.consumedMeal, filled);
  });

  testWidgets('shows the failure message when saving fails', (tester) async {
    CalorieEntry? result;

    await _pumpHarness(
      tester,
      actions: _FakeQuickEatActions(fail: true),
      onResult: (entry) => result = entry,
    );

    expect(result, isNull);
    expect(find.textContaining('Prepared meal action failed'), findsOneWidget);
  });

  testWidgets('confirms the log and undo returns the portions', (tester) async {
    _restoredPortions.clear();

    await _pumpHarness(
      tester,
      actions: _FakeQuickEatActions(),
      onResult: (_) {},
    );

    expect(find.text('Added to diary'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(_restoredPortions, [(mealId: 'meal-1', portions: 1)]);
  });

  testWidgets('a plan says so and undo deletes the plan', (tester) async {
    _restoredPortions.clear();
    final plans = FakePlannedEntryRepository();
    CalorieEntry? result;

    await _pumpHarness(
      tester,
      actions: _FakeQuickEatActions(plan: true),
      onResult: (entry) => result = entry,
      plans: plans,
    );
    plans.plans.add(result!);

    expect(find.text('Planned for the day'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(plans.plans, isEmpty);
    expect(_restoredPortions, isEmpty);
  });
}
