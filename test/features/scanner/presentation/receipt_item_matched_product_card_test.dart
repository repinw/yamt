import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/scanner/domain/models/product_candidate.dart';
import 'package:yamt/features/scanner/presentation/widgets/receipt_item_matched_product_card.dart';

void main() {
  group('ReceiptItemMatchedProductCard', () {
    testWidgets('renders unmatched placeholder when product is null', (
      tester,
    ) async {
      var searched = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceiptItemMatchedProductCard(
              product: null,
              onClearProduct: () {},
              onSearchProduct: () => searched = true,
            ),
          ),
        ),
      );

      expect(find.text('Kein Produkt zugewiesen'), findsOneWidget);
      expect(find.text('Produkt suchen'), findsOneWidget);

      await tester.tap(find.text('Produkt suchen'));
      expect(searched, isTrue);
    });

    testWidgets('renders matched product info and macro chips', (tester) async {
      var switchTapped = false;
      var clearTapped = false;

      const product = ProductCandidate(
        id: 'p1',
        name: 'Bio Haferdrink',
        brand: 'REWE Bio',
        barcode: '4388844093814',
        packageSize: '1 l',
        nutritionPer100g: {
          'kcal': 46,
          'protein': 0.8,
          'carbs': 6.8,
          'fat': 1.4,
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceiptItemMatchedProductCard(
              product: product,
              onClearProduct: () => clearTapped = true,
              onSearchProduct: () => switchTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Bio Haferdrink'), findsOneWidget);
      expect(find.text('REWE Bio · 4388844093814'), findsOneWidget);
      expect(find.text('Produkt wechseln'), findsOneWidget);
      expect(find.text('Nährwerte je 100 g/ml'), findsOneWidget);
      expect(find.text('Packung: 1 l'), findsOneWidget);
      expect(find.text('46 kcal'), findsOneWidget);
      expect(find.text('Fett'), findsOneWidget);
      expect(find.text('1.4 g'), findsOneWidget);
      expect(find.text('KH'), findsOneWidget);
      expect(find.text('6.8 g'), findsOneWidget);
      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('0.8 g'), findsOneWidget);

      await tester.tap(find.text('Produkt wechseln'));
      expect(switchTapped, isTrue);

      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(clearTapped, isTrue);
    });
  });
}
