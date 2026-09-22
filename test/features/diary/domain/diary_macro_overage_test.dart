import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/diary/domain/diary_macro_overage.dart';

void main() {
  group('diaryMacroOverageShare', () {
    test('is the excess share of what was eaten', () {
      expect(
        diaryMacroOverageShare(current: 85, target: 70),
        closeTo(15 / 85, 0.0001),
      );
    });

    test('is zero at or under the target', () {
      expect(diaryMacroOverageShare(current: 70, target: 70), 0);
      expect(diaryMacroOverageShare(current: 40, target: 70), 0);
    });

    test('is zero without a target', () {
      expect(diaryMacroOverageShare(current: 20, target: 0), 0);
    });
  });
}
