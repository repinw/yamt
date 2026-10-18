import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/product_search_hub/domain/manual_product_photo_servings.dart';

void main() {
  group('front serving', () {
    test('takes the piece the AI read, named', () {
      expect(manualProductFrontServing(weight: 25, unit: 'g', name: 'Riegel'), (
        size: '1 Riegel (25 g)',
        quantity: 25.0,
        quantityUnit: 'g',
      ));
    });

    test('reads a multipack label without the AI fields', () {
      expect(manualProductFrontServing(quantityLabel: '6 x 25 g'), (
        size: null,
        quantity: 25.0,
        quantityUnit: 'g',
      ));
      expect(manualProductFrontServing(quantityLabel: '4×0,33 l'), (
        size: null,
        quantity: 330.0,
        quantityUnit: 'ml',
      ));
      expect(
        manualProductFrontServing(weight: 25),
        isNull,
        reason: 'a weight without a unit is no serving',
      );
      expect(manualProductFrontServing(quantityLabel: '500 g'), isNull);
    });
  });

  group('table serving', () {
    test('takes the heading the AI read', () {
      expect(
        manualProductTableServing(quantity: 30, unit: 'g', name: 'Portion'),
        (size: '1 Portion (30 g)', quantity: 30.0, quantityUnit: 'g'),
      );
    });

    test('reads the serving label without the AI fields', () {
      expect(manualProductTableServing(label: 'pro Riegel (25 g)'), (
        size: '1 Riegel (25 g)',
        quantity: 25.0,
        quantityUnit: 'g',
      ));
      expect(manualProductTableServing(label: '250 ml'), (
        size: null,
        quantity: 250.0,
        quantityUnit: 'ml',
      ));
      expect(manualProductTableServing(label: 'pro Riegel (12,5 g)'), (
        size: '1 Riegel (12.5 g)',
        quantity: 12.5,
        quantityUnit: 'g',
      ));
      expect(
        manualProductTableServing(quantity: 37.5, unit: 'g')?.quantity,
        37.5,
      );
      expect(manualProductTableServing(label: '1 Portion = 30 g'), (
        size: '1 Portion (30 g)',
        quantity: 30.0,
        quantityUnit: 'g',
      ));
      expect(
        manualProductTableServing(label: 'pro 100 g / Portion 30 g')?.quantity,
        30,
        reason: 'the per-100 column comes first',
      );
      expect(
        manualProductTableServing(label: 'pro Becher (100 g)')?.quantity,
        100,
        reason: 'a portion of 100 g in parentheses is a serving',
      );
      expect(manualProductTableServing(label: 'eine Portion'), isNull);
      expect(manualProductTableServing(label: 'pro 100 g'), isNull);
      expect(
        manualProductTableServing(label: '250 g Packung (pro 30 g)')?.quantity,
        30,
        reason: 'the amount in parentheses wins',
      );
      expect(
        manualProductTableServing(label: 'pro Riegel (25 g), 250 g')?.quantity,
        25,
      );
    });
  });

  test('the table wins until the user picks the front', () {
    const front = (size: '1 Riegel (25 g)', quantity: 25.0, quantityUnit: 'g');
    const table = (size: '1 Portion (30 g)', quantity: 30.0, quantityUnit: 'g');
    const servings = ManualProductPhotoServings(front: front, table: table);

    expect(servings.differ, isTrue);
    expect(servings.chosen, table);
    expect(servings.picking(front: true).chosen, front);
    expect(
      servings.withFront(null).chosen,
      table,
      reason: 'a new front photo without a piece drops the old one',
    );
    expect(
      const ManualProductPhotoServings(front: front).chosen,
      front,
      reason: 'a single read needs no choice',
    );
    expect(
      const ManualProductPhotoServings(front: front, table: front).differ,
      isFalse,
    );
    expect(servings.savedFor(countedInPieces: true), front);
    expect(servings.offersChoice(countedInPieces: true), isFalse);
    expect(servings.offersChoice(countedInPieces: false), isTrue);
  });

  test('the same amount with and without a name needs no choice', () {
    const named = (size: '1 Riegel (25 g)', quantity: 25.0, quantityUnit: 'g');
    const bare = (size: null, quantity: 25.0, quantityUnit: 'g');

    const servings = ManualProductPhotoServings(front: bare, table: named);
    expect(servings.differ, isFalse);
    expect(servings.chosen, named);
    expect(
      const ManualProductPhotoServings(front: named, table: bare).chosen,
      named,
    );
  });
}
