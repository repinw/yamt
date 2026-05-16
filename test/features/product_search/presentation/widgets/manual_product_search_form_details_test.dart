import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_form/manual_product_preview.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_form/manual_product_search_input.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_form_details.dart';
import 'package:yamt/l10n/app_localizations.dart';

Widget _wrapDetailsForm({
  required ScrollController scrollController,
  required bool showDetails,
  required VoidCallback? onScanNutritionLabel,
  String nameText = 'Banane',
  String brandText = 'Ja!',
  String weightAmount = '200',
  InventoryAmountUnit selectedWeightUnit = InventoryAmountUnit.gram,
  String kcalText = '89',
  String saturatedFatText = '0.1',
  String polyunsaturatedFatText = '',
  bool showPolyunsaturatedFatField = false,
  String fatText = '0.2',
  String carbsText = '20',
  String sugarText = '18',
  String fiberText = '',
  bool showFiberField = false,
  String proteinText = '1',
  String saltText = '0',
  bool canAddOptionalNutrition = false,
  bool isAddingOptionalNutrition = false,
  String optionalNutritionValueText = '',
  InventoryAmountUnit optionalNutritionUnit = InventoryAmountUnit.gram,
  InventoryReceiptOptionalNutritionType? optionalNutritionType,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 360,
          height: 220,
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ManualProductDetailsForm(
                searchResults: const [],
                recentItems: <InventoryItem>[_recentItem()],
                showDetails: showDetails,
                preview: showDetails
                    ? const InventoryReceiptManualProductPreviewData(
                        imageUrl: null,
                        name: 'Banane',
                        brand: 'Ja!',
                        weight: '200 g',
                      )
                    : null,
                nameText: nameText,
                brandText: brandText,
                weightAmount: weightAmount,
                selectedWeightUnit: selectedWeightUnit,
                kcalText: kcalText,
                saturatedFatText: saturatedFatText,
                polyunsaturatedFatText: polyunsaturatedFatText,
                showPolyunsaturatedFatField: showPolyunsaturatedFatField,
                fatText: fatText,
                carbsText: carbsText,
                sugarText: sugarText,
                fiberText: fiberText,
                showFiberField: showFiberField,
                proteinText: proteinText,
                saltText: saltText,
                canAddOptionalNutrition: canAddOptionalNutrition,
                isAddingOptionalNutrition: isAddingOptionalNutrition,
                optionalNutritionValueText: optionalNutritionValueText,
                optionalNutritionUnit: optionalNutritionUnit,
                optionalNutritionType: optionalNutritionType,
                availableOptionalNutritionTypes:
                    const <InventoryReceiptOptionalNutritionType>[
                      InventoryReceiptOptionalNutritionType.polyunsaturatedFat,
                      InventoryReceiptOptionalNutritionType.fiber,
                    ],
                errorText: null,
                showActionSelector: false,
                selectedAction:
                    InventoryReceiptManualProductAction.addToInventory,
                canSave: true,
                isRunningNutritionOcr: false,
                onSearchResultSelected: (_) {},
                onSearchResultStoreSelected: null,
                onSearchResultEatSelected: null,
                onRecentItemSelected: (_) {},
                onNameChanged: (_) {},
                onBrandChanged: (_) {},
                onWeightAmountChanged: (_) {},
                onWeightUnitChanged: (_) {},
                onScanNutritionLabel: onScanNutritionLabel,
                onKcalChanged: (_) {},
                onFatChanged: (_) {},
                onSaturatedFatChanged: (_) {},
                onCarbsChanged: (_) {},
                onSugarChanged: (_) {},
                onProteinChanged: (_) {},
                onSaltChanged: (_) {},
                onPolyunsaturatedFatChanged: (_) {},
                onFiberChanged: (_) {},
                onStartAddingOptionalNutrition: () {},
                onOptionalNutritionValueChanged: (_) {},
                onOptionalNutritionUnitChanged: (_) {},
                onOptionalNutritionTypeChanged: (_) {},
                onApplyOptionalNutrition: () {},
                onCancelOptionalNutrition: () {},
                onCancel: () {},
                onSave: () {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

InventoryItem _recentItem() {
  return InventoryItem.create(
    id: 'recent-1',
    name: 'Banane',
    brand: 'Ja!',
    entryDate: DateTime.parse('2026-04-19T12:00:00Z'),
    storeName: 'Rewe',
    quantity: 1,
  );
}

Future<void> _settleScrollAnimation(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 240));
}

Set<String> _registeredFieldNames(WidgetTester tester) {
  final state = tester.state<FormBuilderState>(find.byType(FormBuilder));
  return state.fields.keys.toSet();
}

Object? _fieldValue(WidgetTester tester, String fieldName) {
  final state = tester.state<FormBuilderState>(find.byType(FormBuilder));
  return state.fields[fieldName]?.value;
}

void main() {
  testWidgets('registered field names match the full details form', (
    tester,
  ) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      _wrapDetailsForm(
        scrollController: scrollController,
        showDetails: true,
        onScanNutritionLabel: null,
        showPolyunsaturatedFatField: true,
        showFiberField: true,
        isAddingOptionalNutrition: true,
        optionalNutritionType:
            InventoryReceiptOptionalNutritionType.polyunsaturatedFat,
      ),
    );

    expect(
      _registeredFieldNames(tester),
      ManualProductSearchFormFieldName.registeredNames.toSet(),
    );
  });

  testWidgets('patches every registered field from updated props', (
    tester,
  ) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      _wrapDetailsForm(
        scrollController: scrollController,
        showDetails: true,
        onScanNutritionLabel: null,
        showPolyunsaturatedFatField: true,
        showFiberField: true,
        isAddingOptionalNutrition: true,
        optionalNutritionType:
            InventoryReceiptOptionalNutritionType.polyunsaturatedFat,
      ),
    );

    await tester.pumpWidget(
      _wrapDetailsForm(
        scrollController: scrollController,
        showDetails: true,
        onScanNutritionLabel: null,
        nameText: 'Apfel',
        brandText: 'Biohof',
        weightAmount: '250',
        selectedWeightUnit: InventoryAmountUnit.milliliter,
        kcalText: '52',
        saturatedFatText: '0.0',
        polyunsaturatedFatText: '0.2',
        showPolyunsaturatedFatField: true,
        fatText: '0.4',
        carbsText: '14',
        sugarText: '10',
        fiberText: '2.4',
        showFiberField: true,
        proteinText: '0.3',
        saltText: '0.01',
        isAddingOptionalNutrition: true,
        optionalNutritionValueText: '2.4',
        optionalNutritionUnit: InventoryAmountUnit.milliliter,
        optionalNutritionType: InventoryReceiptOptionalNutritionType.fiber,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(_fieldValue(tester, ManualProductSearchFormFieldName.name), 'Apfel');
    expect(
      _fieldValue(tester, ManualProductSearchFormFieldName.brand),
      'Biohof',
    );
    expect(
      _fieldValue(tester, ManualProductSearchFormFieldName.weightAmount),
      '250',
    );
    expect(
      _fieldValue(tester, ManualProductSearchFormFieldName.weightUnit),
      InventoryAmountUnit.milliliter,
    );
    expect(_fieldValue(tester, ManualProductSearchFormFieldName.kcal), '52');
    expect(_fieldValue(tester, ManualProductSearchFormFieldName.fat), '0.4');
    expect(
      _fieldValue(tester, ManualProductSearchFormFieldName.saturatedFat),
      '0.0',
    );
    expect(_fieldValue(tester, ManualProductSearchFormFieldName.carbs), '14');
    expect(_fieldValue(tester, ManualProductSearchFormFieldName.sugar), '10');
    expect(
      _fieldValue(tester, ManualProductSearchFormFieldName.protein),
      '0.3',
    );
    expect(_fieldValue(tester, ManualProductSearchFormFieldName.salt), '0.01');
    expect(
      _fieldValue(tester, ManualProductSearchFormFieldName.polyunsaturatedFat),
      '0.2',
    );
    expect(
      _fieldValue(tester, ManualProductSearchFormFieldName.fiber),
      '2.4',
    );
    expect(
      _fieldValue(
        tester,
        ManualProductSearchFormFieldName.optionalNutritionValue,
      ),
      '2.4',
    );
    expect(
      _fieldValue(
        tester,
        ManualProductSearchFormFieldName.optionalNutritionUnit,
      ),
      InventoryAmountUnit.milliliter,
    );
    expect(
      _fieldValue(
        tester,
        ManualProductSearchFormFieldName.optionalNutritionType,
      ),
      InventoryReceiptOptionalNutritionType.fiber,
    );
  });

  testWidgets('scrolls when details become visible', (tester) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      _wrapDetailsForm(
        scrollController: scrollController,
        showDetails: false,
        onScanNutritionLabel: null,
      ),
    );

    expect(scrollController.offset, 0);

    await tester.pumpWidget(
      _wrapDetailsForm(
        scrollController: scrollController,
        showDetails: true,
        onScanNutritionLabel: null,
      ),
    );
    await _settleScrollAnimation(tester);

    expect(scrollController.offset, greaterThan(0));
  });

  testWidgets('scrolls when nutrition OCR button becomes enabled', (
    tester,
  ) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      _wrapDetailsForm(
        scrollController: scrollController,
        showDetails: true,
        onScanNutritionLabel: null,
      ),
    );

    expect(scrollController.offset, 0);

    await tester.pumpWidget(
      _wrapDetailsForm(
        scrollController: scrollController,
        showDetails: true,
        onScanNutritionLabel: () {},
      ),
    );
    await _settleScrollAnimation(tester);

    expect(scrollController.offset, greaterThan(0));
  });

  testWidgets('does not scroll when unrelated details props change', (
    tester,
  ) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      _wrapDetailsForm(
        scrollController: scrollController,
        showDetails: true,
        onScanNutritionLabel: null,
      ),
    );

    expect(scrollController.offset, 0);

    await tester.pumpWidget(
      _wrapDetailsForm(
        scrollController: scrollController,
        showDetails: true,
        onScanNutritionLabel: null,
        nameText: 'Banane Bio',
      ),
    );
    await _settleScrollAnimation(tester);

    expect(scrollController.offset, 0);
  });

  testWidgets('stays crash-free when widget unmounts after scroll trigger', (
    tester,
  ) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      _wrapDetailsForm(
        scrollController: scrollController,
        showDetails: false,
        onScanNutritionLabel: null,
      ),
    );

    await tester.pumpWidget(
      _wrapDetailsForm(
        scrollController: scrollController,
        showDetails: true,
        onScanNutritionLabel: () {},
      ),
    );
    await tester.pump();

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
