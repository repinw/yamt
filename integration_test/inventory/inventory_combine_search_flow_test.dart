import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
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

const _mealFoodArgs = ProductSearchHubRouteArgs(
  mode: ProductSearchHubMode.mealFood,
  initialIntent: ProductSearchHubInitialIntent.search,
);

/// Opens the search for a meal from the combine pick page by default.
Widget _buildHarness({
  required Future<void> Function(BuildContext context) open,
  ProductSearchHubRouteArgs args = _mealFoodArgs,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) => Scaffold(
          body: Center(
            child: FilledButton(
              key: _openKey,
              onPressed: () => open(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.homeFoodPick,
        builder: (context, state) => ProductSearchHubPage(
          args: args,
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

  // Signed out, as in the diary flow tests. The recent items of the search
  // read the Vorrat repository, which reaches Firebase Auth and the user
  // profile; without these fakes they fail or are still loading when the
  // test disposes the container.
  final container = ProviderContainer(
    overrides: [
      authStateChangesProvider.overrideWith((ref) => Stream<User?>.value(null)),
      firebaseFirestoreProvider.overrideWith((ref) => null),
      userProfileProvider.overrideWith((ref) => Stream.value(null)),
    ],
  );
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

/// Waits until the soft keyboard that `enterText` opened is gone
/// again. The emulator keyboard can show up seconds after the key that
/// closes it, so this waits for it to open and then to close, at most
/// [timeout]. Without a keyboard it returns after the timeout.
Future<void> _waitForKeyboardClosed(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  const step = Duration(milliseconds: 100);
  var seenOpen = false;
  for (var waited = Duration.zero; waited < timeout; waited += step) {
    await tester.pump();
    final isOpen = tester.view.viewInsets.bottom > 0;
    if (isOpen) {
      seenOpen = true;
    } else if (seenOpen) {
      break;
    }
    await Future<void>.delayed(step);
  }
  expect(
    tester.view.viewInsets.bottom,
    0,
    reason: 'The keyboard is still open after $timeout.',
  );
  await _pumpVisibleStep(tester);
}

/// Searches for milk and opens the result on its eat page.
Future<void> _openMilkEatPage(WidgetTester tester) async {
  expect(find.byType(ProductSearchHubPage), findsOneWidget);
  await tester.enterText(
    find.byKey(const Key('product_search_hub_search_field')),
    'Milch',
  );
  // The search key closes the keyboard, so the eat page gets the full
  // screen.
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await _waitForKeyboardClosed(tester);
  await tester.tap(find.byKey(_resultKey));
  await _pumpVisibleStep(tester, observeFor: const Duration(seconds: 1));

  // The eat page opens, not the product editor.
  expect(find.byKey(_amountFieldKey), findsOneWidget);
  expect(find.byKey(ManualProductDetailsForm.saveKey), findsNothing);
}

/// "Bearbeiten" opens the editor; leaving it comes back to the eat page.
Future<void> _editAndComeBack(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(productSearchHubEatPageEditKey));
  await _pumpVisibleStep(tester);
  await tester.tap(find.byKey(productSearchHubEatPageEditKey));
  await _pumpVisibleStep(tester, observeFor: const Duration(seconds: 1));
  expect(find.byKey(ManualProductDetailsForm.saveKey), findsOneWidget);

  await tester.binding.handlePopRoute();
  await _pumpVisibleStep(tester, observeFor: const Duration(seconds: 1));
  expect(find.byKey(_amountFieldKey), findsOneWidget);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('a searched food opens on its eat page and joins the meal', (
    tester,
  ) async {
    InventoryCombinePickResult? result;
    await tester.pumpWidget(
      _buildHarness(
        open: (context) async => result = await showInventoryCombinePickPage(
          context,
          candidates: const <InventoryItem>[],
        ),
      ),
    );
    await _pumpVisibleStep(tester);

    await tester.tap(find.byKey(_openKey));
    await _pumpVisibleStep(tester);
    await tester.tap(find.byKey(InventoryCombinePickPage.searchKey));
    await _pumpVisibleStep(tester, observeFor: const Duration(seconds: 1));
    await _openMilkEatPage(tester);
    await _editAndComeBack(tester);

    await tester.enterText(find.byKey(_amountFieldKey), '250');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await _waitForKeyboardClosed(tester);
    await tester.tap(find.byKey(_addKey));
    await _pumpVisibleStep(tester, observeFor: const Duration(seconds: 1));

    expect(find.byKey(_openKey), findsOneWidget);
    final searched = result?.searched;
    expect(searched?.result.item.name, 'Vollmilch');
    expect(searched?.request.inventoryAmount, 250);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a food searched in the diary opens the editor from its eat page',
    (tester) async {
      await tester.pumpWidget(
        _buildHarness(
          args: const ProductSearchHubRouteArgs.diary(
            initialIntent: ProductSearchHubInitialIntent.search,
          ),
          open: (context) => context.push<void>(AppRoutes.homeFoodPick),
        ),
      );
      await _pumpVisibleStep(tester);

      await tester.tap(find.byKey(_openKey));
      await _pumpVisibleStep(tester, observeFor: const Duration(seconds: 1));
      await _openMilkEatPage(tester);
      await _editAndComeBack(tester);
      expect(tester.takeException(), isNull);
    },
  );
}
