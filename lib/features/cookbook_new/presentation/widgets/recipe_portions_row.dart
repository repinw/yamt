import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/portion_stepper.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The portions to cook on the recipe page: how many the recipe is written
/// for, and the stepper. Without [onChanged] the count only shows.
class RecipePortionsRow extends StatelessWidget {
  /// Creates the row for [portions] of a recipe written for [basePortions].
  const new({
    required this.portions,
    required this.basePortions,
    required this.onChanged,
    required this.countKey,
    required this.moreKey,
    super.key,
  });

  /// The portions to cook.
  final int portions;

  /// The portions the recipe is written for.
  final int basePortions;

  /// Called with the new portions; `null` turns the stepper off.
  final ValueChanged<int>? onChanged;

  /// Key of the count.
  final Key countKey;

  /// Key of the button that adds a portion.
  final Key moreKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.cookedPortions,
                style: textTheme.titleMedium?.copyWith(color: colors.ink),
              ),
              Text(
                l10n.recipeOriginalPortions(basePortions),
                style: textTheme.bodySmall?.copyWith(color: colors.muted),
              ),
            ],
          ),
        ),
        PortionStepper(
          count: portions,
          onChanged: onChanged,
          lessTooltip: l10n.cookedPortionsLess,
          moreTooltip: l10n.cookedPortionsMore,
          countKey: countKey,
          moreKey: moreKey,
        ),
      ],
    );
  }
}
