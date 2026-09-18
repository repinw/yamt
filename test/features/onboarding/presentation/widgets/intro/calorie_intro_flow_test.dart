import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/onboarding/presentation/'
    'calorie_goal_onboarding_keys.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/'
    'calorie_intro_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../calories/support/fake_calories_repositories.dart';

final _today = DateTime(2026, 9, 17, 10);

void _disableAnimations(WidgetTester tester) {
  tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(
    tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
  );
}

void main() {
  testWidgets('saves the calculated goal and leaves onboarding', (
    tester,
  ) async {
    final harness = await _pumpIntro(tester);

    await _completeIntro(tester);
    await _tapFinish(tester);

    final settings = await harness.settingsRepository.readSettings();
    expect(
      settings.goalHistory.single.effectiveDate,
      normalizeDiaryDay(_today),
    );
    expect(
      harness.runStateRepository.state.currentWeekStartDayKey,
      diaryDayKey(normalizeDiaryDay(_today)),
    );
    expect(harness.currentLocation, '/');
  });

  testWidgets('shows a failure message when the goal cannot be saved', (
    tester,
  ) async {
    final harness = await _pumpIntro(tester);
    harness.settingsRepository.saveShouldFail = true;

    await _completeIntro(tester);
    await _tapFinish(tester);

    expect(
      find.text('Could not save the calculated calorie target.'),
      findsOneWidget,
    );
    expect(harness.currentLocation, '/onboarding');
  });

  testWidgets('blocks the identity page until gender and birthday are set', (
    tester,
  ) async {
    await _pumpIntro(tester);
    await _goToIdentityPage(tester);

    await _tapNext(tester);

    expect(find.text('Please pick your birthday.'), findsOneWidget);
    expect(find.text('What are your current numbers?'), findsNothing);
  });

  testWidgets('blocks the target page while the target weight is empty', (
    tester,
  ) async {
    await _pumpIntro(tester);
    await _goToIdentityPage(tester);
    await _completeIdentity(tester);
    await _completeBody(tester);

    await _tapNext(tester);

    expect(find.text('Please enter your weight.'), findsOneWidget);
    expect(find.text('How much do you move on a normal day?'), findsNothing);
  });

  testWidgets('keeps the goal feedback box in place before a target is set', (
    tester,
  ) async {
    await _pumpIntro(tester);
    await _goToIdentityPage(tester);
    await _completeIdentity(tester);
    await _completeBody(tester);

    expect(find.text('Pick your target weight.'), findsOneWidget);

    await _spinWheel(tester, CalorieGoalOnboardingKeys.introTargetWeightWheel);

    expect(find.text('Pick your target weight.'), findsNothing);
    expect(find.textContaining('You want to'), findsOneWidget);
  });

  testWidgets('fits the body page on a phone without scrolling', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpIntro(tester);
    await _goToIdentityPage(tester);
    await _completeIdentity(tester);

    final heightWheel = find.byKey(CalorieGoalOnboardingKeys.introHeightWheel);
    expect(heightWheel, findsOneWidget);
    expect(
      find.ancestor(
        of: heightWheel,
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
    );
    expect(
      find.text(
        'Day-to-day swings do not matter. We read your weekly weight trend, '
        'not single highs and lows.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('fits activity and training pages on a phone without scrolling', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpIntro(tester);
    await _goToIdentityPage(tester);
    await _completeIdentity(tester);
    await _completeBody(tester);
    await _spinWheel(tester, CalorieGoalOnboardingKeys.introTargetWeightWheel);
    await _tapNext(tester);

    _expectPageDoesNotScroll(tester, find.text('Sitting, but on the move'));

    await _tapNext(tester);
    await tester.tap(find.text('Mo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('We'));
    await tester.pumpAndSettle();

    _expectPageDoesNotScroll(tester, find.text('Do you train on fixed days?'));
  });

  testWidgets('shows the estimated target date on the pace page', (
    tester,
  ) async {
    await _pumpIntro(tester);
    await _completeIntro(tester, stopOnPacePage: true);

    expect(
      find.byKey(CalorieGoalOnboardingKeys.introTargetDateEstimate),
      findsOneWidget,
    );
  });

  testWidgets('opens the welcome route from the login action', (tester) async {
    final harness = await _pumpIntro(tester);

    await tester.tap(find.byKey(CalorieGoalOnboardingKeys.introLoginAction));
    await tester.pumpAndSettle();

    expect(harness.currentLocation, startsWith('/welcome'));
  });
}

class _IntroHarness {
  new({
    required this.settingsRepository,
    required this.runStateRepository,
    required this.router,
  });

  final FakeCalorieSettingsRepository settingsRepository;
  final _FakeBurnWeekRunStateRepository runStateRepository;
  final GoRouter router;

  String get currentLocation => router.state.uri.path;
}

Future<_IntroHarness> _pumpIntro(WidgetTester tester) async {
  _disableAnimations(tester);
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
        builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const CalorieIntroFlow(
          initialSettings: CalorieGoalSettings.empty(),
        ),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => _today),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        calorieLogRepositoryProvider.overrideWithValue(logRepository),
        burnWeekRunStateRepositoryProvider.overrideWithValue(
          runStateRepository,
        ),
      ],
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  unawaited(router.push('/onboarding'));
  await tester.pumpAndSettle();

  return _IntroHarness(
    settingsRepository: settingsRepository,
    runStateRepository: runStateRepository,
    router: router,
  );
}

Future<void> _goToIdentityPage(WidgetTester tester) async {
  await tester.tap(find.byKey(CalorieGoalOnboardingKeys.introStartAction));
  await tester.pumpAndSettle();
  for (var story = 0; story < 6; story++) {
    await _tapNext(tester);
  }
  expect(find.text('First we need a rough picture of you.'), findsOneWidget);
}

Future<void> _completeIdentity(WidgetTester tester) async {
  await tester.tap(find.text('Female'));
  await tester.pumpAndSettle();
  await _pickBirthDay(tester);
  await _tapNext(tester);
}

Future<void> _pickBirthDay(WidgetTester tester) async {
  await _spinWheel(tester, CalorieGoalOnboardingKeys.introBirthDayWheel);
}

Future<void> _spinWheel(WidgetTester tester, Key wheelKey) async {
  final wheel = find.byKey(wheelKey);
  await tester.ensureVisible(wheel);
  await tester.drag(wheel, const Offset(0, -60));
  await tester.pumpAndSettle();
}

Future<void> _completeBody(WidgetTester tester) async {
  await _spinWheel(tester, CalorieGoalOnboardingKeys.introHeightWheel);
  await _spinWheel(tester, CalorieGoalOnboardingKeys.introWeightWheel);
  await _tapNext(tester);
}

Future<void> _completeIntro(
  WidgetTester tester, {
  bool stopOnPacePage = false,
}) async {
  await _goToIdentityPage(tester);
  await _completeIdentity(tester);
  await _completeBody(tester);

  await _spinWheel(tester, CalorieGoalOnboardingKeys.introTargetWeightWheel);
  await _tapNext(tester);

  await tester.tap(find.text('Sitting, but on the move'));
  await tester.pumpAndSettle();
  await _tapNext(tester);

  await _tapNext(tester);
  if (stopOnPacePage) {
    return;
  }
  await _tapNext(tester);
}

Future<void> _tapNext(WidgetTester tester) async {
  final next = find.byKey(CalorieGoalOnboardingKeys.introNextAction);
  await tester.ensureVisible(next);
  await tester.tap(next);
  await tester.pumpAndSettle();
}

Future<void> _tapFinish(WidgetTester tester) async {
  final finish = find.byKey(CalorieGoalOnboardingKeys.introFinishAction);
  await tester.ensureVisible(finish);
  await tester.tap(finish);
  await tester.pumpAndSettle();
}

class _FakeBurnWeekRunStateRepository implements BurnWeekRunStateRepository {
  new(this.state);

  BurnWeekRunState state;

  @override
  Future<BurnWeekRunState> readState() async => state;

  @override
  Future<bool> saveState(BurnWeekRunState nextState) async {
    state = nextState;
    return true;
  }
}

void _expectPageDoesNotScroll(WidgetTester tester, Finder content) {
  final scrollable = tester.state<ScrollableState>(
    find.ancestor(of: content, matching: find.byType(Scrollable)).first,
  );
  expect(scrollable.position.maxScrollExtent, 0);
}
