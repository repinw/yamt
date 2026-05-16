/// Named route paths used by `go_router`.
abstract final class AppRoutes {
  /// App root route.
  static const root = '/';

  /// Splash route.
  static const splash = '/splash';

  /// Welcome route.
  static const welcome = '/welcome';

  /// Guest-name setup route.
  static const guestNameSetup = '/welcome/guest-name';

  /// Calorie goal setup route.
  static const calorieGoalSetup = '/welcome/calorie-goal';

  /// Home shell route.
  static const home = '/home';

  /// Inventory home route.
  static const homeInventory = '/home/inventory';

  /// Manual inventory add route.
  static const homeInventoryManualAdd = '/home/inventory/manual-add';

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

  /// Statistics home route.
  static const homeStatistics = '/home/statistics';

  /// Weight trends route from statistics.
  static const homeStatisticsWeight = '/home/statistics/weight';

  /// Settings home route.
  static const homeSettings = '/home/settings';

  /// Account settings route.
  static const homeSettingsAccount = '/home/settings/account';

  /// Household settings route.
  static const homeSettingsHousehold = '/home/settings/household';

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
}
