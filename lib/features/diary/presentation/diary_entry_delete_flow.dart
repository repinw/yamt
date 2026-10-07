import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_delete_result.dart';
import 'package:yamt/features/diary/presentation/controllers/'
    'diary_entry_change_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_entry_delete_dialogs.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Removes a diary entry from its details page and offers an undo.
///
/// The undo may run after the page closed, so it reads the controller from
/// the page's container, never through the page's `context`.
abstract final class DiaryEntryDeleteFlow {
  /// Removes [entry] and closes the page. An entry that took stock asks
  /// first whether the stock goes back to the Vorrat.
  static Future<void> remove(
    BuildContext context, {
    required CalorieEntry entry,
  }) async {
    if (!entry.canRestoreToInventory &&
        !entry.canReturnPreparedMealToInventory &&
        !entry.canReturnCombinedToInventory) {
      await _delete(context, entry: entry, restoreToInventory: false);
      return;
    }
    final canRestore = await _controller(
      ProviderScope.containerOf(context, listen: false),
    ).canRestoreSource(entry);
    if (!context.mounted) {
      return;
    }
    final restore = canRestore
        ? await showDiaryEntryReturnToInventoryDialog(context, entry: entry)
        : await _confirmWithoutSource(context, entry);
    if (restore == null || !context.mounted) {
      return;
    }
    await _delete(context, entry: entry, restoreToInventory: restore);
  }

  /// Asks to remove [entry] without its stock source. Returns false (remove
  /// only the entry) on yes and null on cancel.
  static Future<bool?> _confirmWithoutSource(
    BuildContext context,
    CalorieEntry entry,
  ) async {
    final confirmed = await showDiaryEntryMissingInventorySourceDialog(
      context,
      entry: entry,
    );
    return confirmed == true ? false : null;
  }

  static Future<void> _delete(
    BuildContext context, {
    required CalorieEntry entry,
    required bool restoreToInventory,
  }) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final result = await _controller(container)
        .delete(entry, restoreToInventory: restoreToInventory);
    if (!context.mounted) {
      return;
    }
    if (result.isSuccess) {
      context.pop();
      messenger.showAppSnackBar(
        result.restoredToInventory
            ? l10n.caloriesEntryReturnedToInventoryMessage
            : l10n.caloriesEntryDeletedMessage,
        // Read again: the controller of the delete may be gone by now.
        onUndo: () => _controller(container)
            .undoDelete(entry, restoredToInventory: result.restoredToInventory),
      );
      return;
    }
    if (restoreToInventory &&
        result.failureReason == CalorieEntryDeleteFailureReason.sourceMissing) {
      final restore = await _confirmWithoutSource(context, entry);
      if (restore == null || !context.mounted) {
        return;
      }
      await _delete(context, entry: entry, restoreToInventory: false);
      return;
    }
    messenger.showAppSnackBar(switch (result.failureReason) {
      CalorieEntryDeleteFailureReason.restoreFailed =>
        entry.canReturnPreparedMealToInventory
            ? l10n.caloriesReturnPreparedMealFailed
            : l10n.caloriesDeleteRestoreFailed,
      CalorieEntryDeleteFailureReason.sourceMissing ||
      CalorieEntryDeleteFailureReason.deleteFailed ||
      null => l10n.caloriesDeleteFailed,
    }, tone: AppSnackBarTone.error);
  }

  static DiaryEntryChangeController _controller(ProviderContainer container) {
    return container.read(diaryEntryChangeControllerProvider.notifier);
  }
}
