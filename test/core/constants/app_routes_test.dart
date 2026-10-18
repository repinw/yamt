import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/constants/app_routes.dart';

void main() {
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

  test('food pick path carries the text the search starts with', () {
    final uri = Uri.parse(AppRoutes.homeFoodPickPath(query: 'Reis & Bohnen'));

    expect(uri.path, AppRoutes.homeFoodPick);
    expect(uri.queryParameters, {
      AppRoutes.homeFoodPickQueryParam: 'Reis & Bohnen',
    });
  });
}
