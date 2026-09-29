import 'package:intl/intl.dart';

/// Parses and validates editable receipt item inputs from the review UI.
class ReceiptItemInputParser {
  /// The receipt item input parser.
  const new();

  /// Parses [quantityText] and [unitPriceText].
  ///
  /// Returns `null` when either value is invalid.
  ({int quantity, double unitPrice})? parseNumbers({
    required String quantityText,
    required String unitPriceText,
    required String locale,
  }) {
    final quantity = parseInt(quantityText, locale: locale);
    final unitPrice = parseDouble(unitPriceText, locale: locale);
    if (quantity == null || unitPrice == null) {
      return null;
    }
    return (quantity: quantity, unitPrice: unitPrice);
  }

  /// Parses a number and requires an integer result.
  int? parseInt(String value, {required String locale}) {
    final parsed = parseDouble(value, locale: locale);
    if (parsed == null || parsed.isNaN || parsed.isInfinite) {
      return null;
    }
    if (parsed % 1 != 0) {
      return null;
    }
    return parsed.toInt();
  }

  /// Parses a floating-point number in locale-aware and fallback formats.
  ///
  /// Supports grouped values like `1.000,50` and `1,000.50`.
  double? parseDouble(String value, {required String locale}) {
    final sanitized = _sanitizeNumber(value);
    if (sanitized.isEmpty) {
      return null;
    }

    final normalized = _normalizeSeparators(sanitized);
    if (normalized != null) {
      final parsed = double.tryParse(normalized);
      if (parsed != null) {
        return parsed;
      }
    }

    return _parseWithLocale(sanitized, locale);
  }

  /// Parses structured discount rows from the receipt editor.
  ///
  /// Empty rows are ignored. Rows with only one side filled are invalid.
  /// Positive amounts are normalized to negative values.
  Map<String, double>? parseDiscountEntries(
    List<MapEntry<String, String>> entries, {
    required String locale,
  }) {
    final parsed = <String, double>{};
    for (final entry in entries) {
      final key = entry.key.trim();
      final amountText = entry.value.trim();
      if (key.isEmpty && amountText.isEmpty) {
        continue;
      }
      if (key.isEmpty || amountText.isEmpty) {
        return null;
      }

      final amount = parseDouble(amountText, locale: locale);
      if (amount == null) {
        return null;
      }
      parsed[key] = amount > 0 ? -amount : amount;
    }
    return parsed;
  }

  double? _parseWithLocale(String value, String locale) {
    final normalizedLocale = locale.replaceAll('-', '_');
    try {
      final parsed = NumberFormat.decimalPattern(normalizedLocale).parse(value);
      return parsed.toDouble();
    } on Object catch (_) {
      return null;
    }
  }

  String _sanitizeNumber(String value) {
    return value
        .trim()
        .replaceAll('\u00A0', '')
        .replaceAll('\u202F', '')
        .replaceAll(' ', '')
        .replaceAll("'", '');
  }

  String? _normalizeSeparators(String value) {
    final hasComma = value.contains(',');
    final hasDot = value.contains('.');

    if (hasComma && hasDot) {
      return _normalizeMixedSeparators(value);
    }

    if (hasComma) {
      return _normalizeSingleSeparator(
        value,
        separator: ',',
        groupedPattern: RegExp(r'^-?\d{1,3}(,\d{3})+$'),
      );
    }

    if (hasDot) {
      return _normalizeSingleSeparator(
        value,
        separator: '.',
        groupedPattern: RegExp(r'^-?\d{1,3}(\.\d{3})+$'),
      );
    }

    return value;
  }

  String _normalizeMixedSeparators(String value) {
    final lastComma = value.lastIndexOf(',');
    final lastDot = value.lastIndexOf('.');
    final decimalSeparator = lastComma > lastDot ? ',' : '.';
    final groupSeparator = decimalSeparator == ',' ? '.' : ',';

    return value
        .replaceAll(groupSeparator, '')
        .replaceFirst(decimalSeparator, '.');
  }

  String _normalizeSingleSeparator(
    String value, {
    required String separator,
    required RegExp groupedPattern,
  }) {
    if (groupedPattern.hasMatch(value)) {
      return value.replaceAll(separator, '');
    }
    if (separator == ',') {
      return value.replaceAll(',', '.');
    }
    return value;
  }
}
