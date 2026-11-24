import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/device/local_notifications.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/calories/application/burn_week_live_sync_provider.dart';
import 'package:yamt/features/calories/application/calorie_entry_saver.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_product_cache_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_pace_notice_day_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_pace_notification_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_pace_notification_listener.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../helpers/auth_user_data_key_session.dart';
import '../../../../helpers/fake_local_notifications.dart';
import '../../../../helpers/memory_app_preferences.dart';
import '../../../calories/support/fake_calories_repositories.dart';
import '../../../calories/support/fake_planned_entry_repository.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth;

class _MockUser extends Mock implements User;

// A Monday, the day the goal starts: today's target stays at 2000 kcal.
final _today = DateTime(2026, 9, 28);

/// A meal of [kcal] kcal, eaten at 8:00.
CalorieEntry _meal(String id, double kcal) => CalorieEntry.create(
  id: id,
  userId: 'user-1',
  name: id,
  mealType: MealType.breakfast,
  consumedAmount: 100,
  consumedUnit: ConsumedUnit.grams,
  per100Kcal: kcal,
  per100Protein: 10,
  per100Carbs: 50,
  per100Fat: 5,
  loggedAt: _today.add(const Duration(hours: 8)),
  createdAt: _today,
  updatedAt: _today,
);

/// The listener over the diary's fake repositories, with the notices and
/// the pace marker on.
class _Harness {
  new({AsyncValue<double?>? tomorrow}) {
    final user = _MockUser();
    when(() => user.uid).thenReturn('user-1');
    final auth = _MockFirebaseAuth();
    when(() => auth.currentUser).thenReturn(user);
    container = ProviderContainer(
      overrides: [
        appPreferencesProvider.overrideWithValue(
          MemoryAppPreferences(
            initialInts: {'diary_pace_marker_v1': 1},
            initialStrings: {'diary_pace_notification_on_v1': 'set'},
          ),
        ),
        // 12:00: the 6:00 and 11:00 notices are past, 16:00 is pending.
        clockProvider.overrideWithValue(() => DateTime(2026, 9, 28, 12)),
        localNotificationsProvider.overrideWithValue(notifications),
        authStateChangesProvider.overrideWith(
          (ref) => Stream<User?>.value(user),
        ),
        userDataKeySessionProvider.overrideWith(AuthUserDataKeySession.new),
        firebaseAuthProvider.overrideWithValue(auth),
        if (tomorrow != null)
          diaryPaceTomorrowTargetProvider.overrideWithValue(tomorrow),
        calorieSettingsRepositoryProvider.overrideWithValue(settings),
        calorieLogRepositoryProvider.overrideWithValue(log),
        calorieProductCacheRepositoryProvider.overrideWithValue(
          FakeCalorieProductCacheRepository(),
        ),
        plannedEntryRepositoryProvider.overrideWithValue(
          FakePlannedEntryRepository(),
        ),
        burnWeekLiveSyncTickerPeriodProvider.overrideWithValue(null),
        burnWeekRunStateRepositoryProvider.overrideWithValue(
          FakeBurnWeekRunStateRepository(),
        ),
        healthConnectionServiceProvider.overrideWithValue(
          FakeHealthConnectionService(
            const HealthConnectionStatus.unsupported(),
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
  }

  final notifications = FakeLocalNotifications();
  final settings = FakeCalorieSettingsRepository(
    initialSettings: CalorieGoalSettings.single(
      dailyKcalGoal: 2000,
      calculatorProfile: const CalorieCalculatorProfile.defaults().copyWith(
        trainingWeekdays: const [],
      ),
      effectiveDate: _today,
    ),
  );
  final log = FakeCalorieLogRepository();
  late final ProviderContainer container;

  Widget app(Locale locale) => UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const DiaryPaceNotificationListener(child: SizedBox()),
    ),
  );

  Future<void> dispose() async {
    container.dispose();
    await settings.dispose();
    await log.dispose();
  }
}

Future<_Harness> _pump(
  WidgetTester tester, {
  AsyncValue<double?>? tomorrow,
  void Function(FakeLocalNotifications notifications)? seed,
}) async {
  final harness = _Harness(tomorrow: tomorrow);
  addTearDown(harness.dispose);
  seed?.call(harness.notifications);
  await tester.pumpWidget(harness.app(const Locale('de')));
  await tester.pumpAndSettle();
  return harness;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The pending notice planned for [at] today, or null.
  ({DateTime at, String title, String payload})? at(
    _Harness harness,
    int hour,
  ) => harness.notifications.scheduled.values
      .where((n) => n.at == DateTime(2026, 9, 28, hour))
      .firstOrNull;

  testWidgets('schedules the notices once today loads, with localized texts', (
    tester,
  ) async {
    final harness = await _pump(tester);

    // 12:00, 2000 kcal, nothing eaten: the 11:00 notice is past, the 16:00
    // one says what is due by the end of dinner's part: 1.800 kcal.
    expect(at(harness, 11), isNull);
    expect(at(harness, 16)!.title, 'Hey, du hast wieder 1.800 kcal frei');
    expect(at(harness, 20), isNull);
  });

  testWidgets('a new entry lowers the value of the pending notice', (
    tester,
  ) async {
    final harness = await _pump(tester);

    await harness.container.read(calorieEntrySaverProvider)(
      _meal('lunch', 900),
    );
    // The diary waits a moment for the backend before it reads again.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // 900 kcal eaten: 1.800 due by the end of dinner's part minus 900.
    expect(at(harness, 16)!.title, 'Hey, du hast wieder 900 kcal frei');
  });

  testWidgets('cancels the notices when the user turns them off', (
    tester,
  ) async {
    final harness = await _pump(tester);
    expect(harness.notifications.scheduled, isNotEmpty);

    await harness.container
        .read(diaryPaceNotificationControllerProvider.notifier)
        .setEnabled(enabled: false);
    await tester.pumpAndSettle();

    expect(harness.notifications.scheduled, isEmpty);
  });

  testWidgets('schedules again when the language changes', (tester) async {
    final harness = await _pump(tester);
    String title() => at(harness, 16)!.title;
    expect(title(), 'Hey, du hast wieder 1.800 kcal frei');

    // The same listener, only the app's language changes.
    await tester.pumpWidget(harness.app(const Locale('en')));
    await tester.pumpAndSettle();

    expect(title(), 'Hey, you have 1,800 kcal free again');
  });

  group('tomorrow notice', () {
    final tomorrowAt = DateTime(2026, 9, 29, 6);
    const tomorrowId = 300000050;
    ({DateTime at, String title, String payload}) pending() =>
        (at: tomorrowAt, title: 'pending', payload: diaryPaceChannelId);

    testWidgets("plans tomorrow's day start from tomorrow's budget", (
      tester,
    ) async {
      final harness = await _pump(tester);

      // 2000 kcal, 25 % due by the end of breakfast.
      final notice = harness.notifications.scheduled[tomorrowId]!;
      expect(notice.at, tomorrowAt);
      expect(notice.title, 'Hey, du hast wieder 500 kcal frei');
    });

    testWidgets('passes the target of tomorrow on to the notice', (
      tester,
    ) async {
      final harness = await _pump(tester, tomorrow: const AsyncData(1200));

      expect(
        harness.notifications.scheduled[tomorrowId]!.title,
        'Hey, du hast wieder 300 kcal frei',
      );
    });

    testWidgets('keeps a pending notice while tomorrow loads', (tester) async {
      final harness = await _pump(
        tester,
        tomorrow: const AsyncLoading(),
        seed: (n) => n.scheduled[tomorrowId] = pending(),
      );

      expect(harness.notifications.scheduled[tomorrowId]!.title, 'pending');
      // Today's notices are planned all the same.
      expect(at(harness, 16), isNotNull);
    });

    testWidgets('cancels a pending notice when tomorrow is a pause day', (
      tester,
    ) async {
      final harness = await _pump(
        tester,
        tomorrow: const AsyncData(null),
        seed: (n) => n.scheduled[tomorrowId] = pending(),
      );

      expect(harness.notifications.scheduled.containsKey(tomorrowId), isFalse);
    });
  });
}
