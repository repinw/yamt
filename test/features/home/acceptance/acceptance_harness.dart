import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/router/app_route_observer.dart';
import 'package:yamt/core/router/home_shell_routes.dart';
import 'package:yamt/core/widgets/home_bottom_nav_bar.dart';
import 'package:yamt/core/widgets/home_header_tool.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/calories/application/burn_week_live_sync_provider.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/health/data/progress_photo_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/data/receipt_ai_repository.dart';
import 'package:yamt/features/scanner/data/receipt_gateway_providers.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/auth_user_data_key_session.dart';
import '../../../helpers/fake_inventory_item_repository.dart';
import '../../../helpers/fake_prepared_meal_repository.dart';
import '../../../helpers/fake_progress_photo_repository.dart';
import '../../../helpers/fake_signed_in_user.dart';
import '../../../helpers/profile_summary_source_overrides.dart';
import '../../../helpers/progress_source_overrides.dart' show progressProfile;
import '../../calories/support/fake_calories_repositories.dart';
import '../../calories/support/fake_planned_entry_repository.dart';
import '../../scanner/fakes/fake_receipt_ai_repository.dart';
import '../../scanner/fakes/fake_receipt_product_resolver.dart';
import '../../shoppinglist/support/fake_shopping_list_repository.dart';

/// Thursday, 19 November 2026: "today" of the acceptance tests.
final acceptanceNow = DateTime(2026, 11, 19, 10);

/// Key of the page that the shopping route shows in the harness.
const shoppingRouteMarker = ValueKey<String>('acceptance-shopping-route');

/// The four tabs of the home shell, in branch order of the harness.
enum AcceptanceTab {
  vorrat(AppRoutes.homeInventory),
  tagebuch(AppRoutes.homeDiary),
  kochbuch(AppRoutes.homeInventoryTemplates),
  fortschritt(AppRoutes.homeProgress);

  new(this.route);

  final String route;
}

class _MockFirebaseAuth extends Mock implements FirebaseAuth;

/// An entry of the shopping list; open unless [done].
ShoppingListItem shoppingItem(
  String id, {
  bool done = false,
  bool isPrivate = false,
}) {
  return ShoppingListItem(
    id: id,
    name: 'Ding $id',
    normalizedName: 'ding $id',
    normalizedBrand: '',
    quantity: 1,
    estimatedUnitPrice: 0,
    isDone: done,
    isPrivate: isPrivate,
  );
}

/// [open] open and [done] ticked-off entries on the household list or the
/// private list.
List<ShoppingListItem> shoppingItems({
  int open = 0,
  int done = 0,
  bool isPrivate = false,
}) {
  final scope = isPrivate ? 'p' : 'h';
  return [
    for (var i = 0; i < open; i += 1)
      shoppingItem('$scope-open-$i', isPrivate: isPrivate),
    for (var i = 0; i < done; i += 1)
      shoppingItem('$scope-done-$i', done: true, isPrivate: isPrivate),
  ];
}

/// The home shell with the four real tab pages, in German, at
/// [acceptanceNow].
class HomeShellHarness {
  new _(this.container);

  /// The container of the app.
  final ProviderContainer container;

  /// Selects [day] in the diary.
  void selectDiaryDay(DateTime day) {
    container.read(diaryCalendarControllerProvider.notifier).selectDay(day);
  }
}

/// Pumps the shell on [tab] with [shopping] on the shopping list.
Future<HomeShellHarness> pumpHomeShell(
  WidgetTester tester, {
  AcceptanceTab tab = AcceptanceTab.tagebuch,
  List<ShoppingListItem> shopping = const [],
  List<CalorieEntry> calorieEntries = const [],
  bool emptyVorrat = false,
  Size size = const Size(420, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // The test font is wider than the app font, so the view switch of the
  // diary budget card overflows here. Every other overflow, in the bottom
  // bar and in the tab headers above all, still fails the test.
  final onError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed') &&
        details.toString().contains('diary_budget_view_switch.dart')) {
      return;
    }
    onError?.call(details);
  };
  addTearDown(() => FlutterError.onError = onError);

  // The plan began on the first of the month and the goal was last set two
  // days ago, so no weekly check-in is due and opens a dialog.
  final firstGoal = CalorieGoalSettings.single(
    dailyKcalGoal: 2200,
    calculatorProfile: progressProfile,
    effectiveDate: DateTime(2026, 11),
  );
  final lastGoal = CalorieGoalSettings.single(
    dailyKcalGoal: 2200,
    calculatorProfile: progressProfile,
    effectiveDate: DateTime(2026, 11, 17),
  );
  final settings = FakeCalorieSettingsRepository(
    initialSettings: lastGoal.copyWith(
      goalHistory: [...firstGoal.goalHistory, ...lastGoal.goalHistory],
    ),
  );
  addTearDown(settings.dispose);
  final calorieLog = FakeCalorieLogRepository(initialEntries: calorieEntries);
  addTearDown(calorieLog.dispose);
  final shoppingRepository = FakeShoppingListRepository(initialItems: shopping);
  addTearDown(shoppingRepository.dispose);
  final firebaseAuth = _MockFirebaseAuth();
  when(() => firebaseAuth.currentUser).thenReturn(null);
  final routeObserver = RouteObserver<ModalRoute<void>>();

  GoRoute route(String path, Widget body) =>
      GoRoute(path: path, builder: (context, state) => body);

  final router = GoRouter(
    initialLocation: tab.route,
    observers: [routeObserver],
    routes: [
      buildHomeShellRoute(),
      route(
        AppRoutes.homeShopping,
        const Scaffold(key: shoppingRouteMarker, body: Text('Einkaufsliste')),
      ),
    ],
  );
  addTearDown(router.dispose);

  final container = ProviderContainer(
    overrides: [
      ...profileSummarySourceOverrides(
        settingsRepository: settings,
        now: acceptanceNow,
        householdId: 'user-1',
      ),
      calorieLogRepositoryProvider.overrideWithValue(calorieLog),
      progressPhotoRepositoryProvider.overrideWithValue(
        FakeProgressPhotoRepository(),
      ),
      appRouteObserverProvider.overrideWithValue(routeObserver),
      // Signed in, with the own household as the active one.
      authStateChangesProvider.overrideWith(
        (ref) => Stream<User?>.value(FakeSignedInUser('user-1')),
      ),

      firebaseAuthProvider.overrideWithValue(firebaseAuth),
      burnWeekRunStateRepositoryProvider.overrideWithValue(
        _FakeBurnWeekRunStateRepository(),
      ),
      burnWeekLiveSyncTickerPeriodProvider.overrideWithValue(null),
      inventoryItemRepositoryProvider.overrideWithValue(
        FakeInventoryItemRepository([
          // By default one food stands in the Vorrat; [emptyVorrat] holds
          // no food at all (the prepared meals are always empty).
          if (!emptyVorrat)
            InventoryItem.create(
              id: 'milk',
              name: 'Milch',
              entryDate: DateTime(2026, 11, 10),
              storeName: 'Laden',
              quantity: 1,
            ),
        ]),
      ),
      preparedMealRepositoryProvider.overrideWithValue(
        FakePreparedMealRepository(),
      ),
      shoppingListRepositoryProvider.overrideWithValue(shoppingRepository),
      userDataCipherProvider.overrideWithValue(testUserDataCipher),
      plannedEntryRepositoryProvider.overrideWithValue(
        FakePlannedEntryRepository(),
      ),
      // The Vorrat actions watch the scan coordinator while building.
      receiptAiRepositoryProvider.overrideWithValue(FakeReceiptAiRepository()),
      receiptProductResolverProvider.overrideWithValue(
        FakeReceiptProductResolver(),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: const Locale('de'),
        routerConfig: router,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await settle(tester);
  return HomeShellHarness._(container);
}

class _FakeBurnWeekRunStateRepository implements BurnWeekRunStateRepository {
  @override
  Future<BurnWeekRunState> readState() async =>
      const BurnWeekRunState.initial();

  @override
  Future<bool> saveState(BurnWeekRunState state) async => true;
}

/// The header tool with the word [label] of the visible tab.
Finder headerTool(String label) => find.widgetWithText(HomeHeaderTool, label);

/// The words of the texts inside [tool].
List<String> toolTexts(WidgetTester tester, Finder tool) {
  return [
    for (final text in tester.widgetList<Text>(
      find.descendant(of: tool, matching: find.byType(Text)),
    ))
      text.data ?? text.textSpan?.toPlainText() ?? '',
  ];
}

/// Taps [finder] and lets the page settle.
Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await settle(tester);
}

/// Words of the four tabs in the bottom bar.
const Map<AcceptanceTab, String> tabWords = {
  AcceptanceTab.tagebuch: 'Tagebuch',
  AcceptanceTab.vorrat: 'Vorrat',
  AcceptanceTab.kochbuch: 'Kochbuch',
  AcceptanceTab.fortschritt: 'Fortschritt',
};

/// Taps the tab [tab] in the bottom bar.
Future<void> switchToTab(WidgetTester tester, AcceptanceTab tab) async {
  await tapAndSettle(
    tester,
    find.descendant(
      of: find.byType(HomeBottomNavBar),
      matching: find.text(tabWords[tab]!),
    ),
  );
}

/// Lets animations and streams run; the diary keeps animating, so
/// `pumpAndSettle` would never return.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
