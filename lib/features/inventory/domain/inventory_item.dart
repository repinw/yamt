import 'package:collection/collection.dart';
import 'package:yamt/core/utils/currency_format.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item_product_snapshot.dart';

export 'package:yamt/features/inventory/domain/inventory_amount_parser.dart'
    show InventoryAmountUnit, InventoryAmountUnitCode;

enum InventoryBarcodeStatus { resolved, uncertain, pending, missing }

enum InventoryItemOrigin { standard, manualAdd }

const pendingGlobalFoodItemIdPrefix = 'pending-';

String buildPendingGlobalFoodItemId(String resolvedFoodFingerprint) {
  return '$pendingGlobalFoodItemIdPrefix$resolvedFoodFingerprint';
}

bool isPendingGlobalFoodItemId(String? value) {
  final normalized = _normalizeGlobalFoodItemId(value);
  if (normalized == null) {
    return false;
  }
  return normalized.startsWith(pendingGlobalFoodItemIdPrefix);
}

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.globalFoodItemId,
    required this.productSnapshot,
    required this.entryDate,
    required this.storeName,
    required this.quantity,
    this.initialQuantity = 1,
    this.unitPrice = 0.0,
    this.currencyCode,
    this.weight,
    this.initialAmount = 0,
    this.currentAmount = 0,
    this.amountUnit,
    this.barcodeCandidates = const <String>[],
    this.barcodeLookupRequestedAt,
    this.barcodeResolvedAt,
    this.barcodeLookupUncertain = false,
    this.discounts = const <String, double>{},
    this.receiptId,
    this.receiptDate,
    this.language,
    this.ocrName,
    this.isDeposit = false,
    this.isDiscount = false,
    this.origin = InventoryItemOrigin.standard,
  });

  factory InventoryItem.create({
    required String id,
    required String name,
    required DateTime entryDate,
    required String storeName,
    required int quantity,
    int initialQuantity = 1,
    double unitPrice = 0.0,
    String? currencyCode,
    String? weight,
    int initialAmount = 0,
    int currentAmount = 0,
    InventoryAmountUnit? amountUnit,
    String? barcode,
    List<String> barcodeCandidates = const <String>[],
    String? foodFingerprint,
    DateTime? barcodeLookupRequestedAt,
    DateTime? barcodeResolvedAt,
    bool barcodeLookupUncertain = false,
    String? brand,
    String? category,
    String? imageUrl,
    GlobalFoodNutrition? nutrition,
    Map<String, double> discounts = const <String, double>{},
    String? receiptId,
    DateTime? receiptDate,
    String? language,
    String? ocrName,
    bool isDeposit = false,
    bool isDiscount = false,
    InventoryItemOrigin origin = InventoryItemOrigin.standard,
    String? globalFoodItemId,
  }) {
    final productSnapshot = InventoryItemProductSnapshot(
      name: name,
      brand: brand,
      category: category,
      barcode: barcode,
      imageUrl: imageUrl,
      foodFingerprint: foodFingerprint,
      nutrition: nutrition,
    );

    return InventoryItem(
      id: id,
      globalFoodItemId: _resolveGlobalFoodItemId(
        globalFoodItemId: globalFoodItemId,
        productSnapshot: productSnapshot,
      ),
      productSnapshot: productSnapshot,
      entryDate: entryDate,
      storeName: storeName,
      quantity: quantity,
      initialQuantity: initialQuantity,
      unitPrice: unitPrice,
      currencyCode: _normalizeCurrencyCodeValue(currencyCode),
      weight: _normalizeWeightText(weight),
      initialAmount: initialAmount,
      currentAmount: currentAmount,
      amountUnit: amountUnit,
      barcodeCandidates: barcodeCandidates,
      barcodeLookupRequestedAt: barcodeLookupRequestedAt,
      barcodeResolvedAt: barcodeResolvedAt,
      barcodeLookupUncertain: barcodeLookupUncertain,
      discounts: discounts,
      receiptId: receiptId,
      receiptDate: receiptDate,
      language: language,
      ocrName: _normalizeOcrName(ocrName),
      isDeposit: isDeposit,
      isDiscount: isDiscount,
      origin: origin,
    );
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    final productSnapshot = InventoryItemProductSnapshot.fromJson(
      _readMap(json['product_snapshot']),
    );

    return InventoryItem(
      id: _readTrimmedString(json['id']) ?? '',
      globalFoodItemId: _resolveGlobalFoodItemId(
        globalFoodItemId: _readTrimmedString(json['global_food_item_id']),
        productSnapshot: productSnapshot,
      ),
      productSnapshot: productSnapshot,
      entryDate: _readDateTime(json['entry_date']) ?? DateTime.now(),
      storeName: _readTrimmedString(json['store_name']) ?? '',
      quantity: _readInt(json['quantity']) ?? 0,
      initialQuantity: _readInt(json['initial_quantity']) ?? 1,
      unitPrice: _readDouble(json['unit_price']) ?? 0.0,
      currencyCode: _normalizeCurrencyCodeValue(json['currency_code']),
      weight: _normalizeWeightText(json['weight']),
      initialAmount: _readInt(json['initial_amount']) ?? 0,
      currentAmount: _readInt(json['current_amount']) ?? 0,
      amountUnit: _readAmountUnit(json['amount_unit']),
      barcodeCandidates: _readStringList(json['barcode_candidates']),
      barcodeLookupRequestedAt: _readDateTime(
        json['barcode_lookup_requested_at'],
      ),
      barcodeResolvedAt: _readDateTime(json['barcode_resolved_at']),
      barcodeLookupUncertain:
          _readBool(json['barcode_lookup_uncertain']) ?? false,
      discounts: _readDiscounts(json['discounts']),
      receiptId: _readTrimmedString(json['receipt_id']),
      receiptDate: _readDateTime(json['receipt_date']),
      language: _readTrimmedString(json['language']),
      ocrName: _readTrimmedString(json['ocr_name']),
      isDeposit: _readBool(json['is_deposit']) ?? false,
      isDiscount: _readBool(json['is_discount']) ?? false,
      origin: _readInventoryItemOrigin(json['origin']),
    );
  }

  final String id;
  final String globalFoodItemId;
  final InventoryItemProductSnapshot productSnapshot;
  final DateTime entryDate;
  final String storeName;
  final int quantity;
  final int initialQuantity;
  final double unitPrice;
  final String? currencyCode;
  final String? weight;
  final int initialAmount;
  final int currentAmount;
  final InventoryAmountUnit? amountUnit;
  final List<String> barcodeCandidates;
  final DateTime? barcodeLookupRequestedAt;
  final DateTime? barcodeResolvedAt;
  final bool barcodeLookupUncertain;
  final Map<String, double> discounts;
  final String? receiptId;
  final DateTime? receiptDate;
  final String? language;
  final String? ocrName;
  final bool isDeposit;
  final bool isDiscount;
  final InventoryItemOrigin origin;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'global_food_item_id': globalFoodItemId,
      'product_snapshot': productSnapshot.toJson(),
      'entry_date': entryDate.toIso8601String(),
      'store_name': storeName,
      'quantity': quantity,
      'initial_quantity': initialQuantity,
      'unit_price': unitPrice,
      'currency_code': currencyCode,
      'weight': weight,
      'initial_amount': initialAmount,
      'current_amount': currentAmount,
      'amount_unit': amountUnit?.code,
      'barcode_candidates': barcodeCandidates,
      'barcode_lookup_requested_at': barcodeLookupRequestedAt
          ?.toIso8601String(),
      'barcode_resolved_at': barcodeResolvedAt?.toIso8601String(),
      'barcode_lookup_uncertain': barcodeLookupUncertain,
      'discounts': discounts,
      'receipt_id': receiptId,
      'receipt_date': receiptDate?.toIso8601String(),
      'language': language,
      'ocr_name': ocrName,
      'is_deposit': isDeposit,
      'is_discount': isDiscount,
      'origin': origin.name,
    };
  }

  InventoryItem copyWith({
    String? id,
    String? globalFoodItemId,
    InventoryItemProductSnapshot? productSnapshot,
    String? name,
    Object? brand = _keepValue,
    Object? category = _keepValue,
    Object? barcode = _keepValue,
    Object? imageUrl = _keepValue,
    Object? foodFingerprint = _keepValue,
    Object? nutrition = _keepValue,
    DateTime? entryDate,
    String? storeName,
    int? quantity,
    int? initialQuantity,
    double? unitPrice,
    Object? currencyCode = _keepValue,
    Object? weight = _keepValue,
    int? initialAmount,
    int? currentAmount,
    Object? amountUnit = _keepValue,
    List<String>? barcodeCandidates,
    Object? barcodeLookupRequestedAt = _keepValue,
    Object? barcodeResolvedAt = _keepValue,
    bool? barcodeLookupUncertain,
    Map<String, double>? discounts,
    Object? receiptId = _keepValue,
    Object? receiptDate = _keepValue,
    Object? language = _keepValue,
    Object? ocrName = _keepValue,
    bool? isDeposit,
    bool? isDiscount,
    InventoryItemOrigin? origin,
  }) {
    final nextProductSnapshot = (productSnapshot ?? this.productSnapshot)
        .copyWith(
          name: name,
          brand: brand,
          category: category,
          barcode: barcode,
          imageUrl: imageUrl,
          foodFingerprint: foodFingerprint,
          nutrition: nutrition,
        );

    return InventoryItem(
      id: id ?? this.id,
      globalFoodItemId: globalFoodItemId ?? this.globalFoodItemId,
      productSnapshot: nextProductSnapshot,
      entryDate: entryDate ?? this.entryDate,
      storeName: storeName ?? this.storeName,
      quantity: quantity ?? this.quantity,
      initialQuantity: initialQuantity ?? this.initialQuantity,
      unitPrice: unitPrice ?? this.unitPrice,
      currencyCode: currencyCode == _keepValue
          ? this.currencyCode
          : _normalizeCurrencyCodeValue(currencyCode),
      weight: weight == _keepValue ? this.weight : _normalizeWeightText(weight),
      initialAmount: initialAmount ?? this.initialAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      amountUnit: amountUnit == _keepValue
          ? this.amountUnit
          : amountUnit as InventoryAmountUnit?,
      barcodeCandidates: barcodeCandidates ?? this.barcodeCandidates,
      barcodeLookupRequestedAt: barcodeLookupRequestedAt == _keepValue
          ? this.barcodeLookupRequestedAt
          : barcodeLookupRequestedAt as DateTime?,
      barcodeResolvedAt: barcodeResolvedAt == _keepValue
          ? this.barcodeResolvedAt
          : barcodeResolvedAt as DateTime?,
      barcodeLookupUncertain:
          barcodeLookupUncertain ?? this.barcodeLookupUncertain,
      discounts: discounts ?? this.discounts,
      receiptId: receiptId == _keepValue
          ? this.receiptId
          : receiptId as String?,
      receiptDate: receiptDate == _keepValue
          ? this.receiptDate
          : receiptDate as DateTime?,
      language: language == _keepValue ? this.language : language as String?,
      ocrName: ocrName == _keepValue
          ? this.ocrName
          : _normalizeOcrName(ocrName),
      isDeposit: isDeposit ?? this.isDeposit,
      isDiscount: isDiscount ?? this.isDiscount,
      origin: origin ?? this.origin,
    );
  }

  String get name => productSnapshot.name;
  String? get brand => productSnapshot.brand;
  String? get category => productSnapshot.category;
  String? get barcode => productSnapshot.barcode;
  String? get imageUrl => productSnapshot.imageUrl;
  String? get foodFingerprint => productSnapshot.foodFingerprint;
  GlobalFoodNutrition? get nutrition => productSnapshot.nutrition;

  InventoryItem withDerivedAmount({
    String? weight,
    int? quantity,
    InventoryAmountUnit? fallbackUnit,
  }) {
    final normalizedWeight = _normalizeWeightText(weight ?? this.weight);
    final nextQuantity = quantity ?? this.quantity;
    final parsedAmount = _amountParser.tryParse(
      rawWeight: normalizedWeight,
      quantity: nextQuantity,
      fallbackUnit: fallbackUnit,
    );
    final amount = parsedAmount?.amount ?? 0;

    return copyWith(
      quantity: nextQuantity,
      weight: normalizedWeight,
      initialAmount: amount,
      currentAmount: amount,
      amountUnit: parsedAmount?.unit,
    );
  }

  bool get isReviewOnly => isDeposit || isDiscount;

  bool get canBeSavedToInventory => !isReviewOnly;

  bool get isManuallyAdded => origin == InventoryItemOrigin.manualAdd;

  bool get usesAmountProgress => amountUnit != null && initialAmount > 0;

  /// Best available starting quantity for price and progress fallbacks.
  int get effectiveInitialQuantity {
    if (initialQuantity > 0) {
      return initialQuantity;
    }
    if (quantity > 0) {
      return quantity;
    }
    return 1;
  }

  String get resolvedFoodFingerprint {
    return productSnapshot.resolvedFoodFingerprint;
  }

  String? get normalizedBarcode {
    return productSnapshot.normalizedBarcode;
  }

  InventoryBarcodeStatus get barcodeStatus {
    if (normalizedBarcode != null) {
      if (barcodeLookupUncertain) {
        return InventoryBarcodeStatus.uncertain;
      }
      return InventoryBarcodeStatus.resolved;
    }
    if (barcodeLookupRequestedAt != null) {
      return InventoryBarcodeStatus.pending;
    }
    return InventoryBarcodeStatus.missing;
  }

  bool get isConsumed {
    final progress = _consumptionProgress;
    return progress.remaining < progress.initial;
  }

  bool get isFullyAvailable {
    final progress = _consumptionProgress;
    return progress.remaining >= progress.initial;
  }

  bool get isFullyConsumed {
    final progress = _consumptionProgress;
    return progress.remaining <= 0;
  }

  _ConsumptionProgress get _consumptionProgress {
    if (usesAmountProgress) {
      return _ConsumptionProgress(
        initial: initialAmount,
        remaining: currentAmount,
      );
    }
    return _ConsumptionProgress(initial: initialQuantity, remaining: quantity);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is InventoryItem &&
            other.id == id &&
            other.globalFoodItemId == globalFoodItemId &&
            other.productSnapshot == productSnapshot &&
            other.entryDate == entryDate &&
            other.storeName == storeName &&
            other.quantity == quantity &&
            other.initialQuantity == initialQuantity &&
            other.unitPrice == unitPrice &&
            other.currencyCode == currencyCode &&
            other.weight == weight &&
            other.initialAmount == initialAmount &&
            other.currentAmount == currentAmount &&
            other.amountUnit == amountUnit &&
            const ListEquality<String>().equals(
              other.barcodeCandidates,
              barcodeCandidates,
            ) &&
            other.barcodeLookupRequestedAt == barcodeLookupRequestedAt &&
            other.barcodeResolvedAt == barcodeResolvedAt &&
            other.barcodeLookupUncertain == barcodeLookupUncertain &&
            const MapEquality<String, double>().equals(
              other.discounts,
              discounts,
            ) &&
            other.receiptId == receiptId &&
            other.receiptDate == receiptDate &&
            other.language == language &&
            other.ocrName == ocrName &&
            other.isDeposit == isDeposit &&
            other.isDiscount == isDiscount &&
            other.origin == origin;
  }

  @override
  int get hashCode {
    return Object.hashAll(<Object?>[
      id,
      globalFoodItemId,
      productSnapshot,
      entryDate,
      storeName,
      quantity,
      initialQuantity,
      unitPrice,
      currencyCode,
      weight,
      initialAmount,
      currentAmount,
      amountUnit,
      const ListEquality<String>().hash(barcodeCandidates),
      barcodeLookupRequestedAt,
      barcodeResolvedAt,
      barcodeLookupUncertain,
      const MapEquality<String, double>().hash(discounts),
      receiptId,
      receiptDate,
      language,
      ocrName,
      isDeposit,
      isDiscount,
      origin,
    ]);
  }
}

class _ConsumptionProgress {
  const _ConsumptionProgress({required this.initial, required this.remaining});

  final int initial;
  final int remaining;
}

Map<String, dynamic> _readMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map(
      (key, nestedValue) =>
          MapEntry<String, dynamic>(key.toString(), nestedValue),
    );
  }
  return const <String, dynamic>{};
}

DateTime? _readDateTime(Object? value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value.trim());
  }
  return null;
}

String? _normalizeOcrName(Object? value) {
  final trimmed = _readTrimmedString(value);
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

bool? _readBool(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
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

int? _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return null;
}

double? _readDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.trim());
  }
  return null;
}

InventoryAmountUnit? _readAmountUnit(Object? value) {
  final raw = value is String ? value.trim() : '';
  for (final unit in InventoryAmountUnit.values) {
    if (unit.code == raw) {
      return unit;
    }
  }
  return null;
}

List<String> _readStringList(Object? value) {
  if (value is! List) {
    return const <String>[];
  }
  return value
      .whereType<String>()
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
}

Map<String, double> _readDiscounts(Object? value) {
  if (value is! Map) {
    return const <String, double>{};
  }
  final discounts = <String, double>{};
  for (final entry in value.entries) {
    final amount = _readDouble(entry.value);
    if (amount == null) {
      continue;
    }
    discounts[entry.key.toString()] = amount;
  }
  return discounts;
}

String? _readTrimmedString(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

String? _normalizeCurrencyCodeValue(Object? value) {
  if (value is! String) {
    return null;
  }
  return normalizeCurrencyCode(value);
}

String? _normalizeWeightText(Object? rawWeight) {
  if (rawWeight is! String) {
    return null;
  }
  final trimmed = rawWeight.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

String? _normalizeGlobalFoodItemId(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

String _resolveGlobalFoodItemId({
  required String? globalFoodItemId,
  required InventoryItemProductSnapshot productSnapshot,
}) {
  return _normalizeGlobalFoodItemId(globalFoodItemId) ??
      buildPendingGlobalFoodItemId(productSnapshot.resolvedFoodFingerprint);
}

InventoryItemOrigin _readInventoryItemOrigin(Object? value) {
  final raw = value is String ? value.trim() : '';
  return InventoryItemOrigin.values.firstWhere(
    (origin) => origin.name == raw,
    orElse: () => InventoryItemOrigin.standard,
  );
}

const Object _keepValue = Object();
const _amountParser = InventoryAmountParser();
