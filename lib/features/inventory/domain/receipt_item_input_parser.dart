import 'dart:convert';

import 'package:intl/intl.dart';

/// Parses and validates editable receipt item inputs from the review UI.
class ReceiptItemInputParser {
  /// The receipt item input parser.
  const ReceiptItemInputParser();

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

  /// Parses discounts from JSON (`{"x": 1.2}`) or key/value pairs.
  ///
  /// Supported pair separators are `=` and `:`.
  Map<String, double>? parseDiscounts(String raw, {required String locale}) {
    final normalized = raw.trim();
    if (normalized.isEmpty) {
      return const <String, double>{};
    }

    final fromJson = _parseDiscountsFromJson(normalized, locale: locale);
    if (fromJson != null) {
      return fromJson;
    }

    return _parseDiscountsFromPairs(normalized, locale: locale);
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

  Map<String, double>? _parseDiscountsFromJson(
    String raw, {
    required String locale,
  }) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final parsed = <String, double>{};
      for (final entry in decoded.entries) {
        final value = entry.value;
        final amount = switch (value) {
          num() => value.toDouble(),
          String() => parseDouble(value, locale: locale),
          _ => null,
        };
        if (amount == null) {
          return null;
        }
        parsed[entry.key] = amount;
      }
      return parsed;
    } on Object catch (_) {
      return null;
    }
  }

  Map<String, double>? _parseDiscountsFromPairs(
    String raw, {
    required String locale,
  }) {
    final entries = _splitPairEntries(raw);
    final parsed = <String, double>{};

    for (final entry in entries) {
      final pair = _splitPair(entry);
      if (pair == null) {
        return null;
      }

      final amount = parseDouble(pair.$2, locale: locale);
      if (amount == null) {
        return null;
      }
      parsed[pair.$1] = amount;
    }

    return parsed;
  }

  List<String> _splitPairEntries(String raw) {
    final normalized = raw.replaceAll('\n', ',').replaceAll(';', ',');
    final parts = normalized.split(RegExp(r',(?=\s*[^,=:]+\s*[:=])'));
    return parts
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
  }

  (String, String)? _splitPair(String entry) {
    final equals = entry.indexOf('=');
    final colon = entry.indexOf(':');
    final separatorIndex = _firstValidSeparatorIndex(equals, colon);
    if (separatorIndex < 0) {
      return null;
    }

    final key = entry.substring(0, separatorIndex).trim();
    final value = entry.substring(separatorIndex + 1).trim();
    if (key.isEmpty || value.isEmpty) {
      return null;
    }
    return (key, value);
  }

  int _firstValidSeparatorIndex(int equals, int colon) {
    if (equals < 0 && colon < 0) {
      return -1;
    }
    if (equals < 0) {
      return colon;
    }
    if (colon < 0) {
      return equals;
    }
    return equals < colon ? equals : colon;
  }
}
