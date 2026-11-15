import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/inventory/presentation/inventory_stock_amount_page.dart';
import 'package:yamt/features/inventory/presentation/models/food_pick_route_args.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'prepared_meal_food_source.dart';
import 'package:yamt/features/inventory/presentation/models/recipe_food_pick.dart';
import 'package:yamt/features/inventory/presentation/'
    'prepared_meal_pending_food_flow.dart';
import 'package:yamt/features/inventory/presentation/widgets/stock_amount/'
    'stock_amount_inputs.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/fake_inventory_item_repository.dart';

const _openKey = ValueKey<String>('open');

InventoryItem _food({required InventoryAmountUnit unit, double? pieceWeight}) =>
    InventoryItem.create(
      id: 'draft',
      name: 'Eggs',
      entryDate: DateTime(2026, 11, 12),
      storeName: 'Store',
      quantity: 1,
      weight: unit == InventoryAmountUnit.piece ? '6 Stück' : '1000 g',
      initialAmount: unit == InventoryAmountUnit.piece ? 6000 : 1000,
      currentAmount: unit == InventoryAmountUnit.piece ? 6000 : 1000,
      amountScale: unit == InventoryAmountUnit.piece
          ? inventoryPieceAmountScale
          : 1,
      amountUnit: unit,
      servingQuantity: pieceWeight,
      servingQuantityUnit: pieceWeight == null ? null : 'g',
    );

RecipeFoodNew _pick(
  InventoryItem item, {
  required int amount,
  double? typedWeight,
}) => RecipeFoodNew((
  result: InventoryReceiptManualProductResult(
    item: item,
    action: InventoryReceiptManualProductAction.addToInventory,
    requiresGlobalPersistence: false,
    skipMissingBarcodePrompt: true,
  ),
  request: InventoryItemEatRequest(
    inventoryAmount: amount,
    loggedAt: DateTime(2026, 11, 12, 12),
    mealType: MealType.lunch,
    portionBaseAmount: typedWeight,
    portionBaseUnit: typedWeight == null ? null : ConsumedUnit.grams,
    portionCount: typedWeight == null ? null : amount.toDouble(),
  ),
));

/// Runs `fill` with the food pick answering [pick]; returns what the pick
/// route was opened with, the fill result, and what `onFill` and `onTake`
/// got.
Future<
  ({
    FoodPickRouteArgs? opened,
    bool? filled,
    InventoryItem? filledItem,
    int? filledAmount,
    List<InventoryItem>? taken,
    FakeInventoryItemRepository stock,
  })
>
_fill(
  WidgetTester tester, {
  required RecipeFoodPick? pick,
  String? query,
  String? ingredient = '3 Eggs',
  int? pieceWeight,
  TemplateIngredientRequirement? need,
  bool fillSucceeds = true,
}) async {
  final stock = FakeInventoryItemRepository(const []);
  FoodPickRouteArgs? opened;
  bool? filled;
  InventoryItem? filledItem;
  int? filledAmount;
  List<InventoryItem>? taken;
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: TextButton(
            key: _openKey,
            onPressed: () async {
              filled = await PreparedMealPendingFoodFlow.fill(
                context: context,
                source: PreparedMealFoodSource.search,
                query: query,
                ingredient: ingredient,
                pieceWeight: pieceWeight,
                need: need,
                onTake: (items) async {
                  taken = items;
                  return true;
                },
                onFill: (item, amount) async {
                  filledItem = item;
                  filledAmount = amount;
                  return fillSucceeds;
                },
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.homeFoodPick,
        builder: (context, state) {
          opened = state.extra as FoodPickRouteArgs?;
          return Scaffold(
            body: TextButton(
              onPressed: () => context.pop(pick),
              child: const Text('pick'),
            ),
          );
        },
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [inventoryItemRepositoryProvider.overrideWithValue(stock)],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.tap(find.byKey(_openKey));
  await tester.pumpAndSettle();
  await tester.tap(find.text('pick'));
  await tester.pumpAndSettle();
  return (
    opened: opened,
    filled: filled,
    filledItem: filledItem,
    filledAmount: filledAmount,
    taken: taken,
    stock: stock,
  );
}

void main() {
  testWidgets('opens the food pick with the query, ingredient, piece weight '
      'and need', (tester) async {
    final run = await _fill(
      tester,
      pick: null,
      query: 'Eggs',
      pieceWeight: 60,
      need: const TemplateIngredientRequirement(
        amount: 3,
        unit: TemplateIngredientUnit.piece,
        name: 'Eggs',
      ),
    );

    final opened = run.opened!;
    expect(opened.query, 'Eggs');
    expect(opened.ingredient, '3 Eggs');
    expect(opened.pieceWeight, 60);
    expect(opened.ingredientUnit, InventoryAmountUnit.piece);
    expect(opened.ingredientNeed, 3);
    expect(opened.takesFromStock, isTrue);
    // Closing the pick is a cancel.
    expect(run.filled, isNull);
    expect(run.filledItem, isNull);
  });

  testWidgets('a food in pieces keeps the typed piece weight as its serving '
      'quantity', (tester) async {
    final run = await _fill(
      tester,
      pick: _pick(
        _food(unit: InventoryAmountUnit.piece),
        amount: 3000,
        typedWeight: 60,
      ),
    );

    expect(run.filled, isTrue);
    expect(run.filledAmount, 3000);
    expect(run.filledItem?.servingQuantity, 60);
    expect(run.filledItem?.servingQuantityUnit, 'g');
    expect(run.stock.items.single.servingQuantity, 60);
    expect(run.stock.items.single.name, 'Eggs');
  });

  testWidgets('a piece weight the food already has stays', (tester) async {
    final run = await _fill(
      tester,
      pick: _pick(
        _food(unit: InventoryAmountUnit.piece, pieceWeight: 45),
        amount: 3000,
        typedWeight: 60,
      ),
    );

    expect(run.filledItem?.servingQuantity, 45);
  });

  testWidgets(
    'a food without a package size keeps the typed piece weight too',
    (tester) async {
      final run = await _fill(
        tester,
        pick: _pick(
          InventoryItem.create(
            id: 'draft',
            name: 'Eggs',
            entryDate: DateTime(2026, 11, 12),
            storeName: 'Store',
            quantity: 3,
          ),
          amount: 3,
          typedWeight: 60,
        ),
      );

      // Pieces are kept in thousandths; the weight is the serving size.
      expect(run.filledAmount, 3000);
      expect(run.filledItem?.amountUnit, InventoryAmountUnit.piece);
      expect(run.filledItem?.amountScale, inventoryPieceAmountScale);
      expect(run.filledItem?.servingQuantity, 60);
      expect(run.filledItem?.servingQuantityUnit, 'g');
    },
  );

  testWidgets('a food in grams takes no piece weight', (tester) async {
    final run = await _fill(
      tester,
      pick: _pick(
        _food(unit: InventoryAmountUnit.gram),
        amount: 250,
        typedWeight: 60,
      ),
    );

    expect(run.filledAmount, 250);
    expect(run.filledItem?.servingQuantity, isNull);
  });

  testWidgets('a food that the row cannot take leaves the Vorrat again', (
    tester,
  ) async {
    final run = await _fill(
      tester,
      pick: _pick(_food(unit: InventoryAmountUnit.gram), amount: 250),
      fillSucceeds: false,
    );

    expect(run.filled, isFalse);
    expect(run.stock.items, isEmpty);
  });

  testWidgets('a food that is in the Vorrat goes to onTake, nothing is added', (
    tester,
  ) async {
    final inStock = _food(unit: InventoryAmountUnit.gram);
    final run = await _fill(tester, pick: RecipeFoodInStock([inStock]));

    expect(run.filled, isTrue);
    expect(run.taken, [inStock]);
    expect(run.filledItem, isNull);
    expect(run.stock.items, isEmpty);
  });

  testWidgets('a new food goes to onFill, never to onTake', (tester) async {
    final run = await _fill(
      tester,
      pick: _pick(_food(unit: InventoryAmountUnit.gram), amount: 250),
    );

    expect(run.filled, isTrue);
    expect(run.filledAmount, 250);
    expect(run.taken, isNull);
  });

  group('recount', () {
    // A food without a package size: the amount page asks for its weight.
    final loose = InventoryItem.create(
      id: 'flour',
      name: 'Flour',
      entryDate: DateTime(2026, 11, 12),
      storeName: 'Store',
      quantity: 1,
    );
    const need = TemplateIngredientRequirement(
      amount: 250,
      unit: TemplateIngredientUnit.gram,
      name: 'Flour',
    );

    /// Opens "Ändern" for [loose], lets [drive] work the amount page, and
    /// returns what recount returned and the Vorrat.
    Future<
      ({InventoryItem? saved, bool done, FakeInventoryItemRepository stock})
    >
    recount(
      WidgetTester tester, {
      required Future<void> Function() drive,
      bool saves = true,
    }) async {
      final stock = FakeInventoryItemRepository([loose])..saves = saves;
      InventoryItem? saved;
      var done = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [inventoryItemRepositoryProvider.overrideWithValue(stock)],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  key: _openKey,
                  onPressed: () async {
                    saved = await PreparedMealPendingFoodFlow.recount(
                      context: context,
                      item: loose,
                      need: need,
                    );
                    done = true;
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(_openKey));
      await tester.pumpAndSettle();
      await drive();
      return (saved: saved, done: done, stock: stock);
    }

    Future<void> type(WidgetTester tester, String text) async {
      await tester.enterText(find.byKey(StockAmountField.fieldKey), text);
      await tester.pump();
      await tester.tap(find.byKey(InventoryStockAmountPage.applyKey));
      await tester.pumpAndSettle();
    }

    testWidgets('saves the counted amount and returns the saved food', (
      tester,
    ) async {
      final run = await recount(tester, drive: () => type(tester, '750'));

      expect(run.done, isTrue);
      expect(run.saved?.initialAmount, 750);
      expect(run.saved?.amountUnit, InventoryAmountUnit.gram);
      expect(run.stock.items.single.id, 'flour');
      expect(run.stock.items.single.currentAmount, 750);
    });

    testWidgets('returns null and saves nothing when the cook leaves the '
        'page', (tester) async {
      final run = await recount(
        tester,
        drive: () async {
          await tester.tap(find.byType(CloseButton));
          await tester.pumpAndSettle();
        },
      );

      expect(run.done, isTrue);
      expect(run.saved, isNull);
      expect(run.stock.items.single.currentAmount, loose.currentAmount);
    });

    testWidgets('a failed save returns null and says so', (tester) async {
      final run = await recount(
        tester,
        saves: false,
        drive: () => type(tester, '750'),
      );

      expect(run.done, isTrue);
      expect(run.saved, isNull);
      expect(find.text('Action failed. Please try again.'), findsOneWidget);
      expect(run.stock.items.single.currentAmount, loose.currentAmount);
    });
  });
}
