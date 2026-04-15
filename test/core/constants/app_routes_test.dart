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
    expect(AppRoutes.homeInventoryTemplates, '/home/inventory/templates');
    expect(AppRoutes.homeShopping, '/home/shopping');
    expect(AppRoutes.homeCalories, '/home/calories');
    expect(AppRoutes.homeStatisticsWeight, '/home/statistics/weight');
    expect(AppRoutes.homeSettings, '/home/settings');
    expect(AppRoutes.homeSettingsAccount, '/home/settings/account');
  });
}
