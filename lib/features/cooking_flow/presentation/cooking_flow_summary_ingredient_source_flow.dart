import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_amount_utils.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_summary_builder.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_summary_models.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_summary_page.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/inventory_manual_add_page.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';

/// Resolves an add-ingredient source into a summary ingredient draft.
@Dependencies([InventoryItemsController])
Future<CookingFlowSummaryIngredientDraft?>
resolveCookingFlowSummaryIngredientSource({
  required BuildContext context,
  required ProviderContainer container,
  required CookingFlowSummaryIngredientAddSource source,
  required List<CookingFlowSummaryIngredientDraft> currentIngredients,
  required Future<bool> Function() saveSession,
  String? adjustment,
}) async {
  final localeCode = Localizations.localeOf(context).languageCode;
  return switch (source) {
    CookingFlowSummaryIngredientAddSource.inventory =>
      _pickSummaryInventoryIngredient(
        context: context,
        container: container,
        currentIngredients: currentIngredients,
        adjustment: adjustment,
        localeCode: localeCode,
      ),
    CookingFlowSummaryIngredientAddSource.barcode ||
    CookingFlowSummaryIngredientAddSource.manualSearch ||
    CookingFlowSummaryIngredientAddSource.ai => _openSummaryManualAddSource(
      context: context,
      container: container,
      source: source,
      currentIngredients: currentIngredients,
      saveSession: saveSession,
      adjustment: adjustment,
      localeCode: localeCode,
    ),
  };
}

@Dependencies([InventoryItemsController])
Future<CookingFlowSummaryIngredientDraft?> _pickSummaryInventoryIngredient({
  required BuildContext context,
  required ProviderContainer container,
  required List<CookingFlowSummaryIngredientDraft> currentIngredients,
  required String? adjustment,
  required String localeCode,
}) async {
  final inventoryItems = await container.read(
    inventoryItemsControllerProvider.future,
  );
  if (!context.mounted) {
    return null;
  }
  final item = await showCookingFlowSummaryInventoryIngredientPicker(
    context: context,
    inventoryItems: inventoryItems
        .where(_canUseSummaryInventoryItem)
        .toList(growable: false),
  );
  if (!context.mounted || item == null) {
    return null;
  }
  return _summaryIngredientDraftForItem(
    item: item,
    key: _nextSummaryIngredientKey(
      item: item,
      currentIngredients: currentIngredients,
    ),
    adjustment: adjustment,
    localeCode: localeCode,
  );
}

@Dependencies([InventoryItemsController])
Future<CookingFlowSummaryIngredientDraft?> _openSummaryManualAddSource({
  required BuildContext context,
  required ProviderContainer container,
  required CookingFlowSummaryIngredientAddSource source,
  required List<CookingFlowSummaryIngredientDraft> currentIngredients,
  required Future<bool> Function() saveSession,
  required String? adjustment,
  required String localeCode,
}) async {
  final beforeItemIds = _currentInventoryItemIds(container);
  final saved = await saveSession();
  if (!context.mounted || !saved) {
    return null;
  }

  await context.push<void>(
    AppRoutes.homeInventoryManualAdd,
    extra: InventoryManualAddRouteArgs(
      initialAction: _manualAddActionForSummarySource(source),
    ),
  );
  if (!context.mounted) {
    return null;
  }

  final inventoryItems = await _loadInventoryItems(container);
  if (!context.mounted) {
    return null;
  }
  final newItem = _newSummaryInventoryItem(
    beforeItemIds: beforeItemIds,
    inventoryItems: inventoryItems,
  );
  if (newItem == null) {
    return null;
  }
  return _summaryIngredientDraftForItem(
    item: newItem,
    key: _nextSummaryIngredientKey(
      item: newItem,
      currentIngredients: currentIngredients,
    ),
    adjustment: adjustment,
    localeCode: localeCode,
  );
}

@Dependencies([InventoryItemsController])
Set<String> _currentInventoryItemIds(ProviderContainer container) {
  final inventoryItems = container
      .read(inventoryItemsControllerProvider)
      .asData
      ?.value;
  return (inventoryItems ?? const <InventoryItem>[])
      .map((item) => item.id)
      .toSet();
}

@Dependencies([InventoryItemsController])
Future<List<InventoryItem>> _loadInventoryItems(
  ProviderContainer container,
) async {
  final currentItems = container
      .read(inventoryItemsControllerProvider)
      .asData
      ?.value;
  if (currentItems != null) {
    return currentItems;
  }
  return container.read(inventoryItemsControllerProvider.future);
}

InventoryItem? _newSummaryInventoryItem({
  required Set<String> beforeItemIds,
  required List<InventoryItem> inventoryItems,
}) {
  InventoryItem? newestItem;
  for (final item in inventoryItems) {
    if (beforeItemIds.contains(item.id) || !_canUseSummaryInventoryItem(item)) {
      continue;
    }
    if (newestItem == null || item.entryDate.isAfter(newestItem.entryDate)) {
      newestItem = item;
    }
  }
  return newestItem;
}

CookingFlowSummaryIngredientDraft _summaryIngredientDraftForItem({
  required InventoryItem item,
  required String key,
  required String localeCode,
  String? adjustment,
}) {
  return CookingFlowSummaryIngredientDraft(
    key: key,
    name: item.name,
    amount:
        _summaryAmountFromAdjustment(
          item: item,
          adjustment: adjustment,
          localeCode: localeCode,
        ) ??
        defaultCookingFlowSummaryAmountForItem(item).toString(),
    unitCode: cookingFlowSummaryUnitCodeForItem(item),
    inventoryItemIds: <String>[item.id],
    kind: CookingFlowSummaryIngredientKind.additional,
  );
}

String? _summaryAmountFromAdjustment({
  required InventoryItem item,
  required String? adjustment,
  required String localeCode,
}) {
  if (adjustment == null) {
    return null;
  }
  final parsedIngredient = parseCookingFlowIngredient(
    adjustment,
    localeCode: localeCode,
  );
  if (parsedIngredient == null) {
    return null;
  }
  final requirement = parseCookingFlowIngredientRequirement(
    parsedIngredient.amountLabel,
    localeCode: localeCode,
  );
  if (requirement == null) {
    return null;
  }
  final itemUnitCode = cookingFlowSummaryUnitCodeForItem(item);
  if (itemUnitCode != requirement.unitCode) {
    return null;
  }
  return formatCookingFlowDecimal(requirement.amount);
}

bool _canUseSummaryInventoryItem(InventoryItem item) {
  if (item.usesAmountProgress) {
    return item.amountUnit != null && item.currentAmount > 0;
  }
  return item.quantity > 0;
}

String _nextSummaryIngredientKey({
  required InventoryItem item,
  required List<CookingFlowSummaryIngredientDraft> currentIngredients,
}) {
  final baseKey = 'additional:${item.id}';
  final existingKeys = currentIngredients
      .map((ingredient) => ingredient.key)
      .toSet();
  if (!existingKeys.contains(baseKey)) {
    return baseKey;
  }

  var suffix = 2;
  while (existingKeys.contains('$baseKey:$suffix')) {
    suffix += 1;
  }
  return '$baseKey:$suffix';
}

InventoryManualAddInitialAction _manualAddActionForSummarySource(
  CookingFlowSummaryIngredientAddSource source,
) {
  return switch (source) {
    CookingFlowSummaryIngredientAddSource.inventory =>
      InventoryManualAddInitialAction.launcher,
    CookingFlowSummaryIngredientAddSource.barcode =>
      InventoryManualAddInitialAction.barcodeScan,
    CookingFlowSummaryIngredientAddSource.manualSearch =>
      InventoryManualAddInitialAction.manualSearch,
    CookingFlowSummaryIngredientAddSource.ai =>
      InventoryManualAddInitialAction.aiSuggestion,
  };
}
