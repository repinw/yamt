import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_entry_delete_result.dart';

void main() {
  group('CalorieEntryDeleteResult', () {
    test('success constructor creates successful result', () {
      const result = CalorieEntryDeleteResult.success(
        restoredToInventory: true,
      );

      expect(result.isSuccess, isTrue);
      expect(result.restoredToInventory, isTrue);
      expect(result.failureReason, isNull);
    });

    test('failure constructor creates failed result with reason', () {
      const result = CalorieEntryDeleteResult.failure(
        CalorieEntryDeleteFailureReason.sourceMissing,
      );

      expect(result.isSuccess, isFalse);
      expect(result.restoredToInventory, isFalse);
      expect(
        result.failureReason,
        CalorieEntryDeleteFailureReason.sourceMissing,
      );
    });
  });
}
