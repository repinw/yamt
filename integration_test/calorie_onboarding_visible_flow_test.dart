import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/router/app_router.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/burn_week_live_sync_provider.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/onboarding/domain/'
    'calorie_goal_onboarding_preferences.dart';
import 'package:yamt/features/onboarding/presentation/'
    'calorie_goal_onboarding_keys.dart';
import 'package:yamt/features/scanner/provider/receipt_batch_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_capture_flow_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../test/features/calories/support/fake_calories_repositories.dart';
import '../test/helpers/memory_app_preferences.dart';

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
  Future<bool> saveState(BurnWeekRunState state) async {
    this.state = state;
    return true;
  }
}

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

@Dependencies([
  appRouter,
  InventoryItemsController,
  ReceiptCaptureFlowController,
  ReceiptBatchFlowController,
])
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('calorie onboarding start-later flow runs visibly on Android', (
    tester,
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

    await _tapVisible(tester, find.text("Let's start"));

    await _tapOnboardingNext(tester);
    expect(find.text('Please enter your age.'), findsOneWidget);
    expect(find.text('Please enter your height.'), findsOneWidget);

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

    final startLaterOption = find.byKey(
      CalorieGoalOnboardingKeys.goalStartLaterOption,
    );
    await _tapVisible(tester, startLaterOption);
    await _tapOnboardingNext(tester);

    expect(find.text('All set!'), findsOneWidget);
    await _tapVisible(tester, find.text("Let's go"));
    await _pumpRouterTransition(tester);
    await _pumpRouterTransition(tester);

    expect(_currentRoute(harness), AppRoutes.homeDiary);
    expect(find.byKey(const ValueKey<String>('diary-page')), findsOneWidget);

    final settings = await harness.settingsRepository.readSettings();
    final tomorrow = normalizeDiaryDay(
      DateTime.now().add(const Duration(days: 1)),
    );
    expect(settings.nextGoalStartAfterDay(DateTime.now()), tomorrow);
    expect(harness.runStateRepository.state.currentWeekStartDayKey, isNull);
    expect(harness.logRepository.entries, isEmpty);
    expect(
      harness.preferences.getStringSync(
        calorieGoalOnboardingKeyForUser(_userId),
      ),
      calorieGoalOnboardingCompletedValue,
    );
  });
}

_CalorieOnboardingIntegrationHarness _buildHarness() {
  final user = _authenticatedUser(uid: _userId);
  final authStream = Stream<User?>.value(user).asBroadcastStream();
  final firebaseAuth = _MockFirebaseAuth();
  final preferences = MemoryAppPreferences(
    completedProfileSetupUserIds: {_userId},
  );
  final settingsRepository = FakeCalorieSettingsRepository();
  final logRepository = FakeCalorieLogRepository();
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
  addTearDown(logRepository.dispose);

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

String _currentRoute(_CalorieOnboardingIntegrationHarness harness) {
  return harness.container.read(appRouterProvider).state.uri.path;
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
  final card = find.ancestor(
    of: find.text(text),
    matching: find.byType(GestureDetector),
  );
  await _tapVisible(tester, card.first);
}

Future<void> _dismissKeyboard(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await _pumpVisibleStep(tester);
}
