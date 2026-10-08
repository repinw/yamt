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
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/calories/application/burn_week_live_sync_provider.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/onboarding/presentation/'
    'calorie_goal_load_failed_page.dart';
import 'package:yamt/features/onboarding/presentation/'
    'calorie_goal_onboarding_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/calories/support/fake_calories_repositories.dart';
import '../../test/helpers/auth_user_data_key_session.dart';
import '../../test/helpers/memory_app_preferences.dart';

class _MockUser extends Mock implements User;

class _MockFirebaseAuth extends Mock implements FirebaseAuth;

class _RouterHarness extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      locale: const Locale('en'),
      routerConfig: ref.watch(appRouterProvider),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

const _stepDuration = Duration(milliseconds: 400);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('a failed goal read shows a retry gate instead of onboarding', (
    tester,
  ) async {
    final user = _MockUser();
    when(() => user.uid).thenReturn('user-1');
    when(() => user.isAnonymous).thenReturn(false);
    final settingsRepository = FakeCalorieSettingsRepository()
      ..readError = Exception('client is offline');
    final logRepository = FakeCalorieLogRepository();
    addTearDown(settingsRepository.dispose);
    addTearDown(logRepository.dispose);
    final container = ProviderContainer(
      overrides: [
        appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
        authStateChangesProvider.overrideWith(
          (ref) => Stream<User?>.value(user),
        ),
        userDataKeySessionProvider.overrideWith(AuthUserDataKeySession.new),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        calorieLogRepositoryProvider.overrideWithValue(logRepository),
        burnWeekLiveSyncProvider.overrideWith((ref) => null),
      ],
    );
    addTearDown(container.dispose);
    String currentRoute() => container.read(appRouterProvider).state.uri.path;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _RouterHarness(),
      ),
    );
    await _pumpStep(tester);
    await _pumpStep(tester);

    expect(currentRoute(), AppRoutes.calorieGoalLoadFailed);
    expect(find.byType(CalorieGoalLoadFailedPage), findsOneWidget);

    settingsRepository.readError = null;
    await tester.tap(
      find.byKey(CalorieGoalOnboardingKeys.loadFailedRetryAction),
    );
    await _pumpStep(tester);
    await _pumpStep(tester);

    // No goal is saved, so the retry opens onboarding.
    expect(currentRoute(), AppRoutes.calorieGoalSetup);
  });

  testWidgets('signing out leaves a goal that never loads', (tester) async {
    final user = _MockUser();
    when(() => user.uid).thenReturn('user-1');
    when(() => user.isAnonymous).thenReturn(false);
    final authStates = StreamController<User?>.broadcast();
    addTearDown(authStates.close);
    final auth = _MockFirebaseAuth();
    when(() => auth.currentUser).thenReturn(user);
    when(auth.signOut).thenAnswer((_) async {
      when(() => auth.currentUser).thenReturn(null);
      authStates.add(null);
    });
    final settingsRepository = FakeCalorieSettingsRepository()
      ..readError = Exception('broken settings');
    final logRepository = FakeCalorieLogRepository();
    addTearDown(settingsRepository.dispose);
    addTearDown(logRepository.dispose);
    final container = ProviderContainer(
      overrides: [
        appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
        firebaseAuthProvider.overrideWithValue(auth),
        authStateChangesProvider.overrideWith((ref) async* {
          yield user;
          yield* authStates.stream;
        }),
        userDataKeySessionProvider.overrideWith(AuthUserDataKeySession.new),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        calorieLogRepositoryProvider.overrideWithValue(logRepository),
        burnWeekLiveSyncProvider.overrideWith((ref) => null),
      ],
    );
    addTearDown(container.dispose);
    String currentRoute() => container.read(appRouterProvider).state.uri.path;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _RouterHarness(),
      ),
    );
    await _pumpStep(tester);
    await _pumpStep(tester);
    expect(currentRoute(), AppRoutes.calorieGoalLoadFailed);

    await tester.tap(
      find.byKey(CalorieGoalOnboardingKeys.loadFailedSignOutAction),
    );
    await _pumpStep(tester);
    await _pumpStep(tester);

    verify(auth.signOut).called(1);
    // Signed out, the app starts over like after any sign-out.
    expect(currentRoute(), AppRoutes.calorieGoalSetup);
  });
}

Future<void> _pumpStep(WidgetTester tester) async {
  await tester.pump();
  await Future<void>.delayed(_stepDuration);
  await tester.pump();
}
