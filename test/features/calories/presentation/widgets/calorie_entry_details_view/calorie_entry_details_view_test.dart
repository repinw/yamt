import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_details_view.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('renders passed entry details', (tester) async {
    final entry = _entry();

    await tester.pumpWidget(
      _wrapDetailsView(
        entry: entry,
        selectedMealType: entry.mealType,
        selectedLoggedAt: entry.loggedAt,
      ),
    );

    expect(find.text('Calorie entry details'), findsOneWidget);
    expect(find.text('Dairy Co'), findsOneWidget);
    expect(find.text('Skyr'), findsOneWidget);
    expect(find.byKey(CalorieEntryDetailKeys.amountValue), findsOneWidget);
    expect(find.text('200 g'), findsOneWidget);
    expect(find.byKey(CalorieEntryDetailKeys.nutritionStrip), findsOneWidget);
  });

  testWidgets('fires detail callbacks from controls and actions', (
    tester,
  ) async {
    final entry = _entry();
    var closeCount = 0;
    var saveCount = 0;
    var returnCount = 0;
    var pickLoggedAtCount = 0;
    MealType? selectedMealType;

    await tester.pumpWidget(
      _wrapDetailsView(
        entry: entry,
        selectedMealType: MealType.lunch,
        selectedLoggedAt: entry.loggedAt.add(const Duration(days: 1)),
        onClose: () => closeCount += 1,
        onSave: () => saveCount += 1,
        onReturnToInventory: () => returnCount += 1,
        onPickLoggedAt: () => pickLoggedAtCount += 1,
        onMealTypeChanged: (mealType) => selectedMealType = mealType,
      ),
    );

    await tester.tap(find.byTooltip('Close'));
    await tester.pump();

    await tester.tap(find.byKey(CalorieEntryEditorKeys.saveButton));
    await tester.pump();

    await tester.tap(
      find.byKey(CalorieEntryDetailKeys.returnToInventoryButton),
    );
    await tester.pump();

    await tester.tap(find.byKey(CalorieEntryDetailKeys.loggedDayButton));
    await tester.pump();

    await tester.tap(find.byKey(CalorieEntryDetailKeys.mealSelector));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dinner').last);
    await tester.pumpAndSettle();

    expect(closeCount, 1);
    expect(saveCount, 1);
    expect(returnCount, 1);
    expect(pickLoggedAtCount, 1);
    expect(selectedMealType, MealType.dinner);
  });
}

Widget _wrapDetailsView({
  required CalorieEntry entry,
  required MealType selectedMealType,
  required DateTime selectedLoggedAt,
  VoidCallback? onClose,
  VoidCallback? onSave,
  VoidCallback? onReturnToInventory,
  VoidCallback? onPickLoggedAt,
  ValueChanged<MealType>? onMealTypeChanged,
}) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: CalorieEntryDetailsView(
        title: 'Calorie entry details',
        entry: entry,
        selectedMealType: selectedMealType,
        selectedLoggedAt: selectedLoggedAt,
        isSaving: false,
        onClose: onClose ?? () {},
        onSave: onSave ?? () {},
        onReturnToInventory: onReturnToInventory ?? () {},
        onPickLoggedAt: onPickLoggedAt ?? () {},
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
    brand: 'Dairy Co',
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
