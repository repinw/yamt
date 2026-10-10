import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_check_status.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Zutaten prüfen" on the recipe page. It stands out while an ingredient is
/// missing or only partly there and not on the shopping list yet, and is
/// quiet once every one is sorted.
class RecipeCheckCard extends ConsumerWidget {
  /// Creates the card for the recipe [recipeId].
  const new({required this.recipeId, required this.onOpen, super.key});

  /// Key of the card.
  static const cardKey = ValueKey<String>('recipe-check-card');

  /// The recipe.
  final String recipeId;

  /// Opens the ingredient check.
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final status = ref.watch(
      recipeCheckStatusProvider(recipeId, l10n.localeName),
    );
    final isOpen = status.missing + status.partial > 0;
    final detail = switch (status) {
      (missing: > 0, partial: > 0) => l10n.recipeCheckOpenBoth(
        status.missing,
        status.partial,
      ),
      (missing: > 0, partial: _) => l10n.recipeCheckMissingCount(
        status.missing,
      ),
      (missing: _, partial: > 0) => l10n.recipeCheckPartialCount(
        status.partial,
      ),
      _ => l10n.recipeCheckSettled,
    };

    return AppInkWell(
      key: cardKey,
      onTap: onOpen,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card,
          border: Border.all(
            color: isOpen ? colors.ink : colors.rule,
            width: isOpen ? AppFoodLabel.chipOutline : AppSizes.hairline,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            spacing: AppSpacing.md,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.xs,
                  children: [
                    Text(
                      l10n.recipeCheckTitle,
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      detail,
                      style: textTheme.bodySmall?.copyWith(
                        color: isOpen ? colors.low : colors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.ink),
            ],
          ),
        ),
      ),
    );
  }
}
