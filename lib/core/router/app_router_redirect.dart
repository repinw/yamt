import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/auth/domain/user_data_key_state.dart';
import 'package:yamt/features/household/application/pending_household_invite.dart';
import 'package:yamt/features/household/domain/household_invite.dart';
import 'package:yamt/features/onboarding/provider/'
    'calorie_goal_onboarding_completed_provider.dart';

/// Evaluates application-wide redirects based on auth and onboarding state.
String? appRouterRedirect(Ref ref, GoRouterState state) {
  final path = state.matchedLocation;
  final invite = HouseholdInvite.fromDeepLink(state.uri);
  if (invite != null) {
    // The sign-in and onboarding redirects may come first, so the invite
    // waits until the household page opens.
    ref.read(pendingHouseholdInviteProvider.notifier).invite = invite;
  }
  final authState = ref.read(authStateChangesProvider);
  if (authState.isLoading) {
    return path == AppRoutes.splash ? null : AppRoutes.splash;
  }

  final currentUser = authState.asData?.value;
  if (currentUser == null) {
    return _redirectSignedOut(path);
  }

  final dataKeyRoute = _forcedDataKeyRoute(ref, path);
  if (dataKeyRoute != null) {
    return path == dataKeyRoute ? null : dataKeyRoute;
  }

  final isAnon = currentUser.isAnonymous;
  if (path == AppRoutes.welcome) {
    return _redirectFromWelcome(ref, state, isAnonymous: isAnon);
  }

  return _redirectForOnboarding(ref, path);
}

/// Without an account, the app shows the onboarding intro: at startup, after
/// a sign-out, and when the session ends. The guest account is created only
/// when onboarding finishes. The login page stays open, because the intro
/// opens it.
String? _redirectSignedOut(String path) {
  if (path == AppRoutes.welcome || path == AppRoutes.calorieGoalSetup) {
    return null;
  }
  return AppRoutes.calorieGoalSetup;
}

/// Returns the route that the data key forces, or `null` once it is ready.
///
/// The private data stays unreadable until the key is ready, so the app waits
/// on the splash, or asks for the recovery key on a new device.
String? _forcedDataKeyRoute(Ref ref, String path) {
  final session = ref.read(userDataKeySessionProvider);
  if (session.hasError) {
    // Onboarding keeps its answers only in memory and retries by itself.
    return path == AppRoutes.calorieGoalSetup ? null : AppRoutes.dataKey;
  }
  return switch (session.value) {
    null => _waitsOnCurrentRoute(path) ? null : AppRoutes.splash,
    UserDataKeyRecoveryRequired() => AppRoutes.dataKey,
    UserDataKeyReady() || UserDataKeySignedOut() => null,
  };
}

/// Finishing onboarding signs in a new guest. The intro stays open while the
/// data key and the completion state of that account load.
bool _waitsOnCurrentRoute(String path) {
  return path == AppRoutes.welcome || path == AppRoutes.calorieGoalSetup;
}

String? _redirectFromWelcome(
  Ref ref,
  GoRouterState state, {
  required bool isAnonymous,
}) {
  final calorieState = ref.read(calorieGoalOnboardingCompletedProvider);
  final hasCalorie = calorieState.asData?.value ?? false;
  final isFromOnboarding = state.uri.queryParameters['from'] == 'onboarding';
  if (isAnonymous && isFromOnboarding && !hasCalorie) {
    return null;
  }
  // After a sign-in, a failed read must not open onboarding, so welcome
  // waits until the completion state has loaded.
  if (calorieState.hasError) {
    return AppRoutes.calorieGoalLoadFailed;
  }
  if (calorieState.isLoading) {
    return null;
  }
  return hasCalorie ? AppRoutes.homeDiary : AppRoutes.calorieGoalSetup;
}

String? _redirectForOnboarding(Ref ref, String path) {
  final calorieState = ref.read(calorieGoalOnboardingCompletedProvider);
  final hasPendingInvite = ref.read(pendingHouseholdInviteProvider) != null;
  return _redirectForCalorieGoal(
    calorieState,
    path,
    homeRoute: hasPendingInvite
        ? AppRoutes.homeSettingsHousehold
        : AppRoutes.homeDiary,
  );
}

String? _redirectForCalorieGoal(
  AsyncValue<bool> calorieState,
  String path, {
  required String homeRoute,
}) {
  final isStartup = path == AppRoutes.root || path == AppRoutes.splash;
  if (calorieState.hasError) {
    // An offline read must not send a user with a goal into onboarding.
    // Checked before loading and value: Riverpod keeps the error while it
    // retries, and keeps the `false` of a signed-out start after a failed
    // rebuild. A user with the local marker is never read, so a kept `true`
    // cannot come with an error. Onboarding stays open: a new guest finishing
    // it keeps the answers only in memory while the save runs.
    return path == AppRoutes.calorieGoalLoadFailed ||
            path == AppRoutes.calorieGoalSetup
        ? null
        : AppRoutes.calorieGoalLoadFailed;
  }
  if (calorieState.isLoading) {
    return isStartup ? AppRoutes.splash : null;
  }
  if (!(calorieState.asData?.value ?? false)) {
    return path == AppRoutes.calorieGoalSetup
        ? null
        : AppRoutes.calorieGoalSetup;
  }
  return _isTerminalRoute(path) ? homeRoute : null;
}

bool _isTerminalRoute(String path) {
  return path == AppRoutes.root ||
      path == AppRoutes.splash ||
      path == AppRoutes.dataKey ||
      path == AppRoutes.calorieGoalLoadFailed ||
      path == AppRoutes.calorieGoalSetup;
}
