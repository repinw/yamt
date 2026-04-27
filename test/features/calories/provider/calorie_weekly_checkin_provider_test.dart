import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/provider/calorie_balance_summary_provider.dart';
import 'package:yamt/features/calories/provider/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_provider.dart';
import 'package:yamt/features/health/data/diary_health_service.dart';
import 'package:yamt/features/health/data/health_connection_service.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/health/provider/diary_health_service_provider.dart';
import 'package:yamt/features/health/provider/health_connection_service_provider.dart';
import 'package:yamt/features/health/provider/health_weight_service_provider.dart';
import 'package:yamt/features/health/provider/manual_health_weight_repository_provider.dart';

import '../support/fake_calories_repositories.dart';

const _notReadyStatus = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.notGranted,
  historyAccess: HealthHistoryAccess.notGranted,
);

const _readyStatus = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.granted,
  historyAccess: HealthHistoryAccess.granted,
);

CalorieEntry _entry(String id, DateTime loggedAt, double kcal) {
  return CalorieEntry.create(
    id: id,
    userId: 'user-1',
    name: 'Item $id',
    mealType: MealType.breakfast,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: kcal,
    per100Protein: 10,
    per100Carbs: 5,
    per100Fat: 2,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

ProviderContainer _createContainer({
  required DateTime today,
  required FakeCalorieLogRepository logRepository,
  required FakeCalorieSettingsRepository settingsRepository,
  required ManualHealthWeightRepository manualRepository,
  HealthConnectionService? healthConnectionService,
  FakeHealthWeightService? healthWeightService,
  DiaryHealthService? diaryHealthService,
}) {
  return ProviderContainer(
    overrides: [
      calorieBalanceNowProvider.overrideWith(
        (ref) =>
            () => today,
      ),
      calorieLogRepositoryProvider.overrideWithValue(logRepository),
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      healthConnectionServiceProvider.overrideWith(
        (ref) =>
            healthConnectionService ??
            FakeHealthConnectionService(_notReadyStatus),
      ),
      if (healthWeightService != null)
        healthWeightServiceProvider.overrideWith((ref) => healthWeightService),
      if (diaryHealthService != null)
        diaryHealthServiceProvider.overrideWith((ref) => diaryHealthService),
      manualHealthWeightRepositoryProvider.overrideWith(
        (ref) => manualRepository,
      ),
    ],
  );
}

void main() {
  test('day 8 creates pending weekly check-in and ready calculation', () async {
    final today = DateTime(2026, 4, 15);
    final goalStart = DateTime(2026, 4, 8);
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2400,
        calculatorProfile: null,
        effectiveDate: goalStart,
      ),
    );
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        for (var index = 0; index < 7; index += 1)
          _entry(
            'entry-$index',
            goalStart.add(Duration(days: index, hours: 8)),
            2100 + (index * 10),
          ),
      ],
    );
    final manualRepository = FakeManualHealthWeightRepository(
      <ManualHealthWeightEntry>[
        ManualHealthWeightEntry(day: goalStart, weightKg: 82),
        ManualHealthWeightEntry(
          day: goalStart.add(const Duration(days: 6)),
          weightKg: 81.4,
        ),
      ],
    );
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    final container = _createContainer(
      today: today,
      logRepository: logRepository,
      settingsRepository: settingsRepository,
      manualRepository: manualRepository,
    );
    addTearDown(container.dispose);

    final viewModel = await container.read(
      calorieWeeklyCheckInViewModelProvider.future,
    );

    expect(viewModel.hasPending, isTrue);
    expect(viewModel.shouldAutoOpen, isTrue);
    expect(viewModel.isReady, isTrue);
    expect(
      viewModel.pendingWeeklyCheckIn?.windowStartDate,
      DateTime(2026, 4, 8),
    );
    expect(
      viewModel.pendingWeeklyCheckIn?.windowEndDate,
      DateTime(2026, 4, 14),
    );
    expect(viewModel.lowConfidence, isTrue);
    expect(viewModel.calculation?.newGoalKcal, greaterThan(0));
  });

  test(
    'same-day starter creates first check-in after 6 normal tracked days',
    () async {
      final today = DateTime(2026, 4, 15);
      final goalStart = DateTime(2026, 4, 8, 18);
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2400,
          calculatorProfile: null,
          effectiveDate: goalStart,
        ),
      );
      final logRepository = FakeCalorieLogRepository();
      final manualRepository = FakeManualHealthWeightRepository(
        <ManualHealthWeightEntry>[],
      );
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      final container = _createContainer(
        today: today,
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        manualRepository: manualRepository,
      );
      addTearDown(container.dispose);

      final viewModel = await container.read(
        calorieWeeklyCheckInViewModelProvider.future,
      );

      expect(viewModel.hasPending, isTrue);
      expect(viewModel.shouldAutoOpen, isTrue);
      expect(
        viewModel.pendingWeeklyCheckIn?.windowStartDate,
        DateTime(2026, 4, 9),
      );
      expect(
        viewModel.pendingWeeklyCheckIn?.windowEndDate,
        DateTime(2026, 4, 14),
      );
      expect(viewModel.days, hasLength(6));
      expect(viewModel.calculation, isNull);
    },
  );

  test(
    'mid-day start uses start-day weight as baseline for shifted first window',
    () async {
      final today = DateTime(2026, 4, 16);
      final goalStart = DateTime(2026, 4, 8, 18);
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2400,
          calculatorProfile: null,
          effectiveDate: goalStart,
        ),
      );
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          for (var index = 0; index < 6; index += 1)
            _entry(
              'entry-$index',
              DateTime(2026, 4, 9).add(Duration(days: index, hours: 8)),
              2100 + (index * 10),
            ),
        ],
      );
      final manualRepository = FakeManualHealthWeightRepository(
        <ManualHealthWeightEntry>[
          ManualHealthWeightEntry(day: goalStart, weightKg: 82),
          ManualHealthWeightEntry(day: DateTime(2026, 4, 14), weightKg: 81.4),
        ],
      );
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      final container = _createContainer(
        today: today,
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        manualRepository: manualRepository,
      );
      addTearDown(container.dispose);

      final viewModel = await container.read(
        calorieWeeklyCheckInViewModelProvider.future,
      );

      expect(viewModel.isReady, isTrue);
      expect(
        viewModel.pendingWeeklyCheckIn?.windowStartDate,
        DateTime(2026, 4, 9),
      );
      expect(
        viewModel.pendingWeeklyCheckIn?.windowEndDate,
        DateTime(2026, 4, 14),
      );
      expect(viewModel.days.first.day, DateTime(2026, 4, 9));
      expect(viewModel.days.first.weightKg, 82);
      expect(viewModel.days, hasLength(6));
    },
  );

  test('3 missing intake days block new learning', () async {
    final today = DateTime(2026, 4, 15);
    final goalStart = DateTime(2026, 4, 8);
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2400,
        calculatorProfile: null,
        effectiveDate: goalStart,
      ),
    );
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        for (var index = 0; index < 4; index += 1)
          _entry(
            'entry-$index',
            goalStart.add(Duration(days: index, hours: 8)),
            2100 + (index * 10),
          ),
      ],
    );
    final manualRepository = FakeManualHealthWeightRepository(
      <ManualHealthWeightEntry>[
        ManualHealthWeightEntry(day: goalStart, weightKg: 82),
        ManualHealthWeightEntry(
          day: goalStart.add(const Duration(days: 6)),
          weightKg: 81.4,
        ),
      ],
    );
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    final container = _createContainer(
      today: today,
      logRepository: logRepository,
      settingsRepository: settingsRepository,
      manualRepository: manualRepository,
    );
    addTearDown(container.dispose);

    final viewModel = await container.read(
      calorieWeeklyCheckInViewModelProvider.future,
    );

    expect(viewModel.hasPending, isTrue);
    expect(viewModel.isBlocked, isTrue);
    expect(
      viewModel.blockedReason,
      CalorieWeeklyCheckInBlockedReason.tooManyMissingIntakeDays,
    );
    expect(viewModel.calculation, isNull);
  });

  test(
    'uses calculator start weight on anchor day when no real weight exists',
    () async {
      final today = DateTime(2026, 4, 15);
      final goalStart = DateTime(2026, 4, 8);
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2400,
          calculatorProfile: const CalorieCalculatorProfile(
            sex: CalorieCalculatorSex.male,
            weightKg: 82,
            heightCm: 180,
            ageYears: 30,
            activityLevel: 1.2,
            goalMode: CalorieGoalMode.maintain,
            goalSpeedKgPerWeek: 0,
          ),
          effectiveDate: goalStart,
          source: CalorieGoalSource.calculator,
        ),
      );
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          for (var index = 0; index < 7; index += 1)
            _entry(
              'entry-$index',
              goalStart.add(Duration(days: index, hours: 8)),
              2100 + (index * 10),
            ),
        ],
      );
      final manualRepository = FakeManualHealthWeightRepository(
        <ManualHealthWeightEntry>[
          ManualHealthWeightEntry(
            day: goalStart.add(const Duration(days: 6)),
            weightKg: 81.4,
          ),
        ],
      );
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      final container = _createContainer(
        today: today,
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        manualRepository: manualRepository,
      );
      addTearDown(container.dispose);

      final viewModel = await container.read(
        calorieWeeklyCheckInViewModelProvider.future,
      );

      expect(viewModel.isReady, isTrue);
      expect(viewModel.days.first.weightKg, 82);
    },
  );

  test(
    'keeps noisy weight week calculable after same-day outlier reduction',
    () async {
      final today = DateTime(2026, 4, 15);
      final goalStart = DateTime(2026, 4, 8);
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2426.88,
          calculatorProfile: const CalorieCalculatorProfile(
            sex: CalorieCalculatorSex.male,
            weightKg: 84,
            heightCm: 172,
            ageYears: 31,
            activityLevel: 1.375,
            goalMode: CalorieGoalMode.maintain,
            goalSpeedKgPerWeek: 0,
          ),
          effectiveDate: goalStart,
          source: CalorieGoalSource.calculator,
        ),
      );
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          _entry('d0', DateTime(2026, 4, 8, 8), 2752.60),
          _entry('d1', DateTime(2026, 4, 9, 8), 3974.80),
          _entry('d2', DateTime(2026, 4, 10, 8), 906.37),
          _entry('d3', DateTime(2026, 4, 11, 8), 2744.72),
          _entry('d4', DateTime(2026, 4, 12, 8), 2039.88),
          _entry('d5', DateTime(2026, 4, 13, 8), 1811.05),
          _entry('d6', DateTime(2026, 4, 14, 8), 2996.53),
        ],
      );
      final healthWeightService = FakeHealthWeightService(<HealthWeightSample>[
        HealthWeightSample(recordedAt: DateTime(2026, 4, 8, 7), weightKg: 84),
        HealthWeightSample(
          recordedAt: DateTime(2026, 4, 9, 7),
          weightKg: 84.15,
        ),
        HealthWeightSample(
          recordedAt: DateTime(2026, 4, 10, 7),
          weightKg: 83.55,
        ),
        HealthWeightSample(
          recordedAt: DateTime(2026, 4, 11, 7),
          weightKg: 83.6,
        ),
        HealthWeightSample(
          recordedAt: DateTime(2026, 4, 11, 21),
          weightKg: 81.7,
        ),
        HealthWeightSample(
          recordedAt: DateTime(2026, 4, 12, 7),
          weightKg: 83.65,
        ),
        HealthWeightSample(
          recordedAt: DateTime(2026, 4, 13, 7),
          weightKg: 83,
        ),
        HealthWeightSample(
          recordedAt: DateTime(2026, 4, 14, 7),
          weightKg: 83.5,
        ),
      ]);
      final manualRepository = FakeManualHealthWeightRepository(
        <ManualHealthWeightEntry>[],
      );
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      final container = _createContainer(
        today: today,
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        manualRepository: manualRepository,
        healthConnectionService: FakeHealthConnectionService(_readyStatus),
        healthWeightService: healthWeightService,
        diaryHealthService: FakeDiaryHealthService(
          const <String, DiaryHealthDayData>{},
        ),
      );
      addTearDown(container.dispose);

      final viewModel = await container.read(
        calorieWeeklyCheckInViewModelProvider.future,
      );

      expect(viewModel.isReady, isTrue);
      expect(
        viewModel.days
            .firstWhere((day) => day.day == DateTime(2026, 4, 11))
            .weightKg,
        closeTo(82.65, 0.0001),
      );
      expect(viewModel.blockedReason, isNull);
      expect(viewModel.calculation, isNotNull);
      expect(viewModel.calculation!.newGoalKcal, greaterThan(2426.88));
    },
  );

  test(
    'uses due-day health weight as end boundary for first window',
    () async {
      final today = DateTime(2026, 4, 15);
      final goalStart = DateTime(2026, 4, 8);
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2400,
          calculatorProfile: null,
          effectiveDate: goalStart,
        ),
      );
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          for (var index = 0; index < 7; index += 1)
            _entry(
              'entry-$index',
              goalStart.add(Duration(days: index, hours: 8)),
              2100 + (index * 10),
            ),
        ],
      );
      final healthWeightService = FakeHealthWeightService(
        <HealthWeightSample>[
          HealthWeightSample(
            recordedAt: DateTime(2026, 4, 8, 7),
            weightKg: 82,
          ),
          HealthWeightSample(
            recordedAt: DateTime(2026, 4, 15, 7),
            weightKg: 81.4,
          ),
        ],
      );
      final manualRepository = FakeManualHealthWeightRepository(
        <ManualHealthWeightEntry>[],
      );
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      final container = _createContainer(
        today: today,
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        manualRepository: manualRepository,
        healthConnectionService: FakeHealthConnectionService(_readyStatus),
        healthWeightService: healthWeightService,
        diaryHealthService: FakeDiaryHealthService(
          const <String, DiaryHealthDayData>{},
        ),
      );
      addTearDown(container.dispose);

      final viewModel = await container.read(
        calorieWeeklyCheckInViewModelProvider.future,
      );

      expect(viewModel.isReady, isTrue);
      expect(viewModel.missingWeightDays, isEmpty);
      expect(viewModel.days.first.weightKg, 82);
      expect(viewModel.days.last.weightKg, 81.4);
    },
  );

  test(
    'uses available trend weights when exact start weight is missing',
    () async {
      final today = DateTime(2026, 4, 15);
      final goalStart = DateTime(2026, 4, 8);
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2400,
          calculatorProfile: null,
          effectiveDate: goalStart,
        ),
      );
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          for (var index = 0; index < 7; index += 1)
            _entry(
              'entry-$index',
              goalStart.add(Duration(days: index, hours: 8)),
              2100 + (index * 10),
            ),
        ],
      );
      final healthWeightService = FakeHealthWeightService(
        <HealthWeightSample>[
          HealthWeightSample(
            recordedAt: DateTime(2026, 4, 9, 7),
            weightKg: 82,
          ),
          HealthWeightSample(
            recordedAt: DateTime(2026, 4, 14, 7),
            weightKg: 81.4,
          ),
        ],
      );
      final manualRepository = FakeManualHealthWeightRepository(
        <ManualHealthWeightEntry>[],
      );
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      final container = _createContainer(
        today: today,
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        manualRepository: manualRepository,
        healthConnectionService: FakeHealthConnectionService(_readyStatus),
        healthWeightService: healthWeightService,
        diaryHealthService: FakeDiaryHealthService(
          const <String, DiaryHealthDayData>{},
        ),
      );
      addTearDown(container.dispose);

      final viewModel = await container.read(
        calorieWeeklyCheckInViewModelProvider.future,
      );

      expect(viewModel.isReady, isTrue);
      expect(viewModel.blockedReason, isNull);
      expect(viewModel.missingWeightDays, isEmpty);
      expect(viewModel.calculation, isNotNull);
    },
  );

  test(
    'second overdue window uses previous and next boundary weights',
    () async {
      final today = DateTime(2026, 4, 23);
      final settings = const CalorieGoalSettings.empty()
          .applyGoalChange(
            changedAt: DateTime(2026, 4, 8),
            dailyKcalGoal: 2400,
            calculatorProfile: null,
          )
          .applyGoalChange(
            changedAt: DateTime(2026, 4, 15, 10),
            dailyKcalGoal: 2350,
            calculatorProfile: null,
            source: CalorieGoalSource.weeklyCheckIn,
            weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
              windowStartDate: DateTime(2026, 4, 8),
              windowEndDate: DateTime(2026, 4, 14),
              trendWeightChangePerDay: -0.05,
              calculatedTrueTdeeKcal: 2400,
              averageActiveKcal: 200,
              lowConfidence: false,
            ),
          );
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: settings,
      );
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          for (var index = 0; index < 7; index += 1)
            _entry(
              'previous-entry-$index',
              DateTime(2026, 4, 8).add(Duration(days: index, hours: 8)),
              2000 + (index * 10),
            ),
          for (var index = 0; index < 7; index += 1)
            _entry(
              'entry-$index',
              DateTime(2026, 4, 15).add(Duration(days: index, hours: 8)),
              2100 + (index * 10),
            ),
        ],
      );
      final healthWeightService = FakeHealthWeightService(
        <HealthWeightSample>[
          HealthWeightSample(
            recordedAt: DateTime(2026, 4, 8, 7),
            weightKg: 82.6,
          ),
          HealthWeightSample(
            recordedAt: DateTime(2026, 4, 14, 7),
            weightKg: 82,
          ),
          HealthWeightSample(
            recordedAt: DateTime(2026, 4, 22, 7),
            weightKg: 81.4,
          ),
        ],
      );
      final manualRepository = FakeManualHealthWeightRepository(
        <ManualHealthWeightEntry>[],
      );
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      final container = _createContainer(
        today: today,
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        manualRepository: manualRepository,
        healthConnectionService: FakeHealthConnectionService(_readyStatus),
        healthWeightService: healthWeightService,
        diaryHealthService: FakeDiaryHealthService(
          const <String, DiaryHealthDayData>{},
        ),
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        calorieWeeklyCheckInViewModelProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      final viewModel = await container.read(
        calorieWeeklyCheckInViewModelProvider.future,
      );

      expect(viewModel.isReady, isTrue);
      expect(
        viewModel.pendingWeeklyCheckIn?.windowStartDate,
        DateTime(2026, 4, 15),
      );
      expect(
        viewModel.pendingWeeklyCheckIn?.windowEndDate,
        DateTime(2026, 4, 21),
      );
      expect(viewModel.missingWeightDays, isEmpty);
      expect(viewModel.days.first.weightKg, 82);
      expect(viewModel.days.last.weightKg, 81.4);
      expect(
        viewModel.calculation?.trendWeightChangePerDay,
        closeTo(-0.08506, 0.00001),
      );
      expect(viewModel.calculation?.averageIntakeKcal, closeTo(2080, 0.01));

      await logRepository.saveEntry(
        _entry('previous-entry-0', DateTime(2026, 4, 8, 8), 3000),
      );
      container.read(calorieOverviewRevisionProvider.notifier).markChanged();

      final recomputedViewModel = await container.read(
        calorieWeeklyCheckInViewModelProvider.future,
      );

      expect(
        recomputedViewModel.calculation?.averageIntakeKcal,
        closeTo(2151.43, 0.01),
      );
    },
  );

  test(
    'dismissed pending window is treated as already seen',
    () async {
      final today = DateTime(2026, 4, 15);
      final goalStart = DateTime(2026, 4, 8);
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings:
            CalorieGoalSettings.single(
              dailyKcalGoal: 2400,
              calculatorProfile: null,
              effectiveDate: goalStart,
            ).copyWithPendingWeeklyCheckIn(
              PendingCalorieGoalWeeklyCheckIn(
                windowStartDate: DateTime(2026, 4, 8),
                windowEndDate: DateTime(2026, 4, 14),
                dueDate: DateTime(2026, 4, 15),
                dismissedAt: DateTime(2026, 4, 15, 10),
              ),
            ),
      );
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          for (var index = 0; index < 7; index += 1)
            _entry(
              'entry-$index',
              goalStart.add(Duration(days: index, hours: 8)),
              2100 + (index * 10),
            ),
        ],
      );
      final manualRepository = FakeManualHealthWeightRepository(
        <ManualHealthWeightEntry>[
          ManualHealthWeightEntry(day: goalStart, weightKg: 82),
          ManualHealthWeightEntry(
            day: goalStart.add(const Duration(days: 6)),
            weightKg: 81.4,
          ),
        ],
      );
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      final container = _createContainer(
        today: today,
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        manualRepository: manualRepository,
      );
      addTearDown(container.dispose);

      final viewModel = await container.read(
        calorieWeeklyCheckInViewModelProvider.future,
      );

      expect(viewModel.hasPending, isFalse);
      expect(viewModel.shouldAutoOpen, isFalse);
      expect(viewModel.showDiaryHint, isFalse);
    },
  );

  test(
    'dismissed summary cascades learned tdee into the next window',
    () async {
      final today = DateTime(2026, 4, 22);
      final goalStart = DateTime(2026, 4, 8);
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings:
            CalorieGoalSettings.single(
              dailyKcalGoal: 2400,
              calculatorProfile: null,
              effectiveDate: goalStart,
            ).copyWithPendingWeeklyCheckIn(
              PendingCalorieGoalWeeklyCheckIn(
                windowStartDate: DateTime(2026, 4, 8),
                windowEndDate: DateTime(2026, 4, 14),
                dueDate: DateTime(2026, 4, 15),
                dismissedAt: DateTime(2026, 4, 15, 10),
              ),
            ),
      );
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          for (var index = 0; index < 14; index += 1)
            _entry(
              'entry-$index',
              goalStart.add(Duration(days: index, hours: 8)),
              3000,
            ),
        ],
      );
      final manualRepository = FakeManualHealthWeightRepository(
        <ManualHealthWeightEntry>[
          ManualHealthWeightEntry(day: goalStart, weightKg: 80),
          ManualHealthWeightEntry(day: DateTime(2026, 4, 14), weightKg: 80),
          ManualHealthWeightEntry(day: DateTime(2026, 4, 21), weightKg: 80),
        ],
      );
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      final container = _createContainer(
        today: today,
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        manualRepository: manualRepository,
      );
      addTearDown(container.dispose);

      final viewModel = await container.read(
        calorieWeeklyCheckInViewModelProvider.future,
      );

      expect(
        viewModel.pendingWeeklyCheckIn?.windowStartDate,
        DateTime(2026, 4, 15),
      );
      expect(viewModel.isReady, isTrue);
      expect(
        viewModel.calculation?.calculatedTrueTdeeKcal,
        closeTo(2706, 0.01),
      );
      expect(viewModel.calculation?.newGoalKcal, closeTo(2706, 0.01));
    },
  );

  test(
    'freshness becomes urgent after 28 days without learned refresh',
    () async {
      final today = DateTime(2026, 5, 10);
      final settings = const CalorieGoalSettings.empty()
          .applyGoalChange(
            changedAt: DateTime(2026, 4, 1, 9),
            dailyKcalGoal: 2400,
            calculatorProfile: null,
          )
          .applyGoalChange(
            changedAt: DateTime(2026, 4, 8, 9),
            dailyKcalGoal: 2350,
            calculatorProfile: null,
            source: CalorieGoalSource.weeklyCheckIn,
            weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
              windowStartDate: DateTime(2026, 4),
              windowEndDate: DateTime(2026, 4, 7),
              trendWeightChangePerDay: -0.05,
              calculatedTrueTdeeKcal: 2400,
              averageActiveKcal: 200,
              lowConfidence: false,
            ),
          );
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: settings,
      );
      final logRepository = FakeCalorieLogRepository();
      final manualRepository = FakeManualHealthWeightRepository(
        <ManualHealthWeightEntry>[],
      );
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      final container = _createContainer(
        today: today,
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        manualRepository: manualRepository,
      );
      addTearDown(container.dispose);

      final viewModel = await container.read(
        calorieWeeklyCheckInViewModelProvider.future,
      );

      expect(viewModel.freshness, CalorieLearnedTdeeFreshness.urgent);
    },
  );

  test(
    'freshness becomes stale after 14 days without learned refresh',
    () async {
      final today = DateTime(2026, 4, 22);
      final settings = const CalorieGoalSettings.empty()
          .applyGoalChange(
            changedAt: DateTime(2026, 4, 1, 9),
            dailyKcalGoal: 2400,
            calculatorProfile: null,
          )
          .applyGoalChange(
            changedAt: DateTime(2026, 4, 8, 9),
            dailyKcalGoal: 2350,
            calculatorProfile: null,
            source: CalorieGoalSource.weeklyCheckIn,
            weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
              windowStartDate: DateTime(2026, 4),
              windowEndDate: DateTime(2026, 4, 7),
              trendWeightChangePerDay: -0.05,
              calculatedTrueTdeeKcal: 2400,
              averageActiveKcal: 200,
              lowConfidence: false,
            ),
          );
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: settings,
      );
      final logRepository = FakeCalorieLogRepository();
      final manualRepository = FakeManualHealthWeightRepository(
        <ManualHealthWeightEntry>[],
      );
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      final container = _createContainer(
        today: today,
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        manualRepository: manualRepository,
      );
      addTearDown(container.dispose);

      final viewModel = await container.read(
        calorieWeeklyCheckInViewModelProvider.future,
      );

      expect(viewModel.freshness, CalorieLearnedTdeeFreshness.stale);
    },
  );

  test(
    'first unresolved overdue window stays pending when multiple exist',
    () async {
      final today = DateTime(2026, 4, 22);
      final goalStart = DateTime(2026, 4);
      final settings = const CalorieGoalSettings.empty()
          .applyGoalChange(
            changedAt: goalStart,
            dailyKcalGoal: 2400,
            calculatorProfile: null,
          )
          .applyGoalChange(
            changedAt: DateTime(2026, 4, 8, 10),
            dailyKcalGoal: 2350,
            calculatorProfile: null,
            source: CalorieGoalSource.weeklyCheckIn,
            weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
              windowStartDate: DateTime(2026, 4),
              windowEndDate: DateTime(2026, 4, 7),
              trendWeightChangePerDay: -0.05,
              calculatedTrueTdeeKcal: 2400,
              averageActiveKcal: 200,
              lowConfidence: false,
            ),
          );
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: settings,
      );
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          for (var index = 0; index < 7; index += 1)
            _entry(
              'entry-$index',
              DateTime(2026, 4, 8).add(Duration(days: index, hours: 8)),
              2100 + (index * 10),
            ),
        ],
      );
      final manualRepository = FakeManualHealthWeightRepository(
        <ManualHealthWeightEntry>[
          ManualHealthWeightEntry(day: DateTime(2026, 4, 8), weightKg: 82),
          ManualHealthWeightEntry(day: DateTime(2026, 4, 14), weightKg: 81.4),
        ],
      );
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      final container = _createContainer(
        today: today,
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        manualRepository: manualRepository,
      );
      addTearDown(container.dispose);

      final viewModel = await container.read(
        calorieWeeklyCheckInViewModelProvider.future,
      );

      expect(viewModel.hasPending, isTrue);
      expect(
        viewModel.pendingWeeklyCheckIn?.windowStartDate,
        DateTime(2026, 4, 8),
      );
      expect(
        viewModel.pendingWeeklyCheckIn?.windowEndDate,
        DateTime(2026, 4, 14),
      );
    },
  );

  test('manual rerun resets weekly cadence anchor', () async {
    final today = DateTime(2026, 4, 27);
    final initialSettings = const CalorieGoalSettings.empty()
        .applyGoalChange(
          changedAt: DateTime(2026, 4),
          dailyKcalGoal: 2400,
          calculatorProfile: null,
        )
        .applyGoalChange(
          changedAt: DateTime(2026, 4, 15, 9),
          dailyKcalGoal: 2350,
          calculatorProfile: null,
          source: CalorieGoalSource.weeklyCheckIn,
          weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
            windowStartDate: DateTime(2026, 4, 8),
            windowEndDate: DateTime(2026, 4, 14),
            trendWeightChangePerDay: -0.08,
            calculatedTrueTdeeKcal: 2450,
            averageActiveKcal: 210,
            lowConfidence: false,
          ),
        )
        .applyGoalChange(
          changedAt: DateTime(2026, 4, 20),
          dailyKcalGoal: 2100,
          calculatorProfile: const CalorieCalculatorProfile.defaults(),
          source: CalorieGoalSource.calculator,
        );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: initialSettings,
    );
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        for (var index = 0; index < 7; index += 1)
          _entry(
            'entry-$index',
            DateTime(2026, 4, 20).add(Duration(days: index, hours: 8)),
            2000 + (index * 10),
          ),
      ],
    );
    final manualRepository = FakeManualHealthWeightRepository(
      <ManualHealthWeightEntry>[
        ManualHealthWeightEntry(day: DateTime(2026, 4, 20), weightKg: 82),
        ManualHealthWeightEntry(day: DateTime(2026, 4, 26), weightKg: 81.4),
      ],
    );
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    final container = _createContainer(
      today: today,
      logRepository: logRepository,
      settingsRepository: settingsRepository,
      manualRepository: manualRepository,
    );
    addTearDown(container.dispose);

    final viewModel = await container.read(
      calorieWeeklyCheckInViewModelProvider.future,
    );

    expect(viewModel.hasPending, isTrue);
    expect(
      viewModel.pendingWeeklyCheckIn?.windowStartDate,
      DateTime(2026, 4, 20),
    );
    expect(
      viewModel.pendingWeeklyCheckIn?.windowEndDate,
      DateTime(2026, 4, 26),
    );
  });

  test(
    'future counting start pauses weekly check in during sandbox days',
    () async {
      final today = DateTime(2026, 4, 22);
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: const CalorieGoalSettings.empty()
            .applyGoalChange(
              changedAt: DateTime(2026, 4),
              dailyKcalGoal: 2400,
              calculatorProfile: null,
            )
            .applyGoalChange(
              changedAt: DateTime(2026, 4, 8, 10),
              dailyKcalGoal: 2350,
              calculatorProfile: null,
              source: CalorieGoalSource.weeklyCheckIn,
              weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
                windowStartDate: DateTime(2026, 4),
                windowEndDate: DateTime(2026, 4, 7),
                trendWeightChangePerDay: -0.05,
                calculatedTrueTdeeKcal: 2400,
                averageActiveKcal: 200,
                lowConfidence: false,
              ),
            )
            .applyGoalChange(
              changedAt: today,
              dailyKcalGoal: 2100,
              calculatorProfile: const CalorieCalculatorProfile.defaults(),
              countingStartDate: today.add(const Duration(days: 2)),
            ),
      );
      final logRepository = FakeCalorieLogRepository();
      final manualRepository = FakeManualHealthWeightRepository(
        <ManualHealthWeightEntry>[],
      );
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      final container = _createContainer(
        today: today,
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        manualRepository: manualRepository,
      );
      addTearDown(container.dispose);

      final viewModel = await container.read(
        calorieWeeklyCheckInViewModelProvider.future,
      );

      expect(viewModel.hasPending, isFalse);
      expect(viewModel.pendingWeeklyCheckIn, isNull);
    },
  );

  test(
    'skipped intake day uses prior average and still allows calculation',
    () async {
      final today = DateTime(2026, 4, 15);
      final goalStart = DateTime(2026, 4, 8);
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2400,
          calculatorProfile: null,
          effectiveDate: goalStart,
        ).setSkippedIntakeDay(day: DateTime(2026, 4, 11), isSkipped: true),
      );
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          _entry('entry-0', DateTime(2026, 4, 8, 8), 2100),
          _entry('entry-1', DateTime(2026, 4, 9, 8), 2200),
          _entry('entry-2', DateTime(2026, 4, 10, 8), 2300),
          _entry('entry-4', DateTime(2026, 4, 12, 8), 2400),
          _entry('entry-5', DateTime(2026, 4, 13, 8), 2500),
          _entry('entry-6', DateTime(2026, 4, 14, 8), 2600),
        ],
      );
      final manualRepository = FakeManualHealthWeightRepository(
        <ManualHealthWeightEntry>[
          ManualHealthWeightEntry(day: goalStart, weightKg: 82),
          ManualHealthWeightEntry(
            day: goalStart.add(const Duration(days: 6)),
            weightKg: 81.4,
          ),
        ],
      );
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      final container = _createContainer(
        today: today,
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        manualRepository: manualRepository,
      );
      addTearDown(container.dispose);

      final viewModel = await container.read(
        calorieWeeklyCheckInViewModelProvider.future,
      );

      expect(viewModel.isReady, isTrue);
      final skippedDay = viewModel.days.firstWhere(
        (day) => day.day == DateTime(2026, 4, 11),
      );
      expect(skippedDay.isSkippedIntakeDay, isTrue);
      expect(skippedDay.resolvedIntakeKcal, closeTo(2200, 0.01));
    },
  );
}
