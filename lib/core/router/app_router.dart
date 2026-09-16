import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/router/app_route_definitions.dart';
import 'package:yamt/core/router/app_route_observer.dart';
import 'package:yamt/core/router/app_router_redirect.dart';
import 'package:yamt/features/auth/application/'
    'auth_profile_setup_status_provider.dart';
import 'package:yamt/features/auth/application/'
    'initial_guest_auth_controller.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/onboarding/provider/'
    'calorie_goal_onboarding_completed_provider.dart';

part 'app_router.g.dart';

/// Provides root navigator key for app routing.
@Riverpod(keepAlive: true)
GlobalKey<NavigatorState> navigatorKey(Ref ref) {
  return GlobalKey<NavigatorState>(debugLabel: 'rootNavigator');
}

/// Provides listenable used to refresh router redirects.
@Riverpod(keepAlive: true)
Raw<AppRouterRefreshListenable> appRouterRefreshListenable(Ref ref) {
  final listenable = AppRouterRefreshListenable();
  ref
    ..onDispose(listenable.dispose)
    ..listen(authStateChangesProvider, (previous, next) {
      listenable.refresh();
    })
    ..listen(initialGuestAuthControllerProvider, (previous, next) {
      listenable.refresh();
    })
    ..listen(authProfileSetupCompletedProvider, (previous, next) {
      listenable.refresh();
    })
    ..listen(calorieGoalOnboardingCompletedProvider, (previous, next) {
      listenable.refresh();
    });
  return listenable;
}

/// Provides application `GoRouter` instance.
@Riverpod(keepAlive: true)
Raw<GoRouter> appRouter(Ref ref) {
  final navigatorKey = ref.watch(navigatorKeyProvider);
  final routeObserver = ref.watch(appRouteObserverProvider);
  final refreshListenable = ref.watch(appRouterRefreshListenableProvider);
  final router = GoRouter(
    navigatorKey: navigatorKey,
    observers: [routeObserver],
    initialLocation: AppRoutes.root,
    refreshListenable: refreshListenable,
    redirect: (context, state) => appRouterRedirect(ref, state),
    routes: buildAppRoutes(ref),
  );
  ref.onDispose(router.dispose);
  return router;
}

/// Change notifier bridge used to refresh `GoRouter`.
class AppRouterRefreshListenable extends ChangeNotifier {
  /// Triggers one router refresh cycle.
  void refresh() {
    notifyListeners();
  }
}
