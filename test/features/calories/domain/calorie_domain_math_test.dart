import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_domain_math.dart';

void main() {
  group('CalorieDomainMath.average', () {
    test('returns zero for empty input', () {
      expect(CalorieDomainMath.average(const <double>[]), 0);
    });

    test('returns the single value for one item', () {
      expect(CalorieDomainMath.average(const <double>[42]), 42);
    });

    test('averages identical values', () {
      expect(CalorieDomainMath.average(const <double>[7, 7, 7]), 7);
    });

    test('averages decimal values', () {
      expect(CalorieDomainMath.average(const <double>[1.5, 2.5, 3.5]), 2.5);
    });
  });

  group('CalorieDomainMath.median', () {
    test('returns zero for empty input', () {
      expect(CalorieDomainMath.median(const <double>[]), 0);
    });

    test('returns middle value for odd input length', () {
      expect(CalorieDomainMath.median(const <double>[1, 9, 5]), 5);
    });

    test('averages middle values for even input length', () {
      expect(CalorieDomainMath.median(const <double>[1, 9, 5, 7]), 6);
    });

    test('sorts unsorted input before resolving median', () {
      expect(CalorieDomainMath.median(const <double>[10, 1, 4, 3, 8]), 4);
    });
  });
}
