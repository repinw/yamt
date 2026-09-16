import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/diary/presentation/diary_page.dart';
import 'package:yamt/features/home/home_page.dart';
import 'package:yamt/features/home/widgets/inventory_action_fab.dart';
import 'package:yamt/features/inventory/presentation/inventory_page.dart';
import 'package:yamt/features/meal_templates/presentation/widgets/'
    'meal_templates_page/meal_templates_page.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page.dart';

/// Builds the home navigation shell route with bottom-bar tab branches.
StatefulShellRoute buildHomeShellRoute() {
  return StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) =>
        HomePage(navigationShell: navigationShell),
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.homeInventory,
            builder: (context, state) {
              final expandedPreparedMealId = state.extra is String
                  ? state.extra! as String
                  : null;
              return InventoryPage(
                expandedPreparedMealId: expandedPreparedMealId,
                includeHomeShellChrome: true,
                emptyStateActionButton: const InventoryActionFab.embedded(),
              );
            },
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.homeDiary,
            builder: (context, state) =>
                const DiaryPage(includeHomeShellChrome: true),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.homeInventoryTemplates,
            builder: (context, state) {
              return const MealTemplatesPage(includeAppBar: false);
            },
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.homeSettings,
            builder: (context, state) =>
                const SettingsPage(includeHomeShellChrome: true),
          ),
        ],
      ),
    ],
  );
}
