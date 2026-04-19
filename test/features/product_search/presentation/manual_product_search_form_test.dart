import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_form.dart';
import 'package:yamt/features/product_search/provider/'
    'manual_product_search_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

Widget _wrapForm({
  required WidgetBuilder builder,
  Listenable? listenable,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: listenable == null
          ? Builder(builder: builder)
          : AnimatedBuilder(
              animation: listenable,
              builder: (context, child) => builder(context),
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

OffProductSearchResult _searchResult() {
  return const OffProductSearchResult(
    code: '4006381333931',
    name: 'Wurst',
    brand: 'Metzger',
    packageWeight: '200 g',
    score: 99,
    nutrition: GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 210,
      per100Fat: 17,
      per100SaturatedFat: 6,
      per100Carbs: 1,
      per100Sugar: 1,
      per100Protein: 15,
      per100Salt: 1.8,
    ),
  );
}

InventoryReceiptManualProductForm _buildForm({
  required TextEditingController searchController,
  required TextEditingController nameController,
  required TextEditingController brandController,
  required TextEditingController weightAmountController,
  required TextEditingController kcalController,
  required TextEditingController saturatedFatController,
  required TextEditingController polyunsaturatedFatController,
  required TextEditingController fatController,
  required TextEditingController carbsController,
  required TextEditingController sugarController,
  required TextEditingController fiberController,
  required TextEditingController proteinController,
  required TextEditingController saltController,
  required TextEditingController optionalNutritionValueController,
  List<OffProductSearchResult> searchResults = const <OffProductSearchResult>[],
  List<InventoryItem> recentItems = const <InventoryItem>[],
  bool canSave = true,
  bool showDetails = true,
  bool canAddOptionalNutrition = false,
  bool isAddingOptionalNutrition = false,
  InventoryReceiptOptionalNutritionType? optionalNutritionType,
  VoidCallback? onSave,
  VoidCallback? onCancel,
  ValueChanged<OffProductSearchResult>? onSearchResultSelected,
  ValueChanged<OffProductSearchResult>? onSearchResultStoreSelected,
  ValueChanged<OffProductSearchResult>? onSearchResultEatSelected,
  ValueChanged<InventoryAmountUnit>? onWeightUnitChanged,
  VoidCallback? onApplyOptionalNutrition,
}) {
  return InventoryReceiptManualProductForm(
    title: 'Produktsuche',
    searchController: searchController,
    nameController: nameController,
    brandController: brandController,
    isSearching: false,
    canSave: canSave,
    isRunningNutritionOcr: false,
    showDetails: showDetails,
    searchResults: searchResults,
    recentItems: recentItems,
    weightAmountController: weightAmountController,
    selectedWeightUnit: InventoryAmountUnit.gram,
    kcalController: kcalController,
    saturatedFatController: saturatedFatController,
    polyunsaturatedFatController: polyunsaturatedFatController,
    showPolyunsaturatedFatField: false,
    fatController: fatController,
    carbsController: carbsController,
    sugarController: sugarController,
    fiberController: fiberController,
    showFiberField: false,
    proteinController: proteinController,
    saltController: saltController,
    canAddOptionalNutrition: canAddOptionalNutrition,
    isAddingOptionalNutrition: isAddingOptionalNutrition,
    optionalNutritionValueController: optionalNutritionValueController,
    optionalNutritionUnit: InventoryAmountUnit.gram,
    optionalNutritionType: optionalNutritionType,
    availableOptionalNutritionTypes:
        const <InventoryReceiptOptionalNutritionType>[
          InventoryReceiptOptionalNutritionType.polyunsaturatedFat,
          InventoryReceiptOptionalNutritionType.fiber,
        ],
    preview: const InventoryReceiptManualProductPreviewData(
      imageUrl: null,
      name: 'Banane',
      brand: 'Ja!',
      weight: '200 g',
    ),
    errorText: null,
    showActionSelector: false,
    selectedAction: InventoryReceiptManualProductAction.addToInventory,
    onSearchResultSelected: onSearchResultSelected ?? (_) {},
    onRecentItemSelected: (_) {},
    onScanBarcode: () {},
    onWeightUnitChanged: onWeightUnitChanged ?? (_) {},
    onScanNutritionLabel: () {},
    onStartAddingOptionalNutrition: () {},
    onOptionalNutritionUnitChanged: (_) {},
    onOptionalNutritionTypeChanged: (_) {},
    onApplyOptionalNutrition: onApplyOptionalNutrition ?? () {},
    onCancelOptionalNutrition: () {},
    onCancel: onCancel ?? () {},
    onSave: onSave ?? () {},
    onSearchResultStoreSelected: onSearchResultStoreSelected,
    onSearchResultEatSelected: onSearchResultEatSelected,
  );
}

Finder _editableTextWithin(Key key) {
  return find.descendant(
    of: find.byKey(key),
    matching: find.byType(EditableText),
  );
}

void main() {
  testWidgets('details form keeps button wiring and weight unit callback', (
    tester,
  ) async {
    final searchController = TextEditingController(text: 'Banane');
    final nameController = TextEditingController(text: 'Banane');
    final brandController = TextEditingController(text: 'Ja!');
    final weightAmountController = TextEditingController(text: '200');
    final kcalController = TextEditingController(text: '89');
    final saturatedFatController = TextEditingController(text: '0.1');
    final polyunsaturatedFatController = TextEditingController();
    final fatController = TextEditingController(text: '0.2');
    final carbsController = TextEditingController(text: '20');
    final sugarController = TextEditingController(text: '18');
    final fiberController = TextEditingController();
    final proteinController = TextEditingController(text: '1');
    final saltController = TextEditingController(text: '0');
    final optionalNutritionValueController = TextEditingController();

    var didSave = false;
    var didCancel = false;
    InventoryAmountUnit? changedUnit;

    addTearDown(() {
      searchController.dispose();
      nameController.dispose();
      brandController.dispose();
      weightAmountController.dispose();
      kcalController.dispose();
      saturatedFatController.dispose();
      polyunsaturatedFatController.dispose();
      fatController.dispose();
      carbsController.dispose();
      sugarController.dispose();
      fiberController.dispose();
      proteinController.dispose();
      saltController.dispose();
      optionalNutritionValueController.dispose();
    });

    final listenable = Listenable.merge(<Listenable>[
      searchController,
      nameController,
      brandController,
      weightAmountController,
      kcalController,
      saturatedFatController,
      polyunsaturatedFatController,
      fatController,
      carbsController,
      sugarController,
      fiberController,
      proteinController,
      saltController,
      optionalNutritionValueController,
    ]);

    await tester.pumpWidget(
      _wrapForm(
        listenable: listenable,
        builder: (_) => _buildForm(
          searchController: searchController,
          nameController: nameController,
          brandController: brandController,
          weightAmountController: weightAmountController,
          kcalController: kcalController,
          saturatedFatController: saturatedFatController,
          polyunsaturatedFatController: polyunsaturatedFatController,
          fatController: fatController,
          carbsController: carbsController,
          sugarController: sugarController,
          fiberController: fiberController,
          proteinController: proteinController,
          saltController: saltController,
          optionalNutritionValueController: optionalNutritionValueController,
          recentItems: <InventoryItem>[_recentItem()],
          onSave: () => didSave = true,
          onCancel: () => didCancel = true,
          onWeightUnitChanged: (value) => changedUnit = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('receipt_review_manual_preview')), findsOne);
    expect(find.text('Banane'), findsWidgets);
    expect(find.text('200 g'), findsWidgets);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(InventoryReceiptManualProductForm)),
    )!;

    await tester.tap(
      find.byKey(const Key('receipt_review_manual_weight_unit_field')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ml').last);
    await tester.pumpAndSettle();

    expect(changedUnit, InventoryAmountUnit.milliliter);

    await tester.ensureVisible(
      find.byKey(const Key('receipt_review_manual_save_button')),
    );
    await tester.tap(
      find.byKey(const Key('receipt_review_manual_save_button')),
    );
    await tester.pump();
    expect(didSave, isTrue);

    final cancelButtonFinder = find.widgetWithText(
      OutlinedButton,
      l10n.inventoryReceiptReviewCancelAction,
    );
    await tester.ensureVisible(cancelButtonFinder);
    await tester.tap(cancelButtonFinder);
    await tester.pump();
    expect(didCancel, isTrue);
  });

  testWidgets('search results keep select, inventory, and eat actions', (
    tester,
  ) async {
    final searchController = TextEditingController(text: 'Wurst');
    final nameController = TextEditingController();
    final brandController = TextEditingController();
    final weightAmountController = TextEditingController();
    final kcalController = TextEditingController();
    final saturatedFatController = TextEditingController();
    final polyunsaturatedFatController = TextEditingController();
    final fatController = TextEditingController();
    final carbsController = TextEditingController();
    final sugarController = TextEditingController();
    final fiberController = TextEditingController();
    final proteinController = TextEditingController();
    final saltController = TextEditingController();
    final optionalNutritionValueController = TextEditingController();
    final result = _searchResult();

    OffProductSearchResult? selectedResult;
    OffProductSearchResult? storeResult;
    OffProductSearchResult? eatResult;

    addTearDown(() {
      searchController.dispose();
      nameController.dispose();
      brandController.dispose();
      weightAmountController.dispose();
      kcalController.dispose();
      saturatedFatController.dispose();
      polyunsaturatedFatController.dispose();
      fatController.dispose();
      carbsController.dispose();
      sugarController.dispose();
      fiberController.dispose();
      proteinController.dispose();
      saltController.dispose();
      optionalNutritionValueController.dispose();
    });

    final listenable = Listenable.merge(<Listenable>[
      searchController,
      nameController,
      brandController,
      weightAmountController,
      kcalController,
      saturatedFatController,
      polyunsaturatedFatController,
      fatController,
      carbsController,
      sugarController,
      fiberController,
      proteinController,
      saltController,
      optionalNutritionValueController,
    ]);

    await tester.pumpWidget(
      _wrapForm(
        listenable: listenable,
        builder: (_) => _buildForm(
          searchController: searchController,
          nameController: nameController,
          brandController: brandController,
          weightAmountController: weightAmountController,
          kcalController: kcalController,
          saturatedFatController: saturatedFatController,
          polyunsaturatedFatController: polyunsaturatedFatController,
          fatController: fatController,
          carbsController: carbsController,
          sugarController: sugarController,
          fiberController: fiberController,
          proteinController: proteinController,
          saltController: saltController,
          optionalNutritionValueController: optionalNutritionValueController,
          showDetails: false,
          searchResults: <OffProductSearchResult>[result],
          onSearchResultSelected: (value) => selectedResult = value,
          onSearchResultStoreSelected: (value) => storeResult = value,
          onSearchResultEatSelected: (value) => eatResult = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const Key('receipt_review_manual_search_result_4006381333931'),
      ),
    );
    await tester.pump();
    expect(selectedResult?.code, result.code);

    await tester.tap(
      find.byKey(
        const Key(
          'receipt_review_manual_search_result_store_button_4006381333931',
        ),
      ),
    );
    await tester.pump();
    expect(storeResult?.code, result.code);

    await tester.tap(
      find.byKey(
        const Key(
          'receipt_review_manual_search_result_eat_button_4006381333931',
        ),
      ),
    );
    await tester.pump();
    expect(eatResult?.code, result.code);
  });

  testWidgets(
    'optional nutrition composer sanitizes numeric input and enables apply',
    (tester) async {
      final searchController = TextEditingController(text: 'Wurst');
      final nameController = TextEditingController(text: 'Wurst');
      final brandController = TextEditingController(text: 'Metzger');
      final weightAmountController = TextEditingController(text: '200');
      final kcalController = TextEditingController(text: '210');
      final saturatedFatController = TextEditingController(text: '6');
      final polyunsaturatedFatController = TextEditingController();
      final fatController = TextEditingController(text: '17');
      final carbsController = TextEditingController(text: '1');
      final sugarController = TextEditingController(text: '1');
      final fiberController = TextEditingController();
      final proteinController = TextEditingController(text: '15');
      final saltController = TextEditingController(text: '1.8');
      final optionalNutritionValueController = TextEditingController();

      var didApply = false;

      addTearDown(() {
        searchController.dispose();
        nameController.dispose();
        brandController.dispose();
        weightAmountController.dispose();
        kcalController.dispose();
        saturatedFatController.dispose();
        polyunsaturatedFatController.dispose();
        fatController.dispose();
        carbsController.dispose();
        sugarController.dispose();
        fiberController.dispose();
        proteinController.dispose();
        saltController.dispose();
        optionalNutritionValueController.dispose();
      });

      final listenable = Listenable.merge(<Listenable>[
        searchController,
        nameController,
        brandController,
        weightAmountController,
        kcalController,
        saturatedFatController,
        polyunsaturatedFatController,
        fatController,
        carbsController,
        sugarController,
        fiberController,
        proteinController,
        saltController,
        optionalNutritionValueController,
      ]);

      await tester.pumpWidget(
        _wrapForm(
          listenable: listenable,
          builder: (_) => _buildForm(
            searchController: searchController,
            nameController: nameController,
            brandController: brandController,
            weightAmountController: weightAmountController,
            kcalController: kcalController,
            saturatedFatController: saturatedFatController,
            polyunsaturatedFatController: polyunsaturatedFatController,
            fatController: fatController,
            carbsController: carbsController,
            sugarController: sugarController,
            fiberController: fiberController,
            proteinController: proteinController,
            saltController: saltController,
            optionalNutritionValueController: optionalNutritionValueController,
            canAddOptionalNutrition: true,
            isAddingOptionalNutrition: true,
            optionalNutritionType:
                InventoryReceiptOptionalNutritionType.polyunsaturatedFat,
            onApplyOptionalNutrition: () => didApply = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final confirmButtonFinder = find.byKey(
        const Key('receipt_review_manual_optional_nutrition_confirm_button'),
      );
      expect(
        tester.widget<IconButton>(confirmButtonFinder).onPressed,
        isNull,
      );

      await tester.enterText(
        _editableTextWithin(
          const Key('receipt_review_manual_optional_nutrition_value_field'),
        ),
        '4x,5y',
      );
      await tester.pump();

      expect(optionalNutritionValueController.text, '4,5');
      expect(
        tester.widget<IconButton>(confirmButtonFinder).onPressed,
        isNotNull,
      );

      await tester.ensureVisible(confirmButtonFinder);
      await tester.tap(confirmButtonFinder);
      await tester.pump();
      expect(didApply, isTrue);
    },
  );
}
