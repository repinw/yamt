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
import 'package:yamt/features/cookbook_new/presentation/cooked_meal_page.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_editor_route_args.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_editor_page.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_page.dart';
import 'package:yamt/features/data_export/presentation/data_export_page.dart';
import 'package:yamt/features/diary/presentation/diary_entry_details_page.dart';
import 'package:yamt/features/household/presentation/household_page.dart';
import 'package:yamt/features/inventory/presentation/inventory_shopping_list_page.dart';
import 'package:yamt/features/inventory/presentation/models/food_pick_route_args.dart';
import 'package:yamt/features/inventory/presentation/models/prepared_meal_food_source.dart';
import 'package:yamt/features/kitchen_utensils/presentation/'
    'kitchen_utensils_page.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_assign_page.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_page.dart';
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
import 'package:yamt/features/progress/presentation/progress_photo_compare_page.dart';
import 'package:yamt/features/progress/presentation/progress_photo_viewer_page.dart';
import 'package:yamt/features/progress/presentation/progress_photos_page.dart';
import 'package:yamt/features/progress/presentation/progress_weights_page.dart';
import 'package:yamt/features/scanner/domain/models/scanned_receipt.dart';
import 'package:yamt/features/scanner/presentation/receipt_review_page.dart';
import 'package:yamt/features/settings/presentation/pages/account_page.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page.dart';
import 'package:yamt/features/settings/presentation/profile_page.dart';
import 'package:yamt/features/settings/presentation/settings_custom_colors_page.dart';

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
        args: _foodPickArgs(
          requireRouteExtra<FoodPickRouteArgs>(
            state,
            'The food pick route requires FoodPickRouteArgs.',
          ),
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
      path: AppRoutes.homeSettingsCustomColors,
      builder: (context, state) => const SettingsCustomColorsPage(),
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
      path: AppRoutes.homeProgressPhotos,
      builder: (context, state) => const ProgressPhotosPage(),
    ),
    GoRoute(
      path: AppRoutes.homeProgressWeights,
      builder: (context, state) => const ProgressWeightsPage(),
    ),
    GoRoute(
      path: AppRoutes.homeProgressExport,
      builder: (context, state) => const DataExportPage(),
    ),
    GoRoute(
      path: AppRoutes.homeProgressPhotoViewer,
      builder: (context, state) => ProgressPhotoViewerPage(
        photoId:
            state.uri.queryParameters[AppRoutes.homeProgressPhotoIdParam] ?? '',
      ),
    ),
    GoRoute(
      path: AppRoutes.homeProgressPhotoCompare,
      builder: (context, state) => ProgressPhotoComparePage(
        poseName:
            state.uri.queryParameters[AppRoutes.homeProgressPhotoPoseParam],
        scopeName:
            state.uri.queryParameters[AppRoutes.homeProgressPhotoScopeParam],
      ),
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
      path: AppRoutes.homeCook,
      builder: (context, state) => KochmodusAssignPage(
        recipeId: state.pathParameters['recipeId'] ?? '',
        // Fewer than 1 portion cooks the recipe's own.
        portions: switch (int.tryParse(
          state.uri.queryParameters[AppRoutes.homeCookPortionsParam] ?? '',
        )) {
          final portions? when portions >= 1 => portions,
          _ => null,
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.homeCookRun,
      builder: (context, state) =>
          KochmodusPage.run(runId: state.pathParameters['runId'] ?? ''),
    ),
    GoRoute(
      path: AppRoutes.homeFreeCooking,
      builder: (context, state) => const KochmodusPage.free(),
    ),
    GoRoute(
      path: AppRoutes.homeRecipeNew,
      builder: (context, state) => RecipeEditorPage(
        args: requireRouteExtra<RecipeEditorRouteArgs>(
          state,
          'The new recipe editor route requires RecipeEditorRouteArgs.',
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.homeRecipeEdit,
      builder: (context, state) =>
          RecipeEditorPage(recipeId: state.pathParameters['recipeId'] ?? ''),
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

// The hub of the food pick [args]. With a recipe ingredient already in the
// search field the keyboard stays closed, so the results show; a tap into
// the field opens it.
ProductSearchHubRouteArgs _foodPickArgs(FoodPickRouteArgs args) =>
    ProductSearchHubRouteArgs(
      mode: ProductSearchHubMode.mealFood,
      initialIntent: switch (args.source) {
        PreparedMealFoodSource.barcode => ProductSearchHubInitialIntent.barcode,
        PreparedMealFoodSource.ai => ProductSearchHubInitialIntent.ai,
        PreparedMealFoodSource.search => ProductSearchHubInitialIntent.search,
      },
      initialQuery: args.query,
      autofocusSearchField:
          args.ingredient == null || (args.query ?? '').trim().isEmpty,
      ingredient: args.ingredient,
      pieceWeight: args.pieceWeight,
      ingredientUnit: args.ingredientUnit,
      ingredientNeed: args.ingredientNeed,
      takesFromStock: args.takesFromStock,
      heldItemIds: args.heldItemIds,
    );
