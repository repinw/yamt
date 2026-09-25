import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_page_route.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_page_types.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_route_args.dart';

/// Opens the nested product editor for [product].
Future<void> openSelectedProductEditor({
  required BuildContext context,
  required InventoryManualAddQuickEatConfig quickEatConfig,
  required InventoryReceiptManualProductConfig parentConfig,
  required OffProductSearchResult product,
  required InventoryReceiptManualProductAction action,
  required bool showEatImmediatelyOption,
  required bool showActionSelector,
  required Future<void> Function(InventoryReceiptManualProductResult)? onSaved,
  required void Function(InventoryReceiptManualProductResult) onClosePage,
  String? initialInfoMessage,
}) async {
  final config = InventoryReceiptManualProductConfig(
    item: parentConfig.item,
    selectedProduct: product,
    includeStoreInSearch: parentConfig.includeStoreInSearch,
    includeWeightInSearch: parentConfig.includeWeightInSearch,
  );
  final result =
      await pushManualProductSearchPage<InventoryReceiptManualProductResult>(
        context: context,
        args: ManualProductSearchRouteArgs.editor(
          config: config,
          showEatImmediatelyOption: showEatImmediatelyOption,
          initialAction: action,
          closeCurrentEditorOnSave: true,
          showActionSelector: showActionSelector,
          initialInfoMessage: initialInfoMessage,
          quickEatConfig: quickEatConfig,
        ),
      );
  if (!context.mounted || result == null) {
    return;
  }

  if (onSaved != null) {
    await onSaved(result);
    return;
  }
  onClosePage(result);
}
