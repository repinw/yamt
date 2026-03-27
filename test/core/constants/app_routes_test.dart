import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/constants/app_routes.dart';

void main() {
  test('AppRoutes constants are stable', () {
    expect(AppRoutes.root, '/');
    expect(AppRoutes.splash, '/splash');
    expect(AppRoutes.welcome, '/welcome');
    expect(AppRoutes.home, '/home');
    expect(AppRoutes.homeInventory, '/home/inventory');
    expect(AppRoutes.homeInventoryTemplates, '/home/inventory/templates');
    expect(AppRoutes.homeShopping, '/home/shopping');
    expect(AppRoutes.homeCalories, '/home/calories');
    expect(AppRoutes.homeSettings, '/home/settings');
    expect(AppRoutes.homeSettingsAccount, '/home/settings/account');
  });
}
