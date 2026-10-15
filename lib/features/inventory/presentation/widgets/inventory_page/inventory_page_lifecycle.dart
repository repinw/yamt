import 'dart:developer' as developer;

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/application/inventory_combined_eat_service.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meal_selection_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_item_hub_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

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

/// Opens the item hub of the selected food whose eat page started the
/// selection, else of the first one that can be combined, with the other
/// selected foods already in its meal. From there the user logs the meal or
/// keeps it in the Vorrat.
Future<void> _openSelectionAsMeal({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final items = ref.read(inventoryItemsControllerProvider).value;
  final selection = ref.read(preparedMealSelectionControllerProvider);
  final selected = [
    for (final item in items ?? const <InventoryItem>[])
      if (selection.selectedItemIds.contains(item.id)) item,
  ];
  final combinable = selected
      .where(InventoryCombinedEatService.canCombine)
      .toList();
  if (combinable.length < selected.length) {
    // Foods without nutrition values cannot be added up into a meal.
    ScaffoldMessenger.of(context).showAppSnackBar(
      AppLocalizations.of(context)!.eatPageCombineNeedsNutrition,
      tone: AppSnackBarTone.error,
    );
  }
  final hubItem =
      combinable.firstWhereOrNull(
        (item) => item.id == selection.anchorItemId,
      ) ??
      combinable.firstOrNull;
  if (hubItem == null) {
    // Kept, so the catalog foods and their amounts are not lost.
    return;
  }
  ref.read(preparedMealSelectionControllerProvider.notifier).clearSelection();
  await InventoryItemHubFlow.open(
    context: context,
    ref: ref,
    item: hubItem,
    initialPicks: [
      for (final item in combinable)
        if (item.id != hubItem.id) item,
    ],
    initialFoods: selection.catalogFoods,
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
