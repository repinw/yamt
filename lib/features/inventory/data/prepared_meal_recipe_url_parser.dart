import 'package:yamt/features/inventory/domain/wrapped_punctuation.dart';

/// Normalize prepared meal recipe url.
String? normalizePreparedMealRecipeUrl(String value) {
  final trimmedValue = value.trim();
  if (_hasUnsupportedExplicitScheme(trimmedValue)) {
    return null;
  }

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

bool _hasUnsupportedExplicitScheme(String value) {
  final schemeMatch = RegExp(
    r'^\s*([a-z][a-z0-9+\-.]*):\/\/',
    caseSensitive: false,
  ).firstMatch(value);
  if (schemeMatch == null) {
    return false;
  }

  final scheme = schemeMatch.group(1)?.toLowerCase();
  return scheme != null && scheme != 'http' && scheme != 'https';
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
  final normalizedCandidate = stripWrappedPunctuation(candidate.trim());
  return normalizedCandidate.isEmpty ? null : normalizedCandidate;
}

String _withoutQueryAndFragment(Uri uri) {
  final buffer = StringBuffer()
    ..write(uri.scheme)
    ..write('://')
    ..write(uri.authority)
    ..write(uri.path);
  return buffer.toString();
}
