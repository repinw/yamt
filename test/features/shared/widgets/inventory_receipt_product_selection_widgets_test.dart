import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/shared/widgets/'
    'inventory_receipt_product_selection_widgets.dart';

void main() {
  testWidgets('nutrition chips render available nutrition values', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: InventoryReceiptNutritionChips(
            leadingLabel: '  Verified  ',
            nutrition: GlobalFoodNutrition(
              qualityStatus: GlobalFoodNutritionQualityStatus.verified,
              per100Kcal: 123.6,
              per100Carbs: 12,
              per100Protein: 7.25,
              per100Fat: 3.5,
              per100Salt: 0.2,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('124 kcal'), findsOneWidget);
    expect(find.text('KH 12 g'), findsOneWidget);
    expect(find.text('Eiweiß 7.3 g'), findsOneWidget);
    expect(find.text('Fett 3.5 g'), findsOneWidget);
    expect(find.text('Salz 0.2 g'), findsOneWidget);
  });

  testWidgets('nutrition chips collapse when no value is available', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: InventoryReceiptNutritionChips(
            nutrition: GlobalFoodNutrition(
              qualityStatus: GlobalFoodNutritionQualityStatus.missing,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Wrap), findsNothing);
    expect(find.byType(SizedBox), findsOneWidget);
  });

  testWidgets('thumbnail falls back to icon without image url', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: InventoryReceiptSelectionThumbnail(imageUrl: null),
        ),
      ),
    );

    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
  });
}
