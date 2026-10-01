import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/inventory_combine_pick_page.dart';
import 'package:yamt/features/product_search_hub/domain/product_search_gateway.dart';
import 'package:yamt/features/product_search_hub/domain/product_search_hub_mode.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/product_search_hub_meal_food_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/product_search_hub_page.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_form_details.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_page_route.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _openKey = Key('open_combine_pick');
const _amountFieldKey = Key('eat_page_amount_field');
const _addKey = Key('inventory_item_amount_dialog_confirm_button');
const _resultKey = Key('product_search_hub_search_result_4006381333931');

const _milk = OffProductSearchResult(
  code: '4006381333931',
  name: 'Vollmilch',
  brand: 'Weihenstephan',
  score: 1,
  packageWeight: '1000 g',
  nutrition: GlobalFoodNutrition(
    qualityStatus: GlobalFoodNutritionQualityStatus.verified,
    per100Kcal: 64,
    per100Carbs: 4.8,
    per100Protein: 3.4,
    per100Fat: 3.5,
  ),
);

Widget _buildHarness({
  required ValueChanged<InventoryCombinePickResult?> onDone,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) => Scaffold(
          body: Center(
            child: FilledButton(
              key: _openKey,
              onPressed: () async => onDone(
                await showInventoryCombinePickPage(
                  context,
                  candidates: const <InventoryItem>[],
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.homeFoodPick,
        builder: (context, state) => ProductSearchHubPage(
          args: const ProductSearchHubRouteArgs(
            mode: ProductSearchHubMode.mealFood,
            initialIntent: ProductSearchHubInitialIntent.search,
          ),
          lookupProducts: ({
            required query,
            required limit,
            store,
            brand,
            weight,
          }) async => ProductSearchHubSearchLookupResult.success(const [_milk]),
        ),
      ),
      GoRoute(
        path: AppRoutes.productSearchChildFlow,
        redirect: redirectInvalidManualProductSearchRoute,
        pageBuilder: buildManualProductSearchRoutePage,
      ),
    ],
  );
  addTearDown(router.dispose);

  final container = ProviderContainer();
  addTearDown(container.dispose);

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      locale: const Locale('en'),
      routerConfig: router,
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

Future<void> _pumpVisibleStep(
  WidgetTester tester, {
  Duration observeFor = const Duration(milliseconds: 600),
}) async {
  await tester.pump();
  await Future<void>.delayed(observeFor);
  await tester.pump();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('a searched food opens on its eat page and joins the meal', (
    tester,
  ) async {
    InventoryCombinePickResult? result;
    await tester.pumpWidget(_buildHarness(onDone: (value) => result = value));
    await _pumpVisibleStep(tester);

    await tester.tap(find.byKey(_openKey));
    await _pumpVisibleStep(tester);
    await tester.tap(find.byKey(InventoryCombinePickPage.searchKey));
    await _pumpVisibleStep(tester, observeFor: const Duration(seconds: 1));
    expect(find.byType(ProductSearchHubPage), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('product_search_hub_search_field')),
      'Milch',
    );
    // The search key closes the keyboard, so the eat page gets the full
    // screen.
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _pumpVisibleStep(tester, observeFor: const Duration(seconds: 1));
    await tester.tap(find.byKey(_resultKey));
    await _pumpVisibleStep(tester, observeFor: const Duration(seconds: 1));

    // The eat page opens, not the product editor.
    expect(find.byKey(_amountFieldKey), findsOneWidget);
    expect(find.byKey(ManualProductDetailsForm.saveKey), findsNothing);

    // "Bearbeiten" opens the editor; leaving it comes back to the eat page.
    await tester.ensureVisible(find.byKey(productSearchHubMealFoodEditKey));
    await _pumpVisibleStep(tester);
    await tester.tap(find.byKey(productSearchHubMealFoodEditKey));
    await _pumpVisibleStep(tester, observeFor: const Duration(seconds: 1));
    expect(find.byKey(ManualProductDetailsForm.saveKey), findsOneWidget);

    await tester.binding.handlePopRoute();
    await _pumpVisibleStep(tester, observeFor: const Duration(seconds: 1));
    expect(find.byKey(_amountFieldKey), findsOneWidget);

    await tester.enterText(find.byKey(_amountFieldKey), '250');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await _pumpVisibleStep(tester);
    await tester.tap(find.byKey(_addKey));
    await _pumpVisibleStep(tester, observeFor: const Duration(seconds: 1));

    expect(find.byKey(_openKey), findsOneWidget);
    final searched = result?.searched;
    expect(searched?.result.item.name, 'Vollmilch');
    expect(searched?.request.inventoryAmount, 250);
    expect(tester.takeException(), isNull);
  });
}
