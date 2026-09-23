import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/onboarding/domain/tracking_start_day.dart';

void main() {
  group('defaultTrackingStartDay', () {
    test('proposes today in the morning', () {
      expect(
        defaultTrackingStartDay(DateTime(2026, 9, 23, 11, 59)),
        DateTime(2026, 9, 23),
      );
    });

    test('proposes tomorrow from noon on', () {
      expect(
        defaultTrackingStartDay(DateTime(2026, 9, 23, 12)),
        DateTime(2026, 9, 24),
      );
    });

    test('crosses the month end', () {
      expect(
        defaultTrackingStartDay(DateTime(2026, 9, 30, 18)),
        DateTime(2026, 10),
      );
    });
  });

  test('latestTrackingStartDay allows two weeks ahead', () {
    expect(
      latestTrackingStartDay(DateTime(2026, 9, 23, 18)),
      DateTime(2026, 10, 7),
    );
  });
}
