import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/router/home_shell_routes.dart';
import 'package:yamt/core/router/route_page_helpers.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/presentation/guest_name_setup_page.dart';
import 'package:yamt/features/auth/presentation/welcome_page.dart';
import 'package:yamt/features/calories/presentation/calorie_entry_editor_page.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_args.dart';
import 'package:yamt/features/calories/presentation/pages/tdee_analytics_page.dart';
import 'package:yamt/features/cooking_flow/presentation/cooking_flow_page.dart';
import 'package:yamt/features/household/presentation/household_page.dart';
import 'package:yamt/features/inventory/presentation/inventory_shopping_list_page.dart';
import 'package:yamt/features/kitchen_utensils/presentation/'
    'kitchen_utensils_page.dart';
import 'package:yamt/features/meal_templates/presentation/'
    'meal_template_import_review_page.dart';
import 'package:yamt/features/meal_templates/presentation/models/'
    'meal_template_import_review_args.dart';
import 'package:yamt/features/onboarding/presentation/'
    'calorie_goal_onboarding_page.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'models/product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_page.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_search_page.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_page_route.dart';
import 'package:yamt/features/scanner/domain/models/scanned_receipt.dart';
import 'package:yamt/features/scanner/presentation/receipt_review_page.dart';
import 'package:yamt/features/settings/presentation/pages/account_page.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page.dart';

/// Builds the complete route tree for `GoRouter`.
List<RouteBase> buildAppRoutes(Ref ref) {
  return [
    GoRoute(
      path: AppRoutes.root,
      redirect: (context, state) {
        final authState = ref.read(authStateChangesProvider);
        return authState.asData?.value != null
            ? AppRoutes.homeDiary
            : AppRoutes.welcome;
      },
    ),
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const AuthLoadingPage(),
    ),
    GoRoute(
      path: AppRoutes.welcome,
      builder: (context, state) => const WelcomePage(),
    ),
    GoRoute(
      path: AppRoutes.guestNameSetup,
      builder: (context, state) => const GuestNameSetupPage(),
    ),
    GoRoute(
      path: AppRoutes.calorieGoalSetup,
      builder: (context, state) => const CalorieGoalOnboardingPage(),
    ),
    GoRoute(
      path: AppRoutes.home,
      redirect: (context, state) => AppRoutes.homeDiary,
    ),
    GoRoute(
      path: AppRoutes.productSearchChildFlow,
      redirect: redirectInvalidManualProductSearchRoute,
      pageBuilder: buildManualProductSearchRoutePage,
    ),
    GoRoute(
      path: AppRoutes.homeProductSearchHub,
      builder: (context, state) => ProductSearchHubPage(
        args: resolveProductSearchHubRouteArgs(state.extra),
      ),
    ),
    GoRoute(
      path: AppRoutes.homeProductSearchHubSearch,
      builder: (context, state) => ProductSearchHubSearchPage(
        args: resolveProductSearchHubRouteArgs(state.extra),
      ),
    ),
    GoRoute(
      path: AppRoutes.homeSettings,
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: AppRoutes.homeSettingsAccount,
      builder: (context, state) => const AccountPage(),
    ),
    GoRoute(
      path: AppRoutes.homeSettingsHousehold,
      builder: (context, state) => const HouseholdPage(),
    ),
    GoRoute(
      path: AppRoutes.homeCaloriesEntryCreate,
      redirect: _redirectCalorieEntryCreate,
      builder: _buildCalorieEntryCreate,
    ),
    GoRoute(
      path: AppRoutes.homeCaloriesEntryDetails,
      pageBuilder: (context, state) => ModalBottomSheetPage<void>(
        key: state.pageKey,
        child: CalorieEntryEditorPage(entryId: state.pathParameters['entryId']),
      ),
    ),
    GoRoute(
      path: AppRoutes.homeCaloriesAnalytics,
      builder: (context, state) => const TdeeAnalyticsPage(),
    ),
    GoRoute(
      path: AppRoutes.homeInventoryReceiptReview,
      builder: (context, state) => ReceiptReviewPage(
        initialReceipt: requireRouteExtra<ScannedReceipt>(
          state,
          'Inventory receipt review route requires ScannedReceipt.',
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.homeInventoryTemplateImportReview,
      builder: (context, state) => MealTemplateImportReviewPage(
        args: requireRouteExtra<MealTemplateImportReviewArgs>(
          state,
          'Meal template import review route requires '
          'MealTemplateImportReviewArgs.',
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.homeInventoryTemplateDetail,
      builder: (context, state) =>
          CookingFlowPage(templateId: state.pathParameters['templateId'] ?? ''),
    ),
    GoRoute(
      path: AppRoutes.homeKitchenUtensils,
      builder: (context, state) => const KitchenUtensilsPage(),
    ),
    GoRoute(
      path: AppRoutes.homeShopping,
      builder: (context, state) => const InventoryShoppingListPage(),
    ),
    buildHomeShellRoute(),
  ];
}

String? _redirectCalorieEntryCreate(BuildContext context, GoRouterState state) {
  final args = state.extra;
  if (args is! CalorieEntryCreateArgs || args.inventoryContext == null) {
    return AppRoutes.homeInventory;
  }
  return null;
}

Widget _buildCalorieEntryCreate(BuildContext context, GoRouterState state) {
  final args = state.extra! as CalorieEntryCreateArgs;
  return CalorieEntryEditorPage(
    prefilledProfile: args.prefilledProfile,
    scannedSourceRef: args.scannedSourceRef,
    inventoryContext: args.inventoryContext,
    preselectedMealType: args.preselectedMealType,
    preselectedLoggedAt: args.preselectedLoggedAt,
  );
}
