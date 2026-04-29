import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/constants/app_routes.dart';

void main() {
  test('AppRoutes constants are stable', () {
    expect(AppRoutes.root, '/');
    expect(AppRoutes.splash, '/splash');
    expect(AppRoutes.welcome, '/welcome');
    expect(AppRoutes.guestNameSetup, '/welcome/guest-name');
    expect(AppRoutes.calorieGoalSetup, '/welcome/calorie-goal');
    expect(AppRoutes.home, '/home');
    expect(AppRoutes.homeInventory, '/home/inventory');
    expect(AppRoutes.homeInventoryManualAdd, '/home/inventory/manual-add');
    expect(AppRoutes.homeInventoryTemplates, '/home/inventory/templates');
    expect(
      AppRoutes.homeInventoryTemplateImportReview,
      '/home/inventory/templates/import-review',
    );
    expect(
      AppRoutes.homeInventoryTemplateDetail,
      '/home/inventory/templates/:templateId',
    );
    expect(
      AppRoutes.homeInventoryReceiptReview,
      '/home/inventory/receipt-review',
    );
    expect(AppRoutes.homeShopping, '/home/shopping');
    expect(AppRoutes.homeDiary, '/home/calories');
    expect(AppRoutes.homeCalories, '/home/calories');
    expect(AppRoutes.homeCaloriesBurnWeekMock, '/home/calories/burn-week');
    expect(
      AppRoutes.homeCaloriesEntryCreate,
      '/home/calories/entry/create',
    );
    expect(
      AppRoutes.homeCaloriesEntryDetails,
      '/home/calories/entry/:entryId/details',
    );
    expect(
      AppRoutes.homeCaloriesEntryDetailsPath('entry-1'),
      '/home/calories/entry/entry-1/details',
    );
    expect(
      AppRoutes.homeInventoryTemplateDetailPath('template-1'),
      '/home/inventory/templates/template-1',
    );
    expect(AppRoutes.homeStatistics, '/home/statistics');
    expect(AppRoutes.homeStatisticsWeight, '/home/statistics/weight');
    expect(AppRoutes.homeSettings, '/home/settings');
    expect(AppRoutes.homeSettingsAccount, '/home/settings/account');
    expect(AppRoutes.homeSettingsHousehold, '/home/settings/household');
  });
}
