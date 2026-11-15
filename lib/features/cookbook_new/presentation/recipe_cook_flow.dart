import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_controller.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Puts a Vorlage in the pot from its recipe page, or opens "Zuweisen" or
/// the cooking page of a recipe.
abstract final class RecipeCookFlow {
  /// Opens the cooking page of the cook [run] of the recipe [recipeId]
  /// once its lines are assigned, else "Zuweisen" for [portions] portions.
  ///
  /// Nothing waits for the push: its future only ends on a pop, and "Zum
  /// Kochbuch" leaves the cooking page with a go.
  static void open({
    required BuildContext context,
    required String recipeId,
    required CookRun? run,
    required int portions,
  }) {
    // A second tap finds the cooking page already over the recipe page.
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) {
      return;
    }
    unawaited(
      context.push<void>(
        AppRoutes.homeCookRecipePath(
          recipeId,
          runId: run == null || run.needsAssigning ? null : run.id,
          portions: portions,
        ),
      ),
    );
  }

  /// Cooks the Vorlage [recipeId] as the recipe page shows it now and
  /// replaces the page with the "Gekocht" step. A failure says so and stays.
  static Future<void> cook({
    required BuildContext context,
    required WidgetRef ref,
    required String recipeId,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = recipeControllerProvider(recipeId);
    final view = ref.read(recipeViewProvider(recipeId, l10n.localeName)).value;
    // A second tap before the button turns off finds the first cook running.
    // A Vorlage needs a food that counts, also when it changed meanwhile.
    if (view == null ||
        view.activeLines.isEmpty ||
        ref.read(provider).isCooking) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final mealId = await ref.read(provider.notifier).cook(view);
    // The failure shows also when the page closed meanwhile.
    if (mealId == null) {
      messenger.showAppSnackBar(
        l10n.cookingSaveFailed,
        tone: AppSnackBarTone.error,
      );
      return;
    }
    if (!context.mounted) {
      return;
    }
    // Straight on to the "Gekocht" step; closing it leaves the meal in the pot.
    unawaited(router.pushReplacement(AppRoutes.homeCookedMealPath(mealId)));
  }
}
