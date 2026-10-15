import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_controller.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet_l10n.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_when_menu.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Plans a Kochbuch recipe or Vorlage from the Kochbuch or its recipe page.
abstract final class RecipePlanFlow {
  /// Key of the snack bar that says the plan is saved.
  static const snackBarKey = ValueKey<String>('recipe-planned');

  /// Asks for the day, then plans one portion of the recipe or Vorlage
  /// [recipeId] as its recipe page shows it now, with an undo. A recipe
  /// with an ingredient that has no Vorrat item becomes a reminder without
  /// kcal. A failure says so.
  static Future<void> plan({
    required BuildContext context,
    required WidgetRef ref,
    required String recipeId,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final container = ProviderScope.containerOf(context, listen: false);
    final today = container.read(clockProvider)();
    final day = await showEatPlanDayPicker(
      context,
      today: today,
      loggedAt: today,
    );
    if (day == null || !context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final view = ref.read(recipeViewProvider(recipeId, l10n.localeName)).value;
    final controller = ref.read(recipeControllerProvider(recipeId).notifier);
    final plan = view == null ? null : await controller.plan(view, day);
    if (plan == null) {
      messenger.showAppSnackBar(
        l10n.caloriesSaveFailed,
        tone: AppSnackBarTone.error,
      );
      return;
    }
    messenger.showAppSnackBar(
      planSavedMessage(l10n, day: plan.loggedAt, today: today),
      key: snackBarKey,
      onUndo: () => container
          .read(recipeControllerProvider(recipeId).notifier)
          .unplan(plan),
    );
  }
}
