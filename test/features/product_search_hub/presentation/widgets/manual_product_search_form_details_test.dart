import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/domain/product_photo.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_photo_state.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_state.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'manual_product_form_field.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_form/manual_product_editor_header.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_form/manual_product_nutrition_editor.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_form/manual_product_photo_section.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_form_details.dart';
import 'package:yamt/l10n/app_localizations.dart';

final List<int> _pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8'
  'AAAAASUVORK5CYII=',
);

const _complete = InventoryReceiptManualProductState(
  nameText: 'Haferflocken zart',
  brandText: 'Rewe Bio',
  weightAmount: '500',
  selectedWeightUnit: InventoryAmountUnit.gram,
  kcalText: '372',
  fatText: '7',
  saturatedFatText: '1.3',
  carbsText: '58.7',
  sugarText: '0.7',
  proteinText: '13.5',
  saltText: '0.01',
);

class _Calls {
  final fields = <(ManualProductFormField, String)>[];
  final units = <InventoryAmountUnit>[];
  final noBarcode = <bool>[];
  final optional = <InventoryReceiptOptionalNutritionType>[];
  final actions = <InventoryReceiptManualProductAction>[];
  int scans = 0;
  int frontPhotos = 0;
  int tablePhotos = 0;
  int saves = 0;
}

Widget _editor(
  _Calls calls, {
  InventoryReceiptManualProductState state = _complete,
  ManualProductPhotoState photoState = const ManualProductPhotoState(),
  bool canSave = true,
  bool showActionSelector = false,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ManualProductDetailsForm(
      state: state,
      imageUrl: null,
      photoState: photoState,
      canSave: canSave,
      errorText: null,
      showActionSelector: showActionSelector,
      selectedAction: InventoryReceiptManualProductAction.addToInventory,
      onFieldChanged: (field, text) => calls.fields.add((field, text)),
      onWeightUnitChanged: calls.units.add,
      onNoBarcodeChanged: calls.noBarcode.add,
      onScanBarcode: () => calls.scans++,
      onTakeFrontPhoto: () => calls.frontPhotos++,
      onTakeNutritionTablePhoto: () => calls.tablePhotos++,
      onAddOptionalNutrition: calls.optional.add,
      onActionChanged: calls.actions.add,
      onSave: () => calls.saves++,
    ),
  );
}

bool _hasFocus(WidgetTester tester, ManualProductFormField field) {
  final text = tester.widget<EditableText>(
    find.descendant(
      of: find.byKey(field.key),
      matching: find.byType(EditableText),
    ),
  );
  return text.focusNode.hasFocus;
}

void main() {
  testWidgets('shows the product on a food label and saves it', (tester) async {
    final calls = _Calls();
    await tester.pumpWidget(_editor(calls));

    expect(find.text('Haferflocken zart'), findsOneWidget);
    expect(find.text('Rewe Bio'), findsOneWidget);
    expect(find.text('372'), findsOneWidget);
    expect(find.text('Per 100 g'), findsOneWidget);
    expect(
      find.text(
        'Required values are missing. Every EU nutrition label lists '
        'them.',
      ),
      findsNothing,
    );

    await tester.tap(find.byKey(ManualProductDetailsForm.saveKey));
    expect(calls.saves, 1);
  });

  testWidgets('a missing mandatory value blocks saving and shows a hint', (
    tester,
  ) async {
    final calls = _Calls();
    await tester.pumpWidget(
      _editor(calls, state: _complete.copyWith(sugarText: ''), canSave: false),
    );

    expect(
      find.text(
        'Required values are missing. Every EU nutrition label lists '
        'them.',
      ),
      findsOneWidget,
    );
    final save = tester.widget<FilledButton>(
      find.byKey(ManualProductDetailsForm.saveKey),
    );
    expect(save.onPressed, isNull);
    final hint = tester.widget<Text>(
      find.byKey(const Key('eat_page_confirm_hint')),
    );
    expect(hint.data, startsWith('Still missing: '));
    expect(hint.data, contains('Barcode'));
    expect(hint.data, isNot(contains('Name')));
  });

  testWidgets('a savable product shows no missing hint', (tester) async {
    await tester.pumpWidget(_editor(_Calls()));

    expect(find.byKey(const Key('eat_page_confirm_hint')), findsNothing);
  });

  testWidgets('typing reports the field', (tester) async {
    final calls = _Calls();
    await tester.pumpWidget(_editor(calls));

    await tester.enterText(find.byKey(ManualProductFormField.kcal.key), '380');
    await tester.enterText(
      find.byKey(ManualProductFormField.name.key),
      'Hafer',
    );

    expect(calls.fields, [
      (ManualProductFormField.kcal, '380'),
      (ManualProductFormField.name, 'Hafer'),
    ]);
  });

  testWidgets('values from a scan replace the inputs', (tester) async {
    final calls = _Calls();
    await tester.pumpWidget(
      _editor(calls, state: _complete.copyWith(fatText: '')),
    );

    await tester.pumpWidget(
      _editor(calls, state: _complete.copyWith(fatText: '6.5')),
    );

    expect(find.text('6.5'), findsOneWidget);
    expect(calls.fields, isEmpty);
  });

  testWidgets('the unit button switches through the units', (tester) async {
    final calls = _Calls();
    await tester.pumpWidget(
      _editor(
        calls,
        state: const InventoryReceiptManualProductState(weightAmount: '500'),
        canSave: false,
      ),
    );

    await tester.tap(find.byKey(ManualProductEditorHeader.weightUnitKey));
    expect(calls.units, [InventoryAmountUnit.gram]);

    await tester.pumpWidget(_editor(calls));
    await tester.tap(find.byKey(ManualProductEditorHeader.weightUnitKey));
    expect(calls.units.last, InventoryAmountUnit.milliliter);
  });

  testWidgets('no barcode locks the barcode input and the scanner', (
    tester,
  ) async {
    final calls = _Calls();
    await tester.pumpWidget(_editor(calls));

    await tester.ensureVisible(
      find.byKey(ManualProductPhotoSection.scanBarcodeKey),
    );
    await tester.tap(find.byKey(ManualProductPhotoSection.scanBarcodeKey));
    await tester.tap(find.byKey(ManualProductPhotoSection.noBarcodeKey));
    expect(calls.scans, 1);
    expect(calls.noBarcode, [true]);

    await tester.pumpWidget(
      _editor(calls, state: _complete.copyWith(hasNoBarcode: true)),
    );
    final barcode = tester.widget<TextField>(
      find.byKey(ManualProductFormField.barcode.key),
    );
    final scan = tester.widget<ButtonStyleButton>(
      find.byKey(ManualProductPhotoSection.scanBarcodeKey),
    );
    expect(barcode.enabled, isFalse);
    expect(scan.onPressed, isNull);
  });

  testWidgets('keyboard confirm jumps to the next empty required value', (
    tester,
  ) async {
    final calls = _Calls();
    await tester.pumpWidget(
      _editor(
        calls,
        state: _complete.copyWith(nameText: '', kcalText: '', sugarText: ''),
        canSave: false,
      ),
    );

    await tester.showKeyboard(find.byKey(ManualProductFormField.name.key));
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(_hasFocus(tester, ManualProductFormField.kcal), isTrue);

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(_hasFocus(tester, ManualProductFormField.sugar), isTrue);

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(_hasFocus(tester, ManualProductFormField.sugar), isFalse);
  });

  testWidgets('adds an optional nutrient from the menu', (tester) async {
    final calls = _Calls();
    await tester.pumpWidget(_editor(calls));

    await tester.ensureVisible(find.byKey(ManualProductNutritionEditor.addKey));
    await tester.tap(find.byKey(ManualProductNutritionEditor.addKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fibre').last);
    await tester.pumpAndSettle();

    expect(calls.optional, [InventoryReceiptOptionalNutritionType.fiber]);
  });

  testWidgets('shown optional nutrients get an input', (tester) async {
    final calls = _Calls();
    await tester.pumpWidget(
      _editor(calls, state: _complete.copyWith(showFiberField: true)),
    );

    expect(find.byKey(ManualProductFormField.fiber.key), findsOneWidget);
    expect(
      find.byKey(ManualProductFormField.polyunsaturatedFat.key),
      findsNothing,
    );
  });

  testWidgets('the action chips choose eating', (tester) async {
    final calls = _Calls();
    await tester.pumpWidget(_editor(calls, showActionSelector: true));

    await tester.ensureVisible(
      find.byKey(const Key('receipt_review_manual_eat_action_button')),
    );
    await tester.tap(
      find.byKey(const Key('receipt_review_manual_eat_action_button')),
    );

    expect(calls.actions, [InventoryReceiptManualProductAction.eatNow]);
  });

  testWidgets('the photo tiles take the front and the nutrition table', (
    tester,
  ) async {
    final calls = _Calls();
    await tester.pumpWidget(_editor(calls));

    await tester.tap(find.byKey(ManualProductPhotoSection.frontKey));
    await tester.tap(find.byKey(ManualProductPhotoSection.nutritionTableKey));

    expect(calls.frontPhotos, 1);
    expect(calls.tablePhotos, 1);
    expect(find.text('Front'), findsOneWidget);
    expect(find.text('Nutrition table'), findsOneWidget);
  });

  testWidgets('says where a barcode from a photo came from', (tester) async {
    final calls = _Calls();
    await tester.pumpWidget(
      _editor(
        calls,
        state: _complete.copyWith(
          barcode: '4006381333931',
          barcodeOrigin: ManualProductBarcodeOrigin.ai,
        ),
      ),
    );

    expect(find.text('Read by the AI, please check'), findsOneWidget);
  });

  testWidgets('says when the photos show no barcode', (tester) async {
    final calls = _Calls();
    await tester.pumpWidget(
      _editor(
        calls,
        photoState: ManualProductPhotoState(
          front: ProductPhoto(
            path: 'front',
            bytes: Uint8List.fromList(_pixel),
            mimeType: 'image/png',
          ),
          hasReadFront: true,
        ),
      ),
    );

    expect(find.text('No barcode on the photos'), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);
  });

  testWidgets('the photo tags say what each photo filled in', (tester) async {
    final photo = ProductPhoto(
      path: 'photo',
      bytes: Uint8List.fromList(_pixel),
      mimeType: 'image/png',
    );
    await tester.pumpWidget(
      _editor(
        _Calls(),
        photoState: ManualProductPhotoState(
          front: photo,
          nutritionTable: photo,
          hasReadFront: true,
          hasReadNutritionTable: true,
          frontDetails: const ProductFrontDetails(
            name: 'Haferflocken zart',
            quantityLabel: '500 g',
          ),
          nutritionValueCount: 9,
        ),
      ),
    );

    expect(find.text('Name · 500 g'), findsOneWidget);
    expect(find.text('9 values'), findsOneWidget);
  });
}
