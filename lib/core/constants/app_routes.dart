abstract final class AppRoutes {
  static const root = '/';
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const guestNameSetup = '/welcome/guest-name';
  static const calorieGoalSetup = '/welcome/calorie-goal';
  static const home = '/home';
  static const homeInventory = '/home/inventory';
  static const homeInventoryManualAdd = '/home/inventory/manual-add';
  static const homeInventoryTemplates = '/home/inventory/templates';
  static const homeInventoryTemplateImportReview =
      '/home/inventory/templates/import-review';
  static const homeInventoryTemplateDetail =
      '/home/inventory/templates/:templateId';
  static const homeInventoryReceiptReview = '/home/inventory/receipt-review';
  static const homeShopping = '/home/shopping';
  static const homeCalories = '/home/calories';
  static const homeCaloriesEntryCreate = '/home/calories/entry/create';
  static const homeCaloriesEntryEdit = '/home/calories/entry/:entryId/edit';
  static const homeCaloriesBarcodeScan = '/home/calories/barcode-scan';
  static const homeStatistics = '/home/statistics';
  static const homeSettings = '/home/settings';
  static const homeSettingsAccount = '/home/settings/account';
  static const homeSettingsHousehold = '/home/settings/household';

  static String homeCaloriesEntryEditPath(String entryId) {
    return '/home/calories/entry/$entryId/edit';
  }

  static String homeInventoryTemplateDetailPath(String templateId) {
    return '/home/inventory/templates/$templateId';
  }
}
