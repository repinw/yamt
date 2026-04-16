import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_creation_sheet.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/inventory/provider/'
    'prepared_meal_selection_controller.dart';
import 'package:yamt/features/inventory/provider/prepared_meals_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _preparedMealImageAssetUuid = Uuid();

/// Run prepared meal creation flow.
@Dependencies([InventoryItemsController, PreparedMealsController])
Future<void> runPreparedMealCreationFlow({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final items = ref.read(inventoryItemsControllerProvider).asData?.value;
  if (items == null || !context.mounted) {
    return;
  }

  final selectionState = ref.read(preparedMealSelectionControllerProvider);
  final selectedItems = items
      .where((item) => selectionState.selectedItemIds.contains(item.id))
      .toList(growable: false);
  if (selectedItems.length < 2) {
    return;
  }

  final sheetResult = await showPreparedMealCreationSheet(
    context: context,
    items: selectedItems,
  );
  if (!context.mounted || sheetResult == null) {
    return;
  }

  final imageBytes = sheetResult.imageBytes;
  final imageAssetId = imageBytes == null
      ? null
      : _preparedMealImageAssetUuid.v4();
  if (imageAssetId != null && imageBytes != null) {
    final imageRef = localImageAssetRef(imageAssetId);
    await ref
        .read(localImageStoreProvider)
        .saveBytes(imageRef: imageRef, bytes: imageBytes);
    ref.invalidate(localImageBytesProvider(imageRef));
  }

  final creationResult = await ref
      .read(preparedMealsControllerProvider.notifier)
      .createPreparedMeal(
        name: sheetResult.name,
        imageAssetId: imageAssetId,
        totalPortions: sheetResult.totalPortions,
        items: sheetResult.items,
      );
  if (!context.mounted) {
    return;
  }

  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(content: Text(_creationFeedbackMessage(l10n, creationResult))),
  );

  if (!creationResult.isSuccess) {
    return;
  }

  ref.read(preparedMealSelectionControllerProvider.notifier).clearSelection();
}

String _creationFeedbackMessage(
  AppLocalizations l10n,
  PreparedMealCreationResult result,
) {
  if (result.isSuccess) {
    return l10n.preparedMealCreatedMessage;
  }

  return switch (result.failureReason) {
    PreparedMealCreationFailureReason.insufficientAmount =>
      l10n.preparedMealInsufficientAmountMessage,
    PreparedMealCreationFailureReason.missingNutrition =>
      l10n.preparedMealMissingNutritionMessage,
    PreparedMealCreationFailureReason.itemUnavailable =>
      l10n.preparedMealItemUnavailableMessage,
    PreparedMealCreationFailureReason.invalidInput ||
    PreparedMealCreationFailureReason.inventorySaveFailed ||
    PreparedMealCreationFailureReason.mealSaveFailed ||
    null => l10n.preparedMealActionFailed,
  };
}
