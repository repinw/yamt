import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/scanner/domain/models/receipt_line_item.dart';
import 'package:yamt/features/scanner/domain/models/scanned_receipt.dart';
import 'package:yamt/features/scanner/presentation/widgets/receipt_review_header.dart';

void main() {
  group('ReceiptReviewHeader', () {
    const baseReceipt = ScannedReceipt(
      id: 'r1',
      storeName: 'REWE Supermarkt',
      printedTotal: 10,
      items: [
        ReceiptLineItem(
          id: 'i1',
          rawName: 'Apfel',
          totalPrice: 10,
          status: ReceiptItemStatus.confirmed,
        ),
      ],
    );

    testWidgets('displays store name and triggers onEditStore', (tester) async {
      var editStoreTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceiptReviewHeader(
              receipt: baseReceipt,
              onEditStore: () => editStoreTapped = true,
              onEditDate: () {},
            ),
          ),
        ),
      );

      expect(find.text('REWE Supermarkt'), findsOneWidget);
      await tester.tap(find.text('REWE Supermarkt'));
      expect(editStoreTapped, isTrue);
    });

    testWidgets('shows matching sum badge when totals match', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceiptReviewHeader(
              receipt: baseReceipt,
              onEditStore: () {},
              onEditDate: () {},
            ),
          ),
        ),
      );

      expect(find.text('Summe stimmt'), findsOneWidget);
      expect(find.text('Differenz'), findsNothing);
    });

    testWidgets('shows discrepancy badge when totals differ', (tester) async {
      final mismatchReceipt = baseReceipt.copyWith(
        printedTotal: 15, // calculated is 10.0 -> diff is 5.0
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceiptReviewHeader(
              receipt: mismatchReceipt,
              onEditStore: () {},
              onEditDate: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('Differenz:'), findsOneWidget);
      expect(find.text('Summe stimmt'), findsNothing);
    });

    testWidgets('shows suggestions button and triggers callback', (
      tester,
    ) async {
      final receiptWithSuggestion = baseReceipt.copyWith(
        items: [
          const ReceiptLineItem(
            id: 'i2',
            rawName: 'Brot',
            totalPrice: 2,
            status: ReceiptItemStatus.suggested,
          ),
        ],
      );

      var confirmAllTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceiptReviewHeader(
              receipt: receiptWithSuggestion,
              onEditStore: () {},
              onEditDate: () {},
              onConfirmAllSuggestions: () => confirmAllTapped = true,
            ),
          ),
        ),
      );

      final button = find.byKey(const Key('confirm_all_suggestions_button'));
      expect(button, findsOneWidget);
      await tester.tap(button);
      expect(confirmAllTapped, isTrue);
    });
  });
}
