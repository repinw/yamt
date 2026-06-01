import 'package:flutter/material.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'models/product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_ai_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_editor_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_entry_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Opens AI from the focused hub search page.
Future<ProductSearchHubEditedResult?> openProductSearchHubSearchAiEntry({
  required BuildContext context,
  required AppLocalizations l10n,
  required ProductSearchHubRouteArgs args,
  required String initialPrompt,
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

/// Opens custom product creation from the focused hub search page.
Future<ProductSearchHubEditedResult?> openProductSearchHubSearchCustomEntry({
  required BuildContext context,
  required AppLocalizations l10n,
  required ProductSearchHubRouteArgs args,
  String initialName = '',
}) async {
  final result = await openProductSearchHubCustomProductEditor(
    context: context,
    draftItem: buildProductSearchHubDraftItem(
      l10n: l10n,
      sourceItem: args.item,
    ),
    args: args,
    initialName: initialName,
  );
  return _editedResult(result);
}

ProductSearchHubEditedResult? _editedResult(
  InventoryReceiptManualProductResult? result,
) {
  if (result == null) {
    return null;
  }
  return ProductSearchHubEditedResult(
    sourceKey: productSearchHubSourceKeyForResult(result),
    result: result,
  );
}
