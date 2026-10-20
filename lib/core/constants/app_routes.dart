/// Named route paths used by `go_router`.
abstract final class AppRoutes {
  /// App root route.
  static const root = '/';

  /// Splash route.
  static const splash = '/splash';

  /// Welcome route.
  static const welcome = '/welcome';

  /// Calorie goal setup route.
  static const calorieGoalSetup = '/welcome/calorie-goal';

  /// Shown when the onboarding state of a signed-in user could not load, for
  /// example offline on a new device.
  static const calorieGoalLoadFailed = '/calorie-goal-load-failed';

  /// Data key route: shows a new recovery key or asks for it on a new device.
  static const dataKey = '/data-key';

  /// Shown instead of the app while it is older than the minimum version.
  static const updateRequired = '/update-required';

  /// Home shell route.
  static const home = '/home';

  /// Inventory home route.
  static const homeInventory = '/home/inventory';

  /// Product search hub route.
  static const homeProductSearchHub = '/home/product-search-hub';

  /// Product search that returns the picked food without saving it.
  static const homeFoodPick = '/home/food-pick';

  /// Query parameter of [homeFoodPick] that opens the barcode scanner or the
  /// AI instead of the search.
  static const homeFoodPickStartParam = 'start';

  /// [homeFoodPickStartParam] value that opens the barcode scanner.
  static const homeFoodPickStartBarcode = 'barcode';

  /// [homeFoodPickStartParam] value that opens the AI.
  static const homeFoodPickStartAi = 'ai';

  /// Query parameter of [homeFoodPick] with the text the search starts with.
  static const homeFoodPickQueryParam = 'q';

  /// Builds the food pick path that starts with [start], one of the
  /// `homeFoodPickStart*` values, or with the search for [query] when it is
  /// null.
  static String homeFoodPickPath({String? start, String? query}) {
    final parameters = <String, String>{
      homeFoodPickStartParam: ?start,
      homeFoodPickQueryParam: ?query,
    };
    return Uri(
      path: homeFoodPick,
      queryParameters: parameters.isEmpty ? null : parameters,
    ).toString();
  }

  /// Product-search child flow route.
  static const productSearchChildFlow = '/product-search/child-flow/:flow';

  /// Inventory template list route.
  static const homeInventoryTemplates = '/home/inventory/templates';

  /// Inventory template import review route.
  static const homeInventoryTemplateImportReview =
      '/home/inventory/templates/import-review';

  /// A saved recipe from the Kochbuch, with recipe id parameter.
  static const homeRecipe = '/home/recipe/:recipeId';

  /// Ingredient check of one recipe, with recipe id parameter.
  static const homeRecipeCheck = '/home/recipe/:recipeId/check';

  /// Kochhelfer of one recipe, with recipe id parameter.
  static const homeRecipeGuide = '/home/recipe/:recipeId/guide';

  /// Editor of one Vorrat item, with item id parameter.
  static const homeInventoryItemEdit = '/home/inventory/items/:itemId/edit';

  /// Free cooking: a meal without a recipe, filled by voice or typing.
  static const homeFreeCooking = '/home/free-cooking';

  /// The "Gekocht" step of a meal in the pot, with meal id parameter.
  static const homeCookedMeal = '/home/cooked/:mealId';

  /// Builds the "Gekocht" path of the meal [mealId].
  static String homeCookedMealPath(String mealId) => '/home/cooked/$mealId';

  /// Kitchen utensils route.
  static const homeKitchenUtensils = '/home/kitchen-utensils';

  /// Receipt review route.
  static const homeInventoryReceiptReview = '/home/inventory/receipt-review';

  /// Shopping home route.
  static const homeShopping = '/home/shopping';

  /// Diary home route.
  static const homeDiary = '/home/calories';

  /// Legacy calorie tab route alias.
  static const String homeCalories = homeDiary;

  /// Calorie entry details route with entry id parameter.
  static const homeCaloriesEntryDetails =
      '/home/calories/entry/:entryId/details';

  /// Progress home route.
  static const homeProgress = '/home/progress';

  /// All progress photos, grouped by goal.
  static const homeProgressPhotos = '/home/progress/photos';

  /// Every weighing with the weight trend, grouped by 7-day runs.
  static const homeProgressWeights = '/home/progress/weights';

  /// The before and after comparison of the progress photos.
  static const homeProgressPhotoCompare = '/home/progress/photos/compare';

  /// One progress photo in full size, with its edits.
  static const homeProgressPhotoViewer = '/home/progress/photos/view';

  /// Query parameter with the id of the photo that the viewer shows.
  static const homeProgressPhotoIdParam = 'photo';

  /// The viewer of the photo [photoId].
  static String homeProgressPhotoViewerPath(String photoId) =>
      '$homeProgressPhotoViewer?$homeProgressPhotoIdParam=$photoId';

  /// Query parameter with the pose that the comparison opens with.
  static const homeProgressPhotoPoseParam = 'pose';

  /// Query parameter with the Fortschritt scope that the comparison covers.
  static const homeProgressPhotoScopeParam = 'scope';

  /// The comparison opened with the pose named [pose] in the scope named
  /// [scope].
  static String homeProgressPhotoComparePath({
    required String pose,
    required String scope,
  }) =>
      '$homeProgressPhotoCompare?$homeProgressPhotoPoseParam=$pose'
      '&$homeProgressPhotoScopeParam=$scope';

  /// Settings route, opened from the home side menu.
  static const homeSettings = '/home/settings';

  /// Query parameter of [homeSettings] that names the section to open at.
  static const homeSettingsSectionParam = 'section';

  /// [homeSettingsSectionParam] value for the Appearance section.
  static const homeSettingsSectionAppearance = 'appearance';

  /// Settings opened at the Appearance section.
  static const homeSettingsAppearance =
      '$homeSettings?$homeSettingsSectionParam=$homeSettingsSectionAppearance';

  /// Profile route, opened from the home side menu.
  static const homeProfile = '/home/profile';

  /// Account settings route.
  static const homeSettingsAccount = '/home/settings/account';

  /// Recovery key route, opened from the account settings.
  static const homeSettingsRecoveryKey = '/home/settings/account/recovery-key';

  /// Household settings route.
  static const homeSettingsHousehold = '/home/settings/household';

  /// Path of the household invite deep link `yamt://household/join`.
  static const householdJoinLink = '/join';

  /// Builds calorie entry details path for concrete entry id.
  static String homeCaloriesEntryDetailsPath(String entryId) {
    return '/home/calories/entry/$entryId/details';
  }

  /// Builds product-search child flow path for concrete flow segment.
  static String productSearchChildFlowPath(String flow) {
    return '/product-search/child-flow/$flow';
  }

  /// Builds the path of the recipe page for [recipeId].
  static String homeRecipePath(String recipeId) => '/home/recipe/$recipeId';

  /// Builds the ingredient check path for the recipe [recipeId].
  static String homeRecipeCheckPath(String recipeId) =>
      '/home/recipe/$recipeId/check';

  /// Builds the Kochhelfer path for the recipe [recipeId].
  static String homeRecipeGuidePath(String recipeId) =>
      '/home/recipe/$recipeId/guide';

  /// Builds the editor path for the Vorrat item with [itemId].
  static String homeInventoryItemEditPath(String itemId) {
    return '/home/inventory/items/$itemId/edit';
  }
}
