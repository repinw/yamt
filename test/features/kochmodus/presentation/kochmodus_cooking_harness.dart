import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/device/local_notifications.dart';
import 'package:yamt/core/device/screen_wake_lock.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/preferences/install_id.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/router/app_router.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/household/application/household_data_scope.dart';
import 'package:yamt/features/inventory/data/cooked_meal_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kitchen_utensils/data/kitchen_utensil_repository.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_assign_page.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_page.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/cook_timer_alarm_listener.dart';
import 'package:yamt/features/recipes/data/cook_run_repository.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/fake_kitchen_utensil_repository.dart';
import '../../../helpers/fake_local_notifications.dart';
import '../../../helpers/fake_signed_in_user.dart';
import '../../../helpers/fake_voice_search_service.dart';
import '../../../helpers/memory_app_preferences.dart';
import '../application/cook_services_harness.dart';

/// The signed-in member of every cooking test.
const kochmodusTestUserId = 'uid-1';

/// The time every cooking test starts at.
final kochmodusTestStart = DateTime.utc(2026, 11, 7, 12);

/// A line that came in while cooking, open unless [settlement] says more.
CookRunLine cookedLine(
  String id,
  String text, {
  LineSettlement settlement = const LineOpen(),
}) => CookRunLine(
  id: id,
  text: text,
  origin: CookLineOrigin.cooking,
  conversion: null,
  amount: null,
  amountPortions: null,
  amountUnit: null,
  settlement: settlement,
  weighed: null,
  potId: null,
  addedItemIds: const [],
);

// How often [KochmodusCookingHarness.idle] takes turns at least (a second
// of frames, for the sheets and routes to open) and at most.
const _minRounds = 50;

// The most turns.
const _idleRounds = 500;

// Real time a write may take before the test fails instead of hanging.
const _ioTimeout = Duration(seconds: 10);

/// Key of the stub home.
const homeKey = ValueKey<String>('kochmodus-test-home');

/// Key of the stub route that is not a home route.
const awayKey = ValueKey<String>('kochmodus-test-away');

/// Key of the stub Vorrat that "Jetzt essen" opens.
const inventoryKey = ValueKey<String>('kochmodus-test-inventory');

/// A route outside `/home`, such as the sign-in.
const awayPath = '/away';

/// The cooking page on real cook run repositories over `fake_cloud_firestore`
/// with the Vorrat, the notifications and the speech service faked.
class KochmodusCookingHarness {
  new _(this.cook);

  /// Opens the household of one test.
  static Future<KochmodusCookingHarness> open() async =>
      KochmodusCookingHarness._(await CookHarness.open());

  /// The household: runs, meals and Vorrat.
  final CookHarness cook;

  /// The scheduled notifications.
  final notifications = FakeLocalNotifications();

  /// The preferences of this device; the install id names its timers.
  final preferences = MemoryAppPreferences();

  /// The speech service.
  final voice = FakeVoiceSearchService();

  /// The kitchen utensils.
  final utensils = FakeKitchenUtensilRepository();

  /// The cook run repository the app reads, the household's own when unset.
  CookRunRepository? runsOverride;

  /// Whether the household key is ready; when not, the data scope is null.
  bool householdReady = true;

  /// What the clock shows.
  DateTime now = kochmodusTestStart;

  /// The location the stub Vorrat was last opened with, `null` before.
  Uri? inventoryUri;

  /// The router of the app below [app].
  late final GoRouter router;

  /// The container of [app], to read what the page and the services read.
  late final ProviderContainer container;

  /// The overrides every page and listener test shares.
  List<Override> get overrides {
    final auth = FakeSignedInAuth(
      FakeSignedInUser(kochmodusTestUserId, displayName: 'Ada'),
    );
    return [
      firebaseAuthProvider.overrideWithValue(auth),
      appPreferencesProvider.overrideWithValue(preferences),
      clockProvider.overrideWithValue(() => now),
      // The household key is ready, as the timer listener checks.
      householdDataScopeProvider.overrideWithValue(
        householdReady
            ? (
                householdId: 'h1',
                firestore: cook.firestore,
                cipher: cook.cipher,
              )
            : null,
      ),
      cookRunRepositoryProvider.overrideWithValue(runsOverride ?? cook.runs),
      cookedMealRepositoryProvider.overrideWithValue(cook.meals),
      inventoryItemRepositoryProvider.overrideWithValue(cook.inventory),
      preparedMealTemplateRepositoryProvider.overrideWithValue(cook.templates),
      kitchenUtensilRepositoryProvider.overrideWithValue(utensils),
      localNotificationsProvider.overrideWithValue(notifications),
      voiceSearchServiceProvider.overrideWithValue(voice),
      screenWakeLockProvider.overrideWithValue(
        ScreenWakeLock(toggle: ({required on}) async {}),
      ),
      appRouterProvider.overrideWith((ref) => router),
    ];
  }

  /// An app that starts at [initialLocation]: a stub home, a stub away
  /// route, [KochmodusAssignPage] and [KochmodusPage.run] under their
  /// routes, so "back" and "Zum
  /// Kochbuch" have somewhere to go. With [alarms] the timer listener wraps
  /// it like in the real app.
  Widget app({
    String initialLocation = AppRoutes.homeInventoryTemplates,
    bool alarms = false,
    Locale locale = const Locale('en'),
    double? textScale,
  }) {
    router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: AppRoutes.homeInventoryTemplates,
          builder: (context, state) => const Scaffold(key: homeKey),
        ),
        GoRoute(
          path: AppRoutes.homeInventory,
          builder: (context, state) {
            inventoryUri = state.uri;
            return const Scaffold(key: inventoryKey);
          },
        ),
        GoRoute(
          path: awayPath,
          builder: (context, state) => const Scaffold(key: awayKey),
        ),
        GoRoute(
          path: AppRoutes.homeCook,
          builder: (context, state) => KochmodusAssignPage(
            recipeId: state.pathParameters['recipeId']!,
            portions: int.tryParse(
              state.uri.queryParameters[AppRoutes.homeCookPortionsParam] ?? '',
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.homeCookRun,
          builder: (context, state) =>
              KochmodusPage.run(runId: state.pathParameters['runId']!),
        ),
      ],
    );
    addTearDown(router.dispose);
    container = ProviderContainer(overrides: overrides);
    addTearDown(container.dispose);
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: locale,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
        builder: (context, child) {
          final page = alarms ? CookTimerAlarmListener(child: child!) : child!;
          // Without [textScale] the platform's scale stays in force.
          return textScale == null
              ? page
              : MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(textScale)),
                  child: page,
                );
        },
      ),
    );
  }

  /// The id this device gives its timers.
  Future<String> deviceId(WidgetTester tester) async =>
      (await tester.runAsync(() => readInstallId(preferences)))!;

  /// Opens the page of the stored run [runId] on top of the stub home.
  ///
  /// [width] narrows the screen and [textScale] / [locale] set up the
  /// accessibility case: a small phone, big text, long German words.
  Future<void> pumpRun(
    WidgetTester tester,
    String runId, {
    double width = 800,
    double? textScale,
    Locale locale = const Locale('en'),
  }) async {
    _tallScreen(tester, width: width);
    await tester.pumpWidget(app(textScale: textScale, locale: locale));
    await tester.pump();
    unawaited(router.push<void>(AppRoutes.homeCookRunPath(runId)));
    await idle(tester);
  }

  /// Opens "Zuweisen" of the recipe [recipeId] on top of the stub home.
  Future<void> pumpAssign(
    WidgetTester tester,
    String recipeId, {
    int? portions,
    double width = 800,
    double? textScale,
    Locale locale = const Locale('en'),
  }) async {
    _tallScreen(tester, width: width);
    await tester.pumpWidget(app(textScale: textScale, locale: locale));
    await tester.pump();
    unawaited(
      router.push<void>(AppRoutes.homeCookPath(recipeId, portions: portions)),
    );
    await idle(tester);
  }

  /// A phone screen tall enough to build the lists of a long step whole.
  void _tallScreen(WidgetTester tester, {double width = 800}) {
    tester.view.physicalSize = Size(width, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// Opens the app at [initialLocation] with the timer listener around it.
  Future<void> pumpApp(
    WidgetTester tester, {
    String initialLocation = AppRoutes.homeInventoryTemplates,
  }) async {
    _tallScreen(tester);
    await tester.pumpWidget(
      app(alarms: true, initialLocation: initialLocation),
    );
    await idle(tester);
  }

  /// Lets the writes of the page land and the streams deliver, and builds
  /// the frames. The page writes in the test's fake time, while the
  /// encrypting and Firestore need real time, so it takes turns.
  Future<void> idle(WidgetTester tester) async {
    var pending = true;
    unawaited(cook.runs.pending.whenComplete(() => pending = false));
    for (
      var round = 0;
      round < _idleRounds && (pending || round < _minRounds);
      round++
    ) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 2)),
      );
    }
    expect(pending, isFalse, reason: 'A write of the page never landed.');
  }

  /// Stores [run] before the page opens.
  Future<void> store(WidgetTester tester, CookRun run) async {
    await tester.runAsync(() => cook.start(run).timeout(_ioTimeout));
  }

  /// Puts [items] into the Vorrat before the page opens.
  Future<void> stock(WidgetTester tester, List<InventoryItem> items) async {
    await tester.runAsync(() => cook.stock(items).timeout(_ioTimeout));
  }

  /// The run [id] as stored; throws when it is gone.
  Future<CookRun> storedRun(WidgetTester tester, String id) async =>
      (await tester.runAsync(() => cook.storedRun(id)))!;

  /// The texts of the page in English.
  AppLocalizations l10n(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(Scaffold).last))!;
}

/// Matches the moment [moment], whether the time is UTC or local: Firestore
/// hands dates back as local time.
Matcher atMoment(DateTime moment) =>
    predicate<DateTime>((time) => time.isAtSameMomentAs(moment), 'is $moment');
