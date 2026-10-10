import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/router/hero_sheet_page.dart';
import 'package:yamt/core/router/home_shell_routes.dart';
import 'package:yamt/core/router/route_page_helpers.dart';
import 'package:yamt/features/app_update/presentation/update_required_page.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/presentation/data_key_page.dart';
import 'package:yamt/features/auth/presentation/recovery_key_page.dart';
import 'package:yamt/features/auth/presentation/welcome_page.dart';
import 'package:yamt/features/calories/presentation/calorie_goal_archive_page.dart';
import 'package:yamt/features/calories/presentation/tdee_analytics_page.dart';
import 'package:yamt/features/cookbook_new/presentation/cooked_meal_page.dart';
import 'package:yamt/features/cookbook_new/presentation/free_cooking_page.dart';
import 'package:yamt/features/cookbook_new/presentation/ingredient_check_page.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_page.dart';
import 'package:yamt/features/cooking_flow/presentation/cooking_flow_page.dart';
import 'package:yamt/features/diary/presentation/diary_entry_details_page.dart';
import 'package:yamt/features/household/presentation/household_page.dart';
import 'package:yamt/features/inventory/presentation/inventory_shopping_list_page.dart';
import 'package:yamt/features/kitchen_utensils/presentation/'
    'kitchen_utensils_page.dart';
import 'package:yamt/features/meal_templates/presentation/'
    'meal_template_import_review_page.dart';
import 'package:yamt/features/meal_templates/presentation/models/'
    'meal_template_import_review_args.dart';
import 'package:yamt/features/onboarding/presentation/'
    'calorie_goal_load_failed_page.dart';
import 'package:yamt/features/onboarding/presentation/'
    'calorie_goal_onboarding_page.dart';
import 'package:yamt/features/product_search_hub/domain/product_search_hub_mode.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'models/product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/product_search_hub_item_edit_page.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_page.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_page_route.dart';
import 'package:yamt/features/scanner/domain/models/scanned_receipt.dart';
import 'package:yamt/features/scanner/presentation/receipt_review_page.dart';
import 'package:yamt/features/settings/presentation/pages/account_page.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page.dart';
import 'package:yamt/features/settings/presentation/profile_page.dart';

/// Builds the complete route tree for `GoRouter`.
List<RouteBase> buildAppRoutes(Ref ref) {
  return [
    GoRoute(
      path: AppRoutes.root,
      redirect: (context, state) {
        final authState = ref.read(authStateChangesProvider);
        return authState.asData?.value != null
            ? AppRoutes.homeDiary
            : AppRoutes.calorieGoalSetup;
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
      path: AppRoutes.calorieGoalSetup,
      builder: (context, state) => const CalorieGoalOnboardingPage(),
    ),
    GoRoute(
      path: AppRoutes.calorieGoalLoadFailed,
      builder: (context, state) => const CalorieGoalLoadFailedPage(),
    ),
    GoRoute(
      path: AppRoutes.dataKey,
      builder: (context, state) => const DataKeyPage(),
    ),
    GoRoute(
      path: AppRoutes.updateRequired,
      builder: (context, state) => const UpdateRequiredPage(),
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
      path: AppRoutes.homeFoodPick,
      builder: (context, state) => ProductSearchHubPage(
        args: ProductSearchHubRouteArgs(
          mode: ProductSearchHubMode.mealFood,
          initialIntent: switch (state.uri.queryParameters[AppRoutes
              .homeFoodPickStartParam]) {
            AppRoutes.homeFoodPickStartBarcode =>
              ProductSearchHubInitialIntent.barcode,
            AppRoutes.homeFoodPickStartAi => ProductSearchHubInitialIntent.ai,
            _ => ProductSearchHubInitialIntent.search,
          },
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.homeSettings,
      builder: (context, state) => SettingsPage(
        revealAppearance:
            state.uri.queryParameters[AppRoutes.homeSettingsSectionParam] ==
            AppRoutes.homeSettingsSectionAppearance,
      ),
    ),
    GoRoute(
      path: AppRoutes.homeProfile,
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: AppRoutes.homeSettingsAccount,
      builder: (context, state) => const AccountPage(),
    ),
    GoRoute(
      path: AppRoutes.homeSettingsRecoveryKey,
      builder: (context, state) => const RecoveryKeyPage(),
    ),
    GoRoute(
      path: AppRoutes.homeSettingsHousehold,
      builder: (context, state) => const HouseholdPage(),
    ),
    GoRoute(
      path: AppRoutes.householdJoinLink,
      redirect: (context, state) => AppRoutes.homeSettingsHousehold,
    ),
    GoRoute(
      path: AppRoutes.homeCaloriesEntryDetails,
      pageBuilder: (context, state) => HeroSheetPage<void>(
        key: state.pageKey,
        child: DiaryEntryDetailsPage(
          entryId: state.pathParameters['entryId'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.homeCaloriesAnalytics,
      builder: (context, state) => TdeeAnalyticsPage(
        initialCycleIds: state
            .uri
            .queryParameters[AppRoutes.homeCaloriesAnalyticsCyclesParam]
            ?.split(',')
            .toSet(),
      ),
    ),
    GoRoute(
      path: AppRoutes.homeSettingsGoalArchive,
      builder: (context, state) => const CalorieGoalArchivePage(),
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
      path: AppRoutes.homeInventoryItemEdit,
      builder: (context, state) => ProductSearchHubItemEditPage(
        itemId: state.pathParameters['itemId'] ?? '',
      ),
    ),
    GoRoute(
      path: AppRoutes.homeRecipe,
      builder: (context, state) =>
          RecipePage(recipeId: state.pathParameters['recipeId'] ?? ''),
    ),
    GoRoute(
      path: AppRoutes.homeRecipeCheck,
      builder: (context, state) =>
          IngredientCheckPage(recipeId: state.pathParameters['recipeId'] ?? ''),
    ),
    GoRoute(
      path: AppRoutes.homeFreeCooking,
      builder: (context, state) => const FreeCookingPage(),
    ),
    GoRoute(
      path: AppRoutes.homeCookedMeal,
      builder: (context, state) =>
          CookedMealPage(mealId: state.pathParameters['mealId'] ?? ''),
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
