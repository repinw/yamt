import 'dart:developer' as developer;

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/application/inventory_combined_eat_service.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meal_selection_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_item_hub_flow.dart';

/// Handles prepared-meal selection completion for the inventory page.
Future<void> handleInventoryPageSelectionConfirmed({
  required BuildContext context,
  required WidgetRef ref,
  required int? previous,
  required int next,
}) async {
  if (previous == next || next < 1) {
    return;
  }
  await _openSelectionAsMeal(context: context, ref: ref);
}

/// Opens the item hub of the first selected food that can be combined, with
/// the other selected foods already in its meal. From there the user logs
/// the meal or keeps it in the Vorrat.
Future<void> _openSelectionAsMeal({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final items = ref.read(inventoryItemsControllerProvider).value;
  final selectedIds = ref
      .read(preparedMealSelectionControllerProvider)
      .selectedItemIds;
  ref.read(preparedMealSelectionControllerProvider.notifier).clearSelection();
  final selected = [
    for (final item in items ?? const <InventoryItem>[])
      if (selectedIds.contains(item.id)) item,
  ];
  final hubItem = selected.firstWhereOrNull(
    InventoryCombinedEatService.canCombine,
  );
  if (hubItem == null || !context.mounted) {
    return;
  }
  await InventoryItemHubFlow.open(
    context: context,
    ref: ref,
    item: hubItem,
    initialPicks: [
      for (final item in selected)
        if (item.id != hubItem.id) item,
    ],
  );
}

/// Logs each new inventory loading error once.
void logInventoryPageLoadError(
  AsyncValue<List<InventoryItem>>? previous,
  AsyncValue<List<InventoryItem>> next,
) {
  final nextError = next.asError;
  final prevError = previous?.asError;
  if (nextError == null ||
      (identical(prevError?.error, nextError.error) &&
          prevError?.stackTrace == nextError.stackTrace)) {
    return;
  }

  developer.log(
    'Failed to load inventory items.',
    name: 'InventoryPage',
    error: nextError.error,
    stackTrace: nextError.stackTrace,
  );
}
