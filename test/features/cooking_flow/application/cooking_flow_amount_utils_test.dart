import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking_flow/application/cooking_flow_amount_utils.dart';

void main() {
  group('parseCookingFlowQuantity', () {
    test('parses decimal and comma values', () {
      expect(parseCookingFlowQuantity('12.5'), 12.5);
      expect(parseCookingFlowQuantity('12,5'), 12.5);
      expect(parseCookingFlowQuantity('1.000,50'), 1000.5);
      expect(parseCookingFlowQuantity('1,000.50'), 1000.5);
      expect(parseCookingFlowQuantity('1 000,50'), 1000.5);
    });

    test('parses simple and mixed fractions', () {
      expect(parseCookingFlowQuantity('1/2'), 0.5);
      expect(parseCookingFlowQuantity(' 1 1/2 '), 1.5);
    });

    test('rejects invalid and zero denominator fractions', () {
      expect(parseCookingFlowQuantity('1/0'), isNull);
      expect(parseCookingFlowQuantity('1 1/0'), isNull);
      expect(parseCookingFlowQuantity('1/2/3'), isNull);
      expect(parseCookingFlowQuantity('abc/def'), isNull);
      expect(parseCookingFlowQuantity('nope'), isNull);
    });
  });

  group('formatCookingFlowDecimal', () {
    test('formats integer values without decimals', () {
      expect(formatCookingFlowDecimal(3), '3');
    });

    test('removes trailing zero noise from decimals', () {
      expect(formatCookingFlowDecimal(1.5), '1.5');
      expect(formatCookingFlowDecimal(1.25), '1.25');
    });
  });
}
