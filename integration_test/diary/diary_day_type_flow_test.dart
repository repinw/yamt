import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/constants/app_routes.dart';
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
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/diary/domain/diary_day_type.dart';
import 'package:yamt/features/diary/presentation/diary_page.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_budget_card/diary_budget_card_keys.dart';
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

// 2026-09-28 is a Monday, the training weekday. The goal started two days
// before, so no weekly check-in is due yet.
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
      appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
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
    ),
  );
}

/// Taps the [type] button in the budget card.
Future<void> _tap(WidgetTester tester, DiaryDayType type) async {
  await tester.tap(find.byKey(DiaryBudgetCardKeys.dayTypeButton(type)));
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the training and pause buttons in the card change the day', (
    tester,
  ) async {
    final settings = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2000,
        calculatorProfile: const CalorieCalculatorProfile.defaults().copyWith(
          trainingWeekdays: [DateTime.monday],
          trainingDayKcalOffset: 300,
        ),
        effectiveDate: _today.subtract(const Duration(days: 2)),
      ),
    );
    final log = FakeCalorieLogRepository();
    addTearDown(settings.dispose);
    addTearDown(log.dispose);

    await tester.pumpWidget(_buildApp(settings, log));
    await tester.pumpAndSettle();

    // Monday is a training weekday, so the training button starts pressed.
    expect(find.byKey(DiaryBudgetCardKeys.card), findsOneWidget);
    expect(find.text('Training'), findsOneWidget);

    // Pressing it again makes the day a normal day.
    await _tap(tester, DiaryDayType.training);
    expect((await settings.readSettings()).isTrainingDay(_today), isFalse);
    expect(find.text('Training'), findsNothing);

    await _tap(tester, DiaryDayType.pause);
    expect((await settings.readSettings()).isPauseDay(_today), isTrue);
    expect(find.text('Pausentag'), findsWidgets);

    await _tap(tester, DiaryDayType.pause);
    final normal = await settings.readSettings();
    expect(normal.isPauseDay(_today), isFalse);
    expect(normal.isTrainingDay(_today), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a tap on a day of the week strip moves it to the next type', (
    tester,
  ) async {
    final settings = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2000,
        calculatorProfile: const CalorieCalculatorProfile.defaults().copyWith(
          trainingWeekdays: const [],
        ),
        effectiveDate: _today.subtract(const Duration(days: 2)),
      ),
    );
    final log = FakeCalorieLogRepository();
    addTearDown(settings.dispose);
    addTearDown(log.dispose);

    await tester.pumpWidget(_buildApp(settings, log));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DiaryBudgetCardKeys.detailsChip));
    await tester.pumpAndSettle();

    // Today, a Monday, in the strip: normal, then training, then pause.
    final today = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          (widget.properties.label?.startsWith('Montag: ') ?? false),
    );
    await tester.ensureVisible(today);
    await tester.pumpAndSettle();
    await tester.tap(today);
    await tester.pumpAndSettle();
    expect((await settings.readSettings()).isTrainingDay(_today), isTrue);

    await tester.tap(today);
    await tester.pumpAndSettle();
    final paused = await settings.readSettings();
    expect(paused.isPauseDay(_today), isTrue);

    await tester.tap(today);
    await tester.pumpAndSettle();
    final normal = await settings.readSettings();
    expect(normal.isPauseDay(_today), isFalse);
    expect(normal.isTrainingDay(_today), isFalse);
    expect(tester.takeException(), isNull);
  });
}
