const String _defaultOffProductSearchUrl = 'https://api.yamt.de/search';
const String _offProductSearchUrl = String.fromEnvironment(
  'OFF_PRODUCT_SEARCH_URL',
  defaultValue: _defaultOffProductSearchUrl,
);
const int _offProductSearchTimeoutSeconds = int.fromEnvironment(
  'OFF_PRODUCT_SEARCH_TIMEOUT_SECONDS',
  defaultValue: 8,
);

/// Resolves the optional OFF product search endpoint from compile-time config.
Uri? resolveOffProductSearchUri() {
  final raw = _offProductSearchUrl.trim();
  if (raw.isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(raw);
  if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
    return null;
  }

  return uri;
}

/// Returns the configured timeout for OFF product search requests.
Duration offProductSearchTimeout() {
  const seconds = _offProductSearchTimeoutSeconds < 1
      ? 1
      : _offProductSearchTimeoutSeconds;
  return const Duration(seconds: seconds);
}
