import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/diary/presentation/diary_product_search_hub_completion_handler.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/inventory_combine_pick_page.dart';
import 'package:yamt/features/inventory/presentation/inventory_manual_product_eat_coordinator.dart';
import 'package:yamt/features/inventory/presentation/inventory_product_search_hub_completion_handler.dart';
import 'package:yamt/features/inventory/presentation/inventory_stock_add_page.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_page_scaffold.dart';
import 'package:yamt/features/product_search_hub/application/product_search_hub_completion_providers.dart';
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

import '../../test/features/calories/support/fake_planned_entry_repository.dart';
import '../../test/helpers/inventory_item_whole_list_writes.dart';

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
  List<Override> overrides = const <Override>[],
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

  // Signed out. The recent items of the search read the Vorrat repository,
  // which reaches Firebase Auth and the user profile. The fakes start with
  // their value: a provider first read under the fullscreen eat page starts
  // paused, so a fake stream would never emit and would still be loading
  // when the test disposes the container.
  final container = ProviderContainer(
    overrides: [
      authStateChangesProvider.overrideWithValue(const AsyncData<User?>(null)),
      firebaseFirestoreProvider.overrideWith((ref) => null),
      userProfileProvider.overrideWithValue(const AsyncData(null)),
      ...overrides,
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

  testWidgets('a food searched for tomorrow becomes a plan', (tester) async {
    final plans = FakePlannedEntryRepository();
    final user = _MockUser();
    when(() => user.uid).thenReturn('user-1');
    final auth = _MockFirebaseAuth();
    when(() => auth.currentUser).thenReturn(user);
    await tester.pumpWidget(
      _buildHarness(
        args: ProductSearchHubRouteArgs.diary(
          initialIntent: ProductSearchHubInitialIntent.search,
          preselectedMealType: MealType.lunch,
          preselectedLoggedAt: DateTime(2026, 5, 14, 12),
        ),
        open: (context) => context.push<void>(AppRoutes.homeFoodPick),
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          plannedEntryRepositoryProvider.overrideWithValue(plans),
          clockProvider.overrideWithValue(() => DateTime(2026, 5, 13, 20)),
          // Wired in main.dart for the app.
          productSearchHubCompletionHandlerFactoryProvider.overrideWith((ref) {
            final container = ref.container;
            return (mode) => DiaryProductSearchHubCompletionHandler(
              eatCoordinator: container.read(
                inventoryManualProductEatCoordinatorProvider,
              ),
            );
          }),
        ],
      ),
    );
    await _pumpVisibleStep(tester);

    await tester.tap(find.byKey(_openKey));
    await _pumpVisibleStep(tester, observeFor: const Duration(seconds: 1));
    await _openMilkEatPage(tester);
    await tester.enterText(find.byKey(_amountFieldKey), '250');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await _waitForKeyboardClosed(tester);
    await tester.tap(find.byKey(_addKey));
    await _pumpVisibleStep(tester, observeFor: const Duration(seconds: 1));

    final plan = plans.plans.single;
    expect(plan.name, 'Vollmilch');
    expect(plan.consumedAmount, 250);
    expect(plan.loggedAt, DateTime(2026, 5, 14, 12));
    // The food stays out of the Vorrat, so the plan names no Vorrat item.
    expect(plan.sourceInventoryItemId, isNull);
    expect(find.byKey(_openKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a food searched in the diary goes into the Vorrat instead', (
    tester,
  ) async {
    final plans = FakePlannedEntryRepository();
    final items = _FakeItems();
    final user = _MockUser();
    when(() => user.uid).thenReturn('user-1');
    final auth = _MockFirebaseAuth();
    when(() => auth.currentUser).thenReturn(user);
    await tester.pumpWidget(
      _buildHarness(
        args: ProductSearchHubRouteArgs.diary(
          initialIntent: ProductSearchHubInitialIntent.search,
          preselectedMealType: MealType.lunch,
          preselectedLoggedAt: DateTime(2026, 5, 13, 12),
        ),
        open: (context) => context.push<void>(AppRoutes.homeFoodPick),
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          plannedEntryRepositoryProvider.overrideWithValue(plans),
          inventoryItemRepositoryProvider.overrideWithValue(items),
          clockProvider.overrideWithValue(() => DateTime(2026, 5, 13, 20)),
          // Wired in main.dart for the app.
          productSearchHubCompletionHandlerFactoryProvider.overrideWith((ref) {
            final container = ref.container;
            return (mode) => switch (mode) {
              ProductSearchHubMode.inventory =>
                const InventoryProductSearchHubCompletionHandler(),
              _ => DiaryProductSearchHubCompletionHandler(
                eatCoordinator: container.read(
                  inventoryManualProductEatCoordinatorProvider,
                ),
              ),
            };
          }),
        ],
      ),
    );
    await _pumpVisibleStep(tester);

    await tester.tap(find.byKey(_openKey));
    await _pumpVisibleStep(tester, observeFor: const Duration(seconds: 1));
    await _openMilkEatPage(tester);
    await tester.tap(find.byKey(EatPageScaffold.storeButtonKey));
    await _pumpVisibleStep(tester, observeFor: const Duration(seconds: 1));

    // The Vorrat page takes over, as from the Vorrat search.
    expect(find.byKey(InventoryStockAddPage.confirmKey), findsOneWidget);
    await tester.tap(find.byKey(InventoryStockAddPage.confirmKey));
    await _pumpVisibleStep(tester, observeFor: const Duration(seconds: 1));

    expect(items.items.single.name, 'Vollmilch');
    expect(plans.plans, isEmpty);
    // It ends like one eaten food: the search closes.
    expect(find.byKey(_openKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _MockFirebaseAuth extends Mock implements FirebaseAuth;

/// Vorrat repository that keeps what the test saves.
class _FakeItems with InventoryItemWholeListWrites {
  List<InventoryItem> items = const [];

  @override
  Stream<List<InventoryItem>> watchAll() => Stream.value(items);

  @override
  Future<List<InventoryItem>> readAll() async => items;

  @override
  Future<bool> replaceItems(List<InventoryItem> items) async {
    this.items = items;
    return true;
  }

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    this.items = [...this.items, ...items];
    return true;
  }
}

class _MockUser extends Mock implements User;
