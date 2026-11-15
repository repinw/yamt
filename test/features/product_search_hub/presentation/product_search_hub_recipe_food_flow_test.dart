import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/inventory/presentation/inventory_stock_amount_page.dart';
import 'package:yamt/features/inventory/presentation/models/recipe_food_pick.dart';
import 'package:yamt/features/inventory/presentation/widgets/stock_amount/'
    'stock_amount_inputs.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_mode.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_recipe_food_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/fake_inventory_item_repository.dart';

const _openKey = ValueKey<String>('open');

ProductSearchHubRouteArgs _args({
  InventoryAmountUnit unit = InventoryAmountUnit.gram,
  int need = 250,
  bool takesFromStock = true,
  Set<String> held = const {},
}) => ProductSearchHubRouteArgs(
  mode: ProductSearchHubMode.mealFood,
  ingredient: 'Flour',
  initialQuery: 'Flour',
  ingredientUnit: unit,
  ingredientNeed: need,
  takesFromStock: takesFromStock,
  heldItemIds: held,
);

InventoryItem _food({
  String id = 'recent',
  String weight = '',
  String barcode = '',
}) => InventoryItem.create(
  id: id,
  name: 'Flour',
  barcode: barcode,
  entryDate: DateTime(2026, 11, 12),
  storeName: 'Store',
  quantity: 1,
  weight: weight,
).withDerivedAmount();

InventoryReceiptManualProductResult _result(InventoryItem item) =>
    InventoryReceiptManualProductResult(
      item: item,
      action: InventoryReceiptManualProductAction.addToInventory,
      requiresGlobalPersistence: false,
    );

typedef _Picked = ({RecipeFoodPick? pick, bool done});

/// Runs `pickProductSearchHubRecipeFood` for [item] with the Vorrat [stock].
/// [during] drives what the flow shows before it ends.
Future<_Picked> _pick(
  WidgetTester tester, {
  required InventoryItem item,
  required ProductSearchHubRouteArgs args,
  List<InventoryItem> stock = const [],
  Future<void> Function()? during,
}) async {
  RecipeFoodPick? pick;
  var done = false;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(
          FakeInventoryItemRepository(stock),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Consumer(
          builder: (context, ref, _) {
            // The recipe page keeps the Vorrat alive; so does the harness.
            ref.watch(inventoryQuickEatItemsProvider);
            return TextButton(
              key: _openKey,
              onPressed: () async {
                final picked = await pickProductSearchHubRecipeFood(
                  context: context,
                  args: args,
                  result: _result(item),
                );
                pick = picked.pick;
                done = true;
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(_openKey));
  await tester.pumpAndSettle();
  await during?.call();
  return (pick: pick, done: done);
}

void main() {
  testWidgets('a product that the Vorrat holds already (same barcode) comes '
      'back as the Vorrat packs, with no page', (tester) async {
    final inStock = _food(id: 'in-stock', weight: '1 kg', barcode: '4001');

    final run = await _pick(
      tester,
      item: _food(weight: '500 g', barcode: '4001'),
      args: _args(),
      stock: [inStock],
    );

    expect(run.done, isTrue);
    final pick = run.pick! as RecipeFoodInStock;
    expect(pick.items.map((item) => item.id), ['in-stock']);
    expect(find.byType(InventoryStockAmountPage), findsNothing);
  });

  testWidgets('a scanned pack that is planned for something else comes back '
      'as a new pack', (tester) async {
    final held = _food(id: 'held', weight: '1 kg', barcode: '4001');

    final run = await _pick(
      tester,
      item: _food(weight: '500 g', barcode: '4001'),
      args: _args(held: {'held'}),
      stock: [held],
    );

    expect(run.done, isTrue);
    final food = (run.pick! as RecipeFoodNew).food;
    expect(food.request.inventoryAmount, 500);
    expect(food.result.item.id, isNot('held'));
  });

  testWidgets('of two packs with the barcode only the one with something '
      'left comes back', (tester) async {
    final run = await _pick(
      tester,
      item: _food(weight: '500 g', barcode: '4001'),
      args: _args(held: {'held'}),
      stock: [
        _food(id: 'held', weight: '1 kg', barcode: '4001'),
        _food(id: 'free', weight: '1 kg', barcode: '4001'),
      ],
    );

    final pick = run.pick! as RecipeFoodInStock;
    expect(pick.items.map((item) => item.id), ['free']);
  });

  testWidgets('a caller that does not take the Vorrat gets a new full pack', (
    tester,
  ) async {
    final run = await _pick(
      tester,
      item: _food(weight: '500 g', barcode: '4001'),
      args: _args(takesFromStock: false),
      stock: [_food(id: 'in-stock', weight: '1 kg', barcode: '4001')],
    );

    expect(run.pick, isA<RecipeFoodNew>());
  });

  testWidgets('a product with a package size enters one full pack without '
      'asking', (tester) async {
    final run = await _pick(
      tester,
      item: _food(weight: '500 g', barcode: '4002'),
      args: _args(),
    );

    expect(run.done, isTrue);
    expect(find.byType(InventoryStockAmountPage), findsNothing);
    final food = (run.pick! as RecipeFoodNew).food;
    expect(food.request.inventoryAmount, 500);
    expect(food.result.item.initialAmount, 500);
    // The pack is a new item, never the recent one's id.
    expect(food.result.item.id, isNot('recent'));
  });

  testWidgets('a product without a package size asks on the amount page for '
      'the pack weight', (tester) async {
    final run = await _pick(
      tester,
      item: _food(),
      args: _args(),
      during: () async {
        expect(find.byType(InventoryStockAmountPage), findsOneWidget);
        await tester.enterText(find.byKey(StockAmountField.fieldKey), '750');
        await tester.pump();
        await tester.tap(find.byKey(InventoryStockAmountPage.applyKey));
        await tester.pumpAndSettle();
      },
    );

    expect(run.done, isTrue);
    final food = (run.pick! as RecipeFoodNew).food;
    expect(food.request.inventoryAmount, 750);
    expect(food.result.item.amountUnit, InventoryAmountUnit.gram);
    expect(food.result.item.initialAmount, 750);
  });

  testWidgets('a product without a package size for a line in spoons, asked '
      'by weight in ml, asks for the pack weight in ml', (tester) async {
    final run = await _pick(
      tester,
      item: _food(),
      args: _args(unit: InventoryAmountUnit.milliliter, need: 50),
      during: () async {
        expect(find.byType(InventoryStockAmountPage), findsOneWidget);
        expect(find.byKey(StockAmountCountRow.countKey), findsNothing);
        await tester.enterText(find.byKey(StockAmountField.fieldKey), '500');
        await tester.pump();
        await tester.tap(find.byKey(InventoryStockAmountPage.applyKey));
        await tester.pumpAndSettle();
      },
    );

    final food = (run.pick! as RecipeFoodNew).food;
    expect(food.request.inventoryAmount, 500);
    expect(food.result.item.amountUnit, InventoryAmountUnit.milliliter);
    expect(food.result.item.initialAmount, 500);
  });

  testWidgets('a product without a package size for a line in pieces asks how '
      'many, starting at the need', (tester) async {
    final run = await _pick(
      tester,
      item: _food(),
      args: _args(unit: InventoryAmountUnit.piece, need: 3),
      during: () async {
        expect(find.byKey(StockAmountCountRow.countKey), findsOneWidget);
        await tester.tap(find.byKey(InventoryStockAmountPage.applyKey));
        await tester.pumpAndSettle();
      },
    );

    final food = (run.pick! as RecipeFoodNew).food;
    expect(food.request.inventoryAmount, 3 * inventoryPieceAmountScale);
    expect(food.result.item.amountUnit, InventoryAmountUnit.piece);
  });

  testWidgets('closing the amount page picks nothing', (tester) async {
    final run = await _pick(
      tester,
      item: _food(),
      args: _args(),
      during: () async {
        await tester.tap(find.byType(CloseButton));
        await tester.pumpAndSettle();
      },
    );

    expect(run.done, isTrue);
    expect(run.pick, isNull);
  });
}
