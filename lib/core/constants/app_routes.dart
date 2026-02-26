abstract final class AppRoutes {
  static const root = '/';
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const guestNameSetup = '/welcome/guest-name';
  static const home = '/home';
  static const homeInventory = '/home/inventory';
  static const homeShopping = '/home/shopping';
  static const homeCalories = '/home/calories';
  static const homeCaloriesEntryCreate = '/home/calories/entry/create';
  static const homeCaloriesEntryEdit = '/home/calories/entry/:entryId/edit';
  static const homeCaloriesBarcodeScan = '/home/calories/barcode-scan';
  static const homeSettings = '/home/settings';
  static const homeSettingsAccount = '/home/settings/account';

  static String homeCaloriesEntryEditPath(String entryId) {
    return '/home/calories/entry/$entryId/edit';
  }
}
