import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/inventory/presentation/models/recipe_food_pick.dart';
import 'package:yamt/features/product_search_hub/domain/product_search_hub_exceptions.dart';
import 'package:yamt/features/product_search_hub/domain/recipe_guess_item.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'recipe_food_guess_controller.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_recipe_food_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Egal, irgendeins" at the foot of the food pick: the app estimates the
/// line's food by its name and takes exactly what the line needs. While it
/// estimates, a spinner turns in the button and the line under it says so;
/// the view takes no other tap meanwhile. Shown only when the line names its
/// food and amount, and hidden while the keyboard is open.
class RecipeGuessButton extends ConsumerWidget {
  /// Creates the button.
  const new({required this.args, required this.onGuessed, super.key});

  /// Key of the button.
  static const buttonKey = Key('product_search_hub_recipe_guess');

  /// Key of the line that says why the estimate failed.
  static const errorKey = Key('product_search_hub_recipe_guess_error');

  /// Route args with the recipe line.
  final ProductSearchHubRouteArgs args;

  /// Called with the estimated food.
  final ValueChanged<RecipeFoodPick> onGuessed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final food = args.initialQuery?.trim() ?? '';
    final (unit, need) = (args.ingredientUnit, args.ingredientNeed);
    if (food.isEmpty ||
        unit == null ||
        need == null ||
        need < 1 ||
        MediaQuery.viewInsetsOf(context).bottom > 0) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(recipeFoodGuessControllerProvider);
    final working = state.isLoading;
    final error = state.hasError && !working ? state.error : null;

    Future<void> guess() async {
      final description = recipeGuessDescription(food, args.ingredient);
      final estimate = await ref
          .read(recipeFoodGuessControllerProvider.notifier)
          .guess(description);
      if (estimate == null || !context.mounted) return;
      onGuessed(
        productSearchHubRecipeGuessPick(
          l10n: l10n,
          args: args,
          estimate: estimate,
          description: description,
          unit: unit,
          need: need,
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xs,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.xs,
          children: [
            if (error != null)
              Text(
                switch (error) {
                  FoodEstimateNotFoodException() => l10n.foodEstimateNotFood,
                  FoodEstimateUnclearException() => l10n.foodEstimateUnclear,
                  _ => l10n.foodEstimateFailed,
                },
                key: errorKey,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: colors.low),
              ),
            OutlinedButton.icon(
              key: buttonKey,
              onPressed: working ? null : () => unawaited(guess()),
              // While it works the button stays as clear as before.
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.ink,
                disabledForegroundColor: colors.ink,
                side: BorderSide(color: colors.rule),
                minimumSize: const Size.fromHeight(AppGraphit.buttonHeight),
              ),
              icon: working
                  ? SizedBox.square(
                      dimension: AppSizes.inlineProgressIndicator,
                      child: CircularProgressIndicator(
                        strokeWidth: AppSizes.progressStrokeWidth,
                        color: colors.ink,
                      ),
                    )
                  : const Icon(Icons.auto_awesome_outlined),
              label: Text(l10n.recipeFoodGuess),
            ),
            Text(
              working ? l10n.recipeFoodGuessWorking : l10n.recipeFoodGuessLine,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: colors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
