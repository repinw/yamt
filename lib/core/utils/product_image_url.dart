import 'package:yamt/core/data/storage_image_cache.dart';

const _offImageHost = 'world.openfoodfacts.org';

/// Normalizes product image URLs into absolute HTTPS URLs. A Firebase
/// Storage address stays as it is.
String? normalizeProductImageUrl(String? value) {
  if (value == null) {
    return null;
  }

  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  if (trimmed.startsWith('//')) {
    return 'https:$trimmed';
  }
  if (trimmed.startsWith('/')) {
    return 'https://$_offImageHost$trimmed';
  }
  if (trimmed.startsWith('http://') ||
      trimmed.startsWith('https://') ||
      isStorageImageAddress(trimmed)) {
    return trimmed;
  }
  return null;
}

/// Storage folder of the user's own food photos, such as a plate photo of
/// an AI food estimate. They stay private and never become a shared
/// product image.
const privateFoodPhotoFolder = 'food_photos';

/// Whether [url] points to one of the user's private food photos.
///
/// A Firebase Storage download address carries its path encoded, so the
/// folder shows up as `%2Ffood_photos%2F`.
bool isPrivateFoodPhotoUrl(String? url) {
  return url != null && url.contains('%2F$privateFoodPhotoFolder%2F');
}

/// [url] normalized for the shared catalog, or null for a private food
/// photo or a Storage address.
///
/// A Storage address can be saved before its upload finishes. If the
/// upload fails, the catalog would keep a broken image for every user, and
/// its image can be set only once. The catalog gets the photo only after
/// a successful upload (#414).
String? shareableProductImageUrl(String? url) {
  if (url == null ||
      isPrivateFoodPhotoUrl(url) ||
      isStorageImageAddress(url.trim())) {
    return null;
  }
  return normalizeProductImageUrl(url);
}
