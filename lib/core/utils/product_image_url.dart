const _offImageHost = 'world.openfoodfacts.org';

/// Normalizes product image URLs into absolute HTTPS URLs.
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
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
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
/// photo.
String? shareableProductImageUrl(String? url) {
  return isPrivateFoodPhotoUrl(url) ? null : normalizeProductImageUrl(url);
}
