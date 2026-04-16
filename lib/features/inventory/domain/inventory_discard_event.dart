import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines inventory discard reason.
enum InventoryDiscardReason {
  /// Documented member.
  expired,

  /// Documented member.
  spoiled,

  /// Documented member.
  cookedTooMuch,

  /// Documented member.
  other
  ;

  /// Localized label.
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

/// Defines inventory discard source type.
enum InventoryDiscardSourceType {
  /// Inventory item.
  inventoryItem,

  /// Prepared meal.
  preparedMeal,
}

/// Defines inventory discard event.
class InventoryDiscardEvent {
  /// The inventory discard event.
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

  /// Creates a [InventoryDiscardEvent] for from json.
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

  /// Creates a [InventoryDiscardEvent] for from inventory item.
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

  /// Creates a [InventoryDiscardEvent] for from prepared meal.
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

  /// The id.
  final String id;

  /// The source type.
  final InventoryDiscardSourceType sourceType;

  /// The source id.
  final String sourceId;

  /// The name.
  final String name;

  /// The reason.
  final InventoryDiscardReason reason;

  /// The discarded at.
  final DateTime discardedAt;

  /// The discarded amount.
  final int discardedAmount;

  /// The discarded value.
  final double discardedValue;

  /// The currency code.
  final String? currencyCode;

  /// To json.
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
    final parsed = DateTime.tryParse(value.trim());
    if (parsed != null) {
      return parsed;
    }
  }

  throw FormatException(
    'Invalid discarded_at value: ${value.runtimeType}',
  );
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
