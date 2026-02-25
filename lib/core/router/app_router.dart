import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/auth/welcome_page.dart';
import 'package:yamt/features/calories/presentation/calorie_entry_editor_page.dart';
import 'package:yamt/features/calories/presentation/calories_page.dart';
import 'package:yamt/features/home/home_page.dart';
import 'package:yamt/features/inventory/presentation/inventory_page.dart';
import 'package:yamt/features/shoppinglist/presentation/shopping_list_page.dart';
import 'package:yamt/features/settings/account_page.dart';
import 'package:yamt/features/settings/settings_page.dart';

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
      GoRoute(
        path: AppRoutes.homeSettingsAccount,
        builder: (context, state) => const AccountPage(),
      ),
      GoRoute(
        path: AppRoutes.homeCaloriesEntryCreate,
        builder: (context, state) => const CalorieEntryEditorPage(),
      ),
      GoRoute(
        path: AppRoutes.homeCaloriesEntryEdit,
        builder: (context, state) {
          final entryId = state.pathParameters['entryId'];
          return CalorieEntryEditorPage(entryId: entryId);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomePage(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.homeInventory,
                builder: (context, state) => const InventoryPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.homeShopping,
                builder: (context, state) => const ShoppingListPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.homeCalories,
                builder: (context, state) => const CaloriesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.homeSettings,
                builder: (context, state) => const SettingsPage(),
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
