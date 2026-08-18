import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/calories/application/calorie_entry_delete_flow.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_inventory_create_context.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/presentation/controllers/'
    'calorie_entry_editor_controller.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_editor_draft.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_editor_dialogs.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Coordinator for calorie editor dialogs, delete flows, and navigation.
abstract final class CalorieEntryEditorFlowHandler {
  /// Prompts and executes the return-to-inventory / delete flow.
  static Future<void> returnEntryToInventory(
    BuildContext context, {
    required CalorieEntry entry,
    required CalorieEntryEditorController controller,
    required VoidCallback onDeleted,
  }) async {
    final sourceCanBeRestored = await controller.canRestoreSource(entry);
    if (!context.mounted) {
      return;
    }

    if (sourceCanBeRestored) {
      final restoreDecision =
          await showCalorieEntryReturnToInventoryDialog(
            context,
            entry: entry,
          );
      if (restoreDecision == null || !context.mounted) {
        return;
      }

      await deleteEntryFromDetails(
        context,
        entry: entry,
        controller: controller,
        restoreToInventory: restoreDecision,
        onDeleted: onDeleted,
      );
    } else {
      final confirmed =
          await showCalorieEntryMissingInventorySourceDialog(
            context,
            entry: entry,
          );
      if (confirmed != true || !context.mounted) {
        return;
      }

      await deleteEntryFromDetails(
        context,
        entry: entry,
        controller: controller,
        restoreToInventory: false,
        onDeleted: onDeleted,
      );
    }
  }

  /// Executes delete and handles fallback prompts or snackbar errors.
  static Future<void> deleteEntryFromDetails(
    BuildContext context, {
    required CalorieEntry entry,
    required CalorieEntryEditorController controller,
    required bool restoreToInventory,
    required VoidCallback onDeleted,
  }) async {
    final result = await controller.deleteEntry(
      entry: entry,
      restoreToInventory: restoreToInventory,
    );
    if (!context.mounted) {
      return;
    }

    if (result.isSuccess) {
      onDeleted();
      return;
    }

    if (restoreToInventory &&
        result.failureReason == CalorieEntryDeleteFailureReason.sourceMissing) {
      await _confirmDeleteEntryOnly(
        context,
        entry: entry,
        controller: controller,
        onDeleted: onDeleted,
      );
      return;
    }

    _showDeleteFailureSnackBar(context, entry: entry, result: result);
  }

  static Future<void> _confirmDeleteEntryOnly(
    BuildContext context, {
    required CalorieEntry entry,
    required CalorieEntryEditorController controller,
    required VoidCallback onDeleted,
  }) async {
    final confirmed = await showCalorieEntryMissingInventorySourceDialog(
      context,
      entry: entry,
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    await deleteEntryFromDetails(
      context,
      entry: entry,
      controller: controller,
      restoreToInventory: false,
      onDeleted: onDeleted,
    );
  }

  static void _showDeleteFailureSnackBar(
    BuildContext context, {
    required CalorieEntry entry,
    required CalorieEntryDeleteResult result,
  }) {
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    final l10n = AppLocalizations.of(context)!;
    final message = switch (result.failureReason) {
      CalorieEntryDeleteFailureReason.restoreFailed =>
        entry.canReturnPreparedMealToInventory
            ? l10n.caloriesReturnPreparedMealFailed
            : l10n.caloriesDeleteRestoreFailed,
      CalorieEntryDeleteFailureReason.sourceMissing =>
        l10n.caloriesDeleteFailed,
      CalorieEntryDeleteFailureReason.deleteFailed ||
      null => l10n.caloriesDeleteFailed,
    };
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  /// Handles popping with root fallback.
  static void maybePopRootNavigator(
    BuildContext context, {
    required bool isEditing,
    Object? result,
  }) {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    if (rootNavigator.canPop()) {
      rootNavigator.pop(result);
      return;
    }

    final localNavigator = Navigator.of(context);
    if (!identical(localNavigator, rootNavigator) && localNavigator.canPop()) {
      localNavigator.pop(result);
      return;
    }

    final fallbackCloseRoute =
        !isEditing ? AppRoutes.homeInventory : AppRoutes.homeCalories;
    GoRouter.of(context).go(fallbackCloseRoute);
  }

  /// Displays error snackbar.
  static void showFailureSnackBar(
    ScaffoldMessengerState messenger,
    String message,
  ) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Prompts user before closing if details has unsaved changes.
  static Future<void> requestCloseExistingEntry(
    BuildContext context, {
    required CalorieEntry entry,
    required bool hasPendingChanges,
    required bool isSaving,
    required VoidCallback onDismissConfirmed,
  }) async {
    if (isSaving) {
      return;
    }
    if (!hasPendingChanges) {
      maybePopRootNavigator(context, isEditing: true);
      return;
    }

    final shouldDiscard = await showCalorieEntryDiscardChangesDialog(context);
    if (shouldDiscard != true || !context.mounted) {
      return;
    }

    onDismissConfirmed();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) {
        return;
      }
      maybePopRootNavigator(context, isEditing: true);
    });
  }

  /// Validates, builds and saves a new or edited entry.
  static Future<void> saveNewEntry(
    BuildContext context, {
    required CalorieEntryEditorDraft draft,
    required String userId,
    required CalorieEntryEditorController controller,
    required CalorieProductProfile? prefilledProfile,
    required CalorieInventoryCreateContext? inventoryContext,
    required CalorieScannedSourceRef? scannedSourceRef,
    required CalorieEntry? initialEntry,
    required VoidCallback onCommitted,
  }) async {
    final formState = draft.formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final parsedDraft = draft.tryParse();
    if (parsedDraft == null) {
      final l10n = AppLocalizations.of(context)!;
      showFailureSnackBar(
        ScaffoldMessenger.of(context),
        l10n.caloriesInvalidNumber,
      );
      return;
    }

    final entry = draft.buildEntry(
      id: const Uuid().v4(),
      userId: userId,
      parsedDraft: parsedDraft,
      imageUrl: prefilledProfile?.imageUrl,
      sourceInventoryItemId: inventoryContext?.inventoryItemId,
      sourceInventoryAmountToRestore:
          inventoryContext?.inventoryAmountToRestore,
      initialEntry: initialEntry,
    );

    final saved = await controller.saveEntry(
      entry: entry,
      inventoryContext: inventoryContext,
      scannedSourceRef: scannedSourceRef,
      pendingConsumptionId: inventoryContext?.pendingConsumptionId,
      isEditing: initialEntry != null,
    );
    if (!context.mounted) {
      return;
    }

    if (saved) {
      onCommitted();
      maybePopRootNavigator(
        context,
        isEditing: initialEntry != null,
        result: true,
      );
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    showFailureSnackBar(
      ScaffoldMessenger.of(context),
      l10n.caloriesSaveFailed,
    );
  }

  /// Updates and saves an existing entry.
  static Future<void> saveExistingEntry(
    BuildContext context, {
    required CalorieEntryEditorDraft draft,
    required CalorieEntry entry,
    required CalorieEntryEditorController controller,
  }) async {
    if (draft.mealType == entry.mealType &&
        draft.loggedAt == entry.loggedAt) {
      return;
    }

    final updatedAt = DateTime.now();
    final updatedEntry = entry
        .copyWith(
          mealType: draft.mealType,
          loggedAt: draft.loggedAt,
          updatedAt: updatedAt,
        )
        .recalculateTotals(updatedAt: updatedAt);

    final saved = await controller.saveEntry(
      entry: updatedEntry,
      isEditing: true,
    );
    if (!context.mounted) {
      return;
    }

    if (saved) {
      maybePopRootNavigator(
        context,
        isEditing: true,
        result: true,
      );
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    showFailureSnackBar(
      ScaffoldMessenger.of(context),
      l10n.caloriesSaveFailed,
    );
  }
}
