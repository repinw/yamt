import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/food_fingerprint.dart';

void main() {
  test('computeFoodFingerprint normalizes name and brand', () {
    final fingerprint = computeFoodFingerprint(
      name: '  Bio-Milk 3.5% ',
      brand: ' ACME Foods ',
    );

    expect(fingerprint, 'bio_milk_3_5__acme_foods');
  });

  test('computeFoodFingerprint uses unknown fallback when empty', () {
    final fingerprint = computeFoodFingerprint(name: '  ');

    expect(fingerprint, 'unknown_food');
  });
}
