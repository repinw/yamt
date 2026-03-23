import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/utils/store_name_normalizer.dart';

void main() {
  test('normalizes Aldi variants to a canonical store name', () {
    const variants = <String>[
      'Aldi',
      'ALDI',
      'Aldi Süd',
      'ALDI SÜD',
      'Aldi Sued',
      'ALDI SUED',
      'Aldi-Nord',
      'ALDI NORD',
      'aldi markt',
      'aldi süd filial 123',
      'a l d i',
    ];

    for (final variant in variants) {
      expect(normalizeStoreName(variant), 'Aldi');
    }
  });

  test('normalizes Netto variants to a canonical store name', () {
    const variants = <String>[
      'Netto',
      'NETTO',
      'Netto Marken-Discount',
      'NETTO MARKEN DISCOUNT',
      'Netto-Markendiscount',
      'Netto Marken Discount',
      'netto filial 123',
      'n e t t o',
    ];

    for (final variant in variants) {
      expect(normalizeStoreName(variant), 'Netto');
    }
  });

  test('keeps unknown stores readable', () {
    expect(normalizeStoreName(' Kaufland  '), 'Kaufland');
    expect(normalizeStoreName('My Store'), 'My Store');
  });

  test('returns null for blank values', () {
    expect(normalizeStoreName(null), isNull);
    expect(normalizeStoreName('   '), isNull);
  });
}
