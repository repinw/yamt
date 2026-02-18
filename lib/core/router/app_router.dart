import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/auth/welcome_page.dart';
import 'package:yamt/features/home/home_page.dart';
import 'package:yamt/features/home/home_tab_page.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);
  final isAuthLoading = authState.isLoading;
  final user = authState.asData?.value;
  final isAuthenticated = user != null;

  return GoRouter(
    initialLocation: AppRoutes.root,
    redirect: (context, state) {
      final path = state.matchedLocation;
      final isStartupRoute = path == AppRoutes.root || path == AppRoutes.splash;

      if (isAuthLoading) {
        return path == AppRoutes.splash ? null : AppRoutes.splash;
      }

      if (!isAuthenticated) {
        return path == AppRoutes.welcome ? null : AppRoutes.welcome;
      }

      if (path == AppRoutes.welcome || isStartupRoute) {
        return AppRoutes.homeInventory;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.root,
        redirect: (context, state) =>
            isAuthenticated ? AppRoutes.homeInventory : AppRoutes.welcome,
      ),
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const _AuthLoadingPage(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        redirect: (context, state) => AppRoutes.homeInventory,
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomePage(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.homeInventory,
                builder: (context, state) =>
                    const HomeTabPage(tab: HomeTabType.inventory),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.homeShopping,
                builder: (context, state) =>
                    const HomeTabPage(tab: HomeTabType.shopping),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.homeCalories,
                builder: (context, state) =>
                    const HomeTabPage(tab: HomeTabType.calories),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.homeSettings,
                builder: (context, state) =>
                    const HomeTabPage(tab: HomeTabType.settings),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class _AuthLoadingPage extends StatelessWidget {
  const _AuthLoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
