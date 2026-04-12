import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/application/'
    'global_food_serving_suggestion_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/'
    'global_food_serving_suggestion.dart';
import 'package:yamt/features/inventory/domain/'
    'global_food_serving_suggestion_repository_contract.dart';
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

class _FakeGlobalFoodServingSuggestionRepository
    implements GlobalFoodServingSuggestionRepository {
  GlobalFoodServingSuggestionSet nextResult =
      const GlobalFoodServingSuggestionSet.empty();

  @override
  Future<GlobalFoodServingSuggestionSet> readSuggestions({
    required String foodFingerprint,
    String? globalFoodItemId,
    int limit = 5,
  }) async {
    return nextResult;
  }

  @override
  Future<void> recordSelection({
    required String foodFingerprint,
    String? globalFoodItemId,
    required double amount,
    required ConsumedUnit unit,
    required DateTime selectedAt,
  }) async {}
}

InventoryItem _amountItemWithServing() {
  return InventoryItem.create(
    id: 'item-1-serving',
    name: 'Quark',
    brand: 'Acme',
    entryDate: DateTime.parse('2026-04-07T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialQuantity: 1,
    initialAmount: 500,
    currentAmount: 500,
    amountUnit: InventoryAmountUnit.gram,
    weight: '500 g',
    servingSize: '125 g',
    servingQuantity: 125,
    servingQuantityUnit: 'g',
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

InventoryItem _pieceItemWithServingSuggestion() {
  return InventoryItem.create(
    id: 'item-2-serving',
    name: 'Wrap',
    brand: 'Acme',
    entryDate: DateTime.parse('2026-04-07T10:00:00Z'),
    storeName: 'Store',
    quantity: 2,
    initialQuantity: 2,
    servingSize: '75 g',
    servingQuantity: 75,
    servingQuantityUnit: 'g',
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 250,
      per100Protein: 8.0,
      per100Carbs: 30.0,
      per100Fat: 10.0,
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
  GlobalFoodServingSuggestionRepository? servingSuggestionRepository,
}) {
  return ProviderScope(
    overrides: [
      if (servingSuggestionRepository != null)
        globalFoodServingSuggestionRepositoryProvider.overrideWithValue(
          servingSuggestionRepository,
        ),
    ],
    child: MaterialApp(
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

DateTime _targetLoggedAtDate() {
  final today = DateUtils.dateOnly(DateTime.now());
  if (today.day > 1) {
    return today.subtract(const Duration(days: 1));
  }
  return today.subtract(const Duration(days: 2));
}

Future<void> _pickLoggedAtDate(WidgetTester tester, DateTime targetDate) async {
  final todayButton = find.text('Today');
  await tester.ensureVisible(todayButton);
  await tester.tap(todayButton);
  await tester.pumpAndSettle();

  final today = DateUtils.dateOnly(DateTime.now());
  if (targetDate.year != today.year || targetDate.month != today.month) {
    final previousMonthButton = find.byTooltip('Previous month');
    await tester.ensureVisible(previousMonthButton);
    await tester.tap(previousMonthButton);
    await tester.pumpAndSettle();
  }

  final dayButton = find.text('${targetDate.day}').last;
  await tester.ensureVisible(dayButton);
  await tester.tap(dayButton);
  await tester.pumpAndSettle();

  final okButton = find.text('OK');
  if (okButton.evaluate().isNotEmpty) {
    await tester.ensureVisible(okButton.last);
    await tester.tap(okButton.last);
    await tester.pumpAndSettle();
  }
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
    final mealTypeDropdown = find.byType(DropdownButton<MealType>);
    await tester.ensureVisible(mealTypeDropdown);
    await tester.tap(mealTypeDropdown);
    await tester.pumpAndSettle();
    final mealTypeOption = find.text(_mealTypeLabel(targetMealType)).last;
    await tester.ensureVisible(mealTypeOption);
    await tester.tap(mealTypeOption);
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

  testWidgets(
    'fixed-unit inedible amount keeps inventory deduction and reduces '
    'calories',
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
        '120',
      );
      await tester.enterText(
        find.byKey(const Key('inventory_item_inedible_amount_dialog_field')),
        '20',
      );
      await _tapConfirmButton(tester);

      expect(result, isNotNull);
      expect(result?.inventoryAmount, 120);
      expect(result?.calorieAmount, 100);
      expect(result?.calorieUnit?.jsonValue, 'g');
    },
  );

  testWidgets(
    'shows validation error when inedible amount is not smaller than eaten '
    'amount',
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
        '120',
      );
      await tester.enterText(
        find.byKey(const Key('inventory_item_inedible_amount_dialog_field')),
        '120',
      );
      await _tapConfirmButton(tester);

      expect(result, isNull);
      expect(
        find.text('The deducted amount must be smaller than the eaten amount.'),
        findsOneWidget,
      );
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

  testWidgets('shows serving suggestion chip for fixed-unit items', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp(
        item: _amountItemWithServing(),
        maxAmount: 500,
        onResult: (_) {},
      ),
    );

    await _openSheet(tester);
    expect(find.text('125 g'), findsOneWidget);

    await tester.tap(find.text('125 g'));
    await tester.pump();

    final amountField = tester.widget<TextField>(
      find.byKey(const Key('inventory_item_amount_dialog_field')),
    );
    expect(amountField.controller?.text, '125');
  });

  testWidgets('shows serving suggestion chip for manual portion input', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp(
        item: _pieceItemWithServingSuggestion(),
        maxAmount: 2,
        onResult: (_) {},
      ),
    );

    await _openSheet(tester);
    expect(find.text('75 g'), findsOneWidget);

    await tester.ensureVisible(find.text('75 g'));
    await tester.tap(find.text('75 g'));
    await tester.pump();

    final manualField = tester.widget<TextField>(find.byType(TextField).at(1));
    expect(manualField.controller?.text, '75');
  });

  testWidgets('prefills fixed-unit amount from learned personal suggestion', (
    tester,
  ) async {
    final repository = _FakeGlobalFoodServingSuggestionRepository()
      ..nextResult = const GlobalFoodServingSuggestionSet(
        personalSuggestion: ServingSizeSuggestion(
          amount: 135,
          unit: ConsumedUnit.grams,
        ),
      );

    await tester.pumpWidget(
      _buildTestApp(
        item: _amountItem().copyWith(globalFoodItemId: 'off-milk'),
        maxAmount: 1000,
        onResult: (_) {},
        servingSuggestionRepository: repository,
      ),
    );

    await _openSheet(tester);

    final amountField = tester.widget<TextField>(
      find.byKey(const Key('inventory_item_amount_dialog_field')),
    );
    expect(amountField.controller?.text, '135');
    expect(find.text('135 g'), findsOneWidget);
  });

  testWidgets('shows learned manual portion suggestions before metadata', (
    tester,
  ) async {
    final repository = _FakeGlobalFoodServingSuggestionRepository()
      ..nextResult = GlobalFoodServingSuggestionSet(
        personalSuggestion: const ServingSizeSuggestion(
          amount: 35,
          unit: ConsumedUnit.grams,
        ),
        globalSuggestions: <GlobalFoodServingSuggestion>[
          GlobalFoodServingSuggestion(
            id: 'global_off-wrap_g_34000',
            itemKey: 'global_off-wrap',
            globalFoodItemId: 'off-wrap',
            amount: 34,
            unit: ConsumedUnit.grams,
            selectionCount: 2,
            uniqueUserCount: 2,
            createdAt: DateTime.parse('2026-04-10T10:00:00.000Z'),
            updatedAt: DateTime.parse('2026-04-10T10:00:00.000Z'),
          ),
        ],
      );

    await tester.pumpWidget(
      _buildTestApp(
        item: _pieceItemWithServingSuggestion().copyWith(
          globalFoodItemId: 'off-wrap',
        ),
        maxAmount: 2,
        onResult: (_) {},
        servingSuggestionRepository: repository,
      ),
    );

    await _openSheet(tester);

    final manualField = tester.widget<TextField>(find.byType(TextField).at(1));
    expect(manualField.controller?.text, '35');
    expect(find.text('35 g'), findsOneWidget);
    expect(find.text('34 g'), findsOneWidget);
    expect(find.text('75 g'), findsOneWidget);
  });

  testWidgets('date picker updates loggedAt in the submitted request', (
    tester,
  ) async {
    InventoryItemEatRequest? result;
    final targetDate = _targetLoggedAtDate();
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
    await _pickLoggedAtDate(tester, targetDate);
    await _tapConfirmButton(tester);

    expect(result, isNotNull);
    expect(
      DateUtils.dateOnly(result!.loggedAt),
      DateUtils.dateOnly(targetDate),
    );
  });
}
