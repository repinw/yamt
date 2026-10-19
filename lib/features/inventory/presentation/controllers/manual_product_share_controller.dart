import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/application/'
    'manual_product_catalog_service.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';

part 'manual_product_share_controller.g.dart';

/// Shares a manually saved product with other users in the background.
@riverpod
class ManualProductShareController extends _$ManualProductShareController {
  @override
  FutureOr<void> build() {}

  /// Writes [product] to the shared catalog, see
  /// [ManualProductCatalogService.share].
  ///
  /// Only once the catalog has the product, the Vorrat item [pendingItem]
  /// points at it through [InventoryItemsController.linkToCatalog] (#806).
  /// A failed write is logged, and the item keeps its pending id.
  /// The caller keeps the Vorrat controller alive until this completes. The
  /// diary entry or plan of the same save keeps its pending id.
  Future<void> share({
    required GlobalFoodItem product,
    required bool append,
    required String? barcode,
    required DateTime selectedAt,
    InventoryItem? pendingItem,
  }) async {
    final keepAlive = ref.keepAlive();
    try {
      await ref
          .read(manualProductCatalogServiceProvider)
          .share(
            product: product,
            append: append,
            barcode: barcode,
            selectedAt: selectedAt,
          );
      if (!ref.mounted) return;
      if (pendingItem != null) {
        await ref
            .read(inventoryItemsControllerProvider.notifier)
            .linkToCatalog(pendingItem, product.id);
      }
    } on Object catch (error, stackTrace) {
      log(
        'Failed to share global product ${product.id}.',
        name: 'ManualProductShareController',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      keepAlive.close();
    }
  }
}
