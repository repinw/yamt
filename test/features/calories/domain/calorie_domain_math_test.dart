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

  group('CalorieDomainMath.theilSenSlope', () {
    test('returns the slope of a straight line', () {
      expect(
        CalorieDomainMath.theilSenSlope([
          for (var x = 0; x < 5; x++) (x: x.toDouble(), y: 80 - 0.1 * x),
        ]),
        closeTo(-0.1, 1e-9),
      );
    });

    test('ignores one outlier', () {
      expect(
        CalorieDomainMath.theilSenSlope([
          for (var x = 0; x < 7; x++)
            (x: x.toDouble(), y: x == 6 ? 82.0 : 80 - 0.1 * x),
        ]),
        closeTo(-0.1, 1e-9),
      );
    });

    test('returns zero without two distinct x values', () {
      expect(CalorieDomainMath.theilSenSlope([(x: 1, y: 80)]), 0);
    });
  });
}
