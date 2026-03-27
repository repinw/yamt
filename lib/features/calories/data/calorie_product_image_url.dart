const _offImageHost = 'world.openfoodfacts.org';

/// Normalizes calorie product image URLs into absolute http(s) URLs.
String? normalizeCalorieProductImageUrl(String? value) {
  final raw = value?.trim();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  if (raw.startsWith('https://') || raw.startsWith('http://')) {
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
