String? normalizePreparedMealRecipeUrl(String value) {
  final candidate = _extractRecipeUrlCandidate(value);
  if (candidate == null) {
    return null;
  }

  final valueWithScheme = candidate.contains('://')
      ? candidate
      : 'https://$candidate';
  final uri = Uri.tryParse(valueWithScheme);
  if (uri == null || uri.host.isEmpty) {
    return null;
  }
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    return null;
  }
  if (!uri.host.contains('.')) {
    return null;
  }
  return _withoutQueryAndFragment(uri);
}

String? _extractRecipeUrlCandidate(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final httpsUrlMatch = RegExp(
    r'https?:\/\/[^\s]+',
    caseSensitive: false,
  ).firstMatch(trimmed);
  final candidate =
      httpsUrlMatch?.group(0) ??
      RegExp(
        r'((?:www\.)?[A-Za-z0-9.-]+\.[A-Za-z]{2,}(?:\/[^\s]*)?)',
        caseSensitive: false,
      ).firstMatch(trimmed)?.group(1) ??
      trimmed;
  final normalizedCandidate = _stripWrappedPunctuation(candidate.trim());
  return normalizedCandidate.isEmpty ? null : normalizedCandidate;
}

String _stripWrappedPunctuation(String value) {
  const leadingCharacters = '<([{"\'';
  const trailingCharacters = '>)]}\'",.!?;:';
  var start = 0;
  var end = value.length;

  while (start < end && leadingCharacters.contains(value[start])) {
    start += 1;
  }
  while (end > start && trailingCharacters.contains(value[end - 1])) {
    end -= 1;
  }

  return value.substring(start, end);
}

String _withoutQueryAndFragment(Uri uri) {
  final buffer = StringBuffer()
    ..write(uri.scheme)
    ..write('://')
    ..write(uri.authority)
    ..write(uri.path);
  return buffer.toString();
}
