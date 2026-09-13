/// Normalizes noisy store names into stable display values.
String? normalizeStoreName(String? rawValue) {
  final collapsed = _collapseWhitespace(rawValue);
  if (collapsed == null) {
    return null;
  }

  final normalizedKey = _normalizeStoreKey(collapsed);
  if (_isAldiVariant(normalizedKey)) {
    return 'Aldi';
  }
  if (_isNettoVariant(normalizedKey)) {
    return 'Netto';
  }
  final canonicalStoreName = _canonicalStoreNameForToken(normalizedKey);
  if (canonicalStoreName != null) {
    return canonicalStoreName;
  }

  return collapsed;
}

const _canonicalStoreNamesByToken = <String, String>{
  'rewe': 'Rewe',
  'lidl': 'Lidl',
  'edeka': 'Edeka',
  'kaufland': 'Kaufland',
  'penny': 'Penny',
  'norma': 'Norma',
  'dm': 'dm',
  'rossmann': 'Rossmann',
  'globus': 'Globus',
  'hit': 'HIT',
  'tegut': 'tegut',
  'marktkauf': 'Marktkauf',
  'alnatura': 'Alnatura',
  'metro': 'Metro',
};

String? _canonicalStoreNameForToken(String normalizedKey) {
  final tokens = normalizedKey.split(' ');
  for (final token in tokens) {
    final canonicalName = _canonicalStoreNamesByToken[token];
    if (canonicalName != null) {
      return canonicalName;
    }
  }
  return null;
}

bool _isAldiVariant(String normalizedKey) {
  if (normalizedKey.isEmpty) {
    return false;
  }

  final compact = normalizedKey.replaceAll(' ', '');
  return normalizedKey.split(' ').contains('aldi') ||
      compact == 'aldi' ||
      compact.startsWith('aldi');
}

bool _isNettoVariant(String normalizedKey) {
  if (normalizedKey.isEmpty) {
    return false;
  }

  final compact = normalizedKey.replaceAll(' ', '');
  return normalizedKey.split(' ').contains('netto') ||
      compact == 'netto' ||
      compact.startsWith('netto');
}

String? _collapseWhitespace(String? rawValue) {
  final trimmed = rawValue?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }

  return trimmed.replaceAll(RegExp(r'\s+'), ' ');
}

String _normalizeStoreKey(String value) {
  final lower = value.trim().toLowerCase();
  if (lower.isEmpty) {
    return '';
  }

  return lower
      .replaceAll('ä', 'ae')
      .replaceAll('ö', 'oe')
      .replaceAll('ü', 'ue')
      .replaceAll('ß', 'ss')
      .replaceAll(RegExp('[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
