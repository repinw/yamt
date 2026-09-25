import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/eat_amount_step.dart';

void main() {
  test('small stocks move in single units', () {
    expect(eatAmountStep(3), 1);
    expect(eatAmountStep(60), 1);
  });

  test('larger stocks move in round steps of at most 60 stops', () {
    expect(eatAmountStep(180), 5);
    expect(eatAmountStep(500), 10);
    expect(eatAmountStep(1000), 25);
  });

  test('huge stocks use the largest step', () {
    expect(eatAmountStep(1000000), 1000);
  });
}
