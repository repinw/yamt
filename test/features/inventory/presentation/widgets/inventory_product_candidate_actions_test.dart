import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_product_candidate_widgets.dart';

void main() {
  testWidgets('eat-only candidate actions hide inventory button', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InventoryProductCandidateActions(
            inventoryLabel: 'Inventory',
            eatLabel: 'Eat',
            showInventoryAction: false,
            onInventory: () {},
            onEat: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.restaurant_menu_outlined), findsOneWidget);
    expect(find.byIcon(Icons.inventory_2_outlined), findsNothing);
  });
}
