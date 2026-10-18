import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_weight_run_rows.dart';

void main() {
  test('a day of another year shows the year', () {
    expect(
      progressWeightDay(DateTime(2026, 9, 21), 2026, 'en_US'),
      'Mon, 9/21',
    );
    expect(
      progressWeightDay(DateTime(2025, 9, 22), 2026, 'en_US'),
      'Mon, 9/22/2025',
    );
  });
}
