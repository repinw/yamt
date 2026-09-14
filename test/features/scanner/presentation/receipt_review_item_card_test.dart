import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/scanner/domain/models/product_candidate.dart';
import 'package:yamt/features/scanner/domain/models/receipt_line_item.dart';
import 'package:yamt/features/scanner/presentation/widgets/receipt_review_item_card.dart';

void main() {
  group('ReceiptReviewItemCard', () {
    const matchedProduct = ProductCandidate(
      id: 'p1',
      name: 'Vollmilch 3.8%',
      brand: 'Ja!',
    );

    testWidgets(
      'renders confirmed item with product name and rawName subtitle',
      (tester) async {
        const item = ReceiptLineItem(
          id: 'i1',
          rawName: 'JA! VOLLM. 1L',
          totalPrice: 1.49,
          status: ReceiptItemStatus.confirmed,
          matchedProduct: matchedProduct,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ReceiptReviewItemCard(
                item: item,
                currencyCode: 'EUR',
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.text('Vollmilch 3.8%'), findsOneWidget);
        expect(find.text('Bon: JA! VOLLM. 1L'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
        expect(find.text('1x'), findsOneWidget);
      },
    );

    testWidgets('renders suggested item with quick confirm button', (
      tester,
    ) async {
      const item = ReceiptLineItem(
        id: 'i2',
        rawName: 'BIO BANANEN',
        totalPrice: 2.29,
        status: ReceiptItemStatus.suggested,
        matchedProduct: ProductCandidate(id: 'p2', name: 'Bio Bananen 1kg'),
      );

      var confirmed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceiptReviewItemCard(
              item: item,
              currencyCode: 'EUR',
              onTap: () {},
              onConfirmSuggestion: () => confirmed = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
      final confirmBtn = find.byKey(const Key('confirm_item_i2'));
      expect(confirmBtn, findsOneWidget);

      await tester.tap(confirmBtn);
      expect(confirmed, isTrue);
    });

    testWidgets('renders discount tag when discount is present', (
      tester,
    ) async {
      const item = ReceiptLineItem(
        id: 'i3',
        rawName: 'GOUDA',
        totalPrice: 2.49,
        discount: 0.50,
        status: ReceiptItemStatus.confirmed,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceiptReviewItemCard(
              item: item,
              currencyCode: 'EUR',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('-0.50 €'), findsOneWidget);
    });

    testWidgets('renders Pfand badge when isDeposit is true', (tester) async {
      const item = ReceiptLineItem(
        id: 'i4',
        rawName: 'EINWEGPFAND 0,25',
        totalPrice: 0.25,
        isDeposit: true,
        status: ReceiptItemStatus.confirmed,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceiptReviewItemCard(
              item: item,
              currencyCode: 'EUR',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Pfand'), findsOneWidget);
    });

    testWidgets('renders macro overview string when product has nutrition', (
      tester,
    ) async {
      const item = ReceiptLineItem(
        id: 'i5',
        rawName: 'BIO HAFERDRINK',
        totalPrice: 1.39,
        status: ReceiptItemStatus.confirmed,
        matchedProduct: ProductCandidate(
          id: 'p5',
          name: 'Haferdrink',
          packageSize: '1 l',
          nutritionPer100g: {
            'kcal': 46,
            'protein': 0.8,
            'carbs': 6.8,
            'fat': 1.4,
          },
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceiptReviewItemCard(
              item: item,
              currencyCode: 'EUR',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Nährwerte je 100 g/ml'), findsOneWidget);
      expect(find.text('Packung: 1 l'), findsOneWidget);
      expect(find.text('46 kcal'), findsOneWidget);
      expect(find.text('Fett'), findsOneWidget);
      expect(find.text('1.4 g'), findsOneWidget);
      expect(find.text('KH'), findsOneWidget);
      expect(find.text('6.8 g'), findsOneWidget);
      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('0.8 g'), findsOneWidget);

      final fatX = tester.getTopLeft(find.text('Fett')).dx;
      final carbsX = tester.getTopLeft(find.text('KH')).dx;
      final proteinX = tester.getTopLeft(find.text('Protein')).dx;
      expect(fatX, lessThan(carbsX));
      expect(carbsX, lessThan(proteinX));
    });
  });
}
