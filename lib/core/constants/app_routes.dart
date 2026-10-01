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

  /// Builds the food pick path that starts with [start], one of the
  /// `homeFoodPickStart*` values, or with the search when it is null.
  static String homeFoodPickPath({String? start}) {
    return Uri(
      path: homeFoodPick,
      queryParameters: start == null
          ? null
          : <String, String>{homeFoodPickStartParam: start},
    ).toString();
  }

  /// Product-search child flow route.
  static const productSearchChildFlow = '/product-search/child-flow/:flow';

  /// Inventory template list route.
  static const homeInventoryTemplates = '/home/inventory/templates';

  /// Inventory template import review route.
  static const homeInventoryTemplateImportReview =
      '/home/inventory/templates/import-review';

  /// Inventory template detail route with template id parameter.
  static const homeInventoryTemplateDetail =
      '/home/inventory/templates/:templateId';

  /// Editor of one Vorrat item, with item id parameter.
  static const homeInventoryItemEdit = '/home/inventory/items/:itemId/edit';

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

  /// Calorie entry creation route.
  static const homeCaloriesEntryCreate = '/home/calories/entry/create';

  /// Calorie entry details route with entry id parameter.
  static const homeCaloriesEntryDetails =
      '/home/calories/entry/:entryId/details';

  /// TDEE and weight analytics route.
  static const homeCaloriesAnalytics = '/home/calories/analytics';

  /// Query parameter that lists goal cycle ids preselected in analytics.
  static const homeCaloriesAnalyticsCyclesParam = 'cycles';

  /// Current and archived calorie goals.
  static const homeSettingsGoalArchive = '/home/settings/goals';

  /// Progress home route.
  static const homeProgress = '/home/progress';

  /// Settings route, opened from the home side menu.
  static const homeSettings = '/home/settings';

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

  /// Builds the analytics path with goal cycles preselected by [cycleIds].
  static String homeCaloriesAnalyticsPath({required Set<String> cycleIds}) {
    return Uri(
      path: homeCaloriesAnalytics,
      queryParameters: {homeCaloriesAnalyticsCyclesParam: cycleIds.join(',')},
    ).toString();
  }

  /// Builds calorie entry details path for concrete entry id.
  static String homeCaloriesEntryDetailsPath(String entryId) {
    return '/home/calories/entry/$entryId/details';
  }

  /// Builds product-search child flow path for concrete flow segment.
  static String productSearchChildFlowPath(String flow) {
    return '/product-search/child-flow/$flow';
  }

  /// Builds inventory template detail path for concrete template id.
  static String homeInventoryTemplateDetailPath(String templateId) {
    return '/home/inventory/templates/$templateId';
  }

  /// Builds the editor path for the Vorrat item with [itemId].
  static String homeInventoryItemEditPath(String itemId) {
    return '/home/inventory/items/$itemId/edit';
  }
}
