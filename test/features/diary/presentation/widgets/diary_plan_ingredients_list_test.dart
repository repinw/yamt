import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_bundle_component.dart';
import 'package:yamt/features/diary/application/diary_plan_ingredients_provider.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_plan_ingredients_list.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_components_list.dart';
import 'package:yamt/l10n/app_localizations.dart';

final _now = DateTime(2026, 10, 26, 9);

InventoryItem _item(String id, {String? brand}) => InventoryItem.create(
  id: id,
  name: id,
  brand: brand,
  nutrition: const GlobalFoodNutrition(
    qualityStatus: GlobalFoodNutritionQualityStatus.verified,
    per100Kcal: 380,
    per100Protein: 8,
    per100Carbs: 80,
    per100Fat: 3,
  ),
  entryDate: DateTime(2026, 9),
  storeName: 'Rewe',
  quantity: 1,
  initialAmount: 500,
  currentAmount: 500,
  amountUnit: InventoryAmountUnit.gram,
);

final InventoryItem _waffles = _item('Reiswaffeln', brand: 'Kölln');
final InventoryItem _rice = _item('Reis');

final CalorieEntry _plan = CalorieEntry.bundle(
  id: 'plan',
  userId: 'user-1',
  name: 'Reis-Bowl',
  mealType: MealType.dinner,
  totalKcal: 190,
  totalProtein: 4,
  totalCarbs: 40,
  totalFat: 2,
  bundleSourcePreparedMealId: 'bowl',
  bundleConsumedPortions: 1,
  bundleTotalPortions: 2,
  bundleComponents: const [
    CalorieEntryBundleComponent(
      name: 'Reiswaffeln',
      brand: 'Kölln',
      amountLabel: '50 g',
      totalKcal: 190,
      totalProtein: 4,
      totalCarbs: 40,
      totalFat: 2,
    ),
  ],
  loggedAt: _now,
  createdAt: _now,
  updatedAt: _now,
).copyWith(bundleSourcePreparedMealId: null, bundleSourceTemplateId: 'bowl');

/// The amount on the plan page, which the rows follow.
class _Amount extends Notifier<int> {
  @override
  int build() => 100;

  void change() => state += 50;
}

final _amountProvider = NotifierProvider<_Amount, int>(_Amount.new);

void main() {
  Future<List<String>> pump(
    WidgetTester tester, {
    AsyncValue<DiaryPlanIngredientRows?> lines = const AsyncData(null),
    CalorieEntry? plan,
  }) async {
    final picks = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: DiaryPlanIngredientsList(
              plan: plan ?? _plan,
              lines: lines,
              onPick: (line) => picks.add(line.ingredient),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return picks;
  }

  testWidgets('a recipe plan names the Vorrat item of each line, and a tap '
      'asks for another one', (tester) async {
    final picks = await pump(
      tester,
      lines: AsyncData(
        diaryPlanIngredientLines(_plan, [
          (
            ingredient: '100 g Reis',
            items: [_waffles],
            candidates: [_rice, _waffles],
          ),
          (ingredient: '2 Eier', items: const [], candidates: const []),
        ]),
      ),
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    final rice = find.byKey(EatComponentsList.recipeLineKey(0));
    expect(
      find.descendant(of: rice, matching: find.text('100 g Reis')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: rice, matching: find.text('Reiswaffeln · Kölln')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: rice, matching: find.text('50 g')),
      findsOneWidget,
    );
    // A line without an item says so and offers no pick.
    final eggs = find.byKey(EatComponentsList.recipeLineKey(1));
    expect(
      find.descendant(
        of: eggs,
        matching: find.text(l10n.eatPageIngredientMissing),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: eggs,
        matching: find.byIcon(Icons.chevron_right_rounded),
      ),
      findsNothing,
    );

    await tester.tap(rice);
    await tester.tap(eggs);

    expect(picks, ['100 g Reis']);
  });

  testWidgets('a food no line takes shows below the lines', (tester) async {
    await pump(
      tester,
      lines: AsyncData(
        diaryPlanIngredientLines(_plan, [
          (ingredient: '100 g Reis', items: [_rice], candidates: [_rice]),
        ]),
      ),
    );

    expect(find.byKey(EatComponentsList.recipeLineKey(0)), findsOneWidget);
    expect(find.text('Reiswaffeln'), findsOneWidget);
    expect(find.text('50 g'), findsOneWidget);
  });

  testWidgets('a plan of no recipe lists its foods', (tester) async {
    await pump(tester);

    expect(find.text('Reiswaffeln'), findsOneWidget);
    expect(find.byKey(EatComponentsList.recipeLineKey(0)), findsNothing);
  });

  testWidgets('a recipe that fails to load says so under the foods', (
    tester,
  ) async {
    await pump(
      tester,
      lines: AsyncError(StateError('offline'), StackTrace.empty),
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    expect(find.text('Reiswaffeln'), findsOneWidget);
    expect(find.text(l10n.diaryPlanIngredientsLoadFailed), findsOneWidget);
  });

  testWidgets('a reminder of no foods shows nothing until its recipe loads', (
    tester,
  ) async {
    await pump(
      tester,
      lines: const AsyncLoading(),
      plan: _plan.copyWith(bundleComponents: const []),
    );

    expect(find.byType(EatComponentsList), findsNothing);
  });

  testWidgets('the lines stay while they reload after an amount change', (
    tester,
  ) async {
    final reload = Completer<void>();
    var loads = 0;
    final rows = FutureProvider<DiaryPlanIngredientRows?>((ref) async {
      ref.watch(_amountProvider);
      // The reload waits, as a slow read would.
      if (loads++ > 0) {
        await reload.future;
      }
      return diaryPlanIngredientLines(_plan, [
        (ingredient: '100 g Reis', items: [_waffles], candidates: [_waffles]),
      ]);
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => DiaryPlanIngredientsList(
                plan: _plan,
                lines: ref.watch(rows),
                onPick: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    container.read(_amountProvider.notifier).change();
    await tester.pump();

    expect(find.byKey(EatComponentsList.recipeLineKey(0)), findsOneWidget);
    reload.complete();
  });
}
