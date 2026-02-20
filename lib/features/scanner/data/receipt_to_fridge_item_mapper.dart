import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';

part 'receipt_to_fridge_item_mapper.g.dart';

@riverpod
ReceiptToFridgeItemMapper receiptToFridgeItemMapper(Ref ref) {
  return const DefaultReceiptToFridgeItemMapper();
}

abstract interface class ReceiptToFridgeItemMapper {
  List<FridgeItem> map(ReceiptAnalysisExtraction extraction);
}

class DefaultReceiptToFridgeItemMapper implements ReceiptToFridgeItemMapper {
  const DefaultReceiptToFridgeItemMapper({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  @override
  List<FridgeItem> map(ReceiptAnalysisExtraction extraction) {
    final now = _now();
    final root = extraction.root;
    final rootStore = _firstNonBlankString(root['s'], root['storeName']);
    final rootLanguage = _firstNonBlankString(root['l'], root['language']);
    final rootReceiptDate = _parseDate(
      _firstNonBlankString(root['rd'], root['receiptDate']),
    );
    final receiptId = _buildReceiptId(now);

    return extraction.items.indexed
        .map((indexedItem) {
          final index = indexedItem.$1;
          final item = indexedItem.$2;
          final payload = item.rawPayload;
          final language = _firstNonBlankString(
            payload['l'],
            payload['language'],
            rootLanguage,
          );

          final name = _firstNonBlankString(
            payload['n'],
            payload['name'],
            item.name,
          );
          final storeName = _firstNonBlankString(
            payload['s'],
            payload['storeName'],
            rootStore,
          );

          final parsedQuantity = _parseNum(
            payload['q'] ?? payload['quantity'],
            language: language,
          );
          final quantity = parsedQuantity?.toInt() ?? 1;
          final safeQuantity = quantity > 0 ? quantity : 1;

          final totalPrice =
              _parseNum(
                payload['p'] ?? payload['totalPrice'] ?? payload['price'],
                language: language,
              ) ??
              0.0;
          final unitPrice = safeQuantity > 0 ? totalPrice / safeQuantity : 0.0;

          final isFood =
              _boolValue(payload['if']) ??
              _boolValue(payload['isFood']) ??
              true;
          final isDiscount =
              _boolValue(payload['id']) ??
              _boolValue(payload['isDiscount']) ??
              false;
          final weight = _firstNonBlankString(payload['w'], payload['weight']);

          return FridgeItem(
            id: _buildItemId(now, index),
            name: name ?? 'Unknown',
            entryDate: now,
            storeName: storeName ?? 'Unknown',
            quantity: safeQuantity,
            initialQuantity: safeQuantity,
            unitPrice: unitPrice,
            weight: weight,
            brand: _firstNonBlankString(payload['b'], payload['brand']),
            category: _firstNonBlankString(payload['c'], payload['category']),
            discounts: _parseDiscounts(
              payload['d'] ?? payload['discounts'],
              language,
            ),
            receiptId: receiptId,
            receiptDate:
                _parseDate(
                  _firstNonBlankString(payload['rd'], payload['receiptDate']),
                ) ??
                rootReceiptDate,
            language: language,
            isDeposit: !isFood,
            isDiscount: isDiscount,
          ).withDerivedAmount(weight: weight, quantity: safeQuantity);
        })
        .toList(growable: false);
  }
}

String _buildReceiptId(DateTime now) {
  return 'receipt-${now.microsecondsSinceEpoch}';
}

String _buildItemId(DateTime now, int index) {
  return 'receipt-item-${now.microsecondsSinceEpoch}-$index';
}

String? _stringValue(Object? value) {
  if (value is String) {
    return value;
  }
  return null;
}

bool? _boolValue(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    if (value == 1) {
      return true;
    }
    if (value == 0) {
      return false;
    }
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == '0') {
      return false;
    }
  }
  return null;
}

String? _firstNonBlankString(Object? first, [Object? second, Object? third]) {
  final values = <Object?>[first, second, third];
  for (final value in values) {
    final normalized = _stringValue(value)?.trim();
    if (normalized == null || normalized.isEmpty) {
      continue;
    }
    return normalized;
  }
  return null;
}

DateTime? _parseDate(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  return DateTime.tryParse(value.trim());
}

double? _parseNum(Object? value, {required String? language}) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is! String) {
    return null;
  }

  final normalized = value.trim();
  if (normalized.isEmpty) {
    return null;
  }

  final dotParsed = double.tryParse(normalized);
  if (dotParsed != null) {
    return dotParsed;
  }

  final commaToDot = double.tryParse(normalized.replaceAll(',', '.'));
  if (commaToDot != null) {
    return commaToDot;
  }

  try {
    return NumberFormat.decimalPattern(language).parse(normalized).toDouble();
  } catch (_) {
    return null;
  }
}

Map<String, double> _parseDiscounts(Object? value, String? language) {
  if (value == null) {
    return const <String, double>{};
  }

  if (value is Map<String, dynamic>) {
    final parsed = <String, double>{};
    for (final entry in value.entries) {
      final amount = _parseNum(entry.value, language: language);
      if (amount == null) {
        continue;
      }
      parsed[entry.key] = amount;
    }
    return parsed;
  }

  if (value is! List<dynamic>) {
    return const <String, double>{};
  }

  final parsed = <String, double>{};
  for (final raw in value) {
    if (raw is! Map<String, dynamic>) {
      continue;
    }

    final name = _stringValue(raw['n']) ?? _stringValue(raw['name']);
    final amount = _parseNum(raw['a'] ?? raw['amount'], language: language);
    if (name == null || name.trim().isEmpty || amount == null) {
      continue;
    }
    parsed[name.trim()] = amount;
  }

  return parsed;
}
