import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'cooked_meal_controller.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/'
    'prepared_meal_eat_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Saves the "Gekocht" step and closes its page.
abstract final class CookedMealSaveFlow {
  const new _();

  /// Marks [meal] as cooked with [portions], counted in pieces when
  /// [servedInPieces], and with the pot's [tareWeight] and the food's
  /// [netWeight] when known. With [toDiary] the eat page opens next for the
  /// first portion. A failure stays on the page and says so.
  static Future<void> save({
    required BuildContext context,
    required WidgetRef ref,
    required PreparedMeal meal,
    required int portions,
    required bool servedInPieces,
    required bool toDiary,
    required int? tareWeight,
    required int? netWeight,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final cooked = await ref
        .read(cookedMealControllerProvider(meal.id).notifier)
        .save(
          totalPortions: portions,
          servedInPieces: servedInPieces,
          potTareWeight: tareWeight,
          netWeight: netWeight,
        );
    if (!context.mounted) {
      return;
    }
    if (cooked == null) {
      messenger.showAppSnackBar(
        l10n.freeCookingSaveFailed,
        tone: AppSnackBarTone.error,
      );
      return;
    }
    if (toDiary) {
      // The eat page shows its own result.
      await PreparedMealEatFlow.eat(context: context, meal: cooked);
      // A meal gone meanwhile closed this page already.
      if (!context.mounted || ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
    }
    context.pop();
    if (!toDiary) {
      messenger.showAppSnackBar(l10n.cookedSaved(meal.name));
    }
  }
}
