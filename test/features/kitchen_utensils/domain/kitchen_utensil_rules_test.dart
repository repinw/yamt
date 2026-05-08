import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil_rules.dart';

KitchenUtensil _utensil({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
}) {
  return KitchenUtensil(
    id: id,
    name: id,
    weightGrams: 100,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

void main() {
  test('normalizes optional names', () {
    expect(normalizeKitchenUtensilName(' Pot '), 'Pot');
    expect(normalizeKitchenUtensilName('   '), isNull);
  });

  test('validates weight and name or image identity', () {
    expect(
      isValidKitchenUtensilInput(
        name: null,
        imageBytes: null,
        imageStoragePath: null,
        weightGrams: 100,
      ),
      isFalse,
    );
    expect(
      isValidKitchenUtensilInput(
        name: 'Pot',
        imageBytes: null,
        imageStoragePath: null,
        weightGrams: 0,
      ),
      isFalse,
    );
    expect(
      isValidKitchenUtensilInput(
        name: null,
        imageBytes: Uint8List(1),
        imageStoragePath: null,
        weightGrams: 100,
      ),
      isTrue,
    );
    expect(
      isValidKitchenUtensilInput(
        name: null,
        imageBytes: null,
        imageStoragePath: 'users/owner/kitchen_utensils/pot/images/1.jpg',
        weightGrams: 100,
      ),
      isTrue,
    );
  });

  test('sorts by updated date then created date descending', () {
    final old = _utensil(
      id: 'old',
      createdAt: DateTime.parse('2026-04-01T09:00:00Z'),
      updatedAt: DateTime.parse('2026-04-01T11:00:00Z'),
    );
    final newerCreated = _utensil(
      id: 'newer-created',
      createdAt: DateTime.parse('2026-04-01T10:00:00Z'),
      updatedAt: DateTime.parse('2026-04-01T11:00:00Z'),
    );
    final newerUpdated = _utensil(
      id: 'newer-updated',
      createdAt: DateTime.parse('2026-04-01T09:00:00Z'),
      updatedAt: DateTime.parse('2026-04-01T12:00:00Z'),
    );

    final sorted = sortKitchenUtensils([old, newerCreated, newerUpdated]);

    expect(
      sorted.map((utensil) => utensil.id),
      ['newer-updated', 'newer-created', 'old'],
    );
  });
}
