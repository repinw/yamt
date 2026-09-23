import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/features/kitchen_utensils/domain/'
    'kitchen_utensil_save_result.dart';
import 'package:yamt/features/kitchen_utensils/presentation/controllers/'
    'kitchen_utensils_controller.dart';
import 'package:yamt/features/kitchen_utensils/presentation/widgets/'
    'kitchen_utensil_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Adds, edits, and deletes utensils, each with an undo in its snack bar.
///
/// The undo reads the controller through the root container, so it still
/// works after the page closed.
abstract final class KitchenUtensilEditFlow {
  /// Asks for a new utensil and saves it.
  static Future<bool> add(BuildContext context, WidgetRef ref) async {
    final draft = await showKitchenUtensilSheet(context: context);
    if (!context.mounted || draft == null) {
      return false;
    }

    final result = await ref
        .read(kitchenUtensilsControllerProvider.notifier)
        .addUtensil(
          name: draft.name,
          imageBytes: draft.imageBytes,
          weightGrams: draft.weightGrams,
        );
    if (!context.mounted) {
      return result.isSuccess;
    }
    final l10n = AppLocalizations.of(context)!;
    final utensilId = result.utensilId;
    if (!result.isSuccess || utensilId == null) {
      _showSaveFailure(context, result);
      return false;
    }

    final container = ProviderScope.containerOf(context, listen: false);
    _messenger(context).showAppSnackBar(
      l10n.kitchenUtensilSavedMessage,
      onUndo: () async {
        final controller = container.read(
          kitchenUtensilsControllerProvider.notifier,
        );
        final removed = await controller.deleteUtensil(utensilId);
        if (removed?.imageStoragePath case final imagePath?) {
          unawaited(controller.discardImage(imagePath));
        }
        return removed != null;
      },
    );
    return true;
  }

  /// Edits [utensil].
  static Future<bool> edit(
    BuildContext context,
    WidgetRef ref,
    KitchenUtensil utensil,
  ) async {
    final draft = await showKitchenUtensilSheet(
      context: context,
      initialUtensil: utensil,
    );
    if (!context.mounted || draft == null) {
      return false;
    }

    final result = await ref
        .read(kitchenUtensilsControllerProvider.notifier)
        .updateUtensil(
          utensilId: utensil.id,
          name: draft.name,
          imageBytes: draft.imageBytes,
          imageChanged: draft.imageChanged,
          weightGrams: draft.weightGrams,
        );
    if (!context.mounted) {
      return result.isSuccess;
    }
    if (!result.isSuccess) {
      _showSaveFailure(context, result);
      return false;
    }

    final l10n = AppLocalizations.of(context)!;
    _showWithRestore(
      context,
      message: l10n.kitchenUtensilUpdatedMessage,
      previous: utensil,
      staleImagePath: draft.imageChanged ? utensil.imageStoragePath : null,
    );
    return true;
  }

  /// Deletes [utensil].
  static Future<bool> delete(
    BuildContext context,
    WidgetRef ref,
    KitchenUtensil utensil,
  ) async {
    final deleted = await ref
        .read(kitchenUtensilsControllerProvider.notifier)
        .deleteUtensil(utensil.id);
    if (!context.mounted) {
      return deleted != null;
    }
    final l10n = AppLocalizations.of(context)!;
    if (deleted == null) {
      _messenger(context).showAppSnackBar(
        l10n.kitchenUtensilDeleteFailed,
        tone: AppSnackBarTone.error,
      );
      return false;
    }

    _showWithRestore(
      context,
      message: l10n.kitchenUtensilDeletedMessage,
      previous: deleted,
      staleImagePath: deleted.imageStoragePath,
    );
    return true;
  }

  /// Shows [message] with an undo that restores [previous]. Without an undo,
  /// the image at [staleImagePath] is deleted once the snack bar closes.
  static void _showWithRestore(
    BuildContext context, {
    required String message,
    required KitchenUtensil previous,
    required String? staleImagePath,
  }) {
    final container = ProviderScope.containerOf(context, listen: false);
    KitchenUtensilsController controller() =>
        container.read(kitchenUtensilsControllerProvider.notifier);
    final snackBar = _messenger(context).showAppSnackBar(
      message,
      onUndo: () => controller().restoreUtensil(previous),
    );
    if (staleImagePath == null) {
      return;
    }
    unawaited(
      snackBar.closed.then((reason) {
        if (reason != SnackBarClosedReason.action) {
          unawaited(controller().discardImage(staleImagePath));
        }
      }),
    );
  }

  static void _showSaveFailure(
    BuildContext context,
    KitchenUtensilSaveResult result,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final message = switch (result.failureReason) {
      KitchenUtensilSaveFailureReason.invalidInput =>
        l10n.kitchenUtensilIdentityRequired,
      KitchenUtensilSaveFailureReason.imageUploadFailed =>
        l10n.kitchenUtensilImageUploadFailed,
      KitchenUtensilSaveFailureReason.saveFailed ||
      null => l10n.kitchenUtensilSaveFailed,
    };
    _messenger(context).showAppSnackBar(message, tone: AppSnackBarTone.error);
  }

  static ScaffoldMessengerState _messenger(BuildContext context) =>
      ScaffoldMessenger.of(context);
}
