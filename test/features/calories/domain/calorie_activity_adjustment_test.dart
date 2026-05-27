import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_activity_adjustment.dart';

void main() {
  test('credits corrected activity without a dynamic cap', () {
    final credit = calculateActivityCredit(rawActivityKcal: 899);

    expect(credit.correctedActivityKcal, closeTo(674.25, 0.01));
    expect(credit.activityCapKcal, closeTo(674.25, 0.01));
    expect(credit.creditedActivityKcal, closeTo(674.25, 0.01));
    expect(credit.wasCapped, isFalse);
  });
}
