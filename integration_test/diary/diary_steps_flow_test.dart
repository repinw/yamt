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
import 'package:yamt/features/diary/presentation/diary_page.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_steps_card/diary_steps_card.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_steps_card/diary_steps_card_menu.dart';
import 'package:yamt/features/health/application/health_steps_controller.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_steps_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/home/home_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/calories/support/fake_calories_repositories.dart';
import '../../test/features/calories/support/fake_planned_entry_repository.dart';
import '../../test/features/health/support/fake_health_steps_service.dart';
import '../../test/helpers/auth_user_data_key_session.dart';
import '../../test/helpers/memory_app_preferences.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth;

class _MockUser extends Mock implements User;

// The goal started two days before, on Saturday, so the run week runs from
// Saturday to Friday and today is its third day.
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
      appPreferencesProvider.overrideWithValue(
        MemoryAppPreferences(initialInts: {healthStepsPreferenceKey: 1}),
      ),
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
        FakeHealthConnectionService(
          const HealthConnectionStatus(
            platform: HealthPlatform.android,
            healthConnectAvailability: HealthConnectAvailability.available,
            permissionState: HealthPermissionState.granted,
            historyAccess: HealthHistoryAccess.granted,
          ),
        ),
      ),
      healthStepsServiceProvider.overrideWithValue(
        // 3000 steps on Saturday, 6000 on Sunday, 1500 so far today.
        FakeHealthStepsService(
          stepsOf: (day) => switch (day.day) {
            26 => 3000,
            27 => 6000,
            _ => 1500,
          },
        ),
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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the diary shows the steps and the card menu sets a goal', (
    tester,
  ) async {
    final settings = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2000,
        calculatorProfile: const CalorieCalculatorProfile.defaults(),
        effectiveDate: _today.subtract(const Duration(days: 2)),
      ),
    );
    final log = FakeCalorieLogRepository();
    addTearDown(settings.dispose);
    addTearDown(log.dispose);

    await tester.pumpWidget(_buildApp(settings, log));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Text>(find.byKey(DiaryStepsCard.valueKey))
          .textSpan!
          .toPlainText(),
      '1.500 Schritte',
    );
    // Seven slots from Saturday on: half, full, a quarter, and four days
    // ahead that are still empty.
    final fills = [
      for (final slot in tester.widgetList<Container>(
        find.descendant(
          of: find.byKey(DiaryStepsCard.cardKey),
          matching: find.byWidgetPredicate(
            (widget) => widget is Container && widget.child is Container,
          ),
        ),
      ))
        tester
            .getSize(
              find.descendant(
                of: find.byWidget(slot),
                matching: find.byWidget(slot.child!),
              ),
            )
            .height,
    ];
    expect(fills, [11, 22, 5.5, 0, 0, 0, 0]);

    // A tap opens the card's menu; a usual goal shows on the card with its
    // line, and "no goal" takes both away again.
    String cardText() => tester
        .widget<Text>(find.byKey(DiaryStepsCard.valueKey))
        .textSpan!
        .toPlainText();
    await tester.tap(find.byKey(DiaryStepsCard.cardKey));
    await tester.pumpAndSettle();
    expect(find.byKey(DiaryStepsCardMenu.menuKey), findsOneWidget);

    // 7500, so no day of the week reaches it: the gold foil of a day at
    // its goal needs the tilt sensor, which the tester does not have.
    await tester.tap(find.byKey(DiaryStepsCardMenu.presetKey(7500)));
    await tester.pumpAndSettle();
    expect(cardText(), '1.500 / 7.500');
    expect(find.byKey(DiaryStepsCard.goalLineKey), findsOneWidget);

    await tester.tap(find.byKey(DiaryStepsCardMenu.noGoalKey));
    await tester.pumpAndSettle();
    expect(cardText(), '1.500 Schritte');
    expect(find.byKey(DiaryStepsCard.goalLineKey), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
