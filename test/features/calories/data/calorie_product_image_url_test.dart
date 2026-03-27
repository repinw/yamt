import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_product_image_url.dart';

void main() {
  test('returns null for null, empty, and unsupported values', () {
    expect(normalizeCalorieProductImageUrl(null), isNull);
    expect(normalizeCalorieProductImageUrl(''), isNull);
    expect(normalizeCalorieProductImageUrl('   '), isNull);
    expect(normalizeCalorieProductImageUrl('not-a-url'), isNull);
  });

  test('keeps absolute http and https URLs unchanged', () {
    expect(
      normalizeCalorieProductImageUrl('https://images.example.com/item.jpg'),
      'https://images.example.com/item.jpg',
    );
    expect(
      normalizeCalorieProductImageUrl('http://images.example.com/item.jpg'),
      'http://images.example.com/item.jpg',
    );
  });

  test('normalizes protocol-relative URLs to https', () {
    expect(
      normalizeCalorieProductImageUrl('//images.example.com/item.jpg'),
      'https://images.example.com/item.jpg',
    );
  });

  test('normalizes root-relative OFF URLs to absolute https URLs', () {
    expect(
      normalizeCalorieProductImageUrl('/images/products/123/front.jpg'),
      'https://world.openfoodfacts.org/images/products/123/front.jpg',
    );
  });
}
