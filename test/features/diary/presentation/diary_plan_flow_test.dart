import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/quick_calorie_entry.dart';
import 'package:yamt/features/diary/presentation/diary_plan_flow.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_plan_accept_service.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/domain/inventory_exceptions.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../calories/support/fake_planned_entry_repository.dart';

/// Eats a plan, or throws [error] when it is set.
class _FakeAcceptService implements InventoryPlanAcceptService {
  new([this.error]);

  final InventoryException? error;

  @override
  Future<InventoryPlanAcceptResult> accept(
    CalorieEntry plan, {
    required List<InventoryItem> items,
    required List<PreparedMeal> meals,
  }) async {
    if (error case final error?) {
      throw error;
    }
    return (entry: plan.copyWith(id: 'entry'), missedStock: false);
  }

  @override
  Future<void> undo(CalorieEntry entry, CalorieEntry plan) async {}
}

const _acceptKey = ValueKey<String>('accept');

final CalorieEntry _recipePlan = buildQuickCalorieEntry(
  id: 'plan',
  userId: 'user-1',
  name: 'Bauerntopf',
  mealType: MealType.dinner,
  loggedAt: DateTime(2026, 10, 6, 19),
  now: DateTime(2026, 10, 5, 12),
  kcal: 700,
).copyWith(bundleSourceTemplateId: 'stew');

/// Accepts [_recipePlan] through the diary flow, with an accept service
/// that throws [error] when it is set.
Future<void> _accept(WidgetTester tester, [InventoryException? error]) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        plannedEntryRepositoryProvider.overrideWithValue(
          FakePlannedEntryRepository(plans: [_recipePlan]),
        ),
        inventoryPlanAcceptServiceProvider.overrideWithValue(
          _FakeAcceptService(error),
        ),
        inventoryQuickEatInventoryProvider.overrideWith(
          (ref) async =>
              const InventoryQuickEatInventoryData(items: [], meals: []),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => TextButton(
              key: _acceptKey,
              onPressed: () =>
                  acceptDiaryPlanFlow(context, ref, plan: _recipePlan),
              child: const Text('Annehmen'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(_acceptKey));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an accepted recipe plan says the stock stays', (tester) async {
    await _accept(tester);

    expect(find.text('Eingetragen – Vorrat nicht abgezogen'), findsOneWidget);
  });

  testWidgets('a recipe reminder with an open ingredient says so', (
    tester,
  ) async {
    await _accept(tester, const PlanNutritionPendingException('open'));

    expect(
      find.text('Erst alle Zutaten des Rezepts einem Vorrat zuordnen'),
      findsOneWidget,
    );
    expect(find.text('Aus Plan entfernen'), findsNothing);
  });

  testWidgets('a reminder of a removed recipe offers to remove it', (
    tester,
  ) async {
    await _accept(tester, const PlanSourceGoneException('gone'));

    expect(find.text('Das Rezept ist nicht mehr im Kochbuch'), findsOneWidget);
    expect(find.text('Aus Plan entfernen'), findsOneWidget);
  });
}
