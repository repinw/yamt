const _offImageHost = 'world.openfoodfacts.org';

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
