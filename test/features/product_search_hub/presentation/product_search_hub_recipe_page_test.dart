import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/food_estimate.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/recipe_food_pick.dart';
import 'package:yamt/features/product_search_hub/data/'
    'food_estimate_repository.dart';
import 'package:yamt/features/product_search_hub/domain/food_estimate.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_gateway.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_exceptions.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_mode.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_page.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_recipe_view/product_search_hub_recipe_guess.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_recipe_view/product_search_hub_recipe_rows.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_recipe_view/product_search_hub_recipe_view.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_recipe_view/product_search_hub_stock_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/fake_inventory_item_repository.dart';
import '../../../helpers/fake_voice_search_service.dart';

const _openKey = ValueKey<String>('open');
const _searchFieldKey = Key('product_search_hub_search_field');

const _recipeArgs = ProductSearchHubRouteArgs(
  mode: ProductSearchHubMode.mealFood,
  ingredient: '250 g Flour',
  initialQuery: 'Flour',
  ingredientUnit: InventoryAmountUnit.gram,
  ingredientNeed: 250,
  takesFromStock: true,
  autofocusSearchField: false,
);

InventoryItem _stock(String id, String name, {String weight = '1 kg'}) =>
    InventoryItem.create(
      id: id,
      name: name,
      entryDate: DateTime(2026, 11, 12),
      storeName: 'Store',
      quantity: 1,
      weight: weight,
    ).withDerivedAmount();

const _estimate = FoodEstimate(
  name: 'Flour',
  portionGrams: 50,
  kcalLean: 170,
  kcalRich: 190,
  per100: GlobalFoodNutrition(
    qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
    per100Kcal: 350,
  ),
  ingredients: [],
);

class _FakeEstimates implements FoodEstimateRepository {
  new(this.answer);

  final Completer<FoodEstimate> answer;
  final descriptions = <String>[];

  @override
  Future<FoodEstimate> loadEstimate({
    required String description,
    required List<FoodEstimatePhoto> photos,
  }) {
    descriptions.add(description);
    return answer.future;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Run {
  new({required this.stock, required this.estimates});

  final FakeInventoryItemRepository stock;
  final _FakeEstimates estimates;
  Object? popped;
  bool closed = false;
}

/// Opens the food pick with [args] over a caller page; what the pick pops is
/// in the returned run.
Future<_Run> _open(
  WidgetTester tester, {
  ProductSearchHubRouteArgs args = _recipeArgs,
  List<InventoryItem> stockItems = const [],
}) async {
  final run = _Run(
    stock: FakeInventoryItemRepository(stockItems),
    estimates: _FakeEstimates(Completer()),
  );
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: TextButton(
            key: _openKey,
            onPressed: () async {
              final result = await context.push<Object?>(
                AppRoutes.homeProductSearchHub,
              );
              run
                ..popped = result
                ..closed = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.homeProductSearchHub,
        builder: (context, state) => ProductSearchHubPage(
          args: args,
          lookupProducts: ({
            required query,
            required limit,
            store,
            brand,
            weight,
          }) async => ProductSearchHubSearchLookupResult.success(const []),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        voiceSearchServiceProvider.overrideWithValue(FakeVoiceSearchService()),
        inventoryItemRepositoryProvider.overrideWithValue(run.stock),
        foodEstimateRepositoryProvider.overrideWithValue(run.estimates),
      ],
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
  return run;
}

void main() {
  group('the recipe view of the food search', () {
    testWidgets('asks which food: head, scan first, the Vorrat row, the '
        'guess button', (tester) async {
      await _open(tester, stockItems: [_stock('flour', 'Flour')]);

      expect(find.byType(ProductSearchHubRecipeView), findsOneWidget);
      expect(find.text('FOR 250 G FLOUR'), findsOneWidget);
      expect(find.text('What kind of Flour do you have?'), findsOneWidget);
      expect(find.byKey(RecipeScanButton.buttonKey), findsOneWidget);
      expect(find.text('or pick one'), findsOneWidget);
      expect(
        find.byKey(ProductSearchHubRecipeView.stockRowKey),
        findsOneWidget,
      );
      expect(find.byKey(RecipeGuessButton.buttonKey), findsOneWidget);
      // The scan button sits above the search field and the Vorrat row.
      final scanTop = tester.getTopLeft(find.byKey(RecipeScanButton.buttonKey));
      expect(
        scanTop.dy,
        lessThan(tester.getTopLeft(find.byKey(_searchFieldKey)).dy),
      );
      expect(
        tester.getTopLeft(find.byKey(_searchFieldKey)).dy,
        lessThan(
          tester
              .getTopLeft(find.byKey(ProductSearchHubRecipeView.stockRowKey))
              .dy,
        ),
      );
    });

    testWidgets('the normal search mode shows none of it', (tester) async {
      await _open(
        tester,
        args: const ProductSearchHubRouteArgs(
          mode: ProductSearchHubMode.mealFood,
          autofocusSearchField: false,
        ),
        stockItems: [_stock('flour', 'Flour')],
      );

      expect(find.byType(ProductSearchHubRecipeView), findsNothing);
      expect(find.byKey(RecipeScanButton.buttonKey), findsNothing);
      expect(find.byKey(ProductSearchHubRecipeView.stockRowKey), findsNothing);
      expect(find.byKey(RecipeGuessButton.buttonKey), findsNothing);
      expect(find.text('or pick one'), findsNothing);
    });

    testWidgets('without a Vorrat there is no Vorrat row', (tester) async {
      await _open(tester);

      expect(find.byType(ProductSearchHubRecipeView), findsOneWidget);
      expect(find.byKey(ProductSearchHubRecipeView.stockRowKey), findsNothing);
    });

    testWidgets('a caller that does not take the Vorrat gets no Vorrat row', (
      tester,
    ) async {
      await _open(
        tester,
        args: const ProductSearchHubRouteArgs(
          mode: ProductSearchHubMode.mealFood,
          ingredient: '250 g Flour',
          initialQuery: 'Flour',
          ingredientUnit: InventoryAmountUnit.gram,
          ingredientNeed: 250,
          autofocusSearchField: false,
        ),
        stockItems: [_stock('flour', 'Flour')],
      );

      expect(find.byKey(ProductSearchHubRecipeView.stockRowKey), findsNothing);
    });

    testWidgets('"Take from stock" returns the chosen Vorrat food, nothing '
        'new is created', (tester) async {
      final flour = _stock('flour', 'Flour');
      final run = await _open(
        tester,
        stockItems: [flour, _stock('sugar', 'Sugar')],
      );

      await tester.tap(find.byKey(ProductSearchHubRecipeView.stockRowKey));
      await tester.pumpAndSettle();
      expect(find.byKey(RecipeStockSheet.listKey), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('flour')));
      await tester.pumpAndSettle();

      expect(run.closed, isTrue);
      final pick = run.popped! as RecipeFoodInStock;
      expect(pick.items.map((item) => item.id), ['flour']);
      expect(run.stock.items.map((item) => item.id), ['flour', 'sugar']);
    });

    testWidgets('a Vorrat food that matches the search is a hit and returns '
        'as the Vorrat food', (tester) async {
      final run = await _open(
        tester,
        stockItems: [_stock('flour', 'Flour'), _stock('sugar', 'Sugar')],
      );

      await tester.enterText(find.byKey(_searchFieldKey), 'sug');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(
        find.byKey(ProductSearchHubRecipeView.stockHitKey('flour')),
        findsNothing,
      );
      await tester.tap(
        find.byKey(ProductSearchHubRecipeView.stockHitKey('sugar')),
      );
      await tester.pumpAndSettle();

      final pick = run.popped! as RecipeFoodInStock;
      expect(pick.items.single.id, 'sugar');
    });
  });

  group('"Any will do"', () {
    testWidgets('asks the estimate with the food name and returns a food that '
        'is marked estimated and holds exactly the need', (tester) async {
      final run = await _open(tester);

      await tester.tap(find.byKey(RecipeGuessButton.buttonKey));
      await tester.pump();
      expect(run.estimates.descriptions, ['Flour']);
      // While the estimate runs, the button waits.
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(RecipeGuessButton.buttonKey))
            .onPressed,
        isNull,
      );
      run.estimates.answer.complete(_estimate);
      await tester.pumpAndSettle();

      expect(run.closed, isTrue);
      final pick = run.popped! as RecipeFoodNew;
      expect(pick.food.result.item.aiEstimated, isTrue);
      expect(pick.food.result.item.name, 'Flour');
      expect(pick.food.request.inventoryAmount, 250);
      expect(pick.food.result.item.currentAmount, 250);
      expect(pick.food.result.requiresGlobalPersistence, isFalse);
      // Nothing is stored by the pick itself.
      expect(run.stock.items, isEmpty);
    });

    testWidgets('a failing estimate shows the error and creates nothing', (
      tester,
    ) async {
      final run = await _open(tester);

      await tester.tap(find.byKey(RecipeGuessButton.buttonKey));
      await tester.pump();
      run.estimates.answer.completeError(const FoodEstimateNotFoodException());
      await tester.pumpAndSettle();

      expect(run.closed, isFalse);
      expect(run.popped, isNull);
      expect(find.byKey(RecipeGuessButton.errorKey), findsOneWidget);
      expect(run.stock.items, isEmpty);
      // The button can be pressed again.
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(RecipeGuessButton.buttonKey))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('a line without an amount has no button', (tester) async {
      await _open(
        tester,
        args: const ProductSearchHubRouteArgs(
          mode: ProductSearchHubMode.mealFood,
          ingredient: 'Salt',
          initialQuery: 'Salt',
          autofocusSearchField: false,
        ),
      );

      expect(find.byType(ProductSearchHubRecipeView), findsOneWidget);
      expect(find.byKey(RecipeGuessButton.buttonKey), findsNothing);
    });
  });
}
