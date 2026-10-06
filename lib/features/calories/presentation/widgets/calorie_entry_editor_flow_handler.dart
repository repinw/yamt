import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_delete_result.dart';
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
      final restoreDecision = await showCalorieEntryReturnToInventoryDialog(
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
  }

  /// Executes delete and handles fallback prompts or snackbar errors.
  static Future<void> deleteEntryFromDetails(
    BuildContext context, {
    required CalorieEntry entry,
    required CalorieEntryEditorController controller,
    required bool restoreToInventory,
    required VoidCallback onDeleted,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final result = await controller.deleteEntry(
      entry: entry,
      restoreToInventory: restoreToInventory,
    );
    if (!context.mounted) {
      return;
    }

    if (result.isSuccess) {
      onDeleted();
      messenger.showAppSnackBar(
        result.restoredToInventory
            ? l10n.caloriesEntryReturnedToInventoryMessage
            : l10n.caloriesEntryDeletedMessage,
        onUndo: () => controller.undoDelete(
          entry,
          restoredToInventory: result.restoredToInventory,
        ),
      );
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
    messenger.showAppSnackBar(message, tone: AppSnackBarTone.error);
  }

  /// Handles popping with root fallback.
  static void maybePopRootNavigator(BuildContext context) {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    if (rootNavigator.canPop()) {
      rootNavigator.pop();
      return;
    }

    final localNavigator = Navigator.of(context);
    if (!identical(localNavigator, rootNavigator) && localNavigator.canPop()) {
      localNavigator.pop();
      return;
    }

    GoRouter.of(context).go(AppRoutes.homeCalories);
  }

  /// Displays error snackbar.
  static void showFailureSnackBar(
    ScaffoldMessengerState messenger,
    String message,
  ) {
    messenger.showAppSnackBar(message, tone: AppSnackBarTone.error);
  }

  /// Validates and builds a new entry and closes the editor with it. The
  /// caller saves the entry.
  static void returnNewEntry(
    BuildContext context, {
    required CalorieEntryEditorDraft draft,
    required String userId,
    required CalorieProductProfile? prefilledProfile,
  }) {
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
      nutrientDetails: prefilledProfile?.nutrientDetails,
    );
    Navigator.of(context).pop(entry);
  }
}
