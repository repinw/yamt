import 'package:uuid/uuid.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository_contract.dart';
import 'package:yamt/features/inventory/data/global_food_receipt_alias_repository_contract.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository_contract.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_receipt_alias.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_unit_aliases.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/domain/contracts/receipt_storage_gateway.dart';
import 'package:yamt/features/scanner/domain/models/product_candidate.dart';
import 'package:yamt/features/scanner/domain/models/receipt_line_item.dart';
import 'package:yamt/features/scanner/domain/models/scanned_receipt.dart';

/// Yamt adapter implementing [ReceiptStorageGateway].
///
/// Converts confirmed scanner items into [InventoryItem]s and saves them
/// via [InventoryItemRepository], while recording OCR aliases via
/// [GlobalFoodReceiptAliasRepository].
class YamtReceiptStorageGateway implements ReceiptStorageGateway {
  /// Creates a [YamtReceiptStorageGateway].
  new({
    required this._inventoryItemRepository,
    required this._globalFoodItemRepository,
    required this._globalFoodReceiptAliasRepository,
    String Function()? idGenerator,
  }) : _idGenerator = idGenerator ?? const Uuid().v4;

  final InventoryItemRepository _inventoryItemRepository;
  final GlobalFoodItemRepository _globalFoodItemRepository;
  final GlobalFoodReceiptAliasRepository _globalFoodReceiptAliasRepository;
  final String Function() _idGenerator;

  @override
  Future<void> saveReceipt({
    required ScannedReceipt receipt,
    required List<ReceiptLineItem> items,
  }) async {
    final now = DateTime.now();
    final savableItems = items
        .where((i) => i.status == ReceiptItemStatus.confirmed)
        .where((i) => !i.isDeposit && !i.isDiscount)
        .toList(growable: false);

    final inventoryItems = _buildInventoryItems(receipt, savableItems, now);
    final globalItems = _buildGlobalItems(receipt, savableItems, now);
    final aliases = _buildAliases(receipt, savableItems, now);

    await _persistGlobalItems(globalItems);
    await _persistInventoryItems(inventoryItems);
    await _persistAliases(aliases);
  }

  List<InventoryItem> _buildInventoryItems(
    ScannedReceipt receipt,
    List<ReceiptLineItem> items,
    DateTime now,
  ) {
    return items
        .map((item) {
          final product = item.matchedProduct;
          final nutrition = product?.nutrition;
          final amount = _resolveInventoryAmount(item, product?.packageSize);
          final unitPrice =
              item.unitPrice ??
              (item.quantity > 0
                  ? (item.totalPrice / item.quantity)
                  : item.totalPrice);

          return InventoryItem.create(
            id: _idGenerator(),
            name: item.displayName,
            storeName: receipt.storeName ?? '',
            entryDate: receipt.dateTime ?? now,
            quantity: amount.quantity,
            initialQuantity: amount.quantity,
            unitPrice: unitPrice,
            currencyCode: receipt.currency,
            weight: amount.weight,
            barcode: product?.barcode,
            brand: product?.brand,
            category: product?.category,
            imageUrl: product?.imageUrl,
            nutrition: nutrition,
            ocrName: item.rawName,
            receiptId: receipt.id,
            receiptDate: receipt.dateTime,
            globalFoodItemId: product?.id,
          ).withDerivedAmount(weight: amount.weight, quantity: amount.quantity);
        })
        .toList(growable: false);
  }

  Map<String, GlobalFoodItem> _buildGlobalItems(
    ScannedReceipt receipt,
    List<ReceiptLineItem> items,
    DateTime now,
  ) {
    final storeName = receipt.storeName;
    if (storeName == null || storeName.isEmpty) return const {};

    final globalItems = <String, GlobalFoodItem>{};
    for (final item in items) {
      final product = item.matchedProduct;
      if (product == null || !product.requiresPersistence) continue;

      final globalItem = _buildGlobalItem(product, storeName, item, now);
      globalItems[globalItem.id] = globalItem;
    }
    return globalItems;
  }

  List<GlobalFoodReceiptAlias> _buildAliases(
    ScannedReceipt receipt,
    List<ReceiptLineItem> items,
    DateTime now,
  ) {
    final storeName = receipt.storeName;
    if (storeName == null || storeName.isEmpty) return const [];

    final aliases = <GlobalFoodReceiptAlias>[];
    for (final item in items) {
      final product = item.matchedProduct;
      if (product == null) continue;

      final globalItem = _buildGlobalItem(product, storeName, item, now);
      final alias = GlobalFoodReceiptAlias.tryCreate(
        storeName: storeName,
        receiptName: item.rawName,
        globalFoodItem: globalItem,
        now: now,
      );
      if (alias != null) aliases.add(alias);
    }
    return aliases;
  }

  GlobalFoodItem _buildGlobalItem(
    ProductCandidate product,
    String storeName,
    ReceiptLineItem item,
    DateTime now,
  ) {
    return GlobalFoodItem.create(
      id: product.id,
      name: product.name,
      now: now,
      brand: product.brand,
      category: product.category,
      storeName: storeName,
      barcode: product.barcode,
      imageUrl: product.imageUrl,
      packageWeight: _firstNonEmpty(item.packageWeight, product.packageSize),
      nutrition: product.nutrition,
    );
  }

  Future<void> _persistGlobalItems(Map<String, GlobalFoodItem> items) async {
    if (items.isEmpty) return;
    final success = await _globalFoodItemRepository.appendAll(
      items.values.toList(growable: false),
    );
    if (!success) {
      throw Exception('Failed to save receipt products to global catalog.');
    }
  }

  Future<void> _persistInventoryItems(List<InventoryItem> items) async {
    if (items.isEmpty) return;
    final success = await _inventoryItemRepository.appendAll(items);
    if (!success) {
      throw Exception('Failed to save receipt items to inventory.');
    }
  }

  Future<void> _persistAliases(List<GlobalFoodReceiptAlias> aliases) async {
    if (aliases.isEmpty) return;
    await _globalFoodReceiptAliasRepository.appendAll(aliases);
  }

  @override
  Future<void> learnAlias({
    required String rawLineText,
    required String productId,
    String? storeName,
  }) async {
    final effectiveStore = storeName ?? '';
    if (effectiveStore.isEmpty || rawLineText.trim().isEmpty) return;

    final now = DateTime.now();
    final alias = GlobalFoodReceiptAlias.tryCreate(
      storeName: effectiveStore,
      receiptName: rawLineText,
      globalFoodItem: GlobalFoodItem.create(
        id: productId,
        name: rawLineText,
        now: now,
      ),
      now: now,
    );
    if (alias != null) {
      await _globalFoodReceiptAliasRepository.appendAll([alias]);
    }
  }

  ({int quantity, String? weight}) _resolveInventoryAmount(
    ReceiptLineItem item,
    String? productPackageSize,
  ) {
    final unit = item.unit?.trim();
    final conversion = resolveInventoryAmountUnitAlias(unit);
    if (conversion != null && conversion.base != InventoryAmountUnit.piece) {
      return (quantity: 1, weight: '${item.quantity}$unit');
    }

    return (
      quantity: item.quantity.toInt().clamp(1, 9999),
      weight: _firstNonEmpty(item.packageWeight, productPackageSize),
    );
  }

  String? _firstNonEmpty(String? primary, String? fallback) {
    final primaryValue = primary?.trim();
    if (primaryValue != null && primaryValue.isNotEmpty) return primaryValue;
    final fallbackValue = fallback?.trim();
    return fallbackValue == null || fallbackValue.isEmpty
        ? null
        : fallbackValue;
  }
}
