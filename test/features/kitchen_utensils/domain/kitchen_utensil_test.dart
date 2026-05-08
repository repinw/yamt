import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';

void main() {
  test('fromJson trims optional fields and parses weight', () {
    final utensil = KitchenUtensil.fromJson(const {
      'id': ' pot-1 ',
      'name': ' Cooking pot ',
      'image_storage_path': ' users/u/kitchen_utensils/p/images/a.jpg ',
      'weight_grams': '420',
      'created_at': '2026-04-01T10:00:00.000Z',
      'updated_at': '2026-04-01T11:00:00.000Z',
    });

    expect(utensil.id, 'pot-1');
    expect(utensil.name, 'Cooking pot');
    expect(
      utensil.imageStoragePath,
      'users/u/kitchen_utensils/p/images/a.jpg',
    );
    expect(utensil.weightGrams, 420);
    expect(utensil.hasIdentity, isTrue);
  });

  test('toJson writes snake case fields', () {
    final utensil = KitchenUtensil(
      id: 'pot-1',
      name: 'Cooking pot',
      imageStoragePath: 'users/u/kitchen_utensils/p/images/a.jpg',
      weightGrams: 420,
      createdAt: DateTime.parse('2026-04-01T10:00:00.000Z'),
      updatedAt: DateTime.parse('2026-04-01T11:00:00.000Z'),
    );

    expect(utensil.toJson(), {
      'id': 'pot-1',
      'name': 'Cooking pot',
      'image_storage_path': 'users/u/kitchen_utensils/p/images/a.jpg',
      'weight_grams': 420,
      'created_at': '2026-04-01T10:00:00.000Z',
      'updated_at': '2026-04-01T11:00:00.000Z',
    });
  });

  test('fromJson rejects missing identity and invalid weight', () {
    expect(
      () => KitchenUtensil.fromJson(const {
        'id': 'pot-1',
        'weight_grams': 0,
        'created_at': '2026-04-01T10:00:00.000Z',
        'updated_at': '2026-04-01T11:00:00.000Z',
      }),
      throwsFormatException,
    );
  });
}
