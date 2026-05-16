import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_form/manual_product_preview.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_form_details.dart';
import 'package:yamt/l10n/app_localizations.dart';

Widget _wrapDetailsForm({
  required ScrollController scrollController,
  required bool showDetails,
  required VoidCallback? onScanNutritionLabel,
  String nameText = 'Banane',
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
                brandText: 'Ja!',
                weightAmount: '200',
                selectedWeightUnit: InventoryAmountUnit.gram,
                kcalText: '89',
                saturatedFatText: '0.1',
                polyunsaturatedFatText: '',
                showPolyunsaturatedFatField: false,
                fatText: '0.2',
                carbsText: '20',
                sugarText: '18',
                fiberText: '',
                showFiberField: false,
                proteinText: '1',
                saltText: '0',
                canAddOptionalNutrition: false,
                isAddingOptionalNutrition: false,
                optionalNutritionValueText: '',
                optionalNutritionUnit: InventoryAmountUnit.gram,
                optionalNutritionType: null,
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

void main() {
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
