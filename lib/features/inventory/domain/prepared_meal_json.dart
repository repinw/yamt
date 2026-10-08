import 'package:yamt/features/inventory/domain/inventory_item.dart';

// JSON values of Vorrat meals and their foods.
//
// Compatibility code from before the removal rule in architecture.md §12:
// these readers accept the loose values of meals saved by older versions
// (numbers as text, missing fields as 0 or ""). The release checklist lists
// them; the user decides when they go. Do not use them for new fields; new
// fields parse strictly.

/// A stored whole number, or 0.
int readPreparedMealInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return 0;
}

/// A stored number, also as text with a decimal comma, or 0.
double readPreparedMealDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    final normalized = value.replaceAll(',', '.').trim();
    return double.tryParse(normalized) ?? 0;
  }
  return 0;
}

/// Stored text, trimmed, or an empty string.
String readPreparedMealString(Object? value) {
  return readPreparedMealOptionalString(value) ?? '';
}

/// Stored text, trimmed, or null when empty.
String? readPreparedMealOptionalString(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// A stored amount unit code, or pieces.
InventoryAmountUnit readPreparedMealAmountUnit(Object? value) {
  final raw = value is String ? value.trim() : '';
  for (final unit in InventoryAmountUnit.values) {
    if (unit.code == raw) {
      return unit;
    }
  }
  return InventoryAmountUnit.piece;
}

/// The stored code of [value].
String writePreparedMealAmountUnit(InventoryAmountUnit value) => value.code;

/// A stored whole number, rounded, or null.
int? readPreparedMealOptionalInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is double) {
    return value.round();
  }
  if (value is String) {
    return int.tryParse(value.trim());
  }
  return null;
}
