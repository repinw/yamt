/// Compute food fingerprint.
String computeFoodFingerprint({required String name, String? brand}) {
  final normalizedName = _normalizeToken(name);
  final normalizedBrand = _normalizeToken(brand ?? '');
  final segments = <String>[
    if (normalizedName.isNotEmpty) normalizedName,
    if (normalizedBrand.isNotEmpty) normalizedBrand,
  ];
  if (segments.isEmpty) {
    return 'unknown_food';
  }
  return segments.join('__');
}

String _normalizeToken(String raw) {
  final lower = raw.trim().toLowerCase();
  if (lower.isEmpty) {
    return '';
  }
  final normalized = lower
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return normalized;
}
