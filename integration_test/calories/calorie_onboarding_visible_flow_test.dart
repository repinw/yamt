import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/router/app_router.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/application/burn_week_live_sync_provider.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/onboarding/domain/'
    'calorie_goal_onboarding_preferences.dart';
import 'package:yamt/features/onboarding/presentation/'
    'calorie_goal_onboarding_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/helpers/memory_app_preferences.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

class _MockUserMetadata extends Mock implements UserMetadata {}

class _CalorieOnboardingIntegrationHarness {
  const _CalorieOnboardingIntegrationHarness({
    required this.container,
    required this.preferences,
    required this.settingsRepository,
    required this.logRepository,
    required this.runStateRepository,
  });

  final ProviderContainer container;
  final MemoryAppPreferences preferences;
  final _FakeCalorieSettingsRepository settingsRepository;
  final _FakeCalorieLogRepository logRepository;
  final _FakeBurnWeekRunStateRepository runStateRepository;
}

class _FakeCalorieSettingsRepository implements CalorieSettingsRepository {
  _FakeCalorieSettingsRepository()
    : _settings = const CalorieGoalSettings.empty();

  CalorieGoalSettings _settings;
  final _controller = StreamController<CalorieGoalSettings>.broadcast();

  @override
  Stream<CalorieGoalSettings> watchSettings() {
    return Stream<CalorieGoalSettings>.multi((controller) {
      controller.add(_settings);
      final subscription = _controller.stream.listen(controller.add);
      controller.onCancel = () {
        unawaited(subscription.cancel());
      };
    });
  }

  @override
  Future<CalorieGoalSettings> readSettings() async => _settings;

  @override
  Future<bool> saveSettings(CalorieGoalSettings settings) async {
    _settings = settings;
    _controller.add(_settings);
    return true;
  }

  @override
  Future<bool> setDailyGoal(double dailyKcalGoal) {
    return saveSettings(
      CalorieGoalSettings.single(
        dailyKcalGoal: dailyKcalGoal,
        calculatorProfile: null,
        effectiveDate: DateTime(2026, 2, 25, 10),
      ),
    );
  }

  @override
  Future<bool> clearDailyGoal() {
    return saveSettings(
      const CalorieGoalSettings.empty().applyGoalChange(
        changedAt: DateTime(2026, 2, 25, 10),
        dailyKcalGoal: null,
        calculatorProfile: null,
      ),
    );
  }

  Future<void> dispose() => _controller.close();
}

class _FakeCalorieLogRepository implements CalorieLogRepositoryContract {
  final List<CalorieEntry> _entries = <CalorieEntry>[];

  List<CalorieEntry> get entries => List<CalorieEntry>.unmodifiable(_entries);

  @override
  Stream<List<CalorieEntry>> watchEntriesForDay(DateTime day) {
    return Stream<List<CalorieEntry>>.value(_entriesForDay(day));
  }

  @override
  Future<List<CalorieEntry>> readEntriesForDay(DateTime day) async {
    return _entriesForDay(day);
  }

  @override
  Future<List<CalorieEntry>> readEntriesInRange({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    final start = normalizeDiaryDay(startInclusive);
    final end = normalizeDiaryDay(endExclusive);
    return _entries
        .where(
          (entry) =>
              !entry.loggedAt.isBefore(start) && entry.loggedAt.isBefore(end),
        )
        .toList(growable: false);
  }

  @override
  Future<DateTime?> readFirstEntryDate() async {
    if (_entries.isEmpty) {
      return null;
    }
    final sorted = List<CalorieEntry>.from(_entries)
      ..sort((left, right) => left.loggedAt.compareTo(right.loggedAt));
    return sorted.first.loggedAt;
  }

  @override
  Future<bool> saveEntry(CalorieEntry entry) {
    return saveEntryForCurrentUser(entry);
  }

  @override
  Future<bool> saveEntryForCurrentUser(CalorieEntry entry) async {
    final index = _entries.indexWhere((item) => item.id == entry.id);
    if (index >= 0) {
      _entries[index] = entry;
    } else {
      _entries.add(entry);
    }
    return true;
  }

  @override
  Future<bool> deleteEntry(String entryId) async {
    _entries.removeWhere((entry) => entry.id == entryId);
    return true;
  }

  @override
  Future<CalorieEntry?> getById(String entryId) async {
    final index = _entries.indexWhere((entry) => entry.id == entryId);
    if (index < 0) {
      return null;
    }
    return _entries[index];
  }

  List<CalorieEntry> _entriesForDay(DateTime day) {
    final normalizedDay = normalizeDiaryDay(day);
    return _entries
        .where((entry) => isSameDiaryDay(entry.loggedAt, normalizedDay))
        .toList(growable: false);
  }
}

class _FakeBurnWeekRunStateRepository implements BurnWeekRunStateRepository {
  _FakeBurnWeekRunStateRepository(this.state);

  BurnWeekRunState state;

  @override
  Future<BurnWeekRunState> readState() async => state;

  @override
  Future<bool> saveState(BurnWeekRunState state) async {
    this.state = state;
    return true;
  }
}

@Dependencies([appRouter])
class _RouterHarness extends ConsumerWidget {
  const _RouterHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      locale: const Locale('en'),
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

const _routerTransitionDuration = Duration(milliseconds: 350);
const _visibleStepDuration = Duration(milliseconds: 400);
const _userId = 'uid-visible-onboarding';

@Dependencies([appRouter])
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('calorie onboarding start-later flow runs visibly on Android', (
    tester,
  ) async {
    final harness = await _pumpOnboardingApp(tester);

    await _completeOnboardingToStartDateStep(
      tester,
      validatePersonalInfo: true,
    );
    await _chooseStartLater(tester);
    await _finishOnboarding(tester);

    _expectHomeDiary(harness);
    await _expectStartLaterSaved(harness);
    _expectOnboardingCompleted(harness);
  });

  testWidgets('calorie onboarding start-now exact flow saves today', (
    tester,
  ) async {
    final harness = await _pumpOnboardingApp(tester);

    await _completeOnboardingToStartDateStep(tester);
    await _chooseStartNowExact(tester);
    await _finishOnboarding(tester);

    _expectHomeDiary(harness);
    await _expectStartTodaySaved(harness);
    expect(harness.logRepository.entries, isEmpty);
    _expectOnboardingCompleted(harness);
  });

  testWidgets('calorie onboarding start-now estimate flow saves catch-up', (
    tester,
  ) async {
    final harness = await _pumpOnboardingApp(tester);

    await _completeOnboardingToStartDateStep(tester);
    await _chooseStartNowEstimateHigh(tester);
    await _finishOnboarding(tester);

    _expectHomeDiary(harness);
    await _expectStartTodaySaved(harness);
    for (final entry in harness.logRepository.entries) {
      expect(entry.name, 'Estimated meal');
      expect(entry.totalKcal, greaterThan(0));
    }
    _expectOnboardingCompleted(harness);
  });

  testWidgets('calorie onboarding future date picker opens and saves', (
    tester,
  ) async {
    final harness = await _pumpOnboardingApp(tester);

    await _completeOnboardingToStartDateStep(tester);
    await _selectStartLater(tester);
    await _tapVisible(
      tester,
      find.byKey(CalorieGoalOnboardingKeys.goalStartChangeButton),
    );

    expect(find.byType(DatePickerDialog), findsOneWidget);
    await _tapVisible(tester, find.text('OK').last);
    await _tapOnboardingNext(tester);
    await _finishOnboarding(tester);

    _expectHomeDiary(harness);
    await _expectStartLaterSaved(harness);
    _expectOnboardingCompleted(harness);
  });

  testWidgets('calorie onboarding start-date step blocks missing choices', (
    tester,
  ) async {
    await _pumpOnboardingApp(tester);
    await _completeOnboardingToStartDateStep(tester);

    await _tapOnboardingNext(tester);
    expect(find.text('When should your goal start?'), findsOneWidget);
    expect(find.text('All set!'), findsNothing);

    await _tapVisible(
      tester,
      find.byKey(CalorieGoalOnboardingKeys.goalStartNowOption),
    );
    await _tapOnboardingNext(tester);

    expect(find.text('How will you track today?'), findsOneWidget);
    expect(find.text('All set!'), findsNothing);
  });

  testWidgets('calorie onboarding keeps inputs visible above keyboard', (
    tester,
  ) async {
    await _pumpOnboardingApp(tester);
    addTearDown(tester.view.resetViewInsets);

    await _tapVisible(tester, find.text("Let's start"));
    await _tapVisible(tester, find.text('Female'));

    await _focusFieldWithKeyboard(tester, find.byType(TextFormField).at(1));
    _expectAboveKeyboard(tester, find.byType(TextFormField).at(1));
    await tester.enterText(find.byType(TextFormField).at(0), '30');
    await tester.enterText(find.byType(TextFormField).at(1), '170');
    await _dismissKeyboard(tester);
    await _tapOnboardingNext(tester);

    await _tapActivityOption(tester, 'Lightly active');
    await _tapOnboardingNext(tester);

    await _focusFieldWithKeyboard(tester, find.byType(TextFormField).at(1));
    _expectAboveKeyboard(tester, find.byType(TextFormField).at(1));
    await tester.enterText(find.byType(TextFormField).at(0), '70');
    await tester.enterText(find.byType(TextFormField).at(1), '70');
    await _dismissKeyboard(tester);
    await _tapOnboardingNext(tester);

    expect(find.textContaining('Your Plan is Ready'), findsOneWidget);
  });
}

@Dependencies([appRouter])
Future<_CalorieOnboardingIntegrationHarness> _pumpOnboardingApp(
  WidgetTester tester,
) async {
  final harness = _buildHarness();
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: harness.container,
      child: const _RouterHarness(),
    ),
  );
  await _pumpRouterTransition(tester);
  await _pumpRouterTransition(tester);

  expect(_currentRoute(harness), AppRoutes.calorieGoalSetup);
  expect(find.text('Glad you are here!'), findsOneWidget);
  return harness;
}

_CalorieOnboardingIntegrationHarness _buildHarness({
  String userId = _userId,
}) {
  final user = _authenticatedUser(uid: userId);
  final authStream = Stream<User?>.value(user).asBroadcastStream();
  final firebaseAuth = _MockFirebaseAuth();
  final preferences = MemoryAppPreferences(
    completedProfileSetupUserIds: {userId},
  );
  final settingsRepository = _FakeCalorieSettingsRepository();
  final logRepository = _FakeCalorieLogRepository();
  final runStateRepository = _FakeBurnWeekRunStateRepository(
    const BurnWeekRunState.initial(),
  );

  when(() => firebaseAuth.currentUser).thenReturn(user);

  final container = ProviderContainer(
    overrides: [
      appPreferencesProvider.overrideWithValue(preferences),
      authStateChangesProvider.overrideWith((ref) => authStream),
      firebaseAuthProvider.overrideWithValue(firebaseAuth),
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      calorieLogRepositoryProvider.overrideWithValue(logRepository),
      burnWeekRunStateRepositoryProvider.overrideWithValue(runStateRepository),
      burnWeekLiveSyncProvider.overrideWith((ref) => null),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(settingsRepository.dispose);

  return _CalorieOnboardingIntegrationHarness(
    container: container,
    preferences: preferences,
    settingsRepository: settingsRepository,
    logRepository: logRepository,
    runStateRepository: runStateRepository,
  );
}

_MockUser _authenticatedUser({
  required String uid,
  String? displayName = 'Visible Test User',
  String? email = 'visible@example.com',
}) {
  final user = _MockUser();
  final metadata = _MockUserMetadata();
  final createdAt = DateTime.utc(2026, 1, 1, 9);
  when(() => metadata.creationTime).thenReturn(createdAt);
  when(() => metadata.lastSignInTime).thenReturn(
    createdAt.add(const Duration(days: 7)),
  );
  when(() => user.uid).thenReturn(uid);
  when(() => user.isAnonymous).thenReturn(false);
  when(() => user.displayName).thenReturn(displayName);
  when(() => user.email).thenReturn(email);
  when(() => user.metadata).thenReturn(metadata);
  return user;
}

@Dependencies([appRouter])
String _currentRoute(_CalorieOnboardingIntegrationHarness harness) {
  return harness.container.read(appRouterProvider).state.uri.path;
}

Future<void> _completeOnboardingToStartDateStep(
  WidgetTester tester, {
  bool validatePersonalInfo = false,
}) async {
  await _tapVisible(tester, find.text("Let's start"));
  if (validatePersonalInfo) {
    await _tapOnboardingNext(tester);
    expect(find.text('Please enter your age.'), findsOneWidget);
    expect(find.text('Please enter your height.'), findsOneWidget);
  }

  await _tapVisible(tester, find.text('Female'));
  await tester.enterText(find.byType(TextFormField).at(0), '30');
  await tester.enterText(find.byType(TextFormField).at(1), '170');
  await _dismissKeyboard(tester);
  await _tapOnboardingNext(tester);

  await _tapActivityOption(tester, 'Lightly active');
  await _tapOnboardingNext(tester);

  await tester.enterText(find.byType(TextFormField).at(0), '70');
  await tester.enterText(find.byType(TextFormField).at(1), '70');
  await _dismissKeyboard(tester);
  await _tapOnboardingNext(tester);

  expect(find.textContaining('Your Plan is Ready'), findsOneWidget);
  await _tapOnboardingNext(tester);
  expect(find.text('When to start?'), findsOneWidget);
}

Future<void> _chooseStartLater(WidgetTester tester) async {
  await _selectStartLater(tester);
  await _tapOnboardingNext(tester);
}

Future<void> _selectStartLater(WidgetTester tester) async {
  await _tapVisible(
    tester,
    find.byKey(CalorieGoalOnboardingKeys.goalStartLaterOption),
  );
  expect(
    find.byKey(CalorieGoalOnboardingKeys.goalStartChangeButton),
    findsOneWidget,
  );
}

Future<void> _chooseStartNowExact(WidgetTester tester) async {
  await _tapVisible(
    tester,
    find.byKey(CalorieGoalOnboardingKeys.goalStartNowOption),
  );
  await _tapVisible(
    tester,
    find.byKey(CalorieGoalOnboardingKeys.todayTrackingExactOption),
  );
  await _tapOnboardingNext(tester);
}

Future<void> _chooseStartNowEstimateHigh(WidgetTester tester) async {
  await _tapVisible(
    tester,
    find.byKey(CalorieGoalOnboardingKeys.goalStartNowOption),
  );
  await _tapVisible(
    tester,
    find.byKey(CalorieGoalOnboardingKeys.todayTrackingEstimateOption),
  );
  await _tapVisible(
    tester,
    find.byKey(CalorieGoalOnboardingKeys.catchUpHighOption),
  );
  await _tapOnboardingNext(tester);
}

Future<void> _finishOnboarding(WidgetTester tester) async {
  expect(find.text('All set!'), findsOneWidget);
  await _tapVisible(tester, find.text("Let's go"));
  await _pumpRouterTransition(tester);
  await _pumpRouterTransition(tester);
}

@Dependencies([appRouter])
void _expectHomeDiary(
  _CalorieOnboardingIntegrationHarness harness,
) {
  expect(_currentRoute(harness), AppRoutes.homeDiary);
  expect(find.byKey(const ValueKey<String>('diary-page')), findsOneWidget);
}

Future<void> _expectStartLaterSaved(
  _CalorieOnboardingIntegrationHarness harness,
) async {
  final settings = await harness.settingsRepository.readSettings();
  final tomorrow = normalizeDiaryDay(
    DateTime.now().add(const Duration(days: 1)),
  );
  expect(settings.nextGoalStartAfterDay(DateTime.now()), tomorrow);
  expect(harness.runStateRepository.state.currentWeekStartDayKey, isNull);
  expect(harness.logRepository.entries, isEmpty);
}

Future<void> _expectStartTodaySaved(
  _CalorieOnboardingIntegrationHarness harness,
) async {
  final today = normalizeDiaryDay(DateTime.now());
  final settings = await harness.settingsRepository.readSettings();
  final goalEntry = settings.goalHistory.single;
  expect(goalEntry.effectiveDate, today);
  expect(goalEntry.effectiveCountingStartDate, today);
  expect(
    harness.runStateRepository.state.currentWeekStartDayKey,
    diaryDayKey(today),
  );
}

void _expectOnboardingCompleted(
  _CalorieOnboardingIntegrationHarness harness,
) {
  expect(
    harness.preferences.getStringSync(
      calorieGoalOnboardingKeyForUser(_userId),
    ),
    calorieGoalOnboardingCompletedValue,
  );
}

Future<void> _pumpRouterTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(_routerTransitionDuration);
}

Future<void> _pumpVisibleStep(WidgetTester tester) async {
  await tester.pump();
  await Future<void>.delayed(_visibleStepDuration);
  await tester.pump();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await _pumpVisibleStep(tester);
  await tester.tap(finder);
  await _pumpVisibleStep(tester);
}

Future<void> _tapOnboardingNext(WidgetTester tester) async {
  final next = find.text('Next');
  final soundsGreat = find.text('Sounds great, next!');
  final button = next.evaluate().isNotEmpty ? next : soundsGreat;
  await _tapVisible(tester, button);
}

Future<void> _tapActivityOption(WidgetTester tester, String text) async {
  await _tapVisible(tester, find.text(text));
}

Future<void> _focusFieldWithKeyboard(WidgetTester tester, Finder field) async {
  await tester.ensureVisible(field);
  await _pumpVisibleStep(tester);
  await tester.tap(field);
  tester.view.viewInsets = FakeViewPadding(
    bottom: 360 * tester.view.devicePixelRatio,
  );
  await _pumpVisibleStep(tester);
}

void _expectAboveKeyboard(WidgetTester tester, Finder finder) {
  final fieldBottom = tester.getBottomLeft(finder).dy;
  final viewHeight =
      tester.view.physicalSize.height / tester.view.devicePixelRatio;
  final keyboardHeight =
      tester.view.viewInsets.bottom / tester.view.devicePixelRatio;
  expect(fieldBottom, lessThanOrEqualTo(viewHeight - keyboardHeight));
}

Future<void> _dismissKeyboard(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  tester.view.resetViewInsets();
  await _pumpVisibleStep(tester);
}
