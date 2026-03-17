import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/product_image_url.dart';

void main() {
  test('normalizes OFF protocol-relative image URLs', () {
    expect(
      normalizeProductImageUrl('//images.openfoodfacts.org/test.png'),
      'https://images.openfoodfacts.org/test.png',
    );
  });

  test('normalizes OFF root-relative image URLs', () {
    expect(
      normalizeProductImageUrl('/images/products/test.png'),
      'https://world.openfoodfacts.org/images/products/test.png',
    );
  });

  test('keeps absolute http urls unchanged', () {
    expect(
      normalizeProductImageUrl('https://example.com/image.png'),
      'https://example.com/image.png',
    );
  });

  test('drops unsupported image urls', () {
    expect(normalizeProductImageUrl('ftp://example.com/image.png'), isNull);
    expect(normalizeProductImageUrl('image.png'), isNull);
  });
}
