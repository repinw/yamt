import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store_provider.dart';
import 'package:yamt/features/inventory/data/prepared_meal_image_picker.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_edit_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../helpers/root_navigator_test_utils.dart';
import '../../../../../support/fake_local_image_store.dart';
import '../../../../../support/fake_prepared_meal_image_picker.dart';
import '../../../../../support/prepared_meal_test_data.dart';

@Dependencies([preparedMealImagePicker])
class _EditSheetHarness extends StatefulWidget {
  const _EditSheetHarness({required this.meal, required this.inventoryItems});

  final PreparedMeal meal;
  final List<InventoryItem> inventoryItems;

  @override
  State<_EditSheetHarness> createState() => _EditSheetHarnessState();
}

class _EditSheetHarnessState extends State<_EditSheetHarness> {
  String? _resultLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextButton(
            onPressed: () async {
              final result = await showPreparedMealEditSheet(
                context: context,
                meal: widget.meal,
                inventoryItems: widget.inventoryItems,
              );
              if (!mounted || result == null) {
                return;
              }
              setState(() {
                _resultLabel =
                    'edited:${result.name}:${result.imageChanged}:'
                    '${result.imageBytes != null}:${result.totalPortions}:'
                    '${result.items.length}:'
                    '${result.items.map((item) => item.usedAmount).join(',')}:'
                    '${result.requestIngredientSelection}';
              });
            },
            child: const Text('Open'),
          ),
          if (_resultLabel != null) Text(_resultLabel!),
        ],
      ),
    );
  }
}

Future<void> _pumpEditSheetHarness(
  WidgetTester tester, {
  required PreparedMeal meal,
  List<InventoryItem>? inventoryItems,
  PreparedMealImagePicker? imagePicker,
  List<Override> overrides = const <Override>[],
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...overrides,
        preparedMealImagePickerProvider.overrideWithValue(
          imagePicker ?? FakePreparedMealImagePicker(),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _EditSheetHarness(
          meal: meal,
          inventoryItems: inventoryItems ?? _inventoryItems(meal),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('edit sheet opens on root navigator by default', (tester) async {
    final rootObserver = RecordingNavigatorObserver();
    final nestedObserver = RecordingNavigatorObserver();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preparedMealImagePickerProvider.overrideWithValue(
            FakePreparedMealImagePicker(),
          ),
        ],
        child: nestedNavigatorHarness(
          rootObserver: rootObserver,
          nestedObserver: nestedObserver,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          child: _EditSheetHarness(
            meal: _meal(),
            inventoryItems: _inventoryItems(_meal()),
          ),
        ),
      ),
    );

    rootObserver.clear();
    nestedObserver.clear();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expectRootPopupRoutePushed(
      rootObserver: rootObserver,
      nestedObserver: nestedObserver,
    );
    expect(find.widgetWithText(TextFormField, 'Meal name'), findsOneWidget);
  });

  testWidgets('returns updated name on happy path submit', (tester) async {
    await _pumpEditSheetHarness(tester, meal: _meal());

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Meal name'),
      'Updated bowl',
    );
    await _tapSave(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('edited:Updated bowl:false:false:2:1:100:false'),
      findsOneWidget,
    );
  });

  testWidgets('allows metadata save for pending-only meal', (tester) async {
    await _pumpEditSheetHarness(
      tester,
      meal: _pendingOnlyMeal(),
      inventoryItems: const <InventoryItem>[],
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Meal name'),
      'Updated pending bowl',
    );
    await _tapSave(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('edited:Updated pending bowl:false:false:2:0::false'),
      findsOneWidget,
    );
  });

  testWidgets('greys content controls for partially consumed meal', (
    tester,
  ) async {
    final meal = _consumedMeal();
    await _pumpEditSheetHarness(tester, meal: meal);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final portionsField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Portions'),
    );
    final amountField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Used amount'),
    );
    final addButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Add ingredient'),
    );
    final removeButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.delete_outline),
    );
    expect(portionsField.enabled, isFalse);
    expect(amountField.enabled, isFalse);
    expect(addButton.onPressed, isNull);
    expect(removeButton.onPressed, isNull);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Meal name'),
      'Consumed bowl',
    );
    await _tapSave(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('edited:Consumed bowl:false:false:3:1:100:false'),
      findsOneWidget,
    );
  });

  testWidgets('shows amount limit for fractional remaining meal', (
    tester,
  ) async {
    final meal = preparedMealTestData(
      imageAssetId: 'asset-meal-1',
      totalPortions: 2,
      remainingPortions: 0.5,
    );
    await _pumpEditSheetHarness(tester, meal: meal);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Available: 900 g'), findsOneWidget);
  });

  testWidgets('can remove image and returns changed state', (tester) async {
    final localImageStore = FakeLocalImageStore();
    await localImageStore.saveBytes(
      imageRef: localImageAssetRef('asset-meal-1'),
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
    );

    await _pumpEditSheetHarness(
      tester,
      meal: _meal(),
      overrides: [localImageStoreProvider.overrideWithValue(localImageStore)],
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remove image'));
    await tester.pumpAndSettle();

    await _tapSave(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('edited:Rice bowl:true:false:2:1:100:false'),
      findsOneWidget,
    );
  });

  testWidgets('can pick replacement image and returns changed bytes', (
    tester,
  ) async {
    await _pumpEditSheetHarness(
      tester,
      meal: _meal(),
      imagePicker: FakePreparedMealImagePicker(
        fileBytes: tinyPreparedMealPngBytes(),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add image'));
    await tester.pumpAndSettle();

    await _tapSave(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('edited:Rice bowl:true:true:2:1:100:false'),
      findsOneWidget,
    );
  });

  testWidgets('can request inventory selection with current draft values', (
    tester,
  ) async {
    final meal = _meal();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preparedMealImagePickerProvider.overrideWithValue(
            FakePreparedMealImagePicker(),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _EditSheetHarness(
            meal: meal,
            inventoryItems: <InventoryItem>[
              ..._inventoryItems(meal),
              _inventoryItem(id: 'beans', name: 'Beans'),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Portions'), '3');
    await tester.tap(find.byTooltip('Remove ingredient'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add ingredient'));
    await tester.pumpAndSettle();

    expect(find.text('edited:Rice bowl:false:false:3:0::true'), findsOneWidget);
  });
}

PreparedMeal _meal() {
  return preparedMealTestData(
    imageAssetId: 'asset-meal-1',
    totalPortions: 2,
  );
}

PreparedMeal _consumedMeal() {
  return preparedMealTestData(
    imageAssetId: 'asset-meal-1',
    remainingPortions: 1.5,
  );
}

PreparedMeal _pendingOnlyMeal() {
  return preparedMealTestData(
    imageAssetId: 'asset-meal-1',
    totalPortions: 2,
  ).copyWith(
    components: const <PreparedMealComponent>[],
    totalKcal: 0,
    totalProtein: 0,
    totalCarbs: 0,
    totalFat: 0,
    pendingRecipeIngredients: const <String>['100 g rice'],
  );
}

List<InventoryItem> _inventoryItems(PreparedMeal meal) {
  return meal.components
      .map((component) => component.sourceItemSnapshot)
      .toList(growable: false);
}

InventoryItem _inventoryItem({required String id, required String name}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialAmount: 180,
    currentAmount: 180,
    amountUnit: InventoryAmountUnit.gram,
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 120,
      per100Protein: 8,
      per100Carbs: 12,
      per100Fat: 2,
    ),
  );
}

Future<void> _tapSave(WidgetTester tester) async {
  final saveButton = find.widgetWithText(FilledButton, 'Save');
  await tester.ensureVisible(saveButton);
  await tester.tap(saveButton);
}
