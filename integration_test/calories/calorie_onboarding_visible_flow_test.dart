import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
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
import 'package:yamt/features/calories/domain/calorie_goal_settings_history.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/onboarding/domain/'
    'calorie_goal_onboarding_preferences.dart';
import 'package:yamt/features/onboarding/presentation/'
    'calorie_goal_onboarding_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/helpers/memory_app_preferences.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth;

class _MockUser extends Mock implements User;

class _MockUserMetadata extends Mock implements UserMetadata;

class _CalorieOnboardingIntegrationHarness {
  const new({
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
  new() : _settings = const CalorieGoalSettings.empty();

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
  CalorieEntry? cachedById(String entryId) => null;

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
  new(this.state);

  BurnWeekRunState state;

  @override
  Future<BurnWeekRunState> readState() async => state;

  @override
  Future<bool> saveState(BurnWeekRunState state) async {
    this.state = state;
    return true;
  }
}

class _RouterHarness extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      locale: const Locale('en'),
      routerConfig: router,
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

const _routerTransitionDuration = Duration(milliseconds: 350);
const _visibleStepDuration = Duration(milliseconds: 400);
const _userId = 'uid-visible-onboarding';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('calorie intro runs visibly and saves the goal for today', (
    tester,
  ) async {
    final harness = await _pumpOnboardingApp(tester);

    await _completeIntro(tester);
    await _finishIntro(tester);

    _expectHomeDiary(harness);
    await _expectGoalStartedToday(harness);
    _expectOnboardingCompleted(harness);
  });

  testWidgets('calorie intro blocks the identity page without a birthday', (
    tester,
  ) async {
    await _pumpOnboardingApp(tester);
    await _openIdentityPage(tester);

    await _tapIntroNext(tester);

    expect(find.text('Please pick your birthday.'), findsOneWidget);
    expect(find.text('What are your current numbers?'), findsNothing);
  });

  testWidgets('calorie intro reaches the goal page from the body page', (
    tester,
  ) async {
    await _pumpOnboardingApp(tester);

    await _openIdentityPage(tester);
    await _completeIdentity(tester);

    await _spinWheel(tester, CalorieGoalOnboardingKeys.introHeightWheel);
    await _spinWheel(tester, CalorieGoalOnboardingKeys.introWeightWheel);
    await _tapIntroNext(tester);

    expect(find.text('Your Goal'), findsOneWidget);
  });
}

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
  expect(find.text('Welcome to YAMT'), findsOneWidget);
  return harness;
}

_CalorieOnboardingIntegrationHarness _buildHarness({String userId = _userId}) {
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
  when(() => metadata.lastSignInTime)
      .thenReturn(createdAt.add(const Duration(days: 7)));
  when(() => user.uid).thenReturn(uid);
  when(() => user.isAnonymous).thenReturn(false);
  when(() => user.displayName).thenReturn(displayName);
  when(() => user.email).thenReturn(email);
  when(() => user.metadata).thenReturn(metadata);
  return user;
}

String _currentRoute(_CalorieOnboardingIntegrationHarness harness) {
  return harness.container.read(appRouterProvider).state.uri.path;
}

Future<void> _openIdentityPage(WidgetTester tester) async {
  await _tapVisible(
    tester,
    find.byKey(CalorieGoalOnboardingKeys.introStartAction),
  );
  for (var storyPage = 0; storyPage < 6; storyPage++) {
    await _tapIntroNext(tester);
  }
  expect(
    find.text('Erstmal brauchen wir ein ungefähres Bild von dir.'),
    findsOneWidget,
  );
}

Future<void> _completeIdentity(WidgetTester tester) async {
  await _tapVisible(tester, find.text('Female'));
  await _spinWheel(tester, CalorieGoalOnboardingKeys.introBirthDayWheel);
  await _tapIntroNext(tester);
}

Future<void> _spinWheel(WidgetTester tester, Key wheelKey) async {
  final wheel = find.byKey(wheelKey);
  await tester.ensureVisible(wheel);
  await _pumpVisibleStep(tester);
  await tester.drag(wheel, const Offset(0, -60));
  await _pumpVisibleStep(tester);
}

Future<void> _completeIntro(WidgetTester tester) async {
  await _openIdentityPage(tester);
  await _completeIdentity(tester);

  await _spinWheel(tester, CalorieGoalOnboardingKeys.introHeightWheel);
  await _spinWheel(tester, CalorieGoalOnboardingKeys.introWeightWheel);
  await _tapIntroNext(tester);

  await _spinWheel(tester, CalorieGoalOnboardingKeys.introTargetWeightWheel);
  await _tapIntroNext(tester);

  await _tapVisible(tester, find.text('Sitting, but on the move'));
  await _tapIntroNext(tester);

  await _tapIntroNext(tester);
  await _tapIntroNext(tester);
}

Future<void> _finishIntro(WidgetTester tester) async {
  expect(find.text('All set!'), findsOneWidget);
  await _tapVisible(
    tester,
    find.byKey(CalorieGoalOnboardingKeys.introFinishAction),
  );
  await _pumpRouterTransition(tester);
  await _pumpRouterTransition(tester);
}

void _expectHomeDiary(_CalorieOnboardingIntegrationHarness harness) {
  expect(_currentRoute(harness), AppRoutes.homeDiary);
  expect(find.byKey(const ValueKey<String>('diary-page')), findsOneWidget);
}

Future<void> _expectGoalStartedToday(
  _CalorieOnboardingIntegrationHarness harness,
) async {
  final today = normalizeDiaryDay(DateTime.now());
  final settings = await harness.settingsRepository.readSettings();
  final goalEntry = settings.goalHistory.single;
  expect(goalEntry.effectiveDate, today);
  expect(
    harness.runStateRepository.state.currentWeekStartDayKey,
    diaryDayKey(today),
  );
  expect(harness.logRepository.entries, isEmpty);
}

void _expectOnboardingCompleted(_CalorieOnboardingIntegrationHarness harness) {
  expect(
    harness.preferences.getStringSync(calorieGoalOnboardingKeyForUser(_userId)),
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

Future<void> _tapIntroNext(WidgetTester tester) async {
  await _tapVisible(
    tester,
    find.byKey(CalorieGoalOnboardingKeys.introNextAction),
  );
}
