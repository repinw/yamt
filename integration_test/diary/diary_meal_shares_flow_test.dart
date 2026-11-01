import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/constants/app_budget_card_constants.dart';
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
import 'package:yamt/features/diary/presentation/diary_page.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_budget_card/diary_budget_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_budget_card/diary_budget_kcal_column.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_budget_card/diary_budget_line.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_budget_card/diary_meal_shares_editor.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section_keys.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/home/home_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/calories/support/fake_calories_repositories.dart';
import '../../test/features/calories/support/fake_planned_entry_repository.dart';
import '../../test/helpers/auth_user_data_key_session.dart';
import '../../test/helpers/long_press_test_utils.dart';
import '../../test/helpers/memory_app_preferences.dart';
import '../../test/helpers/time_picker_test_utils.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth;

class _MockUser extends Mock implements User;

// 2026-09-28 is a Monday, the day the goal starts: no weekly check-in is
// due, and no unused days before it raise today's target over 2000.
final _now = DateTime(2026, 9, 28, 12, 30);
final _today = DateTime(2026, 9, 28);

GoRoute _placeholder(String path) {
  return GoRoute(
    path: path,
    builder: (context, state) => const Scaffold(body: SizedBox.expand()),
  );
}

/// The home shell on the diary tab, with the diary's data in fakes.
Widget _buildApp(
  FakeCalorieSettingsRepository settings,
  FakeCalorieLogRepository log,
  MemoryAppPreferences preferences,
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
      authStateChangesProvider.overrideWith((ref) => Stream<User?>.value(user)),
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

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      locale: const Locale('de'),
      routerConfig: router,
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // A German phone's clock has 24 hours, which the time picker reads
      // the typed hour by.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    ),
  );
}

const _markerKey = 'diary_pace_marker_v1';
const _sharesKey = 'diary_meal_shares_v1';
const _timesKey = 'diary_meal_times_v1';

/// An oat breakfast of 300 kcal, eaten at 8:00.
final _oats = CalorieEntry.create(
  id: 'oats',
  userId: 'user-1',
  name: 'Haferflocken',
  mealType: MealType.breakfast,
  consumedAmount: 100,
  consumedUnit: ConsumedUnit.grams,
  per100Kcal: 300,
  per100Protein: 10,
  per100Carbs: 50,
  per100Fat: 5,
  loggedAt: _today.add(const Duration(hours: 8)),
  createdAt: _today,
  updatedAt: _today,
);

final Finder _card = find.byKey(DiaryBudgetCardKeys.card);
final Finder _marker = find.byKey(DiaryBudgetLine.paceKey);

String? _text(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data;

String? _part(WidgetTester tester, MealType meal) =>
    _text(tester, DiaryMealSharesEditor.partKey(meal));

/// The words on a time button of the parts of the day, such as "bis 09:00".
String? _time(WidgetTester tester, Key key) => tester
    .widget<Text>(
      find.descendant(of: find.byKey(key), matching: find.byType(Text)),
    )
    .data;

/// The breakfast heading's "x / y kcal", or null when it shows none.
String? _breakfastTarget(WidgetTester tester) {
  final finder = find.byKey(
    DiaryMealsSectionKeys.mealKcalOfTarget(MealType.breakfast),
  );
  return finder.evaluate().isEmpty ? null : tester.widget<Text>(finder).data;
}

/// The share of the day the pace marker stands at, from its place on the
/// kcal line.
double _markerShare(WidgetTester tester) {
  final line = tester.getRect(
    find.descendant(
      of: find.byType(DiaryBudgetKcalColumn),
      matching: find.byType(DiaryBudgetLine),
    ),
  );
  final center = tester.getCenter(_marker).dx - line.left;
  return center / line.width * AppBudgetCard.lineScale;
}

/// Drags on the blocks of the parts of the day from [from] to [to] percent
/// of the day.
Future<void> _drag(WidgetTester tester, int from, int to) async {
  final rect = tester.getRect(find.byKey(DiaryMealSharesEditor.blocksKey));
  const inset = AppBudgetCard.mealSharesHandle / 2;
  Offset at(int percent) => Offset(
    rect.left + inset + percent / 100 * (rect.width - 2 * inset),
    rect.center.dy,
  );
  await tester.dragFrom(at(from), at(to) - at(from));
  await tester.pumpAndSettle();
}

Future<void> _openMenu(WidgetTester tester) async {
  await tester.ensureVisible(_card);
  await tester.pumpAndSettle();
  await longPressOpeningRoute(tester, _card);
  await tester.pumpAndSettle();
  expect(find.byKey(DiaryBudgetCardKeys.menu), findsOneWidget);
}

Future<void> _closeMenu(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
  expect(find.byKey(DiaryBudgetCardKeys.menu), findsNothing);
}

/// Taps [key] in the menu, which scrolls its content to it first.
Future<void> _tap(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a long press on the budget card turns on the pace marker, '
      'whose parts of the day and times move it, and resets them (#928)', (
    tester,
  ) async {
    final settings = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2000,
        calculatorProfile: const CalorieCalculatorProfile.defaults().copyWith(
          trainingWeekdays: const [],
        ),
        effectiveDate: _today,
      ),
    );
    final log = FakeCalorieLogRepository(initialEntries: [_oats]);
    final preferences = MemoryAppPreferences();
    addTearDown(settings.dispose);
    addTearDown(log.dispose);

    await tester.pumpWidget(_buildApp(settings, log, preferences));
    await tester.pumpAndSettle();

    // Off by default: no marker on the kcal line, no target in the heading.
    await tester.ensureVisible(_card);
    await tester.pumpAndSettle();
    expect(_marker, findsNothing);
    await tester.ensureVisible(
      find.byKey(DiaryMealsSectionKeys.mealGroup(MealType.breakfast)),
    );
    await tester.pumpAndSettle();
    expect(_breakfastTarget(tester), isNull);

    // The menu has the switch; the parts of the day come with the marker.
    await _openMenu(tester);
    expect(find.byKey(DiaryBudgetCardKeys.paceSwitch), findsOneWidget);
    expect(find.byKey(DiaryMealSharesEditor.blocksKey), findsNothing);

    await _tap(tester, DiaryBudgetCardKeys.paceSwitch);
    expect(preferences.getIntSync(_markerKey), 1);
    expect(find.byKey(DiaryMealSharesEditor.blocksKey), findsOneWidget);
    expect(_part(tester, MealType.breakfast), '25 % · 500 kcal');
    expect(_time(tester, DiaryMealSharesEditor.startKey), 'ab 06:00');
    expect(
      _time(tester, DiaryMealSharesEditor.timeKey(MealType.lunch)),
      'bis 13:00',
    );

    // The marker is on the kcal line at 12:30: 25 % for breakfast and 35 %
    // of lunch for the 3.5 of its 4 hours that are over. The meal heading
    // shows its kcal against its part of the day.
    expect(_marker, findsOneWidget);
    expect(_markerShare(tester), closeTo(0.55625, 1e-3));
    expect(_breakfastTarget(tester), '300 / 500 kcal');

    // Breakfast's end pushed onto the left edge turns breakfast off: its
    // part of the day goes to lunch, and its heading shows no target.
    await _drag(tester, 25, -5);
    expect(_part(tester, MealType.breakfast), 'Aus');
    expect(_part(tester, MealType.lunch), '60 % · 1.200 kcal');
    expect(preferences.getStringSync(_sharesKey), '0,60,30,10');
    expect(_breakfastTarget(tester), isNull);

    // Lunch by 14:00 through the time picker.
    await _tap(tester, DiaryMealSharesEditor.timeKey(MealType.lunch));
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await pickTimeInOpenPicker(tester, const TimeOfDay(hour: 14, minute: 0));
    expect(
      _time(tester, DiaryMealSharesEditor.timeKey(MealType.lunch)),
      'bis 14:00',
    );
    expect(preferences.getStringSync(_timesKey), '360,540,840,1140,1260');

    // Back in the diary the marker stands where the new parts and times put
    // it: lunch's 60 % from 9:00 to 14:00, of which 12:30 is 70 % through.
    await _closeMenu(tester);
    expect(_marker, findsOneWidget);
    expect(_markerShare(tester), closeTo(0.42, 1e-3));

    // Reopened, the menu still has the parts of the day; reset puts back
    // the standard split and times, and the marker with them.
    await _openMenu(tester);
    expect(_part(tester, MealType.breakfast), 'Aus');
    await _tap(tester, DiaryMealSharesEditor.resetKey);
    expect(_part(tester, MealType.breakfast), '25 % · 500 kcal');
    expect(_part(tester, MealType.lunch), '35 % · 700 kcal');
    expect(_time(tester, DiaryMealSharesEditor.startKey), 'ab 06:00');
    expect(
      _time(tester, DiaryMealSharesEditor.timeKey(MealType.lunch)),
      'bis 13:00',
    );
    expect(preferences.getStringSync(_sharesKey), isNull);
    expect(preferences.getStringSync(_timesKey), isNull);

    await _closeMenu(tester);
    expect(_markerShare(tester), closeTo(0.55625, 1e-3));
    expect(_breakfastTarget(tester), '300 / 500 kcal');

    // Switched off, the line and the heading are as they were.
    await _openMenu(tester);
    await _tap(tester, DiaryBudgetCardKeys.paceSwitch);
    expect(preferences.getIntSync(_markerKey), isNull);
    expect(find.byKey(DiaryMealSharesEditor.blocksKey), findsNothing);
    await _closeMenu(tester);
    expect(_marker, findsNothing);
    expect(_breakfastTarget(tester), isNull);
    expect(tester.takeException(), isNull);
  });
}
