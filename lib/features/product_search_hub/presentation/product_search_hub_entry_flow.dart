import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/utils/barcode_utils.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart'
    as inventory_models;
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_ai_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_editor_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Edited product entry result with stable source key.
class ProductSearchHubEditedResult {
  /// Creates edited result.
  const new({required this.sourceKey, required this.result});

  /// Key used for duplicate prevention.
  final String sourceKey;

  /// Edited product result.
  final inventory_models.InventoryReceiptManualProductResult result;
}

/// Opens AI entry flow.
Future<ProductSearchHubEditedResult?> openProductSearchHubAiEntry({
  required BuildContext context,
  required AppLocalizations l10n,
  required ProductSearchHubRouteArgs args,
  String initialPrompt = '',
}) async {
  final result = await openProductSearchHubAiFlow(
    context: context,
    draftItem: buildProductSearchHubDraftItem(
      l10n: l10n,
      sourceItem: args.item,
    ),
    args: args,
    initialPrompt: initialPrompt,
  );
  return _editedResult(result);
}

/// Opens custom product entry flow.
Future<ProductSearchHubEditedResult?> openProductSearchHubCustomEntry({
  required BuildContext context,
  required AppLocalizations l10n,
  required ProductSearchHubRouteArgs args,
  String initialName = '',
}) async {
  final normalized = normalizeBarcode(initialName);
  final isBarcode = normalized.isNotEmpty && isSupportedBarcode(normalized);
  final result = await openProductSearchHubCustomProductEditor(
    context: context,
    draftItem: buildProductSearchHubDraftItem(
      l10n: l10n,
      sourceItem: args.item,
    ),
    args: args,
    scannedBarcode: isBarcode ? normalized : null,
    initialName: isBarcode ? '' : initialName,
  );
  return _editedResult(result);
}

ProductSearchHubEditedResult? _editedResult(
  inventory_models.InventoryReceiptManualProductResult? result,
) {
  if (result == null) {
    return null;
  }
  return ProductSearchHubEditedResult(
    sourceKey: productSearchHubSourceKeyForResult(result),
    result: result,
  );
}

/// Resolves duplicate-prevention key from edited result.
String productSearchHubSourceKeyForResult(
  inventory_models.InventoryReceiptManualProductResult result,
) {
  final barcode = result.item.normalizedBarcode;
  if (barcode != null && barcode.isNotEmpty) {
    return barcode;
  }
  return 'manual-${result.item.id}';
}
