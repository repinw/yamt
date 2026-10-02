import 'package:yamt/core/data/storage_image_cache.dart';

const _offImageHost = 'world.openfoodfacts.org';

/// Normalizes calorie product image URLs into absolute http(s) URLs. A
/// Firebase Storage address stays as it is.
String? normalizeCalorieProductImageUrl(String? value) {
  final raw = value?.trim();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  if (raw.startsWith('https://') ||
      raw.startsWith('http://') ||
      isStorageImageAddress(raw)) {
    return raw;
  }
  if (raw.startsWith('//')) {
    return 'https:$raw';
  }
  if (raw.startsWith('/')) {
    return 'https://$_offImageHost$raw';
  }
  return null;
}
