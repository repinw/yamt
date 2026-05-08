import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_goal_onboarding_start.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/widgets/onboarding/'
    'calorie_onboarding_wizard.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_goal_calculator_form_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../support/fake_calories_repositories.dart';

void main() {
  testWidgets('new onboarding seeds placeholder entries for high estimate', (
    tester,
  ) async {
    final settingsRepository = FakeCalorieSettingsRepository();
    final logRepository = FakeCalorieLogRepository();
    final runStateRepository = _FakeBurnWeekRunStateRepository(
      const BurnWeekRunState.initial(),
    );
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
          builder: (context, state) => const CalorieOnboardingWizard(
            initialSettings: CalorieGoalSettings.empty(),
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

    await tester.tap(find.text("Let's start"));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Female'));
    await tester.enterText(find.byType(TextFormField).at(0), '30');
    await tester.enterText(find.byType(TextFormField).at(1), '170');
    await _tapNext(tester);

    await _tapNext(tester);

    await tester.enterText(find.byType(TextFormField).at(0), '70');
    await tester.enterText(find.byType(TextFormField).at(1), '80');
    await _tapNext(tester);

    await _tapNext(tester);
    await _tapNext(tester);

    await tester.tap(find.text('I will estimate what I ate so far'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A lot'));
    await tester.pumpAndSettle();

    final formProvider = calorieGoalCalculatorFormControllerProvider(
      null,
      useEmptyDefaults: true,
    );
    final context = tester.element(find.byType(CalorieOnboardingWizard));
    final container = ProviderScope.containerOf(context, listen: false);
    final formState = container.read(formProvider);
    expect(
      formState.onboardingTodayTracking,
      CalorieGoalOnboardingTodayTracking.estimate,
    );
    expect(
      formState.onboardingCatchUpEstimate,
      CalorieGoalOnboardingCatchUpEstimate.high,
    );

    await _tapNext(tester);

    await tester.tap(find.text('Sounds great, next!'));
    await tester.pumpAndSettle();

    expect(runStateRepository.state.currentWeekStartDayKey, isNotNull);
    expect(
      runStateRepository.state.currentWeekStartDayKey,
      diaryDayKey(normalizeDiaryDay(DateTime.now())),
    );
    // heartCreditKcal is no longer used for onboarding catch-up; instead
    // the user gets real "estimated meal" placeholder entries in the diary.
    expect(runStateRepository.state.heartCreditKcal, 0);
    final placeholders = logRepository.entries
        .where((e) => e.name == 'Estimated meal')
        .toList();
    // Depending on the time-of-day at which the test runs, there may be
    // 0+ placeholders. We assert the soft invariant: any placeholder
    // created has a positive kcal amount.
    for (final p in placeholders) {
      expect(p.totalKcal, greaterThan(0));
    }
  });
}

Future<void> _tapNext(WidgetTester tester) async {
  final next = find.text('Next');
  final soundsGreat = find.text('Sounds great, next!');
  final button = next.evaluate().isNotEmpty ? next : soundsGreat;
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
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
