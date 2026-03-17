import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';

void main() {
  test('create normalizes fields for matching and storage', () {
    final now = DateTime.parse('2026-03-01T10:00:00Z');
    final item = GlobalFoodItem.create(
      id: 'milk',
      name: '  Whole Milk  ',
      brand: ' Acme ',
      category: ' Dairy ',
      barcode: ' 123456 ',
      now: now,
    );

    expect(item.name, 'Whole Milk');
    expect(item.brand, 'Acme');
    expect(item.category, 'Dairy');
    expect(item.barcode, '123456');
    expect(item.normalizedName, 'whole milk');
    expect(item.normalizedBrand, 'acme');
    expect(item.searchTokens, containsAll(<String>['whole', 'milk']));
    expect(item.foodFingerprint, isNotEmpty);
  });

  test('fromJson derives missing normalized fields and fingerprint', () {
    final item = GlobalFoodItem.fromJson(<String, dynamic>{
      'id': 'milk',
      'name': 'Whole Milk',
      'brand': 'Acme',
      'status': 'active',
      'created_at': '2026-03-01T10:00:00.000Z',
      'updated_at': '2026-03-01T10:00:00.000Z',
    });

    expect(item.id, 'milk');
    expect(item.foodFingerprint, isNotEmpty);
    expect(item.normalizedName, 'whole milk');
    expect(item.normalizedBrand, 'acme');
    expect(item.searchTokens, isEmpty);
  });
}
