import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_eat_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

InventoryItem _amountItem() {
  return InventoryItem.create(
    id: 'item-1',
    name: 'Milk',
    brand: 'Acme',
    entryDate: DateTime.parse('2026-04-07T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialQuantity: 1,
    initialAmount: 1000,
    currentAmount: 1000,
    amountUnit: InventoryAmountUnit.gram,
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 64,
      per100Protein: 3.3,
      per100Carbs: 4.8,
      per100Fat: 3.5,
    ),
  );
}

InventoryItem _pieceItem() {
  return InventoryItem.create(
    id: 'item-2',
    name: 'Banana',
    brand: 'Acme',
    entryDate: DateTime.parse('2026-04-07T10:00:00Z'),
    storeName: 'Store',
    quantity: 3,
    initialQuantity: 3,
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 89,
      per100Protein: 1.1,
      per100Carbs: 23.0,
      per100Fat: 0.3,
    ),
  );
}

class _OpenEatSheetButton extends StatelessWidget {
  const _OpenEatSheetButton({
    required this.item,
    required this.maxAmount,
    required this.onResult,
  });

  final InventoryItem item;
  final int maxAmount;
  final ValueChanged<InventoryItemEatRequest?> onResult;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final result = await showInventoryItemEatSheet(
          context: context,
          item: item,
          maxAmount: maxAmount,
          invalidAmountMessage: 'Invalid amount',
        );
        onResult(result);
      },
      child: const Text('open'),
    );
  }
}

Widget _buildTestApp({
  required InventoryItem item,
  required int maxAmount,
  required ValueChanged<InventoryItemEatRequest?> onResult,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(
        child: _OpenEatSheetButton(
          item: item,
          maxAmount: maxAmount,
          onResult: onResult,
        ),
      ),
    ),
  );
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _tapConfirmButton(WidgetTester tester) async {
  final confirmButton = find.byKey(
    const Key('inventory_item_amount_dialog_confirm_button'),
  );
  await tester.ensureVisible(confirmButton);
  await tester.tap(confirmButton);
  await tester.pumpAndSettle();
}

String _mealTypeLabel(MealType mealType) {
  return switch (mealType) {
    MealType.breakfast => 'Breakfast',
    MealType.lunch => 'Lunch',
    MealType.dinner => 'Dinner',
    MealType.snack => 'Snack',
  };
}

void main() {
  testWidgets(
    'amount field starts without autofocus and clear button clears and focuses',
    (tester) async {
      InventoryItemEatRequest? result;
      await tester.pumpWidget(
        _buildTestApp(
          item: _amountItem(),
          maxAmount: 1000,
          onResult: (value) {
            result = value;
          },
        ),
      );

      await _openSheet(tester);

      final amountField = find.byKey(
        const Key('inventory_item_amount_dialog_field'),
      );
      final clearButton = find.byKey(
        const Key('inventory_item_amount_dialog_clear_button'),
      );
      final amountTextField = tester.widget<TextField>(amountField);

      expect(amountTextField.autofocus, isFalse);
      expect(amountTextField.focusNode?.hasFocus, isFalse);
      expect(amountTextField.controller?.text, '1');

      await tester.tap(clearButton);
      await tester.pump();

      final updatedTextField = tester.widget<TextField>(amountField);
      expect(updatedTextField.controller?.text, isEmpty);
      expect(updatedTextField.focusNode?.hasFocus, isTrue);
      expect(result, isNull);
    },
  );

  testWidgets('submits valid input and pops with the expected request', (
    tester,
  ) async {
    InventoryItemEatRequest? result;
    await tester.pumpWidget(
      _buildTestApp(
        item: _amountItem(),
        maxAmount: 1000,
        onResult: (value) {
          result = value;
        },
      ),
    );

    await _openSheet(tester);

    final targetMealType = MealType.sectionOrder.firstWhere(
      (mealType) => mealType != MealType.defaultForDateTime(DateTime.now()),
    );

    await tester.enterText(
      find.byKey(const Key('inventory_item_amount_dialog_field')),
      '120',
    );
    await tester.tap(find.byType(DropdownButton<MealType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_mealTypeLabel(targetMealType)).last);
    await tester.pumpAndSettle();
    await _tapConfirmButton(tester);

    expect(result, isNotNull);
    expect(result?.inventoryAmount, 120);
    expect(result?.mealType, targetMealType);
    expect(result?.calorieAmount, isNull);
    expect(
      DateUtils.dateOnly(result!.loggedAt),
      DateUtils.dateOnly(DateTime.now()),
    );
    expect(
      find.byKey(const Key('inventory_item_amount_dialog_field')),
      findsNothing,
    );
  });

  testWidgets(
    'shows validation error for invalid inventory amount and keeps sheet open',
    (tester) async {
      InventoryItemEatRequest? result;
      await tester.pumpWidget(
        _buildTestApp(
          item: _amountItem(),
          maxAmount: 1000,
          onResult: (value) {
            result = value;
          },
        ),
      );

      await _openSheet(tester);
      await tester.enterText(
        find.byKey(const Key('inventory_item_amount_dialog_field')),
        '1001',
      );
      await _tapConfirmButton(tester);

      expect(result, isNull);
      expect(find.text('Invalid amount'), findsOneWidget);
      expect(
        find.byKey(const Key('inventory_item_amount_dialog_confirm_button')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'shows validation error when manual calorie portion is required but empty',
    (tester) async {
      InventoryItemEatRequest? result;
      await tester.pumpWidget(
        _buildTestApp(
          item: _pieceItem(),
          maxAmount: 3,
          onResult: (value) {
            result = value;
          },
        ),
      );

      await _openSheet(tester);
      await _tapConfirmButton(tester);

      expect(result, isNull);
      expect(
        find.text('Please enter a number greater than zero.'),
        findsOneWidget,
      );
      expect(find.text('Eat: Banana'), findsOneWidget);
    },
  );

  testWidgets('quick select chip updates the inventory amount field', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp(item: _amountItem(), maxAmount: 1000, onResult: (_) {}),
    );

    await _openSheet(tester);
    await tester.tap(find.text('50g'));
    await tester.pump();

    final amountField = tester.widget<TextField>(
      find.byKey(const Key('inventory_item_amount_dialog_field')),
    );
    expect(amountField.controller?.text, '50');
  });
}
