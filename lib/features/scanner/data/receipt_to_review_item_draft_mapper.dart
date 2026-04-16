import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/utils/currency_format.dart';
import 'package:yamt/core/utils/store_name_normalizer.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';
import 'package:yamt/features/scanner/domain/'
    'receipt_item_quantity_normalizer.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';

part 'receipt_to_review_item_draft_mapper.g.dart';

const _nameNumberTokenPattern = r'(?:\d+(?:[.,]\d+)?|[.,]\d+)';

final _namePackWithUnitPattern = RegExp(
  '(?:^|\\b)(\\d{1,3})\\s*[x\\u00D7]\\s*($_nameNumberTokenPattern)\\s*'
  '(kg|g|mg|ml|cl|dl|l)\\b',
  caseSensitive: false,
);
final _nameValueWithUnitPattern = RegExp(
  '(?:^|\\b)($_nameNumberTokenPattern)\\s*(kg|g|mg|ml|cl|dl|l)\\b',
  caseSensitive: false,
);
final _namePiecePattern = RegExp(
  r'(?:^|\b)(\d{1,3})\s*(stk|st\.?|stueck|stück|pc|pcs|piece|pieces)\b',
  caseSensitive: false,
);

/// Receipt to review item draft mapper.
@riverpod
ReceiptToReviewItemDraftMapper receiptToReviewItemDraftMapper(Ref ref) {
  return const DefaultReceiptToReviewItemDraftMapper();
}

/// Defines receipt to review item draft mapper.
abstract interface class ReceiptToReviewItemDraftMapper {
  /// Map.
  List<ReceiptReviewItemDraft> map(ReceiptAnalysisExtraction extraction);
}

/// Defines default receipt to review item draft mapper.
class DefaultReceiptToReviewItemDraftMapper
    implements ReceiptToReviewItemDraftMapper {
  /// The default receipt to review item draft mapper.
  const DefaultReceiptToReviewItemDraftMapper({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  @override
  List<ReceiptReviewItemDraft> map(ReceiptAnalysisExtraction extraction) {
    final now = _now();
    final root = extraction.root;
    final rootStore = normalizeStoreName(
      _firstNonBlankString(root['s'], root['storeName']),
    );
    final rootLanguage = _firstNonBlankString(root['l'], root['language']);
    final rootReceiptDate = _parseDate(
      _firstNonBlankString(root['rd'], root['receiptDate']),
    );
    final rootReceiptTime = _firstNonBlankString(root['t'], root['time']);
    final rootCurrencyCode = _readCurrencyCode(root);
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
          final storeName = normalizeStoreName(
            _firstNonBlankString(payload['s'], payload['storeName'], rootStore),
          );

          final quantityAndWeight = _resolveQuantityAndWeight(
            payload: payload,
            itemName: name,
            language: language,
          );
          final isFood =
              _boolValue(payload['if']) ??
              _boolValue(payload['isFood']) ??
              true;
          final isDiscount =
              _boolValue(payload['id']) ??
              _boolValue(payload['isDiscount']) ??
              false;
          final safeQuantities = normalizeReceiptItemQuantities(
            quantity: quantityAndWeight.quantity,
            canBeSavedToInventory: isFood && !isDiscount,
          );
          final safeQuantity = safeQuantities.quantity;
          final totalPrice =
              _parseNum(
                payload['p'] ?? payload['totalPrice'] ?? payload['price'],
                language: language,
              ) ??
              0.0;
          final unitPrice = safeQuantity > 0 ? totalPrice / safeQuantity : 0.0;
          final weight = quantityAndWeight.weight;
          final currencyCode = _readCurrencyCode(payload) ?? rootCurrencyCode;

          final inventoryItem = InventoryItem.create(
            id: _buildItemId(now, index),
            name: name ?? 'Unknown',
            entryDate: now,
            storeName: storeName ?? 'Unknown',
            quantity: safeQuantity,
            initialQuantity: safeQuantities.initialQuantity,
            unitPrice: unitPrice,
            currencyCode: currencyCode,
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
            ocrName: name,
            isDeposit: !isFood,
            isDiscount: isDiscount,
          ).withDerivedAmount(weight: weight, quantity: safeQuantity);
          return ReceiptReviewItemDraft(
            item: inventoryItem,
            ocrName: name,
            receiptTimeText: _firstNonBlankString(
              payload['t'],
              payload['time'],
              rootReceiptTime,
            ),
          );
        })
        .toList(growable: false);
  }
}

String? _readCurrencyCode(Map<String, dynamic> payload) {
  return normalizeCurrencyCode(
    _firstNonBlankString(
          payload['cur'],
          payload['currency'],
          payload['currencyCode'],
        ) ??
        _firstNonBlankString(payload['currency_code']),
  );
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

({int quantity, String? weight}) _resolveQuantityAndWeight({
  required Map<String, dynamic> payload,
  required String? itemName,
  required String? language,
}) {
  final parsedQuantity = _parseNum(
    payload['q'] ?? payload['quantity'],
    language: language,
  );
  final parsedWeight = _firstNonBlankString(payload['w'], payload['weight']);

  final inferred = _inferQuantityAndWeightFromName(itemName);
  final quantity = parsedQuantity?.round() ?? inferred.quantity ?? 1;
  final safeQuantity = quantity < 0 ? 0 : quantity;

  return (quantity: safeQuantity, weight: parsedWeight ?? inferred.weight);
}

({int? quantity, String? weight}) _inferQuantityAndWeightFromName(
  String? itemName,
) {
  final normalizedName = itemName?.trim();
  if (normalizedName == null || normalizedName.isEmpty) {
    return (quantity: null, weight: null);
  }

  final packWithUnit = _namePackWithUnitPattern.firstMatch(normalizedName);
  if (packWithUnit != null) {
    return (
      quantity: int.tryParse(packWithUnit.group(1)!),
      weight: '${packWithUnit.group(2)}${packWithUnit.group(3)}',
    );
  }

  final pieceMatch = _namePiecePattern.firstMatch(normalizedName);
  if (pieceMatch != null) {
    return (quantity: int.tryParse(pieceMatch.group(1)!), weight: null);
  }

  final valueWithUnit = _nameValueWithUnitPattern.firstMatch(normalizedName);
  if (valueWithUnit != null) {
    return (
      quantity: 1,
      weight: '${valueWithUnit.group(1)}${valueWithUnit.group(2)}',
    );
  }

  return (quantity: null, weight: null);
}
