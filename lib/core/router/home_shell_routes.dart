import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/diary/application/'
    'diary_quick_eat_inventory_provider.dart';
import 'package:yamt/features/diary/presentation/diary_page.dart';
import 'package:yamt/features/home/home_page.dart';
import 'package:yamt/features/home/widgets/inventory_action_fab.dart';
import 'package:yamt/features/inventory/application/'
    'manual_product_recent_items_service.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_activity_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_image_picker.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meals_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/inventory/presentation/inventory_page.dart';
import 'package:yamt/features/meal_templates/presentation/widgets/'
    'meal_templates_page/meal_templates_page.dart';
import 'package:yamt/features/scanner/data/receipt_gateway_providers.dart';
import 'package:yamt/features/scanner/presentation/flow/'
    'receipt_camera_supported.dart';
import 'package:yamt/features/scanner/presentation/flow/'
    'receipt_scan_flow_coordinator.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page.dart';

/// Builds the home navigation shell route with bottom-bar tab branches.
@Dependencies([
  InventoryItemsController,
  PreparedMealsController,
  receiptScanFlowCoordinator,
  receiptCameraSupported,
  receiptManualProductPicker,
  inventoryManualAddQuickEatConfig,
  inventoryItemRepository,
  preparedMealImagePicker,
  manualProductRecentItemsService,
  inventoryActivityEvents,
  inventoryBackedCalorieEntrySaveFlow,
  diaryQuickEatInventory,
  diaryQuickEatInventoryActions,
])
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
