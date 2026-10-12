import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_controller.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_result_flow.dart';

const _completeNutrition = GlobalFoodNutrition(
  qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
  per100Kcal: 100,
  per100Carbs: 10,
  per100Protein: 5,
  per100Fat: 2,
);

void main() {
  testWidgets('an eaten-up recent item is eaten again from a full package', (
    tester,
  ) async {
    final eatenUp = InventoryItem.create(
      id: 'recent-1',
      name: 'Skyr',
      entryDate: DateTime(2026, 9, 20),
      storeName: 'Manual',
      quantity: 1,
      weight: '500 g',
      nutrition: _completeNutrition,
    ).copyWith(quantity: 0, currentAmount: 0);
    expect(consumableInventoryAmount(eatenUp), isNull);

    InventoryReceiptManualProductResult? completed;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => editAndSaveProductSearchHubRecentItem(
              context: context,
              args: const ProductSearchHubRouteArgs.diary(),
              item: eatenUp,
              isSourceBlocked: (_) => false,
              completeResult: ({required sourceKey, required result}) async {
                completed = result;
              },
            ),
            child: const Text('eat'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('eat'));
    await tester.pump();

    final item = completed!.item;
    expect(item.name, 'Skyr');
    expect(item.quantity, 1);
    expect(item.currentAmount, 500);
    expect(consumableInventoryAmount(item), 500);
  });

  testWidgets('a recent item given a size counts one package', (tester) async {
    // An old stock entry of four packages, never weighed.
    final recent = InventoryItem.create(
      id: 'recent-2',
      name: 'Joghurt',
      entryDate: DateTime(2026, 9, 20),
      storeName: 'Manual',
      quantity: 4,
      initialQuantity: 4,
      barcode: '4311596490202',
      nutrition: _completeNutrition,
    ).copyWith(quantity: 0);

    InventoryReceiptManualProductResult? completed;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => editAndSaveProductSearchHubRecentItem(
              context: context,
              args: const ProductSearchHubRouteArgs.diary(),
              item: recent,
              isSourceBlocked: (_) => false,
              completeResult: ({required sourceKey, required result}) async {
                completed = result;
              },
            ),
            child: const Text('eat'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('eat'));
    await tester.pump();

    final draft = completed!.item;
    expect(draft.quantity, 1);
    expect(draft.initialQuantity, 1);

    // "Bearbeiten" on the pick page adds the package size.
    // Disposed in the body: its pending cleanup must not outlive the test.
    final container = ProviderContainer();
    final provider = inventoryReceiptManualProductControllerProvider(
      InventoryReceiptManualProductConfig(item: draft),
    );
    final controller = container.read(provider.notifier)
      ..updateWeightAmount('500');

    final weighed = controller.buildSavePayload()?.item;

    container.dispose();
    expect(weighed?.initialAmount, 500);
    expect(weighed?.currentAmount, 500);
  });
}
