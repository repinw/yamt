import 'dart:convert';
import 'dart:ui' show PictureRecorder;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/calories/application/burn_week_live_sync_provider.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_tiles.dart';
import 'package:yamt/features/diary/domain/diary_day_type.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_dashboard_layout_controller.dart';
import 'package:yamt/features/diary/presentation/diary_page.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_budget_card/diary_budget_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_dashboard/diary_dashboard_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_dashboard/tiles/diary_tile_number.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/home/home_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/calories/support/fake_calories_repositories.dart';
import '../../test/features/calories/support/fake_planned_entry_repository.dart';
import '../../test/helpers/auth_user_data_key_session.dart';
import '../../test/helpers/memory_app_preferences.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth;

class _MockUser extends Mock implements User;

// A Saturday; the goal started two days before, so no weekly check-in is
// due yet.
final _now = DateTime(2026, 10, 31, 12, 30);
final _today = DateTime(2026, 10, 31);

const _layoutKey = 'diary_dashboard_layout_v1:user-1';

GoRoute _placeholder(String path) {
  return GoRoute(
    path: path,
    builder: (context, state) => const Scaffold(body: SizedBox.expand()),
  );
}

/// The home shell on the diary tab, with the diary's data in fakes.
(Widget, ProviderContainer) _buildApp(
  AppPreferences preferences,
  FakeCalorieSettingsRepository settings,
  FakeCalorieLogRepository log,
) {
  final user = _MockUser();
  when(() => user.uid).thenReturn('user-1');
  final auth = _MockFirebaseAuth();
  when(() => auth.currentUser).thenReturn(user);
  final router = GoRouter(
    initialLocation: AppRoutes.homeDiary,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomePage(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [_placeholder(AppRoutes.homeInventory)]),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.homeDiary,
                builder: (context, state) =>
                    const DiaryPage(includeHomeShellChrome: true),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [_placeholder(AppRoutes.homeInventoryTemplates)],
          ),
          StatefulShellBranch(routes: [_placeholder(AppRoutes.homeProgress)]),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  final container = ProviderContainer(
    overrides: [
      appPreferencesProvider.overrideWithValue(preferences),
      clockProvider.overrideWithValue(() => _now),
      authStateChangesProvider.overrideWithValue(AsyncData<User?>(user)),
      userDataKeySessionProvider.overrideWith(AuthUserDataKeySession.new),
      firebaseAuthProvider.overrideWithValue(auth),
      calorieSettingsRepositoryProvider.overrideWithValue(settings),
      calorieLogRepositoryProvider.overrideWithValue(log),
      plannedEntryRepositoryProvider.overrideWithValue(
        FakePlannedEntryRepository(),
      ),
      burnWeekLiveSyncTickerPeriodProvider.overrideWithValue(null),
      burnWeekRunStateRepositoryProvider.overrideWithValue(
        FakeBurnWeekRunStateRepository(),
      ),
      healthConnectionServiceProvider.overrideWithValue(
        FakeHealthConnectionService(const HealthConnectionStatus.unsupported()),
      ),
      healthWeightServiceProvider.overrideWithValue(
        FakeHealthWeightService(const []),
      ),
      manualHealthWeightRepositoryProvider.overrideWithValue(
        FakeManualHealthWeightRepository([]),
      ),
    ],
  );
  addTearDown(container.dispose);

  return (
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: const Locale('de'),
        routerConfig: router,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
    container,
  );
}

/// A snack of [kcal] eaten this morning.
CalorieEntry _snack(double kcal) => CalorieEntry.create(
  id: 'snack',
  userId: 'user-1',
  name: 'Nüsse',
  mealType: MealType.snack,
  consumedAmount: 100,
  consumedUnit: ConsumedUnit.grams,
  per100Kcal: kcal,
  per100Protein: 0,
  per100Carbs: 0,
  per100Fat: 0,
  loggedAt: _today.add(const Duration(hours: 10)),
  createdAt: _today,
  updatedAt: _today,
);

Future<ProviderContainer> _pumpDiary(
  WidgetTester tester,
  AppPreferences preferences, {
  List<CalorieEntry> entries = const [],
}) async {
  // A compact phone, where four columns are narrowest.
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final settings = FakeCalorieSettingsRepository(
    initialSettings: CalorieGoalSettings.single(
      dailyKcalGoal: 2000,
      calculatorProfile: const CalorieCalculatorProfile.defaults(),
      effectiveDate: _today.subtract(const Duration(days: 2)),
    ),
  );
  final log = FakeCalorieLogRepository(initialEntries: [...entries]);
  addTearDown(settings.dispose);
  addTearDown(log.dispose);
  final (app, container) = _buildApp(preferences, settings, log);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
  return container;
}

Finder _tile(String id) => find.byKey(DiaryDashboardKeys.tile(id));

/// The visible face of the button with [key], inside its bigger tap area.
Rect _face(WidgetTester tester, Key key) => tester.getRect(
  find.descendant(of: find.byKey(key), matching: find.byType(DecoratedBox)),
);

/// How far the round [disc] stays from the [stadium], a box with fully
/// rounded ends; below zero the two overlap.
double _clearance(Rect disc, Rect stadium) {
  final radius = stadium.shortestSide / 2;
  final core = stadium.deflate(radius);
  final nearest = Offset(
    disc.center.dx.clamp(core.left, core.right),
    disc.center.dy.clamp(core.top, core.bottom),
  );
  return (disc.center - nearest).distance - disc.width / 2 - radius;
}

/// How many pixels of the glyphs of [text] lie under the round [disc]. The
/// line box of a text is taller than its glyphs, so this paints the text
/// once more to find them.
Future<int> _inkUnder(WidgetTester tester, Rect disc, Finder text) async {
  final paragraph = tester.renderObject<RenderParagraph>(text);
  final painter = TextPainter(
    text: paragraph.text,
    textDirection: paragraph.textDirection,
    textScaler: paragraph.textScaler,
    maxLines: paragraph.maxLines,
  )..layout();
  // A margin, so that no glyph reaching out of its line box is cut off.
  const margin = 8.0;
  final width = (painter.width + 2 * margin).ceil();
  final height = (painter.height + 2 * margin).ceil();
  final recorder = PictureRecorder();
  painter
    ..paint(Canvas(recorder), const Offset(margin, margin))
    ..dispose();
  final picture = recorder.endRecording();
  final pixels = (await tester.runAsync(() async {
    final image = await picture.toImage(width, height);
    picture.dispose();
    final bytes = await image.toByteData();
    image.dispose();
    return bytes;
  }))!;

  final toGlobal = paragraph.getTransformTo(null);
  var count = 0;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final point = MatrixUtils.transformPoint(
        toGlobal,
        Offset(x + 0.5 - margin, y + 0.5 - margin),
      );
      final alpha = pixels.getUint8((y * width + x) * 4 + 3);
      if (alpha > 0 && (point - disc.center).distance < disc.width / 2) {
        count++;
      }
    }
  }
  return count;
}

List<String> _shown(ProviderContainer container) => [
  for (final t in container.read(diaryDashboardLayoutControllerProvider).tiles)
    t.id,
];

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Shows every tile but those of [except] and draws each in every size and
/// mode.
Future<void> _drawEveryTile(
  WidgetTester tester,
  ProviderContainer container, {
  Set<String> except = const {},
}) async {
  final layout = container.read(
    diaryDashboardLayoutControllerProvider.notifier,
  );
  final specs = [
    for (final spec in diaryDashboardTileSpecs)
      if (!except.contains(spec.id)) spec,
  ];
  for (final spec in specs) {
    await layout.show(spec.id);
  }
  await tester.pumpAndSettle();

  for (final spec in specs) {
    for (final size in spec.sizes) {
      for (final mode in spec.modes) {
        await layout.setSize(spec.id, size);
        await layout.setMode(spec.id, mode);
        await tester.pumpAndSettle();
        expect(_tile(spec.id), findsOneWidget, reason: spec.id);
        expect(
          tester.takeException(),
          isNull,
          reason: '${spec.id} ${size.name} $mode',
        );
      }
    }
  }
}

/// A saved layout that shows the weight and meals tiles, which the default
/// layout hides.
MemoryAppPreferences _withWeightAndMeals() {
  var layout = DiaryDashboardLayout.initial(diaryDashboardTileSpecs);
  for (final spec in diaryDashboardTileSpecs) {
    if (spec.id == DiaryTileIds.weight || spec.id == DiaryTileIds.meals) {
      layout = layout.show(spec);
    }
  }
  return MemoryAppPreferences(
    initialStrings: {_layoutKey: jsonEncode(layout.toJson())},
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a long press arranges the tiles, and the layout is saved', (
    tester,
  ) async {
    final preferences = _withWeightAndMeals();
    final before = preferences.getStringSync(_layoutKey);
    final container = await _pumpDiary(tester, preferences);

    // The budget card leads the tiles.
    expect(find.byKey(DiaryBudgetCardKeys.card), findsOneWidget);
    for (final id in [
      DiaryTileIds.budget,
      DiaryTileIds.weight,
      DiaryTileIds.meals,
    ]) {
      expect(_tile(id), findsOneWidget, reason: id);
    }
    expect(_tile(DiaryTileIds.kcal), findsNothing);

    await tester.longPress(_tile(DiaryTileIds.weight));
    await tester.pumpAndSettle();
    expect(find.byKey(DiaryDashboardKeys.done), findsOneWidget);

    // The tile menu switches the mode and hides the tile.
    await _tapVisible(tester, _tile(DiaryTileIds.weight));
    await _tapVisible(
      tester,
      find.byKey(DiaryDashboardKeys.mode(DiaryTileModes.sparkline)),
    );
    await _tapVisible(tester, find.byKey(DiaryDashboardKeys.hide));
    expect(_tile(DiaryTileIds.weight), findsNothing);

    // The add sheet brings it back at the end, in the default mode.
    await _tapVisible(tester, find.byKey(DiaryDashboardKeys.add));
    await _tapVisible(
      tester,
      find.byKey(DiaryDashboardKeys.addTile(DiaryTileIds.weight)),
    );
    expect(_shown(container).last, DiaryTileIds.weight);

    await _tapVisible(tester, find.byKey(DiaryDashboardKeys.done));
    expect(find.byKey(DiaryDashboardKeys.done), findsNothing);
    expect(preferences.getStringSync(_layoutKey), isNot(before));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the menu buttons of edit mode leave the tile content free', (
    tester,
  ) async {
    await _pumpDiary(tester, _withWeightAndMeals(), entries: [_snack(180)]);
    await tester.longPress(_tile(DiaryTileIds.weight));
    await tester.pumpAndSettle();

    // Pause ends the top row of the budget card.
    expect(
      _clearance(
        _face(tester, DiaryDashboardKeys.menu(DiaryTileIds.budget)),
        _face(tester, DiaryBudgetCardKeys.dayTypeButton(DiaryDayType.pause)),
      ),
      greaterThan(0),
      reason: 'budget menu over Pause',
    );

    // The snack ends the row of meals.
    final snack = find
        .descendant(
          of: _tile(DiaryTileIds.meals),
          matching: find.byType(DiaryTileNumber),
        )
        .last;
    expect(tester.widget<DiaryTileNumber>(snack).text, '180');
    expect(
      await _inkUnder(
        tester,
        _face(tester, DiaryDashboardKeys.menu(DiaryTileIds.meals)),
        find.descendant(of: snack, matching: find.byType(RichText)),
      ),
      0,
      reason: 'meals menu over the snack kcal',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('every tile draws in each of its sizes and modes', (
    tester,
  ) async {
    final container = await _pumpDiary(tester, MemoryAppPreferences());

    // T1: before any change the page shows only the budget card.
    expect(_shown(container), [DiaryTileIds.budget]);
    expect(_tile(DiaryTileIds.weight), findsNothing);
    expect(_tile(DiaryTileIds.meals), findsNothing);

    await _drawEveryTile(tester, container);
  });

  testWidgets('the grid tiles draw in each size and mode at large text', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    // Leaves out the budget card, whose view switch does not fit this text
    // size yet, also outside the dashboard.
    final withoutBudget = DiaryDashboardLayout.initial(diaryDashboardTileSpecs)
        .hide(DiaryTileIds.budget);
    final container = await _pumpDiary(
      tester,
      MemoryAppPreferences(
        initialStrings: {_layoutKey: jsonEncode(withoutBudget.toJson())},
      ),
    );

    await _drawEveryTile(tester, container, except: {DiaryTileIds.budget});
  });
}
