import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/scanner/presentation/widgets/inventory_receipt_review_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

FridgeItem _item({
  required String id,
  required bool isDeposit,
  required bool isDiscount,
  DateTime? receiptDate,
}) {
  return FridgeItem(
    id: id,
    name: 'Item $id',
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    unitPrice: 1.0,
    isDeposit: isDeposit,
    isDiscount: isDiscount,
    receiptDate: receiptDate,
  );
}

Widget _wrap({
  required List<FridgeItem> items,
  required VoidCallback onCancelTap,
  required Future<void> Function(List<FridgeItem> items) onSaveTap,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: InventoryReceiptReviewSheet(
        items: items,
        onCancelTap: onCancelTap,
        onSaveTap: onSaveTap,
      ),
    ),
  );
}

void main() {
  testWidgets('price overview shows total, savable and excluded sums', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        items: <FridgeItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
          _item(id: 'deposit', isDeposit: true, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    expect(find.text('Price overview'), findsOneWidget);
    expect(find.text('Total receipt'), findsOneWidget);
    expect(find.text('Saved to inventory'), findsOneWidget);
    expect(find.text('Excluded lines'), findsOneWidget);
    expect(find.textContaining('€'), findsNWidgets(3));
  });

  testWidgets('edited item including receiptDate is passed to save callback', (
    tester,
  ) async {
    List<FridgeItem>? savedItems;

    await tester.pumpWidget(
      _wrap(
        items: <FridgeItem>[
          _item(
            id: 'food',
            isDeposit: false,
            isDiscount: false,
            receiptDate: DateTime.parse('2026-01-05'),
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('receipt_review_field_name')),
      'Edited item',
    );
    await tester.pumpAndSettle();

    final clearDateButton = find.byKey(
      const Key('receipt_review_clear_receipt_date_button'),
    );
    await tester.ensureVisible(clearDateButton);
    await tester.tap(clearDateButton);
    await tester.pumpAndSettle();

    final applyButton = find.byKey(
      const Key('receipt_review_apply_item_button'),
    );
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    final saveButton = find.byKey(const Key('receipt_review_save_button'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems, hasLength(1));
    expect(savedItems!.single.name, 'Edited item');
    expect(savedItems!.single.receiptDate, isNull);
  });

  testWidgets('save action is disabled when all items are review-only', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        items: <FridgeItem>[
          _item(id: 'deposit', isDeposit: true, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('receipt_review_save_button')),
    );
    expect(button.onPressed, isNull);
  });
}
