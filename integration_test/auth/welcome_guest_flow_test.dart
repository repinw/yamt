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
    'calorie_goal_onboarding_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/calories/support/fake_calories_repositories.dart';
import '../../test/helpers/auth_user_data_key_session.dart';
import '../../test/helpers/memory_app_preferences.dart';

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

const _guestButton = Key('auth_guest_button');
const _stepDuration = Duration(milliseconds: 400);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'the welcome guest button returns to onboarding without an account',
    (tester) async {
      final firebaseAuth = _MockFirebaseAuth();
      when(() => firebaseAuth.currentUser).thenReturn(null);
      final settingsRepository = FakeCalorieSettingsRepository();
      final logRepository = FakeCalorieLogRepository();
      addTearDown(settingsRepository.dispose);
      addTearDown(logRepository.dispose);
      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
          authStateChangesProvider.overrideWith(
            (ref) => Stream<User?>.value(null),
          ),
          firebaseAuthProvider.overrideWithValue(firebaseAuth),
          userDataKeySessionProvider.overrideWith(AuthUserDataKeySession.new),
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
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

      expect(currentRoute(), AppRoutes.calorieGoalSetup);

      await _tapVisible(
        tester,
        find.byKey(CalorieGoalOnboardingKeys.introLoginAction),
      );
      expect(currentRoute(), AppRoutes.welcome);

      await _tapVisible(tester, find.byKey(_guestButton));

      expect(currentRoute(), AppRoutes.calorieGoalSetup);
      expect(find.byKey(_guestButton), findsNothing);
      verifyNever(firebaseAuth.signInAnonymously);
    },
  );
}

Future<void> _pumpStep(WidgetTester tester) async {
  await tester.pump();
  await Future<void>.delayed(_stepDuration);
  await tester.pump();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await _pumpStep(tester);
  await tester.tap(finder);
  await _pumpStep(tester);
}
