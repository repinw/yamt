import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/inventory/application/'
    'global_food_serving_suggestion_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/'
    'global_food_serving_suggestion.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
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
    required double amount,
    required ConsumedUnit unit,
    required DateTime selectedAt,
    String? globalFoodItemId,
    String? label,
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

InventoryItem _slicedCheeseItem() {
  return InventoryItem.create(
    id: 'item-sliced-cheese',
    name: 'Sliced cheese',
    brand: 'Acme',
    entryDate: DateTime.parse('2026-04-07T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialAmount: 200,
    currentAmount: 200,
    amountUnit: InventoryAmountUnit.gram,
    weight: '200 g',
    servingSize: '1 slice (25 g)',
    servingQuantity: 25,
    servingQuantityUnit: 'g',
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 350,
      per100Protein: 25,
      per100Carbs: 1,
      per100Fat: 27,
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
      per100Carbs: 23,
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
      per100Protein: 8,
      per100Carbs: 30,
      per100Fat: 10,
    ),
  );
}

InventoryItem _fractionalPieceAmountItem() {
  return InventoryItem.create(
    id: 'item-3',
    name: 'Apple',
    brand: 'Acme',
    entryDate: DateTime.parse('2026-04-07T10:00:00Z'),
    storeName: 'Store',
    quantity: 2,
    initialQuantity: 2,
    initialAmount: 2000,
    currentAmount: 1500,
    amountScale: inventoryPieceAmountScale,
    amountUnit: InventoryAmountUnit.piece,
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 52,
      per100Protein: 0.3,
      per100Carbs: 14,
      per100Fat: 0.2,
    ),
  );
}

class _OpenEatSheetButton extends StatelessWidget {
  const _OpenEatSheetButton({
    required this.item,
    required this.maxAmount,
    required this.onResult,
    this.initialLoggedAt,
    this.initialMealType,
  });

  final InventoryItem item;
  final int maxAmount;
  final ValueChanged<InventoryItemEatRequest?> onResult;
  final DateTime? initialLoggedAt;
  final MealType? initialMealType;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final result = await showInventoryItemEatSheet(
          context: context,
          item: item,
          maxAmount: maxAmount,
          invalidAmountMessage: 'Invalid amount',
          initialLoggedAt: initialLoggedAt,
          initialMealType: initialMealType,
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
  DateTime? initialLoggedAt,
  MealType? initialMealType,
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
            initialLoggedAt: initialLoggedAt,
            initialMealType: initialMealType,
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

Future<void> _selectAmountMode(WidgetTester tester, String label) async {
  final dropdown = find.byKey(const Key('inventory_item_amount_mode_dropdown'));
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();

  final option = find.text(label).last;
  await tester.ensureVisible(option);
  await tester.tap(option);
  await tester.pumpAndSettle();
}

Future<void> _expandInedibleAmountSection(WidgetTester tester) async {
  final toggle = find.byKey(const Key('inventory_item_inedible_amount_toggle'));
  await tester.ensureVisible(toggle);
  await tester.tap(toggle);
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
  final loggedAtButton = find.byKey(
    const Key('inventory_item_logged_at_button'),
  );
  await tester.ensureVisible(loggedAtButton);
  await tester.tap(loggedAtButton);
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

String _formatMediumDate(WidgetTester tester, DateTime date) {
  final context = tester.element(find.byType(Scaffold));
  return MaterialLocalizations.of(context).formatMediumDate(date);
}

void main() {
  testWidgets('hero shows fallback when product image cannot be resolved', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp(
        item: _amountItem().copyWith(imageUrl: 'not-a-valid-url'),
        maxAmount: 1000,
        onResult: (_) {},
      ),
    );

    await _openSheet(tester);

    expect(
      find.byKey(const Key('inventory_item_eat_sheet_hero_fallback')),
      findsOneWidget,
    );
  });

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

      expect(find.byIcon(Icons.cleaning_services_outlined), findsOneWidget);
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

  testWidgets('done on number keyboard unfocuses amount field', (tester) async {
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
    await tester.tap(amountField);
    await tester.pump();

    final focusedTextField = tester.widget<TextField>(amountField);
    expect(focusedTextField.focusNode?.hasFocus, isTrue);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    final unfocusedTextField = tester.widget<TextField>(amountField);
    expect(unfocusedTextField.focusNode?.hasFocus, isFalse);
    expect(result, isNull);
    expect(amountField, findsOneWidget);
  });

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

  testWidgets('uses preselected logged-at date and meal type', (tester) async {
    InventoryItemEatRequest? result;
    final initialLoggedAt = DateTime(2026, 4, 27, 13, 45);
    await tester.pumpWidget(
      _buildTestApp(
        item: _amountItem(),
        maxAmount: 1000,
        initialLoggedAt: initialLoggedAt,
        initialMealType: MealType.lunch,
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
    await _tapConfirmButton(tester);

    expect(result, isNotNull);
    expect(result?.mealType, MealType.lunch);
    expect(result?.loggedAt, initialLoggedAt);
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
    'asks for a portion weight when a piece item has no learned weight',
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
        find.byKey(const Key('inventory_item_portion_amount_field')),
        findsOneWidget,
      );
      expect(find.text('New portion'), findsOneWidget);
    },
  );

  testWidgets(
    'accepts fractional piece inventory amount and keeps scaled stock amount',
    (tester) async {
      InventoryItemEatRequest? result;
      await tester.pumpWidget(
        _buildTestApp(
          item: _fractionalPieceAmountItem(),
          maxAmount: 1500,
          onResult: (value) {
            result = value;
          },
        ),
      );

      await _openSheet(tester);

      final amountField = tester.widget<TextField>(
        find.byKey(const Key('inventory_item_amount_dialog_field')),
      );
      expect(amountField.controller?.text, '1');

      await tester.enterText(
        find.byKey(const Key('inventory_item_amount_dialog_field')),
        '1,5',
      );
      await _tapConfirmButton(tester);
      await tester.enterText(
        find.byKey(const Key('inventory_item_portion_amount_field')),
        '150',
      );
      await tester.tap(find.text('Save portion'));
      await tester.pumpAndSettle();
      await _tapConfirmButton(tester);

      expect(result, isNotNull);
      expect(result?.inventoryAmount, 1500);
      expect(result?.calorieAmount, 225);
      expect(result?.calorieUnit, ConsumedUnit.grams);
      expect(result?.portionBaseAmount, 150);
      expect(result?.portionCount, 1.5);
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
      await _expandInedibleAmountSection(tester);
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
      await _expandInedibleAmountSection(tester);
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
    expect(find.text('125 g'), findsWidgets);

    await tester.tap(find.text('125 g').first);
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
    expect(find.text('Piece (75g)'), findsOneWidget);

    final amountField = tester.widget<TextField>(
      find.byKey(const Key('inventory_item_amount_dialog_field')),
    );
    expect(amountField.controller?.text, '1');
  });

  testWidgets('asks for a new portion weight when logging raw pieces', (
    tester,
  ) async {
    InventoryItemEatRequest? result;
    await tester.pumpWidget(
      _buildTestApp(
        item: _pieceItemWithServingSuggestion(),
        maxAmount: 2,
        onResult: (value) {
          result = value;
        },
      ),
    );

    await _openSheet(tester);
    await _selectAmountMode(tester, 'Piece');
    await tester.enterText(
      find.byKey(const Key('inventory_item_amount_dialog_field')),
      '2',
    );
    await _tapConfirmButton(tester);

    expect(result, isNull);
    expect(
      find.byKey(const Key('inventory_item_portion_amount_field')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('inventory_item_portion_amount_field')),
      '80',
    );
    await tester.tap(find.text('Save portion'));
    await tester.pumpAndSettle();
    await _tapConfirmButton(tester);

    expect(result, isNotNull);
    expect(result?.inventoryAmount, 2);
    expect(result?.calorieAmount, 160);
    expect(result?.calorieUnit, ConsumedUnit.grams);
    expect(result?.portionBaseAmount, 80);
    expect(result?.portionCount, 2);
  });

  testWidgets('logs fixed-unit item from portion count and label', (
    tester,
  ) async {
    InventoryItemEatRequest? result;
    await tester.pumpWidget(
      _buildTestApp(
        item: _slicedCheeseItem(),
        maxAmount: 200,
        onResult: (value) {
          result = value;
        },
      ),
    );

    await _openSheet(tester);
    await _selectAmountMode(tester, '+ New portion...');
    await tester.enterText(
      find.byKey(const Key('inventory_item_portion_label_field')),
      'Scheibe',
    );
    await tester.enterText(
      find.byKey(const Key('inventory_item_portion_amount_field')),
      '25',
    );
    await tester.tap(find.text('Save portion'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('inventory_item_amount_dialog_field')),
      '3',
    );
    await _tapConfirmButton(tester);

    expect(result, isNotNull);
    expect(result?.inventoryAmount, 75);
    expect(result?.calorieAmount, 75);
    expect(result?.calorieUnit, ConsumedUnit.grams);
    expect(result?.portionBaseAmount, 25);
    expect(result?.portionBaseUnit, ConsumedUnit.grams);
    expect(result?.portionCount, 3);
    expect(result?.portionLabel, 'Scheibe');
  });

  testWidgets('logs fractional fixed-unit portions exactly', (tester) async {
    InventoryItemEatRequest? result;
    await tester.pumpWidget(
      _buildTestApp(
        item: _slicedCheeseItem(),
        maxAmount: 200,
        onResult: (value) {
          result = value;
        },
      ),
    );

    await _openSheet(tester);
    await _selectAmountMode(tester, '+ New portion...');
    await tester.enterText(
      find.byKey(const Key('inventory_item_portion_label_field')),
      'Scheibe',
    );
    await tester.enterText(
      find.byKey(const Key('inventory_item_portion_amount_field')),
      '37,5',
    );
    await tester.tap(find.text('Save portion'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('inventory_item_amount_dialog_field')),
      '0,5',
    );
    await _tapConfirmButton(tester);

    expect(result, isNotNull);
    expect(result?.inventoryAmount, 19);
    expect(result?.calorieAmount, 18.75);
    expect(result?.calorieUnit, ConsumedUnit.grams);
    expect(result?.portionBaseAmount, 37.5);
    expect(result?.portionBaseUnit, ConsumedUnit.grams);
    expect(result?.portionCount, 0.5);
    expect(result?.portionLabel, 'Scheibe');
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
    expect(find.text('135 g'), findsWidgets);
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

    final amountField = tester.widget<TextField>(
      find.byKey(const Key('inventory_item_amount_dialog_field')),
    );
    expect(amountField.controller?.text, '1');
    expect(find.text('Piece (35g)'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('inventory_item_amount_mode_dropdown')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Piece (34g)'), findsOneWidget);
    expect(find.text('Piece (75g)'), findsOneWidget);
  });

  testWidgets('logged-at card switches between compact and labeled states', (
    tester,
  ) async {
    final targetDate = _targetLoggedAtDate();
    await tester.pumpWidget(
      _buildTestApp(item: _amountItem(), maxAmount: 1000, onResult: (_) {}),
    );

    await _openSheet(tester);

    expect(
      find.byKey(const Key('inventory_item_logged_at_compact')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('inventory_item_logged_at_labeled')),
      findsNothing,
    );

    await _pickLoggedAtDate(tester, targetDate);

    expect(
      find.byKey(const Key('inventory_item_logged_at_compact')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('inventory_item_logged_at_labeled')),
      findsOneWidget,
    );
    expect(find.text(_formatMediumDate(tester, targetDate)), findsOneWidget);
  });

  testWidgets('first nutrition metric uses highlight color', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(item: _amountItem(), maxAmount: 1000, onResult: (_) {}),
    );

    await _openSheet(tester);

    final context = tester.element(
      find.byKey(const Key('inventory_item_nutrition_value_0')),
    );
    final colors = Theme.of(context).colorScheme;
    final firstValue = tester.widget<Text>(
      find.byKey(const Key('inventory_item_nutrition_value_0')),
    );
    final secondValue = tester.widget<Text>(
      find.byKey(const Key('inventory_item_nutrition_value_1')),
    );

    expect(firstValue.style?.color, colors.primary);
    expect(secondValue.style?.color, colors.onSurface);
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
