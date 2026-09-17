import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/scanner/data/receipt_gateway_providers.dart';
import 'package:yamt/features/scanner/domain/models/product_candidate.dart';
import 'package:yamt/features/scanner/domain/models/receipt_line_item.dart';
import 'package:yamt/features/scanner/domain/models/scanned_receipt.dart';
import 'package:yamt/features/scanner/presentation/receipt_review_page.dart';

import '../fakes/fake_receipt_manual_product_picker.dart';
import '../fakes/fake_receipt_product_resolver.dart';
import '../fakes/fake_receipt_storage_gateway.dart';

void main() {
  group('ReceiptReviewPage', () {
    late FakeReceiptProductResolver fakeResolver;
    late FakeReceiptStorageGateway fakeGateway;
    late FakeReceiptManualProductPicker fakePicker;

    const testItem = ReceiptLineItem(
      id: 'item-1',
      rawName: 'BIO MILCH',
      rawBrand: 'GL',
      packageWeight: '1L',
      totalPrice: 1.49,
      status: ReceiptItemStatus.suggested,
      matchedProduct: ProductCandidate(id: 'prod-milch', name: 'Bio Milch 1L'),
    );

    const testReceipt = ScannedReceipt(
      id: 'receipt-1',
      storeName: 'Supermarkt',
      printedTotal: 1.49,
      items: [testItem],
    );

    setUp(() {
      fakeResolver = FakeReceiptProductResolver();
      fakeGateway = FakeReceiptStorageGateway();
      fakePicker = FakeReceiptManualProductPicker();
    });

    Future<void> pumpTestWidget(
      WidgetTester tester, {
      ScannedReceipt receipt = testReceipt,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            receiptProductResolverProvider.overrideWithValue(fakeResolver),
            receiptStorageGatewayProvider.overrideWithValue(fakeGateway),
            receiptManualProductPickerProvider.overrideWithValue(fakePicker),
          ],
          child: MaterialApp(home: ReceiptReviewPage(initialReceipt: receipt)),
        ),
      );
    }

    testWidgets('renders receipt items and header', (tester) async {
      await pumpTestWidget(tester);

      expect(find.text('Beleg prüfen'), findsOneWidget);
      expect(find.text('Supermarkt'), findsOneWidget);
      expect(find.text('Bio Milch 1L'), findsOneWidget);
      expect(find.text('Position hinzufügen'), findsOneWidget);
    });

    testWidgets('save button disabled when item is suggested (unresolved)', (
      tester,
    ) async {
      await pumpTestWidget(tester);

      final saveButton = tester.widget<FilledButton>(
        find.byKey(const Key('save_receipt_button')),
      );
      expect(saveButton.onPressed, isNull);
      expect(find.textContaining('1 Position(en) offen'), findsOneWidget);
    });

    testWidgets('confirming suggestion enables save button and saves receipt', (
      tester,
    ) async {
      await pumpTestWidget(tester);

      // Confirm suggestion via quick button on card
      final confirmBtn = find.byKey(const Key('confirm_item_item-1'));
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Save button should now be enabled
      final saveButton = tester.widget<FilledButton>(
        find.byKey(const Key('save_receipt_button')),
      );
      expect(saveButton.onPressed, isNotNull);
      expect(find.textContaining('offen'), findsNothing);

      // Tap save
      await tester.tap(find.byKey(const Key('save_receipt_button')));
      await tester.pumpAndSettle();

      // Verify saved in fake gateway
      expect(fakeGateway.savedReceipts, hasLength(1));
      expect(fakeGateway.savedReceipts.first.receipt.id, 'receipt-1');
      expect(fakeGateway.learnedAliases, isEmpty);
    });

    testWidgets('can toggle item ignore to allow saving without the item', (
      tester,
    ) async {
      const unmatchedItem = ReceiptLineItem(
        id: 'item-unmatched',
        rawName: 'UNBEKANNT',
        totalPrice: 2,
      );
      const receiptWithTwo = ScannedReceipt(
        id: 'r2',
        storeName: 'TestStore',
        printedTotal: 3.49,
        items: [
          ReceiptLineItem(
            id: 'item-ok',
            rawName: 'BROT',
            totalPrice: 1.49,
            status: ReceiptItemStatus.confirmed,
            matchedProduct: ProductCandidate(id: 'p-brot', name: 'Brot'),
          ),
          unmatchedItem,
        ],
      );

      await pumpTestWidget(tester, receipt: receiptWithTwo);

      // 1 item is open
      expect(find.textContaining('1 Position(en) offen'), findsOneWidget);

      // Tap card to open edit sheet
      await tester.tap(find.text('UNBEKANNT'));
      await tester.pumpAndSettle();

      // Tap ignore button in sheet (tooltip: 'Ignorieren')
      final ignoreButton = find.byTooltip('Ignorieren');
      expect(ignoreButton, findsOneWidget);
      await tester.tap(ignoreButton);
      await tester.pumpAndSettle();

      // Save button should now be enabled
      final saveButton = tester.widget<FilledButton>(
        find.byKey(const Key('save_receipt_button')),
      );
      expect(saveButton.onPressed, isNotNull);
    });

    testWidgets(
      'tapping search product calls manual product picker and applies result',
      (tester) async {
        fakePicker.nextResult = const ProductCandidate(
          id: 'chosen-custom-prod',
          name: 'Custom Hafermilch',
          brand: 'Eigenmarke',
          nutritionPer100g: {'kcal': 50, 'protein': 1.5, 'fat': 2.0},
        );

        await pumpTestWidget(tester);

        // Open edit sheet for BIO MILCH
        await tester.tap(find.text('Bio Milch 1L'));
        await tester.pumpAndSettle();

        // The action row uses icons only; labels remain available as tooltips.
        expect(find.text('Barcode'), findsNothing);
        expect(find.text('Suchen'), findsNothing);
        final searchButton = find.byTooltip('Produkt suchen');
        expect(searchButton, findsOneWidget);
        await tester.tap(searchButton);
        await tester.pumpAndSettle();

        // Picker was invoked with line rawName
        expect(fakePicker.recordedQueries, contains('BIO MILCH'));
        expect(fakePicker.recordedStoreNames, contains('Supermarkt'));
        expect(fakePicker.recordedBrands, contains('GL'));
        expect(fakePicker.recordedWeights, contains('1L'));

        // Item is now updated with the chosen candidate
        expect(find.text('Custom Hafermilch'), findsOneWidget);
      },
    );
  });
}
