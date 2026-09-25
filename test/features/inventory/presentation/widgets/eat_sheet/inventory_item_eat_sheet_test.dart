import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/data/'
    'global_food_serving_suggestion_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/'
    'global_food_serving_suggestion.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_amount_ruler.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_inedible_line.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_remember_portion.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_ruler.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_sheet.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_when_menu.dart';
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
  Exception? recordFailure;
  final List<
    ({
      String foodFingerprint,
      String? globalFoodItemId,
      double amount,
      ConsumedUnit unit,
      DateTime selectedAt,
      String? label,
    })
  >
  calls =
      <
        ({
          String foodFingerprint,
          String? globalFoodItemId,
          double amount,
          ConsumedUnit unit,
          DateTime selectedAt,
          String? label,
        })
      >[];

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
  }) async {
    final failure = recordFailure;
    if (failure != null) {
      throw failure;
    }
    calls.add((
      foodFingerprint: foodFingerprint,
      globalFoodItemId: globalFoodItemId,
      amount: amount,
      unit: unit,
      selectedAt: selectedAt,
      label: label,
    ));
  }
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
  const new({
    required this.item,
    required this.onResult,
    this.initialLoggedAt,
    this.initialMealType,
  });

  final InventoryItem item;
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
  required ValueChanged<InventoryItemEatRequest?> onResult,
  GlobalFoodServingSuggestionRepository? servingSuggestionRepository,
  DateTime? initialLoggedAt,
  MealType? initialMealType,
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: [
      if (servingSuggestionRepository != null)
        globalFoodServingSuggestionRepositoryProvider.overrideWithValue(
          servingSuggestionRepository,
        ),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: _OpenEatSheetButton(
            item: item,
            onResult: onResult,
            initialLoggedAt: initialLoggedAt,
            initialMealType: initialMealType,
          ),
        ),
      ),
    ),
  );
}

const _confirmKey = Key('inventory_item_amount_dialog_confirm_button');
const _pieceWeightKey = Key('inventory_item_portion_amount_field');

Future<void> _tapConfirmButton(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(_confirmKey));
  await tester.tap(find.byKey(_confirmKey));
  await tester.pumpAndSettle();
}

Future<void> _enterAmount(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(EatAmountRuler.fieldKey), text);
  await tester.pump();
}

String? _amountText(WidgetTester tester) {
  return tester
      .widget<TextField>(find.byKey(EatAmountRuler.fieldKey))
      .controller
      ?.text;
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text).last;
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _tapKey(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

Future<void> _openWhenMenu(WidgetTester tester) async {
  await tester.tap(find.byKey(EatWhenMenu.buttonKey));
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
  await _openWhenMenu(tester);
  await tester.tap(find.byKey(EatWhenMenu.pickDayKey));
  await tester.pumpAndSettle();

  final today = DateUtils.dateOnly(DateTime.now());
  if (targetDate.year != today.year || targetDate.month != today.month) {
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
  }

  await tester.tap(find.text('${targetDate.day}').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK').last);
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

Future<void> _pumpSheet(
  WidgetTester tester,
  InventoryItem item, {
  ValueChanged<InventoryItemEatRequest?>? onResult,
  GlobalFoodServingSuggestionRepository? servingSuggestionRepository,
  DateTime? initialLoggedAt,
  MealType? initialMealType,
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    _buildTestApp(
      item: item,
      onResult: onResult ?? (_) {},
      servingSuggestionRepository: servingSuggestionRepository,
      initialLoggedAt: initialLoggedAt,
      initialMealType: initialMealType,
      locale: locale,
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('header shows brand, name, stock and a fallback image', (
    tester,
  ) async {
    await _pumpSheet(
      tester,
      _amountItem().copyWith(imageUrl: 'not-a-valid-url'),
    );

    expect(find.text('ACME'), findsOneWidget);
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('1000 g in stock'), findsOneWidget);
    expect(
      find.byKey(const Key('inventory_item_eat_sheet_hero_fallback')),
      findsOneWidget,
    );
  });

  testWidgets('shows the stock in German', (tester) async {
    await _pumpSheet(tester, _amountItem(), locale: const Locale('de'));

    expect(find.text('1000 g im Vorrat'), findsOneWidget);
    expect(find.text('Nährwerte'), findsOneWidget);
  });

  testWidgets('amount field starts unfocused and done unfocuses it', (
    tester,
  ) async {
    await _pumpSheet(tester, _amountItem());

    final field = find.byKey(EatAmountRuler.fieldKey);
    expect(_amountText(tester), '1');
    expect(tester.widget<TextField>(field).focusNode?.hasFocus, isFalse);

    await tester.tap(field);
    await tester.pump();
    expect(tester.widget<TextField>(field).focusNode?.hasFocus, isTrue);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(tester.widget<TextField>(field).focusNode?.hasFocus, isFalse);
  });

  testWidgets('confirm shows the calories and pops with the request', (
    tester,
  ) async {
    InventoryItemEatRequest? result;
    await _pumpSheet(
      tester,
      _amountItem(),
      onResult: (value) => result = value,
    );
    final targetMealType = MealType.sectionOrder.firstWhere(
      (mealType) => mealType != MealType.defaultForDateTime(DateTime.now()),
    );

    await _enterAmount(tester, '120');
    expect(find.text('77 kcal'), findsOneWidget);
    await _openWhenMenu(tester);
    await tester.tap(
      find.widgetWithText(
        CheckedPopupMenuItem<Object>,
        _mealTypeLabel(targetMealType),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('TODAY · ${_mealTypeLabel(targetMealType).toUpperCase()}'),
      findsOneWidget,
    );
    await _tapConfirmButton(tester);

    expect(result?.inventoryAmount, 120);
    expect(result?.mealType, targetMealType);
    expect(result?.calorieAmount, isNull);
    expect(
      DateUtils.dateOnly(result!.loggedAt),
      DateUtils.dateOnly(DateTime.now()),
    );
    expect(find.byKey(EatAmountRuler.fieldKey), findsNothing);
  });

  testWidgets('uses the preselected time and meal', (tester) async {
    InventoryItemEatRequest? result;
    final initialLoggedAt = DateTime(2026, 4, 27, 13, 45);
    await _pumpSheet(
      tester,
      _amountItem(),
      initialLoggedAt: initialLoggedAt,
      initialMealType: MealType.lunch,
      onResult: (value) => result = value,
    );

    await _tapConfirmButton(tester);

    expect(result?.mealType, MealType.lunch);
    expect(result?.loggedAt, initialLoggedAt);
  });

  testWidgets('another day from the when menu is logged', (tester) async {
    InventoryItemEatRequest? result;
    final targetDate = _targetLoggedAtDate();
    await _pumpSheet(
      tester,
      _amountItem(),
      onResult: (value) => result = value,
    );

    await _pickLoggedAtDate(tester, targetDate);
    expect(find.textContaining('TODAY'), findsNothing);
    await _tapConfirmButton(tester);

    expect(
      DateUtils.dateOnly(result!.loggedAt),
      DateUtils.dateOnly(targetDate),
    );
  });

  testWidgets('an amount above the stock shows an error and stays open', (
    tester,
  ) async {
    InventoryItemEatRequest? result;
    await _pumpSheet(
      tester,
      _amountItem(),
      onResult: (value) => result = value,
    );

    await _enterAmount(tester, '1001');
    await _tapConfirmButton(tester);

    expect(result, isNull);
    expect(find.text('Please enter valid numbers.'), findsOneWidget);
    expect(find.byKey(_confirmKey), findsOneWidget);
  });

  testWidgets('the all mark and the product serving set the amount', (
    tester,
  ) async {
    await _pumpSheet(tester, _amountItemWithServing());

    await _tapText(tester, '125 g');
    expect(_amountText(tester), '125');

    await _tapText(tester, 'All');
    expect(_amountText(tester), '500');
  });

  testWidgets('dragging the ruler snaps to its step', (tester) async {
    await _pumpSheet(tester, _amountItem());

    final slider = find.byKey(EatRuler.sliderKey);
    await tester.ensureVisible(slider);
    await tester.tapAt(tester.getCenter(slider));
    await tester.pump();

    final amount = int.parse(_amountText(tester)!);
    expect(amount % 25, 0);
    expect(amount, inInclusiveRange(400, 600));
  });

  testWidgets('a remembered portion becomes a mark and names the entry', (
    tester,
  ) async {
    InventoryItemEatRequest? result;
    final repository = _FakeGlobalFoodServingSuggestionRepository();
    await _pumpSheet(
      tester,
      _slicedCheeseItem().copyWith(globalFoodItemId: 'off-sliced-cheese'),
      servingSuggestionRepository: repository,
      onResult: (value) => result = value,
    );

    await _enterAmount(tester, '30');
    await _tapKey(tester, EatRememberPortion.linkKey);
    expect(find.text('Name for 30 g'), findsOneWidget);
    await tester.enterText(
      find.byKey(EatRememberPortion.nameFieldKey),
      'Scheibe',
    );
    await _tapKey(tester, EatRememberPortion.saveKey);

    expect(find.text('Scheibe 30'), findsOneWidget);
    expect(find.text('= 1 × Scheibe'), findsOneWidget);

    await _enterAmount(tester, '90');
    expect(find.text('= 3 × Scheibe'), findsOneWidget);
    await _tapConfirmButton(tester);

    expect(repository.calls, isEmpty);
    expect(result?.inventoryAmount, 90);
    expect(result?.calorieAmount, isNull);
    expect(result?.portionBaseAmount, 30);
    expect(result?.portionBaseUnit, ConsumedUnit.grams);
    expect(result?.portionCount, 3);
    expect(result?.portionLabel, 'Scheibe');
  });

  testWidgets('a remembered portion is not saved when the page is closed', (
    tester,
  ) async {
    final repository = _FakeGlobalFoodServingSuggestionRepository();
    await _pumpSheet(
      tester,
      _slicedCheeseItem().copyWith(globalFoodItemId: 'off-sliced-cheese'),
      servingSuggestionRepository: repository,
    );

    await _enterAmount(tester, '30');
    await _tapKey(tester, EatRememberPortion.linkKey);
    await tester.enterText(
      find.byKey(EatRememberPortion.nameFieldKey),
      'Scheibe',
    );
    await _tapKey(tester, EatRememberPortion.saveKey);
    await tester.tap(
      find.byKey(const Key('inventory_item_amount_dialog_cancel_button')),
    );
    await tester.pumpAndSettle();

    expect(repository.calls, isEmpty);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('pieces without a weight ask for the weight of one piece', (
    tester,
  ) async {
    InventoryItemEatRequest? result;
    await _pumpSheet(tester, _pieceItem(), onResult: (value) => result = value);

    expect(find.text('1 Piece ='), findsOneWidget);
    expect(find.byKey(EatRememberPortion.linkKey), findsNothing);
    await _tapConfirmButton(tester);

    expect(result, isNull);
    expect(
      find.text('Please enter a number greater than zero.'),
      findsOneWidget,
    );

    await _enterAmount(tester, '2');
    await tester.enterText(find.byKey(_pieceWeightKey), '80');
    await tester.pump();
    expect(find.text('= 160 g'), findsOneWidget);
    await _tapConfirmButton(tester);

    expect(result?.inventoryAmount, 2);
    expect(result?.calorieAmount, 160);
    expect(result?.calorieUnit, ConsumedUnit.grams);
    expect(result?.portionBaseAmount, 80);
    expect(result?.portionCount, 2);
  });

  testWidgets('piece sizes are chips and a new size is remembered', (
    tester,
  ) async {
    InventoryItemEatRequest? result;
    final repository = _FakeGlobalFoodServingSuggestionRepository()
      ..nextResult = GlobalFoodServingSuggestionSet(
        globalSuggestions: [
          for (final (amount, label) in [(53.0, 'S'), (58.0, 'M')])
            GlobalFoodServingSuggestion(
              id: 'egg_$label',
              itemKey: 'fingerprint_egg',
              amount: amount,
              unit: ConsumedUnit.grams,
              label: label,
              selectionCount: 1,
              uniqueUserCount: 1,
              createdAt: DateTime.parse('2026-04-10T10:00:00.000Z'),
              updatedAt: DateTime.parse('2026-04-10T10:00:00.000Z'),
            ),
        ],
      );
    await _pumpSheet(
      tester,
      _pieceItem(),
      servingSuggestionRepository: repository,
      onResult: (value) => result = value,
    );

    await _tapText(tester, 'M 58 g');
    expect(
      tester.widget<TextField>(find.byKey(_pieceWeightKey)).controller?.text,
      '58',
    );
    expect(find.byKey(EatRememberPortion.linkKey), findsNothing);

    await tester.enterText(find.byKey(_pieceWeightKey), '68');
    await tester.pump();
    await _tapKey(tester, EatRememberPortion.linkKey);
    expect(find.text('Name for 68 g'), findsOneWidget);
    await tester.enterText(find.byKey(EatRememberPortion.nameFieldKey), 'L');
    await _tapKey(tester, EatRememberPortion.saveKey);

    expect(find.text('L 68 g'), findsOneWidget);
    expect(find.byKey(EatRememberPortion.linkKey), findsNothing);

    await _enterAmount(tester, '2');
    await _tapConfirmButton(tester);

    expect(repository.calls, isEmpty);
    expect(result?.inventoryAmount, 2);
    expect(result?.calorieAmount, 136);
    expect(result?.portionBaseAmount, 68);
    expect(result?.portionLabel, 'L');
  });

  testWidgets('the piece weight unit switches to milliliters', (tester) async {
    InventoryItemEatRequest? result;
    await _pumpSheet(tester, _pieceItem(), onResult: (value) => result = value);

    await tester.enterText(find.byKey(_pieceWeightKey), '200');
    await tester.tap(
      find.byKey(const Key('inventory_item_portion_unit_button')),
    );
    await tester.pump();
    await _tapConfirmButton(tester);

    expect(result?.calorieAmount, 200);
    expect(result?.calorieUnit, ConsumedUnit.milliliters);
  });

  testWidgets('fractional pieces keep the scaled stock amount', (tester) async {
    InventoryItemEatRequest? result;
    await _pumpSheet(
      tester,
      _fractionalPieceAmountItem(),
      onResult: (value) => result = value,
    );

    expect(_amountText(tester), '1');
    await _enterAmount(tester, '1,5');
    await tester.enterText(find.byKey(_pieceWeightKey), '150');
    await tester.pump();
    await _tapConfirmButton(tester);

    expect(result?.inventoryAmount, 1500);
    expect(result?.calorieAmount, 225);
    expect(result?.calorieUnit, ConsumedUnit.grams);
    expect(result?.portionBaseAmount, 150);
    expect(result?.portionCount, 1.5);
  });

  testWidgets('the product serving fills in the piece weight', (tester) async {
    await _pumpSheet(tester, _pieceItemWithServingSuggestion());

    expect(_amountText(tester), '1');
    expect(
      tester.widget<TextField>(find.byKey(_pieceWeightKey)).controller?.text,
      '75',
    );
  });

  testWidgets('a learned piece weight wins over the product serving', (
    tester,
  ) async {
    final repository = _FakeGlobalFoodServingSuggestionRepository()
      ..nextResult = const GlobalFoodServingSuggestionSet(
        personalSuggestion: ServingSizeSuggestion(
          amount: 35,
          unit: ConsumedUnit.grams,
        ),
      );
    await _pumpSheet(
      tester,
      _pieceItemWithServingSuggestion().copyWith(globalFoodItemId: 'off-wrap'),
      servingSuggestionRepository: repository,
    );

    expect(
      tester.widget<TextField>(find.byKey(_pieceWeightKey)).controller?.text,
      '35',
    );
  });

  testWidgets('a learned amount is prefilled and marked on the ruler', (
    tester,
  ) async {
    final repository = _FakeGlobalFoodServingSuggestionRepository()
      ..nextResult = const GlobalFoodServingSuggestionSet(
        personalSuggestion: ServingSizeSuggestion(
          amount: 135,
          unit: ConsumedUnit.grams,
        ),
      );
    await _pumpSheet(
      tester,
      _amountItem().copyWith(globalFoodItemId: 'off-milk'),
      servingSuggestionRepository: repository,
    );

    expect(_amountText(tester), '135');
    expect(find.text('135 g'), findsWidgets);
  });

  testWidgets('the inedible part keeps the stock and lowers the calories', (
    tester,
  ) async {
    InventoryItemEatRequest? result;
    await _pumpSheet(
      tester,
      _amountItem(),
      onResult: (value) => result = value,
    );

    await _enterAmount(tester, '120');
    await _tapKey(tester, EatInedibleLine.toggleKey);
    await tester.enterText(find.byKey(EatInedibleLine.fieldKey), '20');
    await _tapConfirmButton(tester);

    expect(result?.inventoryAmount, 120);
    expect(result?.calorieAmount, 100);
    expect(result?.calorieUnit, ConsumedUnit.grams);
  });

  testWidgets('an inedible part as large as the amount shows an error', (
    tester,
  ) async {
    InventoryItemEatRequest? result;
    await _pumpSheet(
      tester,
      _amountItem(),
      onResult: (value) => result = value,
    );

    await _enterAmount(tester, '120');
    await _tapKey(tester, EatInedibleLine.toggleKey);
    await tester.enterText(find.byKey(EatInedibleLine.fieldKey), '120');
    await _tapConfirmButton(tester);

    expect(result, isNull);
    expect(
      find.text('The deducted amount must be smaller than the eaten amount.'),
      findsOneWidget,
    );
  });
}
