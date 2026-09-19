import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_nutrient_details.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_details_view.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../support/fake_calories_repositories.dart';

void main() {
  testWidgets('renders entry details without a title or save button', (
    tester,
  ) async {
    await tester.pumpWidget(_wrapDetailsView(entry: _entry()));
    await tester.pumpAndSettle();

    expect(find.text('Calorie entry details'), findsNothing);
    expect(find.byKey(CalorieEntryEditorKeys.saveButton), findsNothing);
    expect(find.text('Dairy Co'), findsOneWidget);
    expect(find.text('Skyr'), findsOneWidget);
    expect(find.byKey(CalorieEntryDetailKeys.amountValue), findsOneWidget);
    expect(find.byKey(CalorieEntryDetailKeys.nutritionStrip), findsOneWidget);
  });

  testWidgets('shows a nutrition table per 100 g and eaten amount', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_wrapDetailsView(entry: _entry()));
    await tester.pumpAndSettle();

    final table = find.byKey(CalorieEntryDetailKeys.nutritionStrip);
    Finder inTable(String text) =>
        find.descendant(of: table, matching: find.text(text));

    expect(inTable('Nutrient'), findsOneWidget);
    expect(inTable('Per 100 g'), findsOneWidget);
    expect(inTable('200 g'), findsOneWidget);
    expect(inTable('Energy'), findsOneWidget);
    expect(inTable('418 kJ\n100 kcal'), findsOneWidget);
    expect(inTable('837 kJ\n200 kcal'), findsOneWidget);
    expect(inTable('Fat'), findsOneWidget);
    expect(inTable('2 g'), findsOneWidget);
    expect(inTable('20 g'), findsOneWidget);
    expect(find.text('10% of your daily goal'), findsOneWidget);
  });

  testWidgets('lists known label nutrients and hides unknown ones', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final entry = _entry().copyWithDetails(
      const CalorieNutrientDetails(per100SaturatedFat: 0.5, per100Salt: 0.1),
    );

    await tester.pumpWidget(_wrapDetailsView(entry: entry));
    await tester.pumpAndSettle();

    expect(find.text('of which saturates'), findsOneWidget);
    expect(find.text('Salt'), findsOneWidget);
    expect(find.text('0.2 g'), findsOneWidget);
    expect(find.text('of which sugars'), findsNothing);
    expect(find.text('Fibre'), findsNothing);
  });

  testWidgets('fires detail callbacks from controls and actions', (
    tester,
  ) async {
    var closeCount = 0;
    var eatAgainCount = 0;
    var returnCount = 0;
    var pickLoggedAtCount = 0;
    var pickAmountCount = 0;
    MealType? selectedMealType;

    await tester.pumpWidget(
      _wrapDetailsView(
        entry: _entry(),
        onClose: () => closeCount += 1,
        onEatAgain: () => eatAgainCount += 1,
        onReturnToInventory: () => returnCount += 1,
        onPickLoggedAt: () => pickLoggedAtCount += 1,
        onPickAmount: () => pickAmountCount += 1,
        onMealTypeChanged: (mealType) => selectedMealType = mealType,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Close'));
    await tester.tap(find.byKey(CalorieEntryDetailKeys.eatAgainButton));
    await tester.tap(
      find.byKey(CalorieEntryDetailKeys.returnToInventoryButton),
    );
    await tester.tap(find.byKey(CalorieEntryDetailKeys.loggedDayButton));
    await tester.tap(find.byKey(CalorieEntryDetailKeys.amountValue));
    await tester.pump();

    await tester.tap(find.byKey(CalorieEntryDetailKeys.mealSelector));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dinner').last);
    await tester.pumpAndSettle();

    expect(closeCount, 1);
    expect(eatAgainCount, 1);
    expect(returnCount, 1);
    expect(pickLoggedAtCount, 1);
    expect(pickAmountCount, 1);
    expect(selectedMealType, MealType.dinner);
  });
}

Widget _wrapDetailsView({
  required CalorieEntry entry,
  VoidCallback? onClose,
  VoidCallback? onEatAgain,
  VoidCallback? onReturnToInventory,
  VoidCallback? onPickLoggedAt,
  VoidCallback? onPickAmount,
  ValueChanged<MealType>? onMealTypeChanged,
}) {
  final settingsRepository = FakeCalorieSettingsRepository(
    initialSettings: CalorieGoalSettings.single(
      dailyKcalGoal: 2000,
      calculatorProfile: null,
      effectiveDate: DateTime(2026),
    ),
  );
  addTearDown(settingsRepository.dispose);

  return ProviderScope(
    overrides: [
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
    ],
    child: MaterialApp(
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: CalorieEntryDetailsView(
        entry: entry,
        isSaving: false,
        canEatAgain: true,
        onClose: onClose ?? () {},
        onEatAgain: onEatAgain ?? () {},
        onReturnToInventory: onReturnToInventory ?? () {},
        onPickLoggedAt: onPickLoggedAt ?? () {},
        onPickAmount: onPickAmount ?? () {},
        onMealTypeChanged: onMealTypeChanged ?? (_) {},
      ),
    ),
  );
}

CalorieEntry _entry() {
  final loggedAt = DateTime(2026, 2, 25, 8);
  return CalorieEntry.create(
    id: 'entry-1',
    userId: 'user-1',
    name: 'Skyr',
    brand: 'Dairy Co, Big Retail',
    mealType: MealType.breakfast,
    consumedAmount: 200,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 100,
    per100Protein: 10,
    per100Carbs: 5,
    per100Fat: 1,
    sourceInventoryItemId: 'inventory-1',
    sourceInventoryAmountToRestore: 2,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

extension on CalorieEntry {
  CalorieEntry copyWithDetails(CalorieNutrientDetails details) {
    return CalorieEntry.create(
      id: id,
      userId: userId,
      name: name,
      brand: brand,
      mealType: mealType,
      consumedAmount: consumedAmount,
      consumedUnit: consumedUnit,
      per100Kcal: per100Kcal,
      per100Protein: per100Protein,
      per100Carbs: per100Carbs,
      per100Fat: per100Fat,
      sourceInventoryItemId: sourceInventoryItemId,
      sourceInventoryAmountToRestore: sourceInventoryAmountToRestore,
      nutrientDetails: details,
      loggedAt: loggedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
