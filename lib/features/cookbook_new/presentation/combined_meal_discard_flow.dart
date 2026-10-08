import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'cooked_meal_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'free_cooking_discard_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Discards a combined meal from its "Gekocht" step.
abstract final class CombinedMealDiscardFlow {
  const new _();

  /// Asks before discarding the meal [mealId], then gives its foods back to
  /// the Vorrat. [onConfirmed] runs before the meal leaves the Vorrat.
  /// Returns whether the meal is gone; a failure says so.
  static Future<bool> discard({
    required BuildContext context,
    required WidgetRef ref,
    required String mealId,
    required VoidCallback onConfirmed,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showFreeCookingDiscardDialog(
      context,
      body: l10n.cookedCombinedDiscardBody,
    );
    if (!confirmed || !context.mounted) {
      return false;
    }
    onConfirmed();
    final undone = await ref
        .read(cookedMealControllerProvider(mealId).notifier)
        .discard();
    if (!undone) {
      messenger.showAppSnackBar(
        l10n.cookedDiscardFailed,
        tone: AppSnackBarTone.error,
      );
    }
    return undone;
  }
}
