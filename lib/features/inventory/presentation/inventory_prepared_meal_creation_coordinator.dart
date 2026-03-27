import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/data/local_image_store.dart';
import 'package:yamt/features/inventory/data/prepared_meal_image_refs.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/inventory/provider/'
    'prepared_meal_selection_controller.dart';
import 'package:yamt/features/inventory/provider/prepared_meals_controller.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_creation_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

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

  final creationResult = await ref
      .read(preparedMealsControllerProvider.notifier)
      .createPreparedMeal(
        name: sheetResult.name,
        imageBase64: sheetResult.imageBytes == null
            ? null
            : base64Encode(sheetResult.imageBytes!),
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

  final createdMealId = creationResult.preparedMealId;
  final imageBytes = sheetResult.imageBytes;
  if (createdMealId != null && imageBytes != null) {
    final imageRef = preparedMealImageRef(createdMealId);
    await ref
        .read(localImageStoreProvider)
        .saveBytes(imageRef: imageRef, bytes: imageBytes);
    ref.invalidate(localImageBytesProvider(imageRef));
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
