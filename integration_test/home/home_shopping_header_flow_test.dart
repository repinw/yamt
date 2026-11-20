import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/constants/app_shopping_constants.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/widgets/home_bottom_nav_bar.dart';
import 'package:yamt/core/widgets/home_header_tool.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/data/closed_day_repository.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/cookbook_new/presentation/cookbook_page.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_home_shell_top_chrome.dart';
import 'package:yamt/features/home/home_page.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_home_shell_top_chrome.dart';
import 'package:yamt/features/recipes/data/cook_run_repository.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/presentation/shopping_list_page.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/'
    'shopping_header_tool.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/'
    'shopping_list_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/calories/support/fake_planned_entry_repository.dart';
import '../../test/features/shoppinglist/support/fake_shopping_list_repository.dart';
import '../../test/helpers/fake_cook_run_repository.dart';
import '../../test/helpers/fake_prepared_meal_repository.dart';
import '../../test/helpers/fake_prepared_meal_template_repository.dart';
import '../../test/helpers/fake_signed_in_user.dart';
import '../../test/helpers/inventory_item_whole_list_writes.dart';
import '../../test/helpers/memory_app_preferences.dart';

ShoppingListItem _item(String id, String name, {bool isPrivate = false}) =>
    ShoppingListItem(
      id: id,
      name: name,
      normalizedName: name.toLowerCase(),
      normalizedBrand: '',
      quantity: 1,
      estimatedUnitPrice: 0,
      isPrivate: isPrivate,
    );

GoRoute _placeholder(String path) => GoRoute(
  path: path,
  builder: (context, state) => const Scaffold(body: SizedBox.expand()),
);

/// The home shell with the real header of each tab and the real shopping
/// list page behind the header tool.
class _Harness {
  new(List<ShoppingListItem> items)
    : repository = FakeShoppingListRepository(initialItems: items) {
    router = GoRouter(
      initialLocation: AppRoutes.homeDiary,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              HomePage(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.homeInventory,
                  builder: (context, state) => const CustomScrollView(
                    slivers: [
                      InventoryHomeShellTopChrome(),
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: SizedBox(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.homeDiary,
                  builder: (context, state) => const Column(
                    children: [
                      DiaryHomeShellTopChrome(),
                      Expanded(child: SizedBox()),
                    ],
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.homeInventoryTemplates,
                  builder: (context, state) => const CookbookPage(),
                ),
              ],
            ),
            StatefulShellBranch(routes: [_placeholder(AppRoutes.homeProgress)]),
          ],
        ),
        GoRoute(
          path: AppRoutes.homeShopping,
          builder: (context, state) => const ShoppingListPage(),
        ),
      ],
    );
  }

  final FakeShoppingListRepository repository;
  late final GoRouter router;

  Widget build() {
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 2, 20)),
        authStateChangesProvider.overrideWith(
          (ref) => Stream.value(FakeSignedInUser('uid-1')),
        ),
        appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
        shoppingListRepositoryProvider.overrideWithValue(repository),
        cookRunRepositoryProvider.overrideWithValue(FakeCookRunRepository()),
        preparedMealTemplateRepositoryProvider.overrideWithValue(
          FakePreparedMealTemplateRepository(),
        ),
        plannedEntryRepositoryProvider.overrideWithValue(
          FakePlannedEntryRepository(),
        ),
        closedDayRepositoryProvider.overrideWithValue(
          ClosedDayRepository(MemoryAppPreferences(), 'user-1'),
        ),
        inventoryItemRepositoryProvider.overrideWithValue(_EmptyInventory()),
        preparedMealRepositoryProvider.overrideWithValue(
          FakePreparedMealRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(router.dispose);
    addTearDown(repository.dispose);
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
}

/// A Vorrat without stock.
class _EmptyInventory with InventoryItemWholeListWrites {
  @override
  Stream<List<InventoryItem>> watchAll() => Stream.value(const []);

  @override
  Future<List<InventoryItem>> readAll() async => const [];

  @override
  Future<bool> replaceItems(List<InventoryItem> items) async => true;

  @override
  Future<bool> appendAll(List<InventoryItem> items) async => true;
}

/// The shown header tool: the widget stays in the tree while it hides, but
/// then it builds no [HomeHeaderTool].
final Finder _tool = find.descendant(
  of: find.byType(ShoppingHeaderTool),
  matching: find.byType(HomeHeaderTool),
);

/// The number in the badge of the header tool, null without a badge.
String? _badge(WidgetTester tester) {
  final badge = find.descendant(of: _tool, matching: find.byType(Badge));
  if (badge.evaluate().isEmpty) return null;
  return (tester.widget<Badge>(badge).label! as Text).data;
}

/// Pumps until [finder] matches, at most five seconds.
Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 50 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsOneWidget);
}

Future<void> _openTab(WidgetTester tester, IconData icon) async {
  await tester.tap(
    find.descendant(
      of: find.byType(HomeBottomNavBar),
      matching: find.byIcon(icon),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'the shopping tool follows the open entries of both lists on every tab',
    (tester) async {
      final harness = _Harness([
        _item('milk', 'Milk'),
        _item('soap', 'Soap', isPrivate: true),
      ]);
      await tester.pumpWidget(harness.build());
      await _waitFor(tester, _tool);
      await tester.pumpAndSettle();

      // Diary today: the tool shows with both open entries counted.
      expect(_tool, findsOneWidget);
      expect(_badge(tester), '2');

      // The tool opens the shopping list page.
      await tester.tap(_tool);
      await tester.pumpAndSettle();
      expect(find.byType(ShoppingListPage), findsOneWidget);

      // Tick both entries off.
      await _waitFor(tester, find.byKey(ShoppingListPageKeys.tile('milk')));
      await tester.tap(find.byKey(ShoppingListPageKeys.tile('milk')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(ShoppingListPageKeys.tile('soap')));
      await tester.pump(AppShopping.tickLinger);
      await _waitFor(tester, find.byKey(ShoppingListPageKeys.cartChip('milk')));
      await _waitFor(tester, find.byKey(ShoppingListPageKeys.cartChip('soap')));

      // Back on the diary nothing is left to buy: no tool.
      harness.router.pop();
      await tester.pumpAndSettle();
      expect(find.byType(ShoppingListPage), findsNothing);
      expect(find.byType(DiaryHomeShellTopChrome), findsOneWidget);
      expect(_tool, findsNothing);

      // Vorrat always shows the tool, without a badge.
      await _openTab(tester, Icons.inventory_2_rounded);
      expect(_tool, findsOneWidget);
      expect(_badge(tester), isNull);

      // Kochbuch shows it only with open entries.
      await _openTab(tester, Icons.auto_stories_rounded);
      expect(find.byType(CookbookPage), findsOneWidget);
      expect(_tool, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
