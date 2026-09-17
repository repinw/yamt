import 'dart:developer' as developer;

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meal_selection_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_item_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_prepared_meal_creation_coordinator.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_prepared_meal_edit_coordinator.dart';

/// Handles prepared-meal selection completion for the inventory page.
Future<void> handleInventoryPageSelectionConfirmed({
  required BuildContext context,
  required WidgetRef ref,
  required InventoryPreparedMealEditCoordinator mealEditCoordinator,
  required int? previous,
  required int next,
}) async {
  if (previous == next || next < 1) {
    return;
  }
  final selectionState = ref.read(preparedMealSelectionControllerProvider);
  if (selectionState.isAddingIngredientsToMeal) {
    await mealEditCoordinator.continueWithSelectedIngredients(
      context: context,
      ref: ref,
      selectionState: selectionState,
    );
    return;
  }
  await runPreparedMealCreationFlow(context: context, ref: ref);
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

/// Starts an inventory item eat flow from the current page snapshot.
Future<bool> eatInventoryPageItem({
  required BuildContext context,
  required WidgetRef ref,
  required String itemId,
  required InventoryItemEatRequest request,
  required List<InventoryItem> itemsSnapshot,
}) async {
  final selectedItem = itemsSnapshot.firstWhereOrNull(
    (item) => item.id == itemId,
  );
  if (selectedItem == null) {
    return false;
  }

  return await InventoryItemEatFlow.stageAndComplete(
    context: context,
    container: ref.container,
    item: selectedItem,
    request: request,
  );
}
