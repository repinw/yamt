import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_edits.dart';
import 'package:yamt/features/diary/presentation/controllers/'
    'diary_entry_change_controller.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_entry_amount_service.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Changes of a logged entry from its details page. Each one saves at once
/// and offers an undo in a snack bar.
///
/// Undo callbacks may run after the page closed, so they read the
/// controller from the page's container, never through the page's `ref` or
/// `context`. Entries logged from the Vorrat move their stock with a
/// changed amount.
abstract final class DiaryEntryDetailsFlow {
  /// Saves [updated] in place of [previous]. Returns whether it saved.
  ///
  /// [onUndone] runs after the undo restored [previous].
  static Future<bool> saveChange(
    BuildContext context, {
    required CalorieEntry previous,
    required CalorieEntry updated,
    required VoidCallback onUndone,
  }) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final saved = await _controller(container)
        .save(updated, previousDay: previous.loggedAt);
    if (!context.mounted) {
      return saved;
    }
    _showResult(
      messenger,
      succeeded: saved,
      successMessage: l10n.caloriesEntryUpdatedMessage,
      failureMessage: l10n.caloriesSaveFailed,
      onUndo: () async {
        final restored = await _controller(container)
            .save(previous, previousDay: updated.loggedAt);
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
  /// The snackbar reports how far the Vorrat stock could follow, and the
  /// undo puts both the entry and the stock back.
  static Future<bool> changeAmount(
    BuildContext context, {
    required CalorieEntry entry,
    required double amount,
    required VoidCallback onUndone,
  }) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final result = await _controller(container).changeAmount(entry, amount);
    if (!context.mounted) {
      return result.saved;
    }
    _showResult(
      messenger,
      succeeded: result.saved,
      successMessage: _amountChangeMessage(l10n, result.stock),
      failureMessage: l10n.caloriesSaveFailed,
      onUndo: () async {
        final undo = await _controller(container)
            .changeAmount(result.entry, entry.consumedAmount);
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
    final repeated = repeatCalorieEntry(
      entry,
      id: const Uuid().v4(),
      now: container.read(clockProvider)(),
    );
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final saved = await _controller(container).save(repeated, isNew: true);
    if (!context.mounted) {
      return;
    }
    if (saved) {
      context.pop();
    }
    _showResult(
      messenger,
      succeeded: saved,
      successMessage: l10n.caloriesEatAgainDoneMessage,
      failureMessage: l10n.caloriesSaveFailed,
      onUndo: () async => (await _controller(
        container,
      ).delete(repeated, restoreToInventory: false)).isSuccess,
    );
  }

  static DiaryEntryChangeController _controller(ProviderContainer container) {
    return container.read(diaryEntryChangeControllerProvider.notifier);
  }

  static String _amountChangeMessage(
    AppLocalizations l10n,
    InventoryEntryStockChange stock,
  ) {
    return switch (stock) {
      InventoryEntryStockChange.stockExhausted =>
        l10n.caloriesEntryAmountStockExhaustedMessage,
      InventoryEntryStockChange.sourceMissing =>
        l10n.caloriesEntryAmountSourceMissingMessage,
      InventoryEntryStockChange.applied ||
      InventoryEntryStockChange.stockUnchanged =>
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
