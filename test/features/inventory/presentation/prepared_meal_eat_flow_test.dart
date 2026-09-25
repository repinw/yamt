import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/application/calorie_entry_delete_flow.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_application.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_calorie_log_bridge.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/prepared_meal_eat_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../support/prepared_meal_test_data.dart';

class _FakeQuickEatActions implements InventoryQuickEatActions {
  new({this.fail = false});

  final bool fail;
  num? consumedPortions;

  @override
  Future<CalorieEntry?> consumePreparedMeal({
    required PreparedMeal meal,
    required num consumedPortions,
    required MealType mealType,
    required DateTime loggedDay,
  }) async {
    this.consumedPortions = consumedPortions;
    if (fail) {
      return null;
    }
    return buildConsumedPreparedMealCalorieEntry(
      meal: meal,
      consumedPortions: consumedPortions,
      mealType: mealType,
      now: () => loggedDay,
      nextEntryId: () => 'entry-1',
    );
  }

  @override
  Future<void> discardInventoryItemConsumption(String pendingConsumptionId) {
    throw UnimplementedError();
  }

  @override
  Future<String?> stageInventoryItemConsumption({
    required InventoryItem item,
    required int amount,
  }) {
    throw UnimplementedError();
  }
}

final _restoredPortions = <({String mealId, num portions})>[];

CalorieEntryDeleteFlow _deleteFlow() {
  return CalorieEntryDeleteFlow(
    deleteEntryById: (_) async => true,
    restoreConsumedItem: (_, _) async => true,
    rollbackRestoredItem: (_, _, {consumedAt}) async => true,
    sourceInventoryItemExists: (_) async => true,
    restorePreparedMealPortions: ({required mealId, required portions}) async {
      _restoredPortions.add((mealId: mealId, portions: portions));
      return true;
    },
    rollbackRestoredPreparedMeal: ({
      required mealId,
      required discardedPortions,
    }) async => true,
    sourcePreparedMealExists: (_) async => true,
  );
}

Future<void> _pumpHarness(
  WidgetTester tester, {
  required _FakeQuickEatActions actions,
  required ValueChanged<CalorieEntry?> onResult,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        inventoryQuickEatActionsProvider.overrideWithValue(actions),
        calorieEntryDeleteFlowProvider.overrideWithValue(_deleteFlow()),
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
}
