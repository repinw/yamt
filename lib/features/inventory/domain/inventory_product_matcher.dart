/// Matches inventory names that describe the same replenishable product.
abstract final class InventoryProductMatcher {
  static const _minimumSingleTokenLength = 7;

  /// Whether two names are equal or one is a qualified variant of the other.
  static bool matches(String left, String right) {
    final leftTokens = _tokens(left);
    final rightTokens = _tokens(right);
    if (leftTokens.isEmpty || rightTokens.isEmpty) return false;
    if (_sameTokens(leftTokens, rightTokens)) return true;

    final shorter = leftTokens.length <= rightTokens.length
        ? leftTokens
        : rightTokens;
    final longer = identical(shorter, leftTokens) ? rightTokens : leftTokens;
    return _isSpecific(shorter) && shorter.every(longer.contains);
  }

  static List<String> _tokens(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll('ß', 'ss')
      .replaceAll('ä', 'ae')
      .replaceAll('ö', 'oe')
      .replaceAll('ü', 'ue')
      .split(RegExp('[^a-z0-9]+'))
      .where((token) => token.isNotEmpty)
      .toSet()
      .toList(growable: false);

  static bool _sameTokens(List<String> left, List<String> right) =>
      left.length == right.length && left.every(right.contains);

  static bool _isSpecific(List<String> tokens) =>
      tokens.length > 1 || tokens.single.length >= _minimumSingleTokenLength;
}
