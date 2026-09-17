import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/auth/application/'
    'auth_profile_setup_status_provider.dart';
import 'package:yamt/features/auth/application/'
    'initial_guest_auth_controller.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/onboarding/provider/'
    'calorie_goal_onboarding_completed_provider.dart';

/// Evaluates application-wide redirects based on auth and onboarding state.
String? appRouterRedirect(Ref ref, GoRouterState state) {
  final path = state.matchedLocation;
  final authState = ref.read(authStateChangesProvider);
  final guestState = ref.read(initialGuestAuthControllerProvider);
  final isAuthLoading = authState.isLoading || guestState.isLoading;
  if (isAuthLoading) return path == AppRoutes.splash ? null : AppRoutes.splash;

  final currentUser = authState.asData?.value;
  if (currentUser == null) {
    return path == AppRoutes.welcome ? null : AppRoutes.welcome;
  }

  final isAnon = currentUser.isAnonymous;
  if (path == AppRoutes.welcome) {
    return _redirectFromWelcome(ref, state, isAnonymous: isAnon);
  }

  return _redirectForOnboarding(ref, path, isAnonymous: isAnon);
}

String? _redirectFromWelcome(
  Ref ref,
  GoRouterState state, {
  required bool isAnonymous,
}) {
  final hasCalorie =
      ref.read(calorieGoalOnboardingCompletedProvider).asData?.value ?? false;
  final isFromOnboarding = state.uri.queryParameters['from'] == 'onboarding';
  if (isAnonymous && isFromOnboarding && !hasCalorie) {
    return null;
  }
  return hasCalorie ? AppRoutes.homeDiary : AppRoutes.calorieGoalSetup;
}

String? _redirectForOnboarding(
  Ref ref,
  String path, {
  required bool isAnonymous,
}) {
  final hasProfile = isAnonymous || ref.read(authProfileSetupCompletedProvider);
  if (!isAnonymous && !hasProfile) {
    return path == AppRoutes.guestNameSetup ? null : AppRoutes.guestNameSetup;
  }

  final calorieState = hasProfile
      ? ref.read(calorieGoalOnboardingCompletedProvider)
      : const AsyncData<bool>(false);
  return _redirectForCalorieGoal(calorieState, path);
}

String? _redirectForCalorieGoal(AsyncValue<bool> calorieState, String path) {
  final isStartup = path == AppRoutes.root || path == AppRoutes.splash;
  if (calorieState.isLoading) {
    return (isStartup || path == AppRoutes.calorieGoalSetup)
        ? AppRoutes.splash
        : null;
  }
  if (!(calorieState.asData?.value ?? false)) {
    return path == AppRoutes.calorieGoalSetup
        ? null
        : AppRoutes.calorieGoalSetup;
  }
  return _isTerminalRoute(path) ? AppRoutes.homeDiary : null;
}

bool _isTerminalRoute(String path) {
  return path == AppRoutes.root ||
      path == AppRoutes.splash ||
      path == AppRoutes.guestNameSetup ||
      path == AppRoutes.calorieGoalSetup;
}
