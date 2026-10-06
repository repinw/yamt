import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_edits.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_inventory_stock_adjustment.dart';
import 'package:yamt/features/calories/presentation/controllers/'
    'calorie_entry_editor_controller.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_editor_flow_handler.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Changes of a logged entry from its details page. Each one saves at once
/// and offers an undo in a snack bar.
///
/// The flow uses the keep-alive editor controller of the page's container.
/// Undo callbacks may run after the page closed, so they never use the
/// page's `ref` or `context`. Entries logged from the inventory move their
/// stock with a changed amount.
abstract final class CalorieEntryDetailsFlow {
  /// Saves [updated] in place of [previous]. Returns whether it saved.
  ///
  /// [onUndone] runs after the undo restored [previous].
  static Future<bool> saveChange(
    BuildContext context, {
    required CalorieEntry previous,
    required CalorieEntry updated,
    required VoidCallback onUndone,
  }) async {
    final controller = _controller(context);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final saved = await controller.saveEntry(entry: updated, isEditing: true);
    if (!context.mounted) {
      return saved;
    }
    _showResult(
      messenger,
      succeeded: saved,
      successMessage: l10n.caloriesEntryUpdatedMessage,
      failureMessage: l10n.caloriesSaveFailed,
      onUndo: () async {
        final restored = await controller.saveEntry(
          entry: previous,
          isEditing: true,
        );
        if (restored) {
          onUndone();
        }
        return restored;
      },
    );
    return saved;
  }

  /// Changes the consumed amount of [entry] to [amount]. Returns whether it
  /// saved.
  ///
  /// The snackbar reports how far the inventory stock could follow, and the
  /// undo puts both the entry and the stock back.
  static Future<bool> changeAmount(
    BuildContext context, {
    required CalorieEntry entry,
    required double amount,
    required VoidCallback onUndone,
  }) async {
    final controller = _controller(context);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final result = await controller.changeAmount(entry: entry, amount: amount);
    if (!context.mounted) {
      return result.saved;
    }
    _showResult(
      messenger,
      succeeded: result.saved,
      successMessage: _amountChangeMessage(l10n, result.status),
      failureMessage: l10n.caloriesSaveFailed,
      onUndo: () async {
        final undo = await controller.changeAmount(
          entry: result.entry,
          amount: entry.consumedAmount,
        );
        if (undo.saved) {
          onUndone();
        }
        return undo.saved;
      },
    );
    return result.saved;
  }

  /// Logs the food of [entry] again as a new entry at the current time and
  /// closes the page.
  static Future<void> eatAgain(
    BuildContext context, {
    required CalorieEntry entry,
  }) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final controller = _controller(context);
    final repeated = repeatCalorieEntry(
      entry,
      id: const Uuid().v4(),
      now: container.read(clockProvider)(),
    );
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final saved = await controller.saveEntry(entry: repeated);
    if (!context.mounted) {
      return;
    }
    if (saved) {
      CalorieEntryEditorFlowHandler.maybePopRootNavigator(context);
    }
    _showResult(
      messenger,
      succeeded: saved,
      successMessage: l10n.caloriesEatAgainDoneMessage,
      failureMessage: l10n.caloriesSaveFailed,
      onUndo: () => controller.deleteEntry(repeated),
    );
  }

  static CalorieEntryEditorController _controller(BuildContext context) {
    return ProviderScope.containerOf(
      context,
      listen: false,
    ).read(calorieEntryEditorControllerProvider.notifier);
  }

  static String _amountChangeMessage(
    AppLocalizations l10n,
    CalorieInventoryStockAdjustmentStatus status,
  ) {
    return switch (status) {
      CalorieInventoryStockAdjustmentStatus.stockExhausted =>
        l10n.caloriesEntryAmountStockExhaustedMessage,
      CalorieInventoryStockAdjustmentStatus.sourceMissing =>
        l10n.caloriesEntryAmountSourceMissingMessage,
      CalorieInventoryStockAdjustmentStatus.applied ||
      CalorieInventoryStockAdjustmentStatus.stockUnchanged =>
        l10n.caloriesEntryUpdatedMessage,
    };
  }

  static void _showResult(
    ScaffoldMessengerState messenger, {
    required bool succeeded,
    required String successMessage,
    required String failureMessage,
    required Future<bool> Function() onUndo,
  }) {
    if (!succeeded) {
      messenger.showAppSnackBar(failureMessage, tone: AppSnackBarTone.error);
      return;
    }
    messenger.showAppSnackBar(successMessage, onUndo: onUndo);
  }
}
