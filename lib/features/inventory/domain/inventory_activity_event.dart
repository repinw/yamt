import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Inventory activity event type.
enum InventoryActivityEventType {
  /// Inventory item added.
  itemAdded,

  /// Inventory item consumed.
  itemConsumed,

  /// Inventory item discarded.
  itemDiscarded,

  /// Inventory item deleted.
  itemDeleted,

  /// Inventory item restored.
  itemRestored,

  /// Inventory item used while creating or editing a prepared meal.
  itemUsedInPreparedMeal,

  /// Inventory item returned from a prepared meal.
  itemReturnedFromPreparedMeal,
}

/// Actor persisted with inventory activity events.
class InventoryActivityActor {
  /// Creates an inventory activity actor.
  const InventoryActivityActor({
    required this.userId,
    required this.displayName,
  });

  /// User id.
  final String userId;

  /// Display name.
  final String? displayName;
}

/// Shared inventory stock activity event.
class InventoryActivityEvent {
  /// Creates an inventory activity event.
  const InventoryActivityEvent({
    required this.id,
    required this.type,
    required this.actorUserId,
    required this.happenedAt,
    required this.itemId,
    required this.itemName,
    required this.amount,
    required this.amountScale,
    required this.beforeQuantity,
    required this.afterQuantity,
    required this.beforeCurrentAmount,
    required this.afterCurrentAmount,
    this.actorDisplayName,
    this.itemBrand,
    this.itemImageUrl,
    this.itemAmountUnit,
    this.reason,
  });

  /// Creates an event from stock before/after snapshots.
  factory InventoryActivityEvent.fromStockChange({
    required String id,
    required InventoryActivityEventType type,
    required InventoryActivityActor actor,
    required InventoryItem item,
    required int amount,
    required int? beforeQuantity,
    required int? afterQuantity,
    required int? beforeCurrentAmount,
    required int? afterCurrentAmount,
    DateTime? happenedAt,
    String? reason,
  }) {
    return InventoryActivityEvent(
      id: id,
      type: type,
      actorUserId: actor.userId,
      actorDisplayName: actor.displayName,
      happenedAt: happenedAt ?? DateTime.now(),
      itemId: item.id,
      itemName: item.name,
      itemBrand: item.brand,
      itemImageUrl: item.imageUrl,
      amount: amount,
      amountScale: item.amountScale,
      itemAmountUnit: item.amountUnit,
      beforeQuantity: beforeQuantity,
      afterQuantity: afterQuantity,
      beforeCurrentAmount: beforeCurrentAmount,
      afterCurrentAmount: afterCurrentAmount,
      reason: reason,
    );
  }

  /// Creates an inventory activity event from JSON.
  factory InventoryActivityEvent.fromJson(Map<String, dynamic> json) {
    return InventoryActivityEvent(
      id: _readString(json['id']),
      type: _readType(json['type']),
      actorUserId: _readString(json['actor_user_id']),
      actorDisplayName: _readNullableString(json['actor_display_name']),
      happenedAt: _readDateTime(json['happened_at']),
      itemId: _readString(json['item_id']),
      itemName: _readString(json['item_name']),
      itemBrand: _readNullableString(json['item_brand']),
      itemImageUrl: _readNullableString(json['item_image_url']),
      amount: _readInt(json['amount']),
      amountScale: _readInt(json['amount_scale'], fallback: 1),
      itemAmountUnit: _readAmountUnit(json['item_amount_unit']),
      beforeQuantity: _readNullableInt(json['before_quantity']),
      afterQuantity: _readNullableInt(json['after_quantity']),
      beforeCurrentAmount: _readNullableInt(json['before_current_amount']),
      afterCurrentAmount: _readNullableInt(json['after_current_amount']),
      reason: _readNullableString(json['reason']),
    );
  }

  /// Id.
  final String id;

  /// Type.
  final InventoryActivityEventType type;

  /// Actor user id.
  final String actorUserId;

  /// Actor display name.
  final String? actorDisplayName;

  /// Happened at.
  final DateTime happenedAt;

  /// Item id.
  final String itemId;

  /// Item name.
  final String itemName;

  /// Item brand.
  final String? itemBrand;

  /// Item image URL.
  final String? itemImageUrl;

  /// Changed amount.
  final int amount;

  /// Changed amount scale.
  final int amountScale;

  /// Item amount unit.
  final InventoryAmountUnit? itemAmountUnit;

  /// Quantity before change.
  final int? beforeQuantity;

  /// Quantity after change.
  final int? afterQuantity;

  /// Current amount before change.
  final int? beforeCurrentAmount;

  /// Current amount after change.
  final int? afterCurrentAmount;

  /// Optional reason/context.
  final String? reason;

  /// To JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'type': type.name,
      'actor_user_id': actorUserId,
      'actor_display_name': actorDisplayName,
      'happened_at': happenedAt.toIso8601String(),
      'item_id': itemId,
      'item_name': itemName,
      'item_brand': itemBrand,
      'item_image_url': itemImageUrl,
      'amount': amount,
      'amount_scale': amountScale,
      'item_amount_unit': itemAmountUnit?.code,
      'before_quantity': beforeQuantity,
      'after_quantity': afterQuantity,
      'before_current_amount': beforeCurrentAmount,
      'after_current_amount': afterCurrentAmount,
      'reason': reason,
    };
  }

  /// Whether amount uses item amount unit.
  bool get usesAmountUnit => itemAmountUnit != null;
}

InventoryActivityEventType _readType(Object? value) {
  final raw = _readString(value);
  for (final type in InventoryActivityEventType.values) {
    if (type.name == raw) {
      return type;
    }
  }
  return InventoryActivityEventType.itemConsumed;
}

InventoryAmountUnit? _readAmountUnit(Object? value) {
  final raw = _readNullableString(value);
  if (raw == null) {
    return null;
  }
  for (final unit in InventoryAmountUnit.values) {
    if (unit.code == raw || unit.name == raw) {
      return unit;
    }
  }
  return null;
}

String _readString(Object? value) {
  return _readNullableString(value) ?? '';
}

String? _readNullableString(Object? value) {
  final string = value?.toString().trim();
  if (string == null || string.isEmpty) {
    return null;
  }
  return string;
}

int _readInt(Object? value, {int fallback = 0}) {
  return _readNullableInt(value) ?? fallback;
}

int? _readNullableInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim());
  }
  return null;
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
  return DateTime.now();
}
