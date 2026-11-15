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
    'product_search_hub_mode.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_page.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_recipe_view/product_search_hub_recipe_guess.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_recipe_view/product_search_hub_recipe_view.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_recipe_view/product_search_hub_stock_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/fake_inventory_item_repository.dart';
import '../../../helpers/fake_voice_search_service.dart';

const _openKey = ValueKey<String>('open');
const _searchFieldKey = Key('product_search_hub_search_field');

ProductSearchHubRouteArgs _args({
  Set<String> held = const {},
  String ingredient = '250 g Flour',
  String query = 'Flour',
}) => ProductSearchHubRouteArgs(
  mode: ProductSearchHubMode.mealFood,
  ingredient: ingredient,
  initialQuery: query,
  ingredientUnit: InventoryAmountUnit.gram,
  ingredientNeed: 250,
  takesFromStock: true,
  autofocusSearchField: false,
  heldItemIds: held,
);

InventoryItem _stock(String id, String name) => InventoryItem.create(
  id: id,
  name: name,
  entryDate: DateTime(2026, 11, 12),
  storeName: 'Store',
  quantity: 1,
  weight: '1 kg',
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
  final answer = Completer<FoodEstimate>();

  /// What the estimate was asked for.
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
  Object? popped;
  bool closed = false;
  final estimates = _FakeEstimates();
}

Future<_Run> _open(
  WidgetTester tester, {
  required ProductSearchHubRouteArgs args,
  List<InventoryItem> stockItems = const [],
}) async {
  final run = _Run();
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
        inventoryItemRepositoryProvider.overrideWithValue(
          FakeInventoryItemRepository(stockItems),
        ),
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
  group('held Vorrat foods', () {
    testWidgets('are left out of the "Take from stock" sheet', (tester) async {
      await _open(
        tester,
        args: _args(held: {'flour'}),
        stockItems: [_stock('flour', 'Flour'), _stock('sugar', 'Sugar')],
      );

      await tester.tap(find.byKey(ProductSearchHubRecipeView.stockRowKey));
      await tester.pumpAndSettle();

      expect(find.byKey(RecipeStockSheet.listKey), findsOneWidget);
      expect(find.byKey(const ValueKey('sugar')), findsOneWidget);
      expect(find.byKey(const ValueKey('flour')), findsNothing);
    });

    testWidgets('are no search hits', (tester) async {
      await _open(
        tester,
        args: _args(held: {'flour'}),
        stockItems: [_stock('flour', 'Flour'), _stock('sugar', 'Sugar')],
      );

      await tester.enterText(find.byKey(_searchFieldKey), 'flo');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(
        find.byKey(ProductSearchHubRecipeView.stockHitKey('flour')),
        findsNothing,
      );
    });

    testWidgets('leave no Vorrat row when all of the Vorrat is held', (
      tester,
    ) async {
      await _open(
        tester,
        args: _args(held: {'flour'}),
        stockItems: [_stock('flour', 'Flour')],
      );

      expect(find.byKey(ProductSearchHubRecipeView.stockRowKey), findsNothing);
    });

    testWidgets('do not hide the others when nothing is held', (tester) async {
      await _open(
        tester,
        args: _args(),
        stockItems: [_stock('flour', 'Flour')],
      );

      expect(
        find.byKey(ProductSearchHubRecipeView.stockRowKey),
        findsOneWidget,
      );
    });
  });

  group('"Any will do" while it works', () {
    testWidgets('says what it does and takes no other tap', (tester) async {
      final run = await _open(
        tester,
        args: _args(),
        stockItems: [_stock('flour', 'Flour')],
      );
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ProductSearchHubRecipeView)),
      )!;
      expect(find.text(l10n.recipeFoodGuessLine), findsOneWidget);

      await tester.tap(find.byKey(RecipeGuessButton.buttonKey));
      await tester.pump();

      expect(find.text(l10n.recipeFoodGuessWorking), findsOneWidget);
      expect(find.text(l10n.recipeFoodGuessLine), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // The view takes no taps meanwhile.
      await tester.tap(
        find.byKey(ProductSearchHubRecipeView.stockRowKey),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(find.byKey(RecipeStockSheet.listKey), findsNothing);

      run.estimates.answer.complete(_estimate);
      await tester.pumpAndSettle();

      expect(run.closed, isTrue);
      expect(run.popped, isA<RecipeFoodNew>());
    });

    testWidgets(
      'asks the estimate for the food with the addition of the line',
      (tester) async {
        final run = await _open(
          tester,
          args: _args(
            ingredient: '100 g Frischkäse (Doppelrahmstufe)',
            query: 'Frischkäse',
          ),
        );

        await tester.tap(find.byKey(RecipeGuessButton.buttonKey));
        await tester.pump();

        expect(run.estimates.descriptions, ['Frischkäse (Doppelrahmstufe)']);
      },
    );

    testWidgets('asks for the food alone when the addition names an amount', (
      tester,
    ) async {
      final run = await _open(
        tester,
        args: _args(ingredient: '1 Dose Tomaten (à 400 g)', query: 'Tomaten'),
      );

      await tester.tap(find.byKey(RecipeGuessButton.buttonKey));
      await tester.pump();

      expect(run.estimates.descriptions, ['Tomaten']);
    });

    testWidgets('the back arrow leaves while it works and drops the estimate', (
      tester,
    ) async {
      final run = await _open(
        tester,
        args: _args(),
        stockItems: [_stock('flour', 'Flour')],
      );
      await tester.tap(find.byKey(RecipeGuessButton.buttonKey));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(run.closed, isTrue);
      expect(run.popped, isNull);
      expect(find.byType(ProductSearchHubRecipeView), findsNothing);

      // The estimate that comes later saves and shows nothing.
      run.estimates.answer.complete(_estimate);
      await tester.pumpAndSettle();

      expect(run.popped, isNull);
      expect(find.byType(ProductSearchHubRecipeView), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the back arrow of an idle view leaves with nothing', (
      tester,
    ) async {
      final run = await _open(
        tester,
        args: _args(),
        stockItems: [_stock('flour', 'Flour')],
      );

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(run.closed, isTrue);
      expect(run.popped, isNull);
    });

    testWidgets('takes taps again after a failed estimate', (tester) async {
      final run = await _open(
        tester,
        args: _args(),
        stockItems: [_stock('flour', 'Flour')],
      );

      await tester.tap(find.byKey(RecipeGuessButton.buttonKey));
      await tester.pump();
      run.estimates.answer.completeError(StateError('offline'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ProductSearchHubRecipeView.stockRowKey));
      await tester.pumpAndSettle();

      expect(find.byKey(RecipeStockSheet.listKey), findsOneWidget);
    });
  });
}
