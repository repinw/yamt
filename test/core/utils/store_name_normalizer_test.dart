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
    expect(normalizeStoreName('My Store'), 'My Store');
  });

  test('normalizes common receipt store variants for product search', () {
    const variants = <String, String>{
      'REWE Markt GmbH': 'Rewe',
      'Lidl Dienstleistung GmbH': 'Lidl',
      'EDEKA Center': 'Edeka',
      'Kaufland Filiale 123': 'Kaufland',
      'PENNY Markt': 'Penny',
      'NORMA Lebensmittelfilialbetrieb': 'Norma',
      'dm-drogerie markt': 'dm',
      'Dirk Rossmann GmbH': 'Rossmann',
      'Globus Markthalle': 'Globus',
      'HIT Handelsgruppe': 'HIT',
      'tegut... gute Lebensmittel': 'tegut',
      'Marktkauf Bielefeld': 'Marktkauf',
      'Alnatura Super Natur Markt': 'Alnatura',
      'METRO Deutschland': 'Metro',
    };

    for (final MapEntry(key: variant, value: expected) in variants.entries) {
      expect(normalizeStoreName(variant), expected, reason: variant);
    }
  });

  test('returns null for blank values', () {
    expect(normalizeStoreName(null), isNull);
    expect(normalizeStoreName('   '), isNull);
  });
}
