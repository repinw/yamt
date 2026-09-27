import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking_flow/domain/'
    'cooking_flow_portion_distribution.dart';

void main() {
  group('distributeCookingFlowPortions', () {
    test('splits the total by net weight and keeps the sum', () {
      final portions = distributeCookingFlowPortions(
        totalPortions: 4,
        netWeights: const <int>[400, 350],
      );

      expect(portions, <int>[2, 2]);
    });

    test('gives the heavier container the bigger share', () {
      final portions = distributeCookingFlowPortions(
        totalPortions: 5,
        netWeights: const <int>[900, 300],
      );

      expect(portions, <int>[4, 1]);
      expect(portions.reduce((a, b) => a + b), 5);
    });

    test('keeps at least one portion per container', () {
      final portions = distributeCookingFlowPortions(
        totalPortions: 4,
        netWeights: const <int>[1000, 10, 10],
      );

      expect(portions, <int>[2, 1, 1]);
    });

    test('uses one portion per container when portions run short', () {
      final portions = distributeCookingFlowPortions(
        totalPortions: 1,
        netWeights: const <int>[500, 500],
      );

      expect(portions, <int>[1, 1]);
    });

    test('splits evenly while no weight is entered', () {
      final portions = distributeCookingFlowPortions(
        totalPortions: 4,
        netWeights: const <int>[0, -20],
      );

      expect(portions, <int>[2, 2]);
    });

    test('keeps the whole total for a single container', () {
      expect(
        distributeCookingFlowPortions(
          totalPortions: 4,
          netWeights: const <int>[600],
        ),
        <int>[4],
      );
      expect(
        distributeCookingFlowPortions(
          totalPortions: 4,
          netWeights: const <int>[],
        ),
        isEmpty,
      );
    });
  });
}
