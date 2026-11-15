import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
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
import 'package:yamt/features/inventory/presentation/'
    'prepared_meal_pending_food_flow.dart';
import 'package:yamt/features/inventory/presentation/widgets/stock_amount/'
    'stock_amount_inputs.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_mode.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_recipe_food_flow.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/helpers/fake_inventory_item_repository.dart';

const _recountKey = Key('recount');
const _pickKey = Key('pick');

// A food without a package size: the app cannot know how much is at home.
final _loose = InventoryItem.create(
  id: 'flour',
  name: 'Flour',
  entryDate: DateTime(2026, 11, 12),
  storeName: 'Store',
  quantity: 1,
);

const _need = TemplateIngredientRequirement(
  amount: 250,
  unit: TemplateIngredientUnit.gram,
  name: 'Flour',
);

const _args = ProductSearchHubRouteArgs(
  mode: ProductSearchHubMode.mealFood,
  ingredient: '250 g Flour',
  initialQuery: 'Flour',
  ingredientUnit: InventoryAmountUnit.gram,
  ingredientNeed: 250,
  takesFromStock: true,
);

Future<
  ({
    FakeInventoryItemRepository stock,
    List<InventoryItem?> recounted,
    List<RecipeFoodPick?> picked,
  })
>
_pump(WidgetTester tester) async {
  final stock = FakeInventoryItemRepository([_loose]);
  final recounted = <InventoryItem?>[];
  final picked = <RecipeFoodPick?>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [inventoryItemRepositoryProvider.overrideWithValue(stock)],
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Consumer(
          builder: (context, ref, _) {
            ref.watch(inventoryQuickEatItemsProvider);
            return Scaffold(
              body: Column(
                children: [
                  TextButton(
                    key: _recountKey,
                    onPressed: () async => recounted.add(
                      await PreparedMealPendingFoodFlow.recount(
                        context: context,
                        item: _loose,
                        need: _need,
                      ),
                    ),
                    child: const Text('Ändern'),
                  ),
                  TextButton(
                    key: _pickKey,
                    onPressed: () async => picked.add(
                      (await pickProductSearchHubRecipeFood(
                        context: context,
                        args: _args,
                        result: InventoryReceiptManualProductResult(
                          item: _loose,
                          action: InventoryReceiptManualProductAction
                              .addToInventory,
                          requiresGlobalPersistence: false,
                        ),
                      )).pick,
                    ),
                    child: const Text('Wählen'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (stock: stock, recounted: recounted, picked: picked);
}

Future<void> _typeAndConfirm(WidgetTester tester, String amount) async {
  expect(find.byType(InventoryStockAmountPage), findsOneWidget);
  await tester.enterText(find.byKey(StockAmountField.fieldKey), amount);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(InventoryStockAmountPage.applyKey));
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a food without a package size asks for the amount and the '
      'Vorrat keeps what the cook typed', (tester) async {
    final run = await _pump(tester);

    await tester.tap(find.byKey(_recountKey));
    await tester.pumpAndSettle();
    // Nothing can be confirmed before an amount is typed.
    expect(
      tester
          .widget<FilledButton>(find.byKey(InventoryStockAmountPage.applyKey))
          .onPressed,
      isNull,
    );
    await _typeAndConfirm(tester, '750');

    expect(find.byType(InventoryStockAmountPage), findsNothing);
    expect(run.recounted.single?.currentAmount, 750);
    expect(run.stock.items.single.id, 'flour');
    expect(run.stock.items.single.currentAmount, 750);
    expect(run.stock.items.single.amountUnit, InventoryAmountUnit.gram);
  });

  testWidgets('picking such a food for a recipe line asks for the amount '
      'and returns the food with it', (tester) async {
    final run = await _pump(tester);

    await tester.tap(find.byKey(_pickKey));
    await tester.pumpAndSettle();
    await _typeAndConfirm(tester, '500');

    final food = (run.picked.single! as RecipeFoodNew).food;
    expect(food.request.inventoryAmount, 500);
    expect(food.result.item.initialAmount, 500);
  });

  testWidgets('closing the amount page leaves the Vorrat as it was', (
    tester,
  ) async {
    final run = await _pump(tester);

    await tester.tap(find.byKey(_recountKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();

    expect(run.recounted.single, isNull);
    expect(run.stock.items.single.currentAmount, _loose.currentAmount);
  });
}
