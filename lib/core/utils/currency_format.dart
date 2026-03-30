import 'package:intl/intl.dart';

const String appDefaultCurrencyCode = 'EUR';

const Map<String, String> _currencySymbolCodes = <String, String>{
  '€': 'EUR',
  '\$': 'USD',
  '£': 'GBP',
  '¥': 'JPY',
  '￥': 'JPY',
};

/// Normalizes a currency identifier into an ISO-like uppercase code.
String? normalizeCurrencyCode(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }

  final symbolCode = _currencySymbolCodes[trimmed];
  if (symbolCode != null) {
    return symbolCode;
  }

  final upper = trimmed.toUpperCase();
  final isAlphaCode = RegExp(r'^[A-Z]{3}$').hasMatch(upper);
  if (isAlphaCode) {
    return upper;
  }

  return null;
}

/// Returns the shared currency code when all non-empty entries agree.
String? resolveSharedCurrencyCode(Iterable<String?> currencyCodes) {
  String? sharedCode;

  for (final value in currencyCodes) {
    final normalized = normalizeCurrencyCode(value);
    if (normalized == null) {
      continue;
    }
    if (sharedCode == null) {
      sharedCode = normalized;
      continue;
    }
    if (sharedCode != normalized) {
      return null;
    }
  }

  return sharedCode;
}

/// Builds a localized formatter that prefers the parsed receipt currency.
NumberFormat buildCurrencyFormat({
  required String locale,
  String? currencyCode,
}) {
  final resolvedCode =
      normalizeCurrencyCode(currencyCode) ?? appDefaultCurrencyCode;
  return NumberFormat.simpleCurrency(locale: locale, name: resolvedCode);
}
