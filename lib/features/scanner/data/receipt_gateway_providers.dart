import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/application/global_food_item_matcher.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository.dart';
import 'package:yamt/features/inventory/data/global_food_receipt_alias_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/scanner/data/adapters/yamt_receipt_manual_product_picker.dart';
import 'package:yamt/features/scanner/data/adapters/yamt_receipt_product_resolver.dart';
import 'package:yamt/features/scanner/data/adapters/yamt_receipt_storage_gateway.dart';
import 'package:yamt/features/scanner/domain/contracts/receipt_manual_product_picker.dart';
import 'package:yamt/features/scanner/domain/contracts/receipt_product_resolver.dart';
import 'package:yamt/features/scanner/domain/contracts/receipt_storage_gateway.dart';

part 'receipt_gateway_providers.g.dart';

/// Provider for [ReceiptProductResolver].
///
/// Uses [YamtReceiptProductResolver] by default in production.
@riverpod
ReceiptProductResolver receiptProductResolver(Ref ref) {
  return YamtReceiptProductResolver(
    matcher: ref.watch(globalFoodItemMatcherProvider),
    searchRepository: ref.watch(offProductSearchRepositoryProvider),
  );
}

/// Provider for [ReceiptStorageGateway].
///
/// Uses [YamtReceiptStorageGateway] by default in production.
@riverpod
ReceiptStorageGateway receiptStorageGateway(Ref ref) {
  return YamtReceiptStorageGateway(
    inventoryItemRepository: ref.watch(inventoryItemRepositoryProvider),
    globalFoodItemRepository: ref.watch(globalFoodItemRepositoryProvider),
    globalFoodReceiptAliasRepository: ref.watch(
      globalFoodReceiptAliasRepositoryProvider,
    ),
  );
}

/// Provider for [ReceiptManualProductPicker].
///
/// Uses [YamtReceiptManualProductPicker] by default in production.
@riverpod
ReceiptManualProductPicker receiptManualProductPicker(Ref ref) {
  return const YamtReceiptManualProductPicker();
}
