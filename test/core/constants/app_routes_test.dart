import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/constants/app_routes.dart';

void main() {
  test('the Vorrat path opens the page of a meal by its id', () {
    final uri = Uri.parse(AppRoutes.homeInventoryMealPath('a b/1'));

    expect(uri.path, AppRoutes.homeInventory);
    expect(uri.queryParameters, {AppRoutes.homeInventoryMealParam: 'a b/1'});
  });

  group('homeCookRecipePath', () {
    test('opens the running cook run of the recipe', () {
      expect(
        AppRoutes.homeCookRecipePath('t1', runId: 'recipe-t1', portions: 3),
        AppRoutes.homeCookRunPath('recipe-t1'),
      );
    });

    test('starts a new cooking with the portions when no run exists', () {
      expect(
        AppRoutes.homeCookRecipePath('t1', runId: null, portions: 3),
        AppRoutes.homeCookPath('t1', portions: 3),
      );
      expect(AppRoutes.homeCookRecipePath('t1', runId: null), '/home/cook/t1');
    });
  });
}
