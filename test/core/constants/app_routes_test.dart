import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/constants/app_routes.dart';

void main() {
  test('analytics path carries the selected goal cycle ids', () {
    final path = AppRoutes.homeCaloriesAnalyticsPath(
      cycleIds: <String>{'cycle_1_0', 'cycle_2_1'},
    );
    final uri = Uri.parse(path);

    expect(uri.path, AppRoutes.homeCaloriesAnalytics);
    expect(
      uri.queryParameters[AppRoutes.homeCaloriesAnalyticsCyclesParam]
          ?.split(',')
          .toSet(),
      <String>{'cycle_1_0', 'cycle_2_1'},
    );
  });

  test('food pick path starts with the search, the scanner, or the AI', () {
    expect(AppRoutes.homeFoodPickPath(), AppRoutes.homeFoodPick);
    final uri = Uri.parse(
      AppRoutes.homeFoodPickPath(start: AppRoutes.homeFoodPickStartBarcode),
    );

    expect(uri.path, AppRoutes.homeFoodPick);
    expect(
      uri.queryParameters[AppRoutes.homeFoodPickStartParam],
      AppRoutes.homeFoodPickStartBarcode,
    );
  });
}
