import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/calories/provider/burn_week_live_sync_provider.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_provider.dart';
import 'package:yamt/features/diary/presentation/diary_page.dart';
import 'package:yamt/features/diary/provider/diary_calendar_controller.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/health/provider/diary_health_service_provider.dart';
import 'package:yamt/features/health/provider/health_connection_service_provider.dart';
import 'package:yamt/features/health/provider/health_weight_service_provider.dart';
import 'package:yamt/features/health/provider/manual_health_weight_repository_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/memory_app_preferences.dart';
import '../../calories/support/fake_calories_repositories.dart';

final _weeklyCheckInViewModelStateProvider =
    StateProvider<CalorieWeeklyCheckInViewModel>(
      (ref) => _emptyWeeklyCheckInViewModel(),
    );

class _MockUser extends Mock implements User {}

class _FakeBurnWeekRunStateRepository implements BurnWeekRunStateRepository {
  BurnWeekRunState state = const BurnWeekRunState.initial();

  @override
  Future<BurnWeekRunState> readState() async => state;

  @override
  Future<bool> saveState(BurnWeekRunState state) async {
    this.state = state;
    return true;
  }
}

class _TestDiaryCalendarController extends DiaryCalendarController {
  _TestDiaryCalendarController(this.day);

  final DateTime day;

  @override
  DiaryCalendarState build() {
    final normalizedDay = normalizeDiaryDay(day);
    return DiaryCalendarState(
      today: normalizedDay,
      selectedDay: normalizedDay,
      todayRequest: 0,
    );
  }
}

void main() {
  final selectedDay = DateTime(2026, 4, 27);

  testWidgets(
    'scroll shortcut jumps to lazily rendered meals section via fallback',
    (tester) async {
      _setSmallSurface(tester);
      await _pumpDiaryPage(tester, selectedDay: selectedDay);

      expect(find.text('Diary'), findsNothing);
      expect(find.text('To diary').hitTestable(), findsOneWidget);

      await tester.tap(find.text('To diary').hitTestable());
      await _pumpFrames(tester, count: 16);

      expect(find.text('Diary'), findsOneWidget);
    },
  );

  testWidgets('scroll shortcut hides while the user is manually scrolling', (
    tester,
  ) async {
    _setSmallSurface(tester);
    await _pumpDiaryPage(tester, selectedDay: selectedDay);

    expect(find.text('To diary').hitTestable(), findsOneWidget);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ListView).first),
    );
    await gesture.moveBy(const Offset(0, -80));
    await tester.pump();

    expect(find.text('To diary').hitTestable(), findsNothing);

    await gesture.up();
    await _pumpFrames(tester);
  });

  testWidgets('auto-opens weekly check-in dialog', (tester) async {
    await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      initialWeeklyCheckIn: _weeklyCheckInViewModel(
        windowStartDate: DateTime(2026, 4, 20),
      ),
    );

    expect(find.byKey(CalorieWeeklyCheckInDialogKeys.dialog), findsOneWidget);
    expect(find.text('Apr 20 - Apr 26'), findsOneWidget);
  });

  testWidgets('defers a second weekly check-in while a dialog is open', (
    tester,
  ) async {
    final container = await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      initialWeeklyCheckIn: _weeklyCheckInViewModel(
        windowStartDate: DateTime(2026, 4, 13),
      ),
    );

    expect(find.byKey(CalorieWeeklyCheckInDialogKeys.dialog), findsOneWidget);
    expect(find.text('Apr 13 - Apr 19'), findsOneWidget);

    container
        .read(_weeklyCheckInViewModelStateProvider.notifier)
        .state = _weeklyCheckInViewModel(
      windowStartDate: DateTime(2026, 4, 20),
    );
    await tester.pump();

    expect(find.text('Apr 13 - Apr 19'), findsOneWidget);
    expect(find.text('Apr 20 - Apr 26'), findsNothing);

    await tester.tap(find.byKey(CalorieWeeklyCheckInDialogKeys.laterButton));
    await _pumpFrames(tester, count: 12);

    expect(find.byKey(CalorieWeeklyCheckInDialogKeys.dialog), findsOneWidget);
    expect(find.text('Apr 20 - Apr 26'), findsOneWidget);
  });

  testWidgets('debug dump shows success snackbar', (tester) async {
    await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      logRepository: FakeCalorieLogRepository(
        initialEntries: [
          _entry(
            id: 'debug-entry',
            day: selectedDay,
            mealType: MealType.breakfast,
          ),
        ],
      ),
    );

    await tester.tap(find.byKey(CaloriesPageKeys.calorieDebugDumpButton));
    await _pumpFrames(tester);

    expect(find.textContaining('Printed calorie debug table'), findsOneWidget);
  });

  testWidgets('debug dump shows failure snackbar', (tester) async {
    final logRepository = FakeCalorieLogRepository()
      ..onReadEntriesInRange = (startInclusive, endExclusive) async {
        throw StateError('debug dump failed');
      };

    await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      logRepository: logRepository,
    );

    await tester.tap(find.byKey(CaloriesPageKeys.calorieDebugDumpButton));
    await _pumpFrames(tester);

    expect(find.text('Could not print calorie debug table.'), findsOneWidget);
  });
}

Future<ProviderContainer> _pumpDiaryPage(
  WidgetTester tester, {
  required DateTime selectedDay,
  Locale locale = const Locale('en'),
  CalorieWeeklyCheckInViewModel? initialWeeklyCheckIn,
  FakeCalorieLogRepository? logRepository,
  FakeCalorieSettingsRepository? settingsRepository,
  List<Override> overrides = const [],
}) async {
  final resolvedLogRepository = logRepository ?? FakeCalorieLogRepository();
  final resolvedSettingsRepository =
      settingsRepository ??
      FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2200,
          calculatorProfile: null,
          effectiveDate: selectedDay.subtract(const Duration(days: 14)),
        ),
      );
  final user = _MockUser();
  when(() => user.uid).thenReturn('user-1');

  final container = ProviderContainer(
    overrides: [
      appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
      authStateChangesProvider.overrideWith((ref) => Stream<User?>.value(user)),
      calorieLogRepositoryProvider.overrideWithValue(resolvedLogRepository),
      calorieSettingsRepositoryProvider.overrideWithValue(
        resolvedSettingsRepository,
      ),
      burnWeekLiveSyncTickerPeriodProvider.overrideWithValue(null),
      burnWeekRunStateRepositoryProvider.overrideWithValue(
        _FakeBurnWeekRunStateRepository(),
      ),
      diaryCalendarControllerProvider.overrideWith(
        () => _TestDiaryCalendarController(selectedDay),
      ),
      healthConnectionServiceProvider.overrideWithValue(
        FakeHealthConnectionService(const HealthConnectionStatus.unsupported()),
      ),
      diaryHealthServiceProvider.overrideWithValue(
        FakeDiaryHealthService(const <String, DiaryHealthDayData>{}),
      ),
      healthWeightServiceProvider.overrideWithValue(
        FakeHealthWeightService(const <HealthWeightSample>[]),
      ),
      manualHealthWeightRepositoryProvider.overrideWithValue(
        FakeManualHealthWeightRepository(<ManualHealthWeightEntry>[]),
      ),
      calorieWeeklyCheckInViewModelProvider.overrideWith(
        (ref) => ref.watch(_weeklyCheckInViewModelStateProvider),
      ),
      ...overrides,
    ],
  );
  addTearDown(() async {
    await resolvedLogRepository.dispose();
    await resolvedSettingsRepository.dispose();
    container.dispose();
  });

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: DiaryPage(),
        ),
        routes: {
          AppRoutes.homeStatisticsWeight: (context) =>
              const Scaffold(body: Text('Trends')),
        },
      ),
    ),
  );
  await _pumpFrames(tester);
  if (initialWeeklyCheckIn != null) {
    container.read(_weeklyCheckInViewModelStateProvider.notifier).state =
        initialWeeklyCheckIn;
    await _pumpFrames(tester);
  }
  return container;
}

Future<void> _pumpFrames(WidgetTester tester, {int count = 8}) async {
  for (var index = 0; index < count; index += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void _setSmallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

CalorieWeeklyCheckInViewModel _emptyWeeklyCheckInViewModel() {
  return const CalorieWeeklyCheckInViewModel(
    pendingWeeklyCheckIn: null,
    shouldAutoOpen: false,
    days: <CalorieWeeklyCheckInWindowDay>[],
    calculation: null,
    blockedReason: null,
    missingIntakeDays: <DateTime>[],
    missingWeightDays: <DateTime>[],
    freshness: CalorieLearnedTdeeFreshness.none,
    latestLearnedTdeeAt: null,
    lowConfidence: false,
  );
}

CalorieWeeklyCheckInViewModel _weeklyCheckInViewModel({
  required DateTime windowStartDate,
}) {
  final pending = PendingCalorieGoalWeeklyCheckIn(
    windowStartDate: windowStartDate,
    windowEndDate: windowStartDate.add(const Duration(days: 6)),
    dueDate: windowStartDate.add(const Duration(days: 7)),
  );
  return CalorieWeeklyCheckInViewModel(
    pendingWeeklyCheckIn: pending,
    shouldAutoOpen: true,
    days: const <CalorieWeeklyCheckInWindowDay>[],
    calculation: const CalorieWeeklyCheckInCalculation(
      trendWeightChangePerDay: -0.05,
      averageIntakeKcal: 2100,
      measuredTrueTdeeKcal: 2450,
      calculatedTrueTdeeKcal: 2400,
      newGoalKcal: 2200,
      lastWeekAverageActiveKcal: 250,
      todayActiveKcal: 300,
      activityDeltaKcal: 50,
      dynamicGoalTodayKcal: 2250,
    ),
    blockedReason: null,
    missingIntakeDays: const <DateTime>[],
    missingWeightDays: const <DateTime>[],
    freshness: CalorieLearnedTdeeFreshness.none,
    latestLearnedTdeeAt: null,
    lowConfidence: false,
  );
}

CalorieEntry _entry({
  required String id,
  required DateTime day,
  required MealType mealType,
}) {
  final loggedAt = day.add(const Duration(hours: 8));
  return CalorieEntry(
    id: id,
    userId: 'user-1',
    name: 'Debug food',
    mealType: mealType,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 100,
    per100Protein: 10,
    per100Carbs: 12,
    per100Fat: 5,
    totalKcal: 100,
    totalProtein: 10,
    totalCarbs: 12,
    totalFat: 5,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}
