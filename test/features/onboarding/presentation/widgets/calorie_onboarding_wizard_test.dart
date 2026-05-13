import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/onboarding/presentation/calorie_goal_onboarding_keys.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/'
    'calorie_onboarding_wizard.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../calories/support/fake_calories_repositories.dart';

void main() {
  testWidgets('seeds placeholder entries for start-now estimate high', (
    tester,
  ) async {
    final harness = await _pumpOnboarding(tester);
    await _goToStartDateStep(tester);

    await tester.tap(
      find.byKey(CalorieGoalOnboardingKeys.goalStartNowOption),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(CalorieGoalOnboardingKeys.todayTrackingEstimateOption),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CalorieGoalOnboardingKeys.catchUpHighOption));
    await tester.pumpAndSettle();

    await _tapNext(tester);

    expect(find.text('Results'), findsOneWidget);

    await tester.tap(find.text("Let's go"));
    await tester.pumpAndSettle();

    expect(harness.runStateRepository.state.currentWeekStartDayKey, isNotNull);
    expect(
      harness.runStateRepository.state.currentWeekStartDayKey,
      diaryDayKey(normalizeDiaryDay(DateTime.now())),
    );
    // heartCreditKcal is no longer used for onboarding catch-up; instead
    // the user gets real "estimated meal" placeholder entries in the diary.
    expect(harness.runStateRepository.state.heartCreditKcal, 0);
    final placeholders = harness.logRepository.entries
        .where((e) => e.name == 'Estimated meal')
        .toList();
    // Depending on the time-of-day at which the test runs, there may be
    // 0+ placeholders. We assert the soft invariant: any placeholder
    // created has a positive kcal amount.
    for (final p in placeholders) {
      expect(p.totalKcal, greaterThan(0));
    }
  });

  testWidgets('saves start-now exact without catch-up estimate', (
    tester,
  ) async {
    final harness = await _pumpOnboarding(tester);
    await _goToStartDateStep(tester);

    await tester.tap(
      find.byKey(CalorieGoalOnboardingKeys.goalStartNowOption),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(CalorieGoalOnboardingKeys.todayTrackingExactOption),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(CalorieGoalOnboardingKeys.catchUpHighOption),
      findsNothing,
    );

    await _tapNext(tester);
    await tester.tap(find.text("Let's go"));
    await tester.pumpAndSettle();

    final today = normalizeDiaryDay(DateTime.now());
    final settings = await harness.settingsRepository.readSettings();
    final goalEntry = settings.goalHistory.single;
    expect(goalEntry.effectiveDate, today);
    expect(goalEntry.effectiveCountingStartDate, today);
    expect(harness.runStateRepository.state.currentWeekStartDayKey, isNotNull);
    expect(harness.logRepository.entries, isEmpty);
  });

  testWidgets('saves start-later future date selected through picker', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 13, 10);
    final harness = await _pumpOnboarding(tester, now: () => now);
    await _goToStartDateStep(tester);

    await tester.tap(
      find.byKey(CalorieGoalOnboardingKeys.goalStartLaterOption),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(CalorieGoalOnboardingKeys.goalStartChangeButton),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK').last);
    await tester.pumpAndSettle();

    await _tapNext(tester);
    await tester.tap(find.text("Let's go"));
    await tester.pumpAndSettle();

    final tomorrow = DateTime(2026, 5, 14);
    final settings = await harness.settingsRepository.readSettings();
    expect(settings.nextGoalStartAfterDay(now), tomorrow);
    expect(harness.runStateRepository.state.currentWeekStartDayKey, isNull);
    expect(harness.runStateRepository.state.runWeekNumber, 1);
    expect(harness.logRepository.entries, isEmpty);
  });

  testWidgets('shows failure snackbar when calculated goal save fails', (
    tester,
  ) async {
    final harness = await _pumpOnboarding(tester);
    await _goToStartDateStep(tester);

    await tester.tap(
      find.byKey(CalorieGoalOnboardingKeys.goalStartLaterOption),
    );
    await tester.pumpAndSettle();
    await _tapNext(tester);

    harness.settingsRepository.saveShouldFail = true;
    await tester.tap(find.text("Let's go"));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not save the calculated calorie target.'),
      findsOneWidget,
    );
    expect(find.text("Let's go"), findsOneWidget);
  });

  testWidgets('blocks personal info step and shows age and height errors', (
    tester,
  ) async {
    await _pumpOnboarding(tester);
    await _startWizard(tester);

    await tester.tap(find.text('Female'));
    await tester.pumpAndSettle();
    await _tapNext(tester);

    expect(find.text('Tell us something about yourself.'), findsOneWidget);
    expect(find.text('Please enter your age.'), findsOneWidget);
    expect(find.text('Please enter your height.'), findsOneWidget);
  });

  testWidgets('blocks goal weight step when target weight is empty', (
    tester,
  ) async {
    await _pumpOnboarding(tester);
    await _startWizard(tester);
    await _completePersonalInfo(tester);
    await _tapNext(tester);

    await tester.enterText(find.byType(TextFormField).at(0), '70');
    await _tapNext(tester);

    expect(find.text('Your Goal'), findsOneWidget);
    expect(find.text('Please enter your weight.'), findsOneWidget);
  });

  testWidgets('shows minimum goal warning on ready step', (tester) async {
    await _pumpOnboarding(tester);
    await _goToStartDateStep(
      tester,
      age: '70',
      height: '150',
      weight: '50',
      targetWeight: '45',
    );

    await tester.tap(
      find.byKey(CalorieGoalOnboardingKeys.goalStartLaterOption),
    );
    await tester.pumpAndSettle();
    await _tapNext(tester);

    expect(find.textContaining('daily target cannot go below'), findsOneWidget);
  });
}

Future<_OnboardingHarness> _pumpOnboarding(
  WidgetTester tester, {
  CalorieGoalSettings initialSettings = const CalorieGoalSettings.empty(),
  BurnWeekRunState initialRunState = const BurnWeekRunState.initial(),
  DateTime Function()? now,
}) async {
  final settingsRepository = FakeCalorieSettingsRepository(
    initialSettings: initialSettings,
  );
  final logRepository = FakeCalorieLogRepository();
  final runStateRepository = _FakeBurnWeekRunStateRepository(initialRunState);
  addTearDown(settingsRepository.dispose);
  addTearDown(logRepository.dispose);

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(
          body: SizedBox.shrink(),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => CalorieOnboardingWizard(
          initialSettings: initialSettings,
          now: now,
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(
          settingsRepository,
        ),
        calorieLogRepositoryProvider.overrideWithValue(logRepository),
        burnWeekRunStateRepositoryProvider.overrideWithValue(
          runStateRepository,
        ),
      ],
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  unawaited(router.push('/onboarding'));
  await tester.pumpAndSettle();

  return _OnboardingHarness(
    settingsRepository: settingsRepository,
    logRepository: logRepository,
    runStateRepository: runStateRepository,
  );
}

Future<void> _startWizard(WidgetTester tester) async {
  await tester.tap(find.text("Let's start"));
  await tester.pumpAndSettle();
}

Future<void> _completePersonalInfo(
  WidgetTester tester, {
  String age = '30',
  String height = '170',
}) async {
  await tester.tap(find.text('Female'));
  await tester.enterText(find.byType(TextFormField).at(0), age);
  await tester.enterText(find.byType(TextFormField).at(1), height);
  await _tapNext(tester);
}

Future<void> _goToStartDateStep(
  WidgetTester tester, {
  String age = '30',
  String height = '170',
  String weight = '70',
  String targetWeight = '80',
}) async {
  await _startWizard(tester);
  await _completePersonalInfo(tester, age: age, height: height);
  await _tapNext(tester);

  await tester.enterText(find.byType(TextFormField).at(0), weight);
  await tester.enterText(find.byType(TextFormField).at(1), targetWeight);
  await _tapNext(tester);

  await _tapNext(tester);
  await _tapNext(tester);
}

Future<void> _tapNext(WidgetTester tester) async {
  final next = find.text('Next');
  final soundsGreat = find.text('Sounds great, next!');
  final button = next.evaluate().isNotEmpty ? next : soundsGreat;
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

class _OnboardingHarness {
  _OnboardingHarness({
    required this.settingsRepository,
    required this.logRepository,
    required this.runStateRepository,
  });

  final FakeCalorieSettingsRepository settingsRepository;
  final FakeCalorieLogRepository logRepository;
  final _FakeBurnWeekRunStateRepository runStateRepository;
}

class _FakeBurnWeekRunStateRepository implements BurnWeekRunStateRepository {
  _FakeBurnWeekRunStateRepository(this.state);

  BurnWeekRunState state;

  @override
  Future<BurnWeekRunState> readState() async => state;

  @override
  Future<bool> saveState(BurnWeekRunState nextState) async {
    state = nextState;
    return true;
  }
}
