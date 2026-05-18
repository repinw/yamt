import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_form/manual_product_preview.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_form/manual_product_search_form.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_form/manual_product_search_shell.dart';
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

InventoryReceiptManualProductLauncherContent _buildLauncher({
  required TextEditingController searchController,
}) {
  return InventoryReceiptManualProductLauncherContent(
    title: 'Produktsuche',
    searchController: searchController,
    recentItems: <InventoryItem>[_recentItem()],
    onClose: () {},
    onAiSearchTap: () {},
    onSearchTap: () {},
    onVoiceSearchTap: () {},
    onRecentItemSelected: (_) {},
    onScanBarcode: () {},
  );
}

InventoryReceiptManualProductForm _buildForm({
  required TextEditingController searchController,
  String nameText = '',
  String brandText = '',
  String weightAmount = '',
  String kcalText = '',
  String saturatedFatText = '',
  String polyunsaturatedFatText = '',
  String fatText = '',
  String carbsText = '',
  String sugarText = '',
  String fiberText = '',
  String proteinText = '',
  String saltText = '',
  String optionalNutritionValueText = '',
  List<OffProductSearchResult> searchResults = const <OffProductSearchResult>[],
  List<InventoryItem> recentItems = const <InventoryItem>[],
  bool canSave = true,
  bool showDetails = true,
  bool canCreateManualDraft = false,
  bool canAddOptionalNutrition = false,
  bool isAddingOptionalNutrition = false,
  InventoryReceiptOptionalNutritionType? optionalNutritionType,
  VoidCallback? onSave,
  VoidCallback? onCreateManualDraft,
  VoidCallback? onCancel,
  ValueChanged<OffProductSearchResult>? onSearchResultSelected,
  ValueChanged<OffProductSearchResult>? onSearchResultStoreSelected,
  ValueChanged<OffProductSearchResult>? onSearchResultEatSelected,
  ValueChanged<String>? onNameChanged,
  ValueChanged<String>? onBrandChanged,
  ValueChanged<String>? onWeightAmountChanged,
  ValueChanged<InventoryAmountUnit>? onWeightUnitChanged,
  ValueChanged<String>? onKcalChanged,
  ValueChanged<String>? onFatChanged,
  ValueChanged<String>? onSaturatedFatChanged,
  ValueChanged<String>? onCarbsChanged,
  ValueChanged<String>? onSugarChanged,
  ValueChanged<String>? onProteinChanged,
  ValueChanged<String>? onSaltChanged,
  ValueChanged<String>? onPolyunsaturatedFatChanged,
  ValueChanged<String>? onFiberChanged,
  ValueChanged<String>? onOptionalNutritionValueChanged,
  VoidCallback? onApplyOptionalNutrition,
}) {
  return InventoryReceiptManualProductForm(
    title: 'Produktsuche',
    searchController: searchController,
    isSearching: false,
    canSave: canSave,
    isRunningNutritionOcr: false,
    showDetails: showDetails,
    searchResults: searchResults,
    recentItems: recentItems,
    nameText: nameText,
    brandText: brandText,
    weightAmount: weightAmount,
    selectedWeightUnit: InventoryAmountUnit.gram,
    kcalText: kcalText,
    saturatedFatText: saturatedFatText,
    polyunsaturatedFatText: polyunsaturatedFatText,
    showPolyunsaturatedFatField: false,
    fatText: fatText,
    carbsText: carbsText,
    sugarText: sugarText,
    fiberText: fiberText,
    showFiberField: false,
    proteinText: proteinText,
    saltText: saltText,
    canAddOptionalNutrition: canAddOptionalNutrition,
    isAddingOptionalNutrition: isAddingOptionalNutrition,
    optionalNutritionValueText: optionalNutritionValueText,
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
    onAiSearchTap: () {},
    canCreateManualDraft: canCreateManualDraft,
    onCreateManualDraft: onCreateManualDraft ?? () {},
    showActionSelector: false,
    selectedAction: InventoryReceiptManualProductAction.addToInventory,
    onSearchResultSelected: onSearchResultSelected ?? (_) {},
    onRecentItemSelected: (_) {},
    onScanBarcode: () {},
    onNameChanged: onNameChanged ?? (_) {},
    onBrandChanged: onBrandChanged ?? (_) {},
    onWeightAmountChanged: onWeightAmountChanged ?? (_) {},
    onWeightUnitChanged: onWeightUnitChanged ?? (_) {},
    onKcalChanged: onKcalChanged ?? (_) {},
    onFatChanged: onFatChanged ?? (_) {},
    onSaturatedFatChanged: onSaturatedFatChanged ?? (_) {},
    onCarbsChanged: onCarbsChanged ?? (_) {},
    onSugarChanged: onSugarChanged ?? (_) {},
    onProteinChanged: onProteinChanged ?? (_) {},
    onSaltChanged: onSaltChanged ?? (_) {},
    onPolyunsaturatedFatChanged: onPolyunsaturatedFatChanged ?? (_) {},
    onFiberChanged: onFiberChanged ?? (_) {},
    onScanNutritionLabel: () {},
    onStartAddingOptionalNutrition: () {},
    onOptionalNutritionValueChanged: onOptionalNutritionValueChanged ?? (_) {},
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
  testWidgets('manual search toolbar wires field and quick actions', (
    tester,
  ) async {
    final searchController = TextEditingController(text: 'Banane');
    addTearDown(searchController.dispose);

    var searchTapped = 0;
    var voiceTapped = 0;
    var aiTapped = 0;
    var scanTapped = 0;

    await tester.pumpWidget(
      _wrapForm(
        builder: (_) => ManualProductSearchToolbar(
          searchController: searchController,
          clearButtonKey: const Key('toolbar_clear_button'),
          fieldKey: const Key('toolbar_field'),
          readOnly: true,
          onTap: () => searchTapped += 1,
          onVoiceSearchPressed: () => voiceTapped += 1,
          onAiSearchTap: () => aiTapped += 1,
          onScanBarcode: () => scanTapped += 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('toolbar_field')));
    await tester.tap(
      find.byKey(const Key('receipt_review_manual_voice_search_button')),
    );
    await tester.tap(
      find.byKey(const Key('receipt_review_manual_ai_search_button')),
    );
    await tester.tap(
      find.byKey(const Key('receipt_review_manual_scan_button')),
    );
    await tester.pump();

    expect(searchTapped, 1);
    expect(voiceTapped, 1);
    expect(aiTapped, 1);
    expect(scanTapped, 1);
  });

  testWidgets('launcher shows ai and scan actions below search bar', (
    tester,
  ) async {
    final searchController = TextEditingController(text: 'Banane');
    addTearDown(searchController.dispose);

    await tester.pumpWidget(
      _wrapForm(
        builder: (_) => _buildLauncher(searchController: searchController),
      ),
    );
    await tester.pumpAndSettle();

    final searchFieldTop = tester.getTopLeft(
      find.byKey(const Key('receipt_review_manual_launcher_search_field')),
    );
    final aiButtonTop = tester.getTopLeft(
      find.byKey(const Key('receipt_review_manual_ai_search_button')),
    );
    final scanButtonTop = tester.getTopLeft(
      find.byKey(const Key('receipt_review_manual_scan_button')),
    );

    expect(aiButtonTop.dy, greaterThan(searchFieldTop.dy));
    expect(scanButtonTop.dy, greaterThan(searchFieldTop.dy));

    final aiIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const Key('receipt_review_manual_ai_search_button')),
        matching: find.byType(Icon),
      ),
    );
    expect(aiIcon.icon, Icons.auto_awesome_rounded);
  });

  testWidgets('details form keeps button wiring and weight unit callback', (
    tester,
  ) async {
    final searchController = TextEditingController(text: 'Banane');

    var didSave = false;
    var didCancel = false;
    InventoryAmountUnit? changedUnit;

    addTearDown(searchController.dispose);

    await tester.pumpWidget(
      _wrapForm(
        builder: (_) => _buildForm(
          searchController: searchController,
          nameText: 'Banane',
          brandText: 'Ja!',
          weightAmount: '200',
          kcalText: '89',
          saturatedFatText: '0.1',
          fatText: '0.2',
          carbsText: '20',
          sugarText: '18',
          proteinText: '1',
          saltText: '0',
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

    final weightUnitField = find.byKey(
      const Key('receipt_review_manual_weight_unit_field'),
    );
    await tester.ensureVisible(weightUnitField);
    await tester.tap(weightUnitField);
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
    final result = _searchResult();

    OffProductSearchResult? selectedResult;
    OffProductSearchResult? storeResult;
    OffProductSearchResult? eatResult;

    addTearDown(searchController.dispose);

    await tester.pumpWidget(
      _wrapForm(
        builder: (_) => _buildForm(
          searchController: searchController,
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

  testWidgets('search results can show eat action without inventory action', (
    tester,
  ) async {
    final searchController = TextEditingController(text: 'Wurst');
    final result = _searchResult();
    OffProductSearchResult? eatResult;

    addTearDown(searchController.dispose);

    await tester.pumpWidget(
      _wrapForm(
        builder: (_) => _buildForm(
          searchController: searchController,
          showDetails: false,
          searchResults: <OffProductSearchResult>[result],
          onSearchResultEatSelected: (value) => eatResult = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const Key(
          'receipt_review_manual_search_result_store_button_4006381333931',
        ),
      ),
      findsNothing,
    );
    expect(
      find.byKey(
        const Key(
          'receipt_review_manual_search_result_eat_button_4006381333931',
        ),
      ),
      findsOneWidget,
    );

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

  testWidgets('create manually action is shown and wired', (tester) async {
    final searchController = TextEditingController(text: 'Skyr');
    var createTapped = 0;
    addTearDown(searchController.dispose);

    await tester.pumpWidget(
      _wrapForm(
        builder: (_) => _buildForm(
          searchController: searchController,
          showDetails: false,
          canCreateManualDraft: true,
          onCreateManualDraft: () => createTapped += 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('receipt_review_manual_create_own_button')),
    );
    await tester.pump();

    expect(createTapped, 1);
  });

  testWidgets(
    'optional nutrition composer sanitizes numeric input and enables apply',
    (tester) async {
      final searchController = TextEditingController(text: 'Wurst');
      final optionalNutritionValue = ValueNotifier<String>('');

      var didApply = false;

      addTearDown(() {
        searchController.dispose();
        optionalNutritionValue.dispose();
      });

      await tester.pumpWidget(
        _wrapForm(
          listenable: optionalNutritionValue,
          builder: (_) => _buildForm(
            searchController: searchController,
            nameText: 'Wurst',
            brandText: 'Metzger',
            weightAmount: '200',
            kcalText: '210',
            saturatedFatText: '6',
            fatText: '17',
            carbsText: '1',
            sugarText: '1',
            proteinText: '15',
            saltText: '1.8',
            canAddOptionalNutrition: true,
            isAddingOptionalNutrition: true,
            optionalNutritionValueText: optionalNutritionValue.value,
            optionalNutritionType:
                InventoryReceiptOptionalNutritionType.polyunsaturatedFat,
            onOptionalNutritionValueChanged: (value) {
              optionalNutritionValue.value = value;
            },
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
      await tester.pumpAndSettle();

      expect(optionalNutritionValue.value, '4,5');
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
