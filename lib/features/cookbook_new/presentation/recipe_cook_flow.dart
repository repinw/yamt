import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Puts a recipe in the pot from its recipe page or its Kochhelfer.
abstract final class RecipeCookFlow {
  /// Cooks the recipe [recipeId] as the recipe page shows it now and
  /// replaces the page with the "Gekocht" step; from the Kochhelfer
  /// ([fromGuide]) the Kochhelfer closes too. A failure says so and stays.
  static Future<void> cook({
    required BuildContext context,
    required WidgetRef ref,
    required String recipeId,
    bool fromGuide = false,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = recipeControllerProvider(recipeId);
    final view = ref.read(recipeViewProvider(recipeId, l10n.localeName)).value;
    // A second tap before the button turns off finds the first cook running.
    // A recipe needs an ingredient that counts, also when it changed meanwhile.
    if (view == null ||
        view.activeLines.isEmpty ||
        ref.read(provider).isCooking) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final mealId = await ref.read(provider.notifier).cook(view);
    if (!context.mounted) {
      return;
    }
    if (mealId == null) {
      messenger.showAppSnackBar(
        l10n.freeCookingSaveFailed,
        tone: AppSnackBarTone.error,
      );
      return;
    }
    // Straight on to the "Gekocht" step; closing it leaves the meal in the pot.
    if (fromGuide) {
      router.pop();
    }
    unawaited(router.pushReplacement(AppRoutes.homeCookedMealPath(mealId)));
  }
}
