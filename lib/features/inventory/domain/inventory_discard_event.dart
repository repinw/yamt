import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/l10n/app_localizations.dart';

enum InventoryDiscardReason {
  expired,
  spoiled,
  cookedTooMuch,
  other;

  String localizedLabel(AppLocalizations l10n) {
    return switch (this) {
      InventoryDiscardReason.expired => l10n.inventoryDiscardReasonExpired,
      InventoryDiscardReason.spoiled => l10n.inventoryDiscardReasonSpoiled,
      InventoryDiscardReason.cookedTooMuch =>
        l10n.inventoryDiscardReasonCookedTooMuch,
      InventoryDiscardReason.other => l10n.inventoryDiscardReasonOther,
    };
  }
}

enum InventoryDiscardSourceType { inventoryItem, preparedMeal }

class InventoryDiscardEvent {
  const InventoryDiscardEvent({
    required this.id,
    required this.sourceType,
    required this.sourceId,
    required this.name,
    required this.reason,
    required this.discardedAt,
    required this.discardedAmount,
    required this.discardedValue,
    this.currencyCode,
  });

  factory InventoryDiscardEvent.fromJson(Map<String, dynamic> json) {
    return InventoryDiscardEvent(
      id: _readString(json['id']),
      sourceType: _readSourceType(json['source_type']),
      sourceId: _readString(json['source_id']),
      name: _readString(json['name']),
      reason: _readReason(json['reason']),
      discardedAt: _readDateTime(json['discarded_at']),
      discardedAmount: _readInt(json['discarded_amount']),
      discardedValue: _readDouble(json['discarded_value']),
      currencyCode: _readNullableString(json['currency_code']),
    );
  }

  factory InventoryDiscardEvent.fromInventoryItem({
    required String id,
    required InventoryItem item,
    required int discardedAmount,
    required InventoryDiscardReason reason,
    DateTime? discardedAt,
  }) {
    return InventoryDiscardEvent(
      id: id,
      sourceType: InventoryDiscardSourceType.inventoryItem,
      sourceId: item.id,
      name: item.name,
      reason: reason,
      discardedAt: discardedAt ?? DateTime.now(),
      discardedAmount: discardedAmount,
      discardedValue: _inventoryDiscardValue(item, discardedAmount),
      currencyCode: item.currencyCode,
    );
  }

  factory InventoryDiscardEvent.fromPreparedMeal({
    required String id,
    required PreparedMeal meal,
    required int discardedPortions,
    required InventoryDiscardReason reason,
    DateTime? discardedAt,
  }) {
    final totalPortions = meal.totalPortions <= 0 ? 1 : meal.totalPortions;
    final discardedRatio = discardedPortions / totalPortions;
    return InventoryDiscardEvent(
      id: id,
      sourceType: InventoryDiscardSourceType.preparedMeal,
      sourceId: meal.id,
      name: meal.name,
      reason: reason,
      discardedAt: discardedAt ?? DateTime.now(),
      discardedAmount: discardedPortions,
      discardedValue: meal.totalPrice * discardedRatio,
      currencyCode: meal.currencyCode,
    );
  }

  final String id;
  final InventoryDiscardSourceType sourceType;
  final String sourceId;
  final String name;
  final InventoryDiscardReason reason;
  final DateTime discardedAt;
  final int discardedAmount;
  final double discardedValue;
  final String? currencyCode;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'source_type': sourceType.name,
      'source_id': sourceId,
      'name': name,
      'reason': reason.name,
      'discarded_at': discardedAt.toIso8601String(),
      'discarded_amount': discardedAmount,
      'discarded_value': discardedValue,
      'currency_code': currencyCode,
    };
  }
}

double _inventoryDiscardValue(InventoryItem item, int discardedAmount) {
  if (discardedAmount <= 0) {
    return 0;
  }

  final totalPurchasedValue = _itemPurchasedValue(item);
  if (totalPurchasedValue <= 0) {
    return 0;
  }

  if (item.usesAmountProgress && item.initialAmount > 0) {
    return totalPurchasedValue * (discardedAmount / item.initialAmount);
  }

  final initialQuantity = item.effectiveInitialQuantity;
  if (initialQuantity <= 0) {
    return 0;
  }
  return totalPurchasedValue * (discardedAmount / initialQuantity);
}

double _itemPurchasedValue(InventoryItem item) {
  final discountTotal = item.discounts.values.fold<double>(
    0,
    (sum, value) => sum + value,
  );
  return (item.effectiveInitialQuantity * item.unitPrice) + discountTotal;
}

InventoryDiscardSourceType _readSourceType(Object? value) {
  final raw = _readString(value);
  for (final type in InventoryDiscardSourceType.values) {
    if (type.name == raw) {
      return type;
    }
  }
  return InventoryDiscardSourceType.inventoryItem;
}

InventoryDiscardReason _readReason(Object? value) {
  final raw = _readString(value);
  for (final reason in InventoryDiscardReason.values) {
    if (reason.name == raw) {
      return reason;
    }
  }
  return InventoryDiscardReason.other;
}

DateTime _readDateTime(Object? value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value.trim()) ?? DateTime.now();
  }
  return DateTime.now();
}

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim()) ?? 0;
  }
  return 0;
}

double _readDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.trim()) ?? 0;
  }
  return 0;
}

String _readString(Object? value) {
  return _readNullableString(value) ?? '';
}

String? _readNullableString(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}
