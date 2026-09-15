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
import 'package:yamt/features/cooking_flow/presentation/controllers/'
    'cooking_flow_controller.dart';
import 'package:yamt/features/cooking_flow/presentation/controllers/'
    'cooking_flow_wizard_controller.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_cooking_page.dart';
import 'package:yamt/features/diary/application/'
    'diary_quick_eat_inventory_provider.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_shopping_suggestions.dart';
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
import 'package:yamt/features/onboarding/provider/'
    'calorie_goal_onboarding_completed_provider.dart';
import 'package:yamt/features/product_search_hub/data/'
    'composite_product_search_adapter.dart';
import 'package:yamt/features/product_search_hub/data/'
    'product_search_hub_completion_providers.dart';
import 'package:yamt/features/scanner/data/receipt_gateway_providers.dart';
import 'package:yamt/features/scanner/presentation/controllers/'
    'receipt_review_controller.dart';
import 'package:yamt/features/scanner/presentation/flow/'
    'receipt_camera_supported.dart';
import 'package:yamt/features/scanner/presentation/flow/'
    'receipt_scan_flow_coordinator.dart';

part 'app_router.g.dart';

/// Provides root navigator key for app routing.
@Riverpod(keepAlive: true, dependencies: [])
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
@Riverpod(
  keepAlive: true,
  dependencies: [
    navigatorKey,
    inventoryItemRepository,
    inventoryManualAddQuickEatConfig,
    diaryQuickEatInventory,
    diaryQuickEatInventoryActions,
    CookingFlowController,
    CookingFlowWizardController,
    cookingInstructionSteps,
    InventoryItemsController,
    PreparedMealsController,
    inventoryBackedCalorieEntrySaveFlow,
    manualProductRecentItemsService,
    preparedMealImagePicker,
    receiptScanFlowCoordinator,
    receiptCameraSupported,
    inventoryActivityEvents,
    inventoryShoppingSuggestions,
    ReceiptReviewController,
    receiptManualProductPicker,
    productSearchGateway,
    productSearchHubCompletionHandler,
  ],
)
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
