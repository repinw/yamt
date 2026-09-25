import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/widgets/text_voice_search_bar/text_voice_search_bar.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_form/manual_product_preview.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_form/manual_product_search_form.dart';
import 'package:yamt/l10n/app_localizations.dart';

Widget _wrapForm({required WidgetBuilder builder, Listenable? listenable}) {
  return MaterialApp(
    localizationsDelegates: appLocalizationsDelegates,
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

InventoryReceiptManualProductForm _buildForm({
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
  bool canSave = true,
  bool canAddOptionalNutrition = false,
  bool isAddingOptionalNutrition = false,
  InventoryReceiptOptionalNutritionType? optionalNutritionType,
  VoidCallback? onSave,
  VoidCallback? onCancel,
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
    canSave: canSave,
    isRunningNutritionOcr: false,
    nameText: nameText,
    brandText: brandText,
    barcodeText: '',
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
    showActionSelector: false,
    selectedAction: InventoryReceiptManualProductAction.addToInventory,
    onScanBarcode: () {},
    onNameChanged: onNameChanged ?? (_) {},
    onBrandChanged: onBrandChanged ?? (_) {},
    onBarcodeChanged: (_) {},
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
  );
}

Finder _editableTextWithin(Key key) {
  return find.descendant(
    of: find.byKey(key),
    matching: find.byType(EditableText),
  );
}

void main() {
  testWidgets('editor form has no search bar and shows the barcode field', (
    tester,
  ) async {
    await tester.pumpWidget(_wrapForm(builder: (_) => _buildForm()));
    await tester.pumpAndSettle();

    expect(find.byType(TextVoiceSearchBar), findsNothing);
    expect(find.text('Product search'), findsNothing);
    expect(
      find.byKey(const Key('receipt_review_manual_name_field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('receipt_review_manual_barcode_field')),
      findsOneWidget,
    );
  });

  testWidgets('details form keeps button wiring and weight unit callback', (
    tester,
  ) async {
    var didSave = false;
    var didCancel = false;
    InventoryAmountUnit? changedUnit;

    await tester.pumpWidget(
      _wrapForm(
        builder: (_) => _buildForm(
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

  testWidgets(
    'optional nutrition composer sanitizes numeric input and enables apply',
    (tester) async {
      final optionalNutritionValue = ValueNotifier<String>('');

      var didApply = false;

      addTearDown(optionalNutritionValue.dispose);

      await tester.pumpWidget(
        _wrapForm(
          listenable: optionalNutritionValue,
          builder: (_) => _buildForm(
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
      expect(tester.widget<IconButton>(confirmButtonFinder).onPressed, isNull);

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
