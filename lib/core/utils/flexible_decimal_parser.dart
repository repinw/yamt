/// Parses decimal numbers with common German and English separators.
double? parseFlexibleDecimal(String value) {
  var compact = value.replaceAll(RegExp(r'\s+'), '');
  final hasLeadingDecimalSeparator =
      compact.startsWith('.') || compact.startsWith(',');
  if (hasLeadingDecimalSeparator) {
    compact = '0$compact';
  }
  if (compact.isEmpty || !RegExp(r'^\d+(?:[.,]\d+)*$').hasMatch(compact)) {
    return null;
  }

  final lastComma = compact.lastIndexOf(',');
  final lastDot = compact.lastIndexOf('.');
  if (lastComma >= 0 && lastDot >= 0) {
    final decimalSeparator = lastComma > lastDot ? ',' : '.';
    final groupingSeparator = decimalSeparator == ',' ? '.' : ',';
    final decimalIndex = compact.lastIndexOf(decimalSeparator);
    final integerPart = compact.substring(0, decimalIndex);
    final decimalPart = compact.substring(decimalIndex + 1);
    if (decimalPart.isEmpty ||
        !_hasValidGrouping(integerPart, groupingSeparator)) {
      return null;
    }
    return double.tryParse(
      '${integerPart.replaceAll(groupingSeparator, '')}.$decimalPart',
    );
  }

  if (lastComma >= 0) {
    return _parseSingleSeparatorNumber(
      compact,
      ',',
      forceDecimal: hasLeadingDecimalSeparator,
    );
  }

  if (lastDot >= 0) {
    return _parseSingleSeparatorNumber(
      compact,
      '.',
      forceDecimal: hasLeadingDecimalSeparator,
    );
  }

  return double.tryParse(compact);
}

double? _parseSingleSeparatorNumber(
  String value,
  String separator, {
  required bool forceDecimal,
}) {
  final matches = separator.allMatches(value).length;
  if (matches > 1) {
    if (!_hasValidGrouping(value, separator)) {
      return null;
    }
    return double.tryParse(value.replaceAll(separator, ''));
  }

  final separatorIndex = value.indexOf(separator);
  final integerPart = value.substring(0, separatorIndex);
  final fractionalPart = value.substring(separatorIndex + 1);
  if (!forceDecimal && fractionalPart.length == 3 && integerPart.length <= 3) {
    return double.tryParse(value.replaceAll(separator, ''));
  }
  return double.tryParse(value.replaceAll(separator, '.'));
}

bool _hasValidGrouping(String value, String separator) {
  final groups = value.split(separator);
  if (groups.length < 2 || groups.first.isEmpty || groups.first.length > 3) {
    return false;
  }
  return groups.skip(1).every((group) => group.length == 3);
}
