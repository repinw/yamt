import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/utils/product_image_url.dart';

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

  test('keeps Firebase Storage addresses unchanged', () {
    expect(
      normalizeProductImageUrl('gs://bucket/product_images/u/1/front.jpg'),
      'gs://bucket/product_images/u/1/front.jpg',
    );
  });

  test('drops unsupported image urls', () {
    expect(normalizeProductImageUrl('ftp://example.com/image.png'), isNull);
    expect(normalizeProductImageUrl('image.png'), isNull);
  });

  test('knows a private food photo by its download URL and its address', () {
    expect(
      isPrivateFoodPhotoUrl(
        'https://firebasestorage.googleapis.com/v0/b/bucket/o/'
        'users%2Fu%2Ffood_photos%2Fx.jpg?alt=media',
      ),
      isTrue,
    );
    expect(
      isPrivateFoodPhotoUrl('gs://bucket/users/u/food_photos/x.jpg'),
      isTrue,
    );
    expect(
      isPrivateFoodPhotoUrl('gs://bucket/product_images/u/1/front.jpg'),
      isFalse,
    );
  });

  test('keeps Storage addresses out of the shared catalog', () {
    expect(
      shareableProductImageUrl('gs://bucket/product_images/u/1/front.jpg'),
      isNull,
    );
    expect(
      shareableProductImageUrl('https://example.com/image.png'),
      'https://example.com/image.png',
    );
  });
}
