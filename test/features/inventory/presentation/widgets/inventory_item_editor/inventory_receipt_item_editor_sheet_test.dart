import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_item_editor/inventory_receipt_item_editor_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'inventory mode hides receipt-only fields without dropping hidden values',
    (tester) async {
      InventoryItem? editedItem;
      final sourceItem = InventoryItem.create(
        id: 'item-1',
        name: 'Milk',
        entryDate: DateTime.parse('2026-04-07T10:00:00Z'),
        storeName: 'Store',
        quantity: 1,
        unitPrice: 1,
        discounts: const <String, double>{'coupon': -0.25},
        isDeposit: true,
        isDiscount: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () async {
                    editedItem = await showModalBottomSheet<InventoryItem>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (context) {
                        return InventoryReceiptItemEditorSheet(
                          item: sourceItem,
                          showDiscountFields: false,
                          showReviewOnlyFields: false,
                        );
                      },
                    );
                  },
                  child: const Text('Open editor'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open editor'));
      await tester.pumpAndSettle();

      expect(find.text('Is deposit item'), findsNothing);
      expect(find.text('Is discount item'), findsNothing);
      expect(find.text('Discounts'), findsNothing);

      await tester.ensureVisible(find.text('Apply changes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply changes'));
      await tester.pumpAndSettle();

      expect(editedItem, isNotNull);
      expect(editedItem?.isDeposit, isTrue);
      expect(editedItem?.isDiscount, isTrue);
      expect(editedItem?.discounts, sourceItem.discounts);
    },
  );

  testWidgets('shows receipt-only fields by default', (tester) async {
    final sourceItem = InventoryItem.create(
      id: 'item-1',
      name: 'Milk',
      entryDate: DateTime.parse('2026-04-07T10:00:00Z'),
      storeName: 'Store',
      quantity: 1,
      unitPrice: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: InventoryReceiptItemEditorSheet(item: sourceItem)),
      ),
    );

    expect(find.text('Discounts'), findsOneWidget);
    expect(find.text('Is deposit item'), findsOneWidget);
    expect(find.text('Is discount item'), findsOneWidget);
  });
}
