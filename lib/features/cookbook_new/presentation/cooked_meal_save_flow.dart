import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'cooked_meal_controller.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Saves the "Gekocht" step and closes its page.
abstract final class CookedMealSaveFlow {
  const new _();

  /// Key of the message that the meal is in the Vorrat but not in the
  /// cookbook.
  static const cookbookFailedKey = ValueKey<String>('cooked-cookbook-failed');

  /// Marks [meal] as cooked with [portions], counted in pieces when
  /// [servedInPieces], and with the pot's [tareWeight] and the food's
  /// [netWeight] when known. With [toCookbook] the cooked meal also becomes
  /// a cookbook template. A failed cooking stays on the page and says so; a
  /// failed template only says so, because the meal is in the Vorrat.
  static Future<void> save({
    required BuildContext context,
    required WidgetRef ref,
    required PreparedMeal meal,
    required int portions,
    required bool servedInPieces,
    required bool toCookbook,
    required int? tareWeight,
    required int? netWeight,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(cookedMealControllerProvider(meal.id).notifier);
    final cooked = await controller.save(
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
    final inCookbook = toCookbook && await controller.addToCookbook(cooked);
    // The cooked meal may close the page meanwhile; the result still shows.
    if (context.mounted) {
      context.pop();
    }
    if (toCookbook && !inCookbook) {
      messenger.showAppSnackBar(
        l10n.cookedCookbookFailed,
        tone: AppSnackBarTone.error,
        key: cookbookFailedKey,
      );
    } else {
      messenger.showAppSnackBar(
        inCookbook
            ? l10n.cookedSavedWithCookbook(meal.name)
            : l10n.cookedSaved(meal.name),
      );
    }
  }
}
